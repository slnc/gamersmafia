# -*- encoding : utf-8 -*-
require 'test_helper'

class CacheObserverClanesTest < ActionController::IntegrationTest

  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
    @portal = nil
  end

  def go_to_clanes
    get '/clanes'
    assert_response :success, @response.body
    assert_template 'clanes/index'
  end

  def create_a_clan
    @c = Clan.new(:name => "foomasters", :tag => "tagm")
    assert @c.save, @c.errors.full_messages_html
  end

  test "should update global var on clan update" do
    cur_value = GlobalVars.get_var("clans_updated_on")
    create_a_clan
    assert_not_equal cur_value, GlobalVars.get_var("clans_updated_on")
  end

  test "should_not_clear_biggest_box_on_main_when_clan_changes_its_games_associations" do
    create_a_clan
    User.db_query(
        "UPDATE global_vars SET clans_updated_on = now() - '1 hour'::interval")
    cur_value = GlobalVars.get_var("clans_updated_on")
    assert @c.update_attributes(:game_ids => [])
    assert_not_equal cur_value, GlobalVars.get_var("clans_updated_on")
  end

  test "should_clear_biggest_box_on_main_when_clan_changes_its_members_count" do
    create_a_clan
    User.db_query(
        "UPDATE global_vars SET clans_updated_on = now() - '1 hour'::interval")
    cur_value = GlobalVars.get_var("clans_updated_on")
    @c.add_user_to_group(User.find(1), 'clanleaders')
    assert_not_equal cur_value, GlobalVars.get_var("clans_updated_on")
  end

  test "should_clear_cache_miembros" do
    go_to "/clanes/clan/1", 'clanes/clan'
    assert_cache_exists "/common/clanes/1/miembros"
    c1 = Clan.find(1)
    c1.add_user_to_group(User.find(2), 'members')
    assert_cache_dont_exist "/common/clanes/1/miembros"
  end

  def teardown
    ActionController::Base.perform_caching = false
  end
end
