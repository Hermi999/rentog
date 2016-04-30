namespace :sharetribe do

  namespace :community_updates do
    desc "Sends the community updates email to everyone who should receive it now"
    task :deliver => :environment do |t, args|
      CommunityMailer.deliver_community_updates
    end
  end

  namespace :device_return_notifications do
    desc "Sends a email to everyone who has open bookings"
    task :deliver => :environment do |t, args|
      PersonMailer.deliver_device_return_notifications
    end

    desc "Test the device return notifiaction emails"
    task :test => :environment do |t, args|
      # Test the device return notifications
      # The admin needs to have active and open bookings for this to work
      admin = Person.where(:organization_name => "Administrator").first
      PersonMailer.deliver_device_return_notifications(admin.id)
    end
  end


  # this job should be called every 30 minutes. In this way the subscribers don't
  # get too many emails (eg. if a users changes a booking a few times)
  namespace :device_event_notifications do
    desc "Sends an email to listing subscribers if there are any listing events"
    task :deliver => :environment do |t, args|
      PersonMailer.deliver_device_event_notifications
    end

    desc "Test the device event notifiaction emails"
    task :test => :environment do |t, args|
      # Test the device return notifications
      # The admin needs to have active and open bookings for this to work
      admin = Person.where(:organization_name => "Administrator").first
      PersonMailer.deliver_device_event_notifications(admin.id)
    end
  end

  def random_location_around(coordinate_string, location_type)
    lat = coordinate_string.split(",")[0].to_f + rand*2*MAX_LOC_DIFF - MAX_LOC_DIFF
    lon =  coordinate_string.split(",")[1].to_f + rand*2*MAX_LOC_DIFF - MAX_LOC_DIFF
    address = coordinate_string.split(",")[2] || "#{lat},#{lon}"

    Location.new(:latitude =>  lat, :longitude =>  lon, :location_type  => location_type, :address => address, :google_address => "#{lat},#{lon}")
  end

  desc "Generates customized CSS stylesheets in the background"
  task :generate_customization_stylesheets => :environment do
    # If preboot in use, give 2 minutes time to load new code
    delayed_opts = {priority: 10, :run_at => 2.minutes.from_now }
    CommunityStylesheetCompiler.compile_all(delayed_opts)
  end

  desc "Generates customized CSS stylesheets immediately"
  task :generate_customization_stylesheets_immediately => :environment do
    CommunityStylesheetCompiler.compile_all_immediately()
  end

  desc "Cleans the auth_tokens table in the DB by deleting expired ones"
  task :delete_expired_auth_tokens => :environment do
    AuthToken.delete_expired
  end

  desc "Retries set express checkouts"
  task :retry_and_clean_paypal_tokens => :environment do
    Delayed::Job.enqueue(PaypalService::Jobs::RetryAndCleanTokens.new(1.hour.ago))
  end

  desc "Synchnorizes verified email address states from SES to local DB"
  task :synchronize_verified_with_ses => :environment do
    EmailService::API::Api.addresses.enqueue_batch_sync()
  end
end
