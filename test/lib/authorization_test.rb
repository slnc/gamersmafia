# -*- encoding : utf-8 -*-
require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  test "editor can edit contents own faction" do
    u61 = User.find(61)
    u61.users_skills.clear
    c1 = Content.find(1)
    p c1.content_type
    f1 = Faction.find(1)
    f1.add_editor(u61, c1.content_type)
    assert_equal f1.id, c1.my_faction.id
    assert Authorization.can_edit_content?(u61, c1)
  end

  test "capo can edit contents own faction" do
    u61 = User.find(61)
    u61.users_skills.clear
    f1 = Faction.find(1)
    f1.update_boss(u61)
    c1 = Content.find(1)
    assert_equal f1.id, c1.my_faction.id
    assert Authorization.can_edit_content?(u61, c1)
  end

  test "edit_contents can edit event" do
    u61 = User.find(61)
    u61.users_skills.clear
    u61.users_skills.create(:role => "EditContents")
    e1 = Event.published.find(1).unique_content
    assert Authorization.can_edit_content?(u61, e1)
  end

  test "edit_contents can edit blogentry" do
    u61 = User.find(61)
    u61.users_skills.clear
    u61.users_skills.create(:role => "EditContents")
    be1 = Blogentry.published.find(1).unique_content
    assert Authorization.can_edit_content?(u61, be1)
  end
end
