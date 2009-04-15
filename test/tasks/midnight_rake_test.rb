require File.dirname(__FILE__) + '/../test_helper'
load RAILS_ROOT + '/Rakefile'

class MidnightRakeTest < ActiveSupport::TestCase
  include Rake
  
  def setup
    overload_rake_for_tests
  end
  
  def test_all
    Rake::Task['gm:midnight']
  end
  
  def test_should_reset_faith_to_everybody
    User.db_query("UPDATE users SET cache_remaining_rating_slots = 0, lastseen_on = now() where id = 1")
    u1 = User.find(1)
    assert_equal 0, u1.remaining_rating_slots
    Rake::Task['gm:midnight'].invoke # TODO no podemos llamar varias veces a invoke, solo se ejecuta la primera
    u1.reload
    assert u1.remaining_rating_slots > 0
    
    
    u1 = User.find(1)
    User.db_query("UPDATE users SET cache_remaining_rating_slots = NULL, lastseen_on = now() where id = 1")
    GmSys.job('Faith.reset_remaining_rating_slots')
    u1.reload
    assert u1.remaining_rating_slots > 0
    
    u1 = User.find(1)
    User.db_query("UPDATE users SET cache_remaining_rating_slots = -1, lastseen_on = now() where id = 1")
    GmSys.job('Faith.reset_remaining_rating_slots')
    u1.reload
    assert u1.remaining_rating_slots > 0
  end
end