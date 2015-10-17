class AddDefaultValueToAvailability < ActiveRecord::Migration
  def up
    change_column :listings, :availability, :string, :default => "intern"
  end

  def down
    change_column :listings, :availability, :string, :default => nil
  end
end
