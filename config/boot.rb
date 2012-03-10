require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Necessary to ensure Rails doesn't mix and match timezones.
ENV['TZ'] = "UTC"

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
