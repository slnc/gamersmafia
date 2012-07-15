# -*- encoding : utf-8 -*-
require 'test_helper'

class KeystoreTest < ActiveSupport::TestCase

  test "set should work" do
    Keystore.set("foo", "bar")
  end

  test "get should work" do
    Keystore.get("foo")
  end

  test "get should get what was set" do
    Keystore.set("foo", "bar")
    assert_equal "bar", Keystore.get("foo")
  end

  test "db down shouldn't trigger errors" do
    Redis.any_instance.stubs(:get).raises(Errno::ECONNREFUSED)
    Keystore.get("foo")
  end

  test "cleanup_keys should work" do
    Keystore.cleanup_keys
  end
end
