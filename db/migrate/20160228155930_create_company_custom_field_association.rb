class CreateCompanyCustomFieldAssociation < ActiveRecord::Migration
  def change
    create_table :custom_fields_people do |t|
      t.string :person_id, index: true
      t.belongs_to :custom_field, index: true
      t.timestamps
    end
  end
end
