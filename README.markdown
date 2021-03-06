Harvest Timelog
==============

Plugin which integrates Redmine Timelog with Harvest app (http://harvestapp.com).

## Instalation

Install the plugin as described at: http://www.redmine.org/wiki/redmine/Plugins,

Download the sources and put them to your vendor/plugins folder.

    $ cd {REDMINE_ROOT}
    $ git clone git://github.com/railsant/redmine_charts.git vendor/plugins/redmine_harvest_timelog

Install harvestd gems. 

    $ gem install harvestd

Run Redmine and have a fun!

## Configuration

Before you can actually use the plugin within the preferred projects some setup has to be done first.

- Go to "Administration -> Custom fields" and create a Project custom field of the type "integer", named 'Harvest Project ID' for example.
- Go to "Administration -> Custom fields" and create a User custom field of the type "integer", named 'Harvest User ID' for example.
- Go to "Administration -> Custom fields" and create a Activities custom field of the type "integer", named 'Harvest Task ID' for example.
- Go to "Administration -> Custom fields" and create a Version custom field of the type "integer", named 'Harvest Version Project ID' for example. (optional)

- Go to "Administration -> Plugins -> Redmine Harvest Plugin > Configure" to configure the Harvest plugin:
  * enter Administrator Username and Password in Account Setting
  * select the project custom field which contains the "Harvest Project ID"
  * select the version custom field "Harvest Version Project ID" (optional)
  * select the user custom field "Harvest User ID"
  * select the activity custom field "Harvest Activities ID"
  * Click "Apply"
  
## Usage

After you have completed the Installation and configuration of the plugin, when you enter a timelog in redmine, it will also post the timelog to Harvest with the same comment. However when you remove a timelog it cannot remove accordingly.

## Changelog

### 0.0.5

- Eliminate the gem dependency of Harvested Gems (due to the time entry update problem)

### 0.0.4

- Support Time Entry Edit/Destroy (also edit/sync to Harvest)
- Fix Time Entry time problem

### 0.0.3

- Support Project Version 

### 0.0.2

- Bug fix

### 0.0.1

- Initial Commit

