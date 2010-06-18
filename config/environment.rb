# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.frameworks -= [:active_resource]
  config.load_paths += %W( #{RAILS_ROOT}/app/concerns )
  # config.log_level = :debug
  config.action_controller.session = {
    :session_key => '_tt_session',
    :secret      => 'SEKRITSEKRITSEKRITSEKRITSEKRITSEKRITSEKRITSEKRITSEKRIT!'
  }

  config.gem 'tinder', :version => '1.4.0'
  config.gem 'fastercsv', :version => '1.2.3'
  config.gem 'googlecharts', :lib => "gchart", :version => '1.3.6'
  config.gem 'hpricot', :version => '>=0.6'
  config.gem 'net-toc', :lib => 'net/toc', :version => '0.2'
  config.gem 'hoptoad_notifier'
  config.active_support.use_standard_json_time_format = true
  config.active_record.include_root_in_json = true

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Activate observers that should always be running
  config.active_record.observers = [ :user_observer, :status_observer ]

  # Make Active Record use UTC-base instead of local time
  # rails 2.3
  # config.active_record.default_time_zone = "UTC"
  config.time_zone = "UTC"
  # config.active_record.time_zone = "UTC"
  config.active_record.default_timezone = :utc
  
  config.after_initialize do
    %w(ostruct md5).each { |lib| require lib }
  end
end
