class AddDeviceReturnedToBooking < ActiveRecord::Migration
  def change
    add_column :bookings, :device_returned, :boolean, :default => false
  end
end
