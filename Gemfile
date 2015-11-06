source 'http://rubygems.org'

ruby '2.1.5'

gem 'rails', '3.2.22'

# To use debugger
#gem 'ruby-debug'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', "~> 3.2.2"
  gem 'uglifier'
  gem 'asset_sync'
end

gem 'sass-rails'
gem 'compass-rails'

gem 'jquery-rails', '3.1.3'     # JQUERY_VERSION "1.11.1", JQUERY_UJS_VERSION = "1.0.4"
gem 'jquery-ui-rails', '5.0.5'
gem 'gon', '~> 6.0.1'
gem 'jquery-rails', '2.1.4'

# Bundle the extra gems:

# gem 'heroku' install the Heroku toolbelt (https://toolbelt.heroku.com/) instead (as gem had some problems)
gem "passenger", "~> 5.0.18"
gem "rack-timeout"

gem "mysql2"
gem 'haml'
gem 'sass', "  ~> 3.2.9"
gem 'rest-client', '>= 1.6.0'
gem 'paperclip'
gem 'delayed_paperclip'
gem 'aws-sdk-v1'
gem 'aws-sdk', '~> 2'
gem "will_paginate"
gem 'dalli'
gem "memcachier"
gem 'kgio', "~>2.8.0"
gem 'thinking-sphinx', '~> 3.1.1'
gem 'flying-sphinx', "~>1.2.0"
# Use patched v2.0.2
# Fixes issues: Create a new delayed delta job if there is an existing delta job which has failed
gem 'ts-delayed-delta', '~> 2.0.2'
gem 'possibly', '~> 0.2.0'
gem 'recaptcha'
gem 'delayed_job', "~>3.0.5"
gem 'delayed_job_active_record'
gem 'json', "~>1.8.0"
gem 'multi_json' # 1.8.0 caused "invalid byte sequence in UTF-8" at heroku
gem 'web_translate_it'
gem 'postmark-rails' # could be removed as not currently used
gem 'rails-i18n'
gem 'devise', "~>2.2.4"  #3.0rc requires bit bigger changes
gem "devise-encryptable"
gem "omniauth-facebook", "~> 2.0.1"
gem 'spreadsheet'
gem 'rabl'
gem 'rake'
gem 'xpath'
gem 'dynamic_form'
gem "truncate_html"
gem 'money-rails'
gem 'mercury-rails'
gem 'fb-channel-file'
gem 'country_select', '> 1.2.0'
gem 'braintree'
gem "mail_view", "~> 1.0.3"
gem 'statesman', '~> 0.5.0'
gem "premailer"
gem 'stringex', '~> 2.5.2'
gem 'validates_timeliness', '~> 3.0'
#gem 'paypal-sdk-permissions', '1.96.3'
gem 'paypal-sdk-permissions', '1.96.4'
gem 'paypal-sdk-merchant', '~> 1.116.0'
gem 'airbrake', '~>4.1.0'
gem 'cache_digests'
gem 'librato-rails'
gem 'jwt', '~> 1.5.1'

gem 'lograge'
gem 'public_suffix' # Needed currently to set GA hostname right, probably not
                    # needed anymore when GA script updated.

group :staging, :production do
  gem 'newrelic_rpm', '~> 3.9.1.236'
  # Daemons gem installed because otherwise delayed worker won't work on beanstalk
  gem 'daemons', '~> 1.2.3'
end

group :development, :test do
  gem 'rubocop',          require: false
  gem 'factory_girl_rails'
end

group :development, :staging do
  gem 'meta_request'
end

group :development do
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'rb-fsevent',       require: false
  gem 'guard-rspec',      require: false
  gem 'annotate'
  gem 'zeus', '0.15.1'
  gem 'i18n-tasks', '~> 0.8.3'
  gem 'quiet_assets'
  gem 'better_errors'

  # Rails ERD generates diagrams using Graphviz, a visualisation library.
  # Here's how to instal it: sudo apt-get install graphviz
  # Then run 'rake erd' (http://voormedia.github.io/rails-erd/customise.html)
  gem "rails-erd"
end

group :test do
  gem "rspec-rails", "~>2.99.0"
  gem 'capybara'
  gem 'cucumber-rails', :require => false
  gem 'cucumber'
  gem 'selenium-webdriver'
  gem 'launchy'
  gem 'ruby-prof'
  gem "pickle"
  gem 'email_spec'
  gem 'action_mailer_cache_delivery'
  gem "parallel_tests", :group => :development
  gem 'timecop'
  gem 'rack-test'
  gem 'database_cleaner'
  gem 'connection_pool'
  gem 'coveralls', require: false
end

group :development, :test do
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-nav'
  gem 'pry-stack_explorer'
end

gem 'strong_parameters'
