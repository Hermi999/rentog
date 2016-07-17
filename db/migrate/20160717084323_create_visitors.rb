class CreateVisitors < ActiveRecord::Migration
  def change
    create_table :visitors do |t|
      t.string :session_id
      t.string :name
      t.string :email
      t.string :phone
      t.string :company
      t.string :country
      t.string :ip_address
      t.integer :count_sessions, default: 0

      t.timestamps null: false
    end
  end
end
