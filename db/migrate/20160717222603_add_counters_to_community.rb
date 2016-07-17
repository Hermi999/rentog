class AddCountersToCommunity < ActiveRecord::Migration
  def change
    add_column :communities, :visitor_counter, :integer
    add_column :communities, :unique_visitor_counter, :integer
    add_column :communities, :scroll_visitor_counter, :integer
  end
end
