require 'redmine'
require 'dispatcher'

['harvested'].each do |gem_name|
  begin
    require gem_name
  rescue LoadError
    raise "You are missing the #{gem_name} gem"
  end
end

Dispatcher.to_prepare do
  require_dependency 'time_entry'
  TimeEntry.after_destroy do |time_entry| 
    # Get Harvest Client's Parameter
    harvest_domain = Setting.plugin_redmine_harvest_timelog['harvest_domain']
    harvest_email = Setting.plugin_redmine_harvest_timelog['harvest_email']
    harvest_password = Setting.plugin_redmine_harvest_timelog['harvest_password']
    
    harvest = Harvest.hardy_client(harvest_domain, harvest_email, harvest_password)

    harvest.time.delete(time_entry.harvest_timelog_id) rescue nil if time_entry.harvest_timelog_id.present?
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
      harvest = Harvest.hardy_client(harvest_domain, harvest_email, harvest_password)
      
      time = harvest.time.find(time_entry.harvest_timelog_id, harvest_user_id) rescue Harvest::TimeEntry.new
      time.notes = harvest_note
      time.hours = time_entry.hours
      time.project_id = harvest_project_id
      time.task_id = harvest_task_id
      time.of_user = harvest_user_id
      time.spent_at = harvest_spent_at
      
      harvest_timelog = time.id.blank? ? harvest.time.create(time) : harvest.time.update(time)
      
      TimeEntry.update_all ['harvest_timelog_id = ?', harvest_timelog.id ], ['id = ?', time_entry.id]
    end
    
  end
end

# redmine_harvest_timelog_config = YAML::load(File.read(RAILS_ROOT + "/config/harvest.yml"))

Redmine::Plugin.register :redmine_harvest_timelog do
  name 'Redmine Harvest Time log plugin'
  author 'Benjamin Wong'
  description 'This is a plugin for Redmine to export project timelog data to Harvest.'
  version '0.0.4'
  url 'https://github.com/inspiresynergy/redmine_harvest_timelog'
  author_url 'http://www.inspiresynergy.com'
  
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
