require 'redmine'
require 'harvested'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'time_entry'
  TimeEntry.after_create do |time_entry| 
      
    harvest_user_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_user_id']
    harvest_project_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_project_id']
    harvest_task_id_custom_id = Setting.plugin_redmine_harvest_timelog['harvest_task_id']
    
    # harvest user id 
    custom_value = time_entry.user.custom_values.detect {|v| v.custom_field_id == harvest_user_id_custom_id.to_i}
    harvest_user_id = custom_value.value.to_i if custom_value
    
    # harvest project id 
    custom_value = time_entry.project.custom_values.detect {|v| v.custom_field_id == harvest_project_id_custom_id.to_i}
    harvest_project_id = custom_value.value.to_i if custom_value
    
    # harvest task id 
    custom_value = time_entry.activity.custom_values.detect {|v| v.custom_field_id == harvest_task_id_custom_id.to_i}
    harvest_task_id = custom_value.value.to_i if custom_value

    if harvest_user_id && harvest_project_id && harvest_task_id
      time = Harvest::TimeEntry.new(:notes => time_entry.comments, :hours => time_entry.hours, :project_id => harvest_project_id, :task_id => harvest_task_id, :of_user => harvest_user_id)
      config = YAML::load(File.read(RAILS_ROOT + "/config/harvest.yml"))
      harvest = Harvest.hardy_client(config["domain"], config["email"], config["password"])
      harvest.time.create(time) 
    end rescue nil
  end
end

Redmine::Plugin.register :redmine_harvest_timelog do
  name 'Redmine Harvest Time log plugin'
  author 'Benjamin Wong'
  description 'This is a plugin for Redmine to export project timelog data to Harvest.'
  version '0.0.1'
  # url 'http://example.com/path/to/plugin'
  # author_url 'http://example.com/about'
  
  # This plugin contains settings
  settings :default => {
    'harvest_project_id' => '',
    'harvest_user_id' => '', 
    'harvest_task_id' => ''
  }, :partial => 'settings/harvest_settings'
  
end
