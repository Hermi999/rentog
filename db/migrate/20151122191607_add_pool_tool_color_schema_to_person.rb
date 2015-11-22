class AddPoolToolColorSchemaToPerson < ActiveRecord::Migration
  def change
    add_column :people, :pool_tool_color_schema, :string, :default=>"theme_dark"
  end
end
