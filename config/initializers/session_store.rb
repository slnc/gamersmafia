# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Gamersmafia::Application.config.session_store :cookie_store,
  :key => 'adn2', :domain => ".#{App.domain}"
