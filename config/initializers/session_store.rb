# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => 'adn2',
  :secret      => '171676f846da1d217ffc44a1a6cd2bed87c727b118b3f0c04c25668d539cca50ef2a67f7016248a481fd02f414f90dae2222786af50736c147f8ad6a3b0fdde5b2a84',
  :domain => ".#{App.domain}"
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
