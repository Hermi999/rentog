class AddDeviceReturnTokenToBooking < ActiveRecord::Migration
  def change
    add_column :bookings, :device_return_token, :string, :default => "33881b4582b5cfc17967"   # any random default value
  end
end
