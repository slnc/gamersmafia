# -*- encoding : utf-8 -*-
require 'test_helper'


class CacheObserverSlogTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # MAIN
  def atest_should_clear_cache
    User.db_query("UPDATE users SET is_hq = 't' WHERE login='superadmin'")
    superadmin = User.find_by_login('superadmin')
    sym_login 'superadmin', 'lalala'
    go_to '/'
    assert_cache_exists "common/slog/#{superadmin.id}"
    assert_count_increases(SlogEntry) do
      SlogEntry.create(:type_id => SlogEntry::TYPES[:error], :headline => 'soy una slogentry molona', :info => 'lolali')
    end
    assert_cache_dont_exist "common/slog/#{superadmin.id}"
    go_to '/site/slog', 'site/slog_html'
    #assert_cache_dont_exist "common/slog/#{superadmin.id}"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
