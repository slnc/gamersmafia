# -*- encoding : utf-8 -*-
require 'test_helper'
load Rails.root + '/Rakefile'

class MidnightRakeTest < ActiveSupport::TestCase
  include Rake

  def setup
    overload_rake_for_tests
  end

  test "all" do
    Rake::Task['gm:midnight']
  end
end
