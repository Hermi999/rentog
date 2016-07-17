class CreateRentogEvents < ActiveRecord::Migration
  def change
    create_table :rentog_events do |t|
      t.string :starter_id
      t.string :other_party_id
      t.string :event_name
      t.string :event_details
      t.boolean :send_to_admins
      t.integer :rentog_version
      t.string :split_test_id

      t.timestamps null: false
    end
  end
end
