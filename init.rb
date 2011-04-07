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
  TimeEntry.after_create do |time_entry| 
      
    harvest_user_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_user_id']
    harvest_project_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_project_id']
    harvest_version_project_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_version_project_id']
    harvest_task_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_task_id']
    harvest_domain = Setting.plugin_redmine_harvest_timelog['harvest_domain']
    harvest_email = Setting.plugin_redmine_harvest_timelog['harvest_email']
    harvest_password = Setting.plugin_redmine_harvest_timelog['harvest_password']
    
    # harvest user id 
    custom_value = time_entry.user.custom_values.detect {|v| v.custom_field_id == harvest_user_id_custom_id.to_i}
    harvest_user_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    # harvest project id (priority version project > project)
    custom_value = time_entry.project.custom_values.detect {|v| v.custom_field_id == harvest_project_id_custom_id.to_i}
    harvest_project_id = custom_value.value.present? ? custom_value.value.to_i : false
    
    if time_entry.issue.present? && time_entry.issue.fixed_version.present?
      custom_value = time_entry.issue.fixed_version.custom_values.detect {|v| v.custom_field_id == harvest_version_project_id_custom_id.to_i}
      harvest_project_id = custom_value.value.present? ? custom_value.value.to_i : false
    end
    
    # harvest task id 
    custom_value = time_entry.activity.custom_values.detect {|v| v.custom_field_id == harvest_task_id_custom_id.to_i}
    harvest_task_id = custom_value.value.present? ? custom_value.value.to_i : false

    if harvest_user_id && harvest_project_id && harvest_task_id
      note = time_entry.issue.present? ? "#{time_entry.issue.to_s} (#{time_entry.comments})" : time_entry.comments
      time = Harvest::TimeEntry.new(:notes => note, :hours => time_entry.hours, :project_id => harvest_project_id, :task_id => harvest_task_id, :of_user => harvest_user_id)
      harvest = Harvest.hardy_client(harvest_domain, harvest_email, harvest_password)
      harvest.time.create(time) 
    end rescue nil
  end
end

# redmine_harvest_timelog_config = YAML::load(File.read(RAILS_ROOT + "/config/harvest.yml"))

Redmine::Plugin.register :redmine_harvest_timelog do
  name 'Redmine Harvest Time log plugin'
  author 'Benjamin Wong'
  description 'This is a plugin for Redmine to export project timelog data to Harvest.'
  version '0.0.3'
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
