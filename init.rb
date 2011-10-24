require 'redmine'
require 'dispatcher'
require 'active_support'
require 'active_support/core_ext'


Dispatcher.to_prepare do
  require_dependency 'time_entry'
  TimeEntry.after_destroy do |time_entry| 
    # Get Harvest Client's Parameter
    harvest_domain = Setting.plugin_redmine_harvest_timelog['harvest_domain']
    harvest_email = Setting.plugin_redmine_harvest_timelog['harvest_email']
    harvest_password = Setting.plugin_redmine_harvest_timelog['harvest_password']
    
    # all timelog custom_id
    harvest_user_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_user_id']
    
    # collect harvest user id 
    custom_value = time_entry.user.custom_values.detect {|v| v.custom_field_id == harvest_user_id_custom_id.to_i}
    harvest_user_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    # Connect to Harvest
    harvest = Harvest.new(harvest_domain, harvest_email, harvest_password)

    # Delete the time entry if any
    harvest.request("/daily/delete/#{time_entry.harvest_timelog_id}?of_user=#{harvest_user_id}",:delete) rescue nil if time_entry.harvest_timelog_id.present?
  end
  TimeEntry.after_save do |time_entry| 
    
    # Get Harvest Client's Parameter
    harvest_domain = Setting.plugin_redmine_harvest_timelog['harvest_domain']
    harvest_email = Setting.plugin_redmine_harvest_timelog['harvest_email']
    harvest_password = Setting.plugin_redmine_harvest_timelog['harvest_password']
    
    # all timelog custom_id
    harvest_user_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_user_id']
    harvest_project_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_project_id']
    harvest_version_project_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_version_project_id']
    harvest_task_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_task_id']
    
    # collect harvest user id 
    custom_value = time_entry.user.custom_values.detect {|v| v.custom_field_id == harvest_user_id_custom_id.to_i}
    harvest_user_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    # collect harvest project id (priority version project > project)
    custom_value = time_entry.project.custom_values.detect {|v| v.custom_field_id == harvest_project_id_custom_id.to_i}
    harvest_project_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    if time_entry.issue.present? && time_entry.issue.fixed_version.present?
      custom_value = time_entry.issue.fixed_version.custom_values.detect {|v| v.custom_field_id == harvest_version_project_id_custom_id.to_i}
      harvest_project_id = custom_value.value.present? ? custom_value.value.to_i : false
    end
    
    # collect harvest task id 
    custom_value = time_entry.activity.custom_values.detect {|v| v.custom_field_id == harvest_task_id_custom_id.to_i}
    harvest_task_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    # collect notes
    harvest_note = time_entry.issue.present? ? "#{time_entry.issue.to_s} (#{time_entry.comments})" : time_entry.comments
    
    # collect spent at
    harvest_spent_at = time_entry.spent_on
    
    if harvest_user_id && harvest_project_id && harvest_task_id
      
      # Connect to Harvest
      harvest = Harvest.new(harvest_domain, harvest_email, harvest_password)
      
      # Build the Request String
      request = %Q{<request>
        <notes>#{harvest_note}</notes>
        <hours>#{time_entry.hours}</hours>
        <project_id type="integer">#{harvest_project_id}</project_id>
        <task_id type="integer">#{harvest_task_id}</task_id>
        <spent_at type="date">#{harvest_spent_at.to_date}</spent_at>
      </request>}
      
      # create or update 
      # FIXME : DRY it 
      if time_entry.harvest_timelog_id
        # Try update it directly. if 404, then clean it up and update with new harvest_timelog id
        begin 
          harvest.request "/daily/update/#{time_entry.harvest_timelog_id}?of_user=#{harvest_user_id}", :post, request
        rescue Exception => e 
          response = harvest.request "/daily/add?of_user=#{harvest_user_id}", :post, request
          time_entry.update_attribute :harvest_timelog_id, Hash.from_xml(response.body)['add']['day_entry']['id']
        end
      else
        response = harvest.request "/daily/add?of_user=#{harvest_user_id}", :post, request
        time_entry.update_attribute :harvest_timelog_id, Hash.from_xml(response.body)['add']['day_entry']['id']
      end
    end
  end
end

Redmine::Plugin.register :redmine_harvest_timelog do
  name 'Redmine Harvest Time log plugin'
  author 'Benjamin Wong'
  description 'This is a plugin for Redmine to export project timelog data to Harvest.'
  version '0.0.5'
  url 'https://github.com/railsant/redmine_harvest_timelog'
  author_url 'http://www.railsant.com'
  
  # This plugin contains settings
  settings :default => {
    'harvest_project_id' => '',
    'harvest_version_project_id' => '',
    'harvest_user_id' => '', 
    'harvest_task_id' => '', 
    'harvest_domain' => '',#redmine_harvest_timelog_config["domain"], 
    'harvest_email' => '', #redmine_harvest_timelog_config["email"], 
    'harvest_password' => '', #redmine_harvest_timelog_config["password"], 
  }, :partial => 'settings/harvest_settings'
  
end
