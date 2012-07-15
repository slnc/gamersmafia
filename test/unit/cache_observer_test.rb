# -*- encoding : utf-8 -*-
require 'test_helper'

class CacheObserverTest < ActiveSupport::TestCase
  test "expire_fragment_should_delete_given_cache_id_if_existing" do
    f = "#{FRAGMENT_CACHE_PATH}/cache_observer_test.file.cache"
    cache_id = '/cache_observer_test.file'
    FileUtils.mkdir_p(File.dirname(f)) unless File.exists?(File.dirname(f))
    fp = File.open(f, 'w+')
    fp.write('foo')
    fp.close
    assert_equal true, File.exists?(f)
    CacheObserver.expire_fragment cache_id
    assert_equal false, File.exists?(f)
  end

  test "expire_fragment_should_do_nothing_when_given_cache_id_didnt_exist" do
    CacheObserver.expire_fragment '/unexisting'
  end
end
