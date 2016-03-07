class AddPoolToolShowLegendToPerson < ActiveRecord::Migration
  def change
    add_column :people, :pool_tool_show_legend, :string, :default => true
  end
end
