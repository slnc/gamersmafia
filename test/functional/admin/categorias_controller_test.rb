# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::CategoriasControllerTest < ActionController::TestCase

  test "index_no_perm" do
    sym_login 3
    assert_raises(AccessDenied) { get :index }
  end

  test "index_capo" do
    give_skill(2, "Capo")
    sym_login 2
    get :index
    assert_response :success
  end

  test "index_boss" do
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    sym_login 2
    get :index
    assert_response :success
  end

  test "index_editor" do
    u2 = User.find(2)
    f1 = Faction.find(1)
    f1.add_editor(u2, ContentType.find(:first))
    sym_login 2
    get :index
    assert_response :success
  end

  test "index_don" do
    u2 = User.find(2)
    bd1 = BazarDistrict.find(1)
    bd1.update_don(u2)
    sym_login 2
    get :index
    assert_response :success
  end

  test "index_sicario" do
    u2 = User.find(2)
    bd1 = BazarDistrict.find(1)
    bd1.add_sicario(u2)
    sym_login 2
    get :index
    assert_response :success
  end

  test "hijos_if_perm" do
    give_skill(2, "Capo")
    sym_login 2
    get :hijos, :id => 1, :content_type => 'News'
  end

  test "hijos_if_no_perm" do
    u2 = User.find(2)
    sym_login 2
    assert_raises(AccessDenied) { get :hijos, :id => 1, :content_type => 'Topic' }
  end

  test "hijos_if_boss_but_no_perm" do
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)

    sym_login 2
    assert_raises(AccessDenied) do
      get :hijos, :id => 5, :content_type => 'Topic' # anime
    end
  end

  test "contenidos_if_perm" do
    give_skill(2, "Capo")
    sym_login 2
    get :contenidos, :id => 1, :content_type => 'Topic'
  end

  test "contenidos_if_no_perm" do
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)

    sym_login 2
    assert_raises(AccessDenied) { get :contenidos, :id => 5, :content_type => 'Topic' } # anime
  end

  test "cant_create_root_level_blank_taxonomy_term" do
    give_skill(2, "Capo")
    sym_login 2
    assert_raises(AccessDenied) do
      post :create, :term => { :name => 'furrinori', :taxonomy => ''}
    end
  end


  test "create_if_perm" do
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)

    sym_login 2
    assert_count_increases(Term) do
      post :create, :term => { :name => 'furrinori', :taxonomy => 'TopicsCategory', :parent_id => 1}
      assert_response :redirect
    end

    @t = Term.find(:first, :order => 'id DESC')
    assert_equal 'furrinori', @t.name
    assert_equal 'TopicsCategory', @t.taxonomy
    assert_equal 1, @t.parent_id
  end

  test "create_if_no_perm" do
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)

    sym_login 2

    assert_raises(AccessDenied) do
      post :create, :term => { :name => 'furrinori', :taxonomy => 'TopicsCategory', :parent_id => 5}
    end
  end

  test "update_if_perm" do
    test_create_if_perm
    post :update, :id => @t.id, :term => { :name => 'furrinori2' }
    assert_response :redirect
    @t.reload
    assert_equal 'furrinori2', @t.name
  end

  test "update_if_no_perm" do
    test_create_if_perm
    sym_login 3
    assert_raises(AccessDenied) do
      post :update, :id => @t.id, :term => { :name => 'furrinori2' }
    end
  end

  test "mass_move_if_perm" do
    test_create_if_perm
    n = Topic.find(:first)
    assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    post :mass_move, :id => @t.id, :destination_term_id => 17, :content_type => 'Topic', :contents => [n.unique_content.id]
    assert_response :redirect
    assert_equal 0, @t.find(:all, :content_type => 'Topic', :conditions => ['contents.id = ?', n.unique_content_id]).size
    t17 = Term.find(17)
    assert_equal 1, t17.find(:all, :content_type => 'Topic', :conditions => ['contents.id = ?', n.unique_content_id]).size
  end

  test "mass_move_if_no_perm" do
    test_create_if_perm
    n = Topic.find(:first)
    t = Term.single_toplevel(:slug => 'deportes').children.create(:name => 'general', :taxonomy => 'TopicsCategory')
    # assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    assert_raises(AccessDenied) do
      post :mass_move, :id => t.id, :destination_term_id => 5, :content_type => 'Topic', :contents => [n.unique_content.id]
    end
  end

  test "destroy_if_perm" do
    test_create_if_perm
    post :destroy, :id => @t.id
    assert_response :redirect
    assert_nil Term.find_by_id(@t.id)
  end

  test "destroy_if_perm_and_root" do
    g = Game.new(:name => 'baaaa', :code => 'b2')
    assert g.save
    @t1 = Term.single_toplevel(:slug => g.code)
    assert_not_nil @t1
    Faction.find_by_code(g.code).destroy
    sym_login 1
    post :destroy, :id => @t1.id
    assert_response :redirect
    assert_nil Term.find_by_id(@t1.id)
  end

  test "destroy_if_no_perm" do
    test_create_if_perm
    sym_login 3
    assert_raises(AccessDenied) do
      post :destroy, :id => @t.id
    end
  end

  test "destroy_if_perm_but_not_empty" do
    test_create_if_perm
    n = Topic.find(:first)
    assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    post :destroy, :id => @t.id
    assert_response :redirect
    assert Term.find_by_id(@t.id)
  end
end
