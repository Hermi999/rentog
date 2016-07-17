class AddEventResultToRentogEvents < ActiveRecord::Migration
  def change
    add_column :rentog_events, :event_result, :string
  end
end
