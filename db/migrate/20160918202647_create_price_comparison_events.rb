class CreatePriceComparisonEvents < ActiveRecord::Migration
  def change
    create_table :price_comparison_events do |t|
      t.string :action_type, default: "device_chosen", null: false
      t.string :email
      t.string :sessionId, null: false
      t.string :ipAddress, null: false
      t.string :device_name
      t.integer :device_id

      t.timestamps null: false
    end
  end
end
