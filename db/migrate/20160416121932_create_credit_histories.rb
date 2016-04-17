class CreateCreditHistories < ActiveRecord::Migration
  def change
    create_table :credit_histories do |t|
      t.string  :person_id
      t.string  :other_user_id
      t.string  :type
      t.integer :credits
      t.timestamps null: false
    end
  end
end
