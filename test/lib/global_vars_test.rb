# -*- encoding : utf-8 -*-
require 'test_helper'

class GlobalVarsTest < ActiveSupport::TestCase
  test "update invalid var name chars" do
    assert_raises(RuntimeError) do
      GlobalVars.update_var("@#!", "foo")
    end
  end

  test "update nonexisting var" do
    assert_raises(ActiveRecord::StatementInvalid) do
      GlobalVars.update_var("nonexisting", "foo")
    end
  end

  test "update valid var" do
    GlobalVars.update_var("online_anonymous", "5")
  end

  test "get invalid var name chars valid var" do
    assert_raises(RuntimeError) do
      GlobalVars.get_var("@#!")
    end
  end

  test "get nonexisting var name" do
    assert_raises(ActiveRecord::StatementInvalid) do
      GlobalVars.get_var("nonexisting")
    end
  end

  test "get valid var name" do
    assert GlobalVars.get_var("online_anonymous")
  end

  test "get_all_vars" do
    assert GlobalVars.get_all_vars
  end
end

