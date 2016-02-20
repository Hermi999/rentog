Given /^there exists an internal booking for company "([^"]*)" and listing "([^"]*)" with reason "([^"]*)" and length (\d+) days and offset (\d+) days$/ do |username, listing_title, reason, length, offset|
  listing_id = Listing.where(:title => listing_title).first.id
  starter_id = author_id = Person.where(:username => username).first.id
  start_date = Date.today + offset.to_i
  end_date = start_date + length.to_i
  booking_fields = {:start_on=>start_date, :end_on=>end_date, :reason=>reason}

  TransactionService::Transaction.create(
  {
    transaction: {
      community_id: @current_community.id,
      listing_id: listing_id,
      listing_title: listing_title,
      starter_id: starter_id,
      listing_author_id: author_id,
      listing_quantity: (length.to_i + 1),
      content: nil,
      booking_fields: booking_fields,
      payment_gateway: :none,
      payment_process: :none
    }
  })
end

Given /^there exists an internal booking for company "([^"]*)" and employee "([^"]*)" and listing "([^"]*)" with length (\d+) and offset (\d+) days$/ do |username, employee_username, listing_title, length, offset|
  listing_id = Listing.where(:title => listing_title).first.id
  starter_id = Person.where(:username => employee_username).first.id
  author_id = Person.where(:username => username).first.id
  start_date = Date.today + offset.to_i
  end_date = start_date + length.to_i
  booking_fields = {:start_on=>start_date, :end_on=>end_date}

  TransactionService::Transaction.create(
  {
    transaction: {
      community_id: @current_community.id,
      listing_id: listing_id,
      listing_title: listing_title,
      starter_id: starter_id,
      listing_author_id: author_id,
      listing_quantity: (length.to_i + 1),
      content: nil,
      booking_fields: booking_fields,
      payment_gateway: :none,
      payment_process: :none
    }
  })
end

Given /^there exists an external booking for company "([^"]*)" from company "([^"]*)" and listing "([^"]*)" with length (\d+) days and offset (\d+) days$/ do |author_username, starter_username, listing_title, length, offset|
  listing_id = Listing.where(:title => listing_title).first.id
  starter_id = Person.where(:username => starter_username).first.id
  author_id = Person.where(:username => author_username).first.id
  start_date = Date.today + offset.to_i
  end_date = start_date + length.to_i
  booking_fields = {:start_on=>start_date, :end_on=>end_date}

  TransactionService::Transaction.create(
  {
    transaction: {
      community_id: @current_community.id,
      listing_id: listing_id,
      listing_title: listing_title,
      starter_id: starter_id,
      listing_author_id: author_id,
      listing_quantity: (length.to_i + 1),
      content: nil,
      booking_fields: booking_fields,
      payment_gateway: :none,
      payment_process: :none
    }
  })
end

When(/I fill booking start-date \+(\d+) and end-date \+(\d+) days$/) do |start_date_offset, end_date_offset|
  start_on = Date.today + start_date_offset.to_i
  end_on = Date.today + end_date_offset.to_i

  start_on_output = start_on.strftime("%m/%d/%Y")
  start_on_output_hidden = start_on.strftime("%Y-%m-%d")
  end_on_output = end_on.strftime("%m/%d/%Y")
  end_on_output_hidden = end_on.strftime("%Y-%m-%d")

  # Selenium can not interact with hidden elements, use JavaScript
  page.execute_script("$('#start-on').val('#{start_on_output}')");
  page.execute_script("$('#booking-start-output').val('#{start_on_output_hidden}')");
  page.execute_script("$('#end-on').val('#{end_on_output}')");
  page.execute_script("$('#booking-end-output').val('#{end_on_output_hidden}')");
end

When(/I update start-date \+(\d+) and end-date \+(\d+) days$/) do |start_date_offset, end_date_offset|
  start_on = Date.strptime(find_field('start_on2').value,"%m/%d/%Y") + start_date_offset.to_i
  end_on = Date.strptime(find_field('end_on2').value,"%m/%d/%Y") + end_date_offset.to_i

  start_on_output = start_on.strftime("%m/%d/%Y")
  start_on_output_hidden = start_on.strftime("%Y-%m-%d")
  end_on_output = end_on.strftime("%m/%d/%Y")
  end_on_output_hidden = end_on.strftime("%Y-%m-%d")

  # Selenium can not interact with hidden elements, use JavaScript
  page.execute_script("$('#start-on2').val('#{start_on_output}')");
  page.execute_script("$('#booking-start-output2').val('#{start_on_output_hidden}')");
  page.execute_script("$('#end-on2').val('#{end_on_output}')");
  page.execute_script("$('#booking-end-output2').val('#{end_on_output_hidden}')");
end

Then /^there should be a booking with starter "([^"]*)" and reason "([^"]*)" in the Db$/ do |starter_username, reason|
  expect(Booking.last.tx.starter.username).to eq(starter_username)
  expect(Booking.last.reason).to eq(reason)
end

Then /^there should be a booking with starter "([^"]*)" in the Db$/ do |starter_username|
  expect(Booking.last.tx.starter.username).to eq(starter_username)
end

Then /^there should be a booking with starter "([^"]*)", start-date \+(\d+), end-date \+(\d+), length (\d+) and offset (\d+) days in the Db$/ do |starter_username, start_date_offset, end_date_offset, length, initial_offset|
  starter = Person.where(:username => starter_username).first
  booking = Booking.joins(:tx).where('transactions.starter_id = ?', starter.id).first

  expect(booking.tx.starter.username).to eq(starter_username)
  expect(booking.start_on).to eq(Date.today + initial_offset.to_i + start_date_offset.to_i)
  expect(booking.end_on).to eq(Date.today + length.to_i + initial_offset.to_i + end_date_offset.to_i)
end

Then /^there should not be a booking with starter "([^"]*)" in the Db$/ do |starter_username|
  starter = Person.where(:username => starter_username).first
  booking = Booking.joins(:tx).where('transactions.starter_id = ?', starter.id).first
  expect(booking).to eq(nil)
end

Then /^there should not be a booking with starter "([^"]*)" and reason "([^"]*)" in the Db$/ do |starter_username, reason|
  starter = Person.where(:username => starter_username).first
  booking = Booking.joins(:tx).where('bookings.reason = ? and transactions.starter_id = ?', reason, starter.id).first
  expect(booking).to eq(nil)
end
