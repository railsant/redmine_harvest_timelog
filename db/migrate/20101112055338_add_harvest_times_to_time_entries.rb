class AddHarvestTimesToTimeEntries < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :harvest_timelog_id, :integer
  end

  def self.down
    remove_column :time_entries, :harvest_timelog_id
  end
end
