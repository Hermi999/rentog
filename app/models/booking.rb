# == Schema Information
#
# Table name: bookings
#
#  id              :integer          not null, primary key
#  transaction_id  :integer
#  start_on        :date
#  end_on          :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  reason          :string(255)
#  device_returned :boolean          default(FALSE)
#  description     :string(255)
#

class Booking < ActiveRecord::Base

  belongs_to :transaction

  attr_accessible :transaction_id, :end_on, :start_on, :reason, :description, :device_returned

  validates :start_on, :end_on, presence: true
  validates_date :end_on, on_or_after: :start_on

  ## TODO REMOVE THIS
  def duration
    (end_on - start_on).to_i + 1
  end

  # Get overdue of this bookings in days
  def getOverdueInDays
    (Date.today - end_on).to_i
  end

  # Is the current booking active?
  def is_active?
    start_on <= Date.today && end_on >= Date.today
  end

  # Is the current booking in future?
  def is_in_future?
    start_on > Date.today
  end

  def return!
    update_attributes :device_returned => true, :end_on => Date.today
  end

  # Returns all open bookings [of a specific listing] which should be returned
  # by now, because the return date is in the past
  def self.getOverdueBookings(listing_id=nil)
    if listing_id.nil?
      Booking.where("device_returned = false AND end_on < ?", Date.today)
    else
      Booking.joins(:transaction).where('listing_id = ? AND device_returned = false AND end_on < ?', listing_id, Date.today)
    end
  end

  # Returns all bookings [of a specific listing], which are currently active
  def self.getActiveBookings(listing_id=nil)
    if listing_id.nil?
      Booking.where("end_on >= ? AND start_on <= ?", Date.today, Date.today)
    else
      Booking.joins(:transaction).where('listing_id = ? AND end_on >= ? AND start_on <= ?', listing_id, Date.today, Date.today)
    end
  end

  # Returns all open bookings [of a specific listing], no matter if they are in
  # the future or in the past (overdue)
  def self.getOpenBookings(listing_id=nil)
    if listing_id.nil?
      Booking.where("device_returned = false")
    else
      Booking.joins(:transaction).where("listing_id = ? AND device_returned = false", listing_id)
    end
  end

  # Returns all open bookings of a user [and a specific listing] which should be
  # returned by now, because the return date is in the past
  def self.getOverdueBookingsOfUser(user_id, listing_id=nil)
    if listing_id.nil?
      Booking.joins(:transaction).where('starter_id = ? AND device_returned = false AND end_on < ?', user_id, Date.today)
    else
      Booking.joins(:transaction).where('listing_id = ? AND starter_id = ? AND device_returned = false AND end_on < ?', listing_id, user_id, Date.today)
    end
  end

  # Returns all bookings of a user [and a specific listing] which are currently active
  def self.getActiveBookingsOfUser(user_id, listing_id=nil)
    if listing_id.nil?
      Booking.joins(:transaction).where('starter_id = ? AND end_on >= ? AND start_on <= ?', user_id, Date.today, Date.today)
    else
      Booking.joins(:transaction).where('listing_id = ? AND starter_id = ? AND end_on >= ? AND start_on <= ?', listing_id, user_id, Date.today, Date.today)
    end
  end

  # Returns all open bookings of a user [and a specific listing], no matter if
  # they are in the future or in the  past (overdue)
  def self.getOpenBookingsOfUser(user_id, listing_id=nil)
    if listing_id.nil?
      Booking.joins(:transaction).where("starter_id = ? AND device_returned = false", user_id)
    else
      Booking.joins(:transaction).where("listing_id = ? AND starter_id = ? AND device_returned = false", listing_id, user_id)
    end
  end

  # Returns all open bookings of a company [and specific listing] which should
  # be returned by now, because the return date is in the past
  def self.getOverdueBookingsOfCompany(company, listing_id=nil)
    overdueBookings = {}

    # Get all employees of company
    employees = company.employees

    # Get the open bookings of each user and store them into array
    employees.each_with_index do |employee, i|
      if listing_id.nil?
        employee_overdueBookings = getOverdueBookingsOfUser(employee.id)
      else
        employee_overdueBookings = getOverdueBookingsOfUser(employee.id, listing_id)
      end

      overdueBookings["user_#{i}"] = {
        employee: employee,                  # Person
        bookings: employee_overdueBookings   # Array of Bookings
      }
    end

    overdueBookings
  end

  # Returns all currently active bookings of a company [and specific listing]
  def self.getActiveBookingsOfCompany(company, listing_id=nil)
    activeBookings = {}

    # Get all employees of company
    employees = company.employees

    # Get the open bookings of each user and store them into array
    employees.each_with_index do |employee, i|
      if listing_id.nil?
        employee_activeBookings = getActiveBookingsOfUser(employee.id)
      else
        employee_activeBookings = getActiveBookingsOfUser(employee.id, listing_id)
      end

      activeBookings["user_#{i}"] = {
        employee: employee,                 # Person
        bookings: employee_activeBookings   # Array of Bookings
      }
    end

    activeBookings
  end

  # Returns all open bookings of a company [and specific listing], no matter if
  # they are in the future or in the  past (overdue)
  def self.getOpenBookingsOfCompany(company, listing_id=nil)
    openBookings = {}

    # Get all employees of company
    employees = company.employees

    # Get the open bookings of each user and store them into array
    employees.each_with_index do |employee, i|
      if listing_id.nil?
        employee_openBookings = getOpenBookingsOfUser(employee.id)
      else
        employee_openBookings = getOpenBookingsOfUser(employee.id, listing_id)
      end

      openBookings["user_#{i}"] = {
        employee: employee,              # Person
        bookings: employee_openBookings  # Array of Bookings
      }
    end

    openBookings
  end



  # Sets the device returned status of a booking to 'new_val'
  def setDeviceReturnedTo(new_val)
    update_attribute :device_returned, new_val
  end

  # Set all overdue bookings of user [and listing] to status "returned"
  def self.setDeviceReturnedOfOverdueBookingsOfUser(new_val, user_id, listing_id=nil)
    if listing_id.nil?
      overdueBookings = self.getOverdueBookingsOfUser(user_id)
    else
      overdueBookings = self.getOverdueBookingsOfUser(user_id, listing_id)
    end

    overdueBookings.each do |overdueBooking|
      overdueBooking.setDeviceReturnedTo(new_val)
    end
  end

  # Set all overdue bookings of company [and listing] to status "returned"
  def self.setDeviceReturnedOfOverdueBookingsOfCompany(new_val, company, listing=nil)
    if listing_id.nil?
      overdueBookings = self.getOverdueBookingsOfCompany(company)
    else
      overdueBookings = self.getOverdueBookingsOfCompany(company, listing_id)
    end

    overdueBookings.each do |overdueBooking|
      overdueBooking.setDeviceReturnedTo(new_val)
    end
  end

  # Set all overdue bookings of listing to status "returned"
  def self.setDeviceReturnedOfOverdueBookingsOfListing(new_val, listing_id)
    overdueBookings = self.getOverdueBookings(listing_id)

    overdueBookings.each do |overdueBooking|
      overdueBooking.setDeviceReturnedTo(new_val)
    end
  end

end
