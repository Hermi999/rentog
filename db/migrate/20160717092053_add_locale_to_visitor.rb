class AddLocaleToVisitor < ActiveRecord::Migration
  def change
    add_column :visitors, :locale, :string, default: "en"
  end
end
