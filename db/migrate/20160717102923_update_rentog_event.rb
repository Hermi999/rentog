class UpdateRentogEvent < ActiveRecord::Migration
  def change
    add_column :rentog_events, :visitor_id, :integer
    rename_column :rentog_events, :starter_id, :person_id
  end
end
