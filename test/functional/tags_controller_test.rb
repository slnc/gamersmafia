# -*- encoding : utf-8 -*-
require 'test_helper'

class TagsControllerTest < ActionController::TestCase

  test "index should work without tags" do
    get :index
    assert_response :success
  end

  test "index should work with tags" do
    t = Term.create(:taxonomy => 'ContentsTag', :name => 'foo')
    t.link(Content.find(:first))

    get :index
    assert_response :success
  end

  test "show should work" do
    t = Term.create(:taxonomy => 'ContentsTag', :name => 'foo')
    t.link(Content.find(:first))
    get :show, :id => t.slug
    assert_response :success
  end

  test "autocomplete" do
    give_skill(1, "TagContents")
    sym_login 1
    get :autocomplete, :text => "a"
    assert_response :success
  end

  test "new no auth" do
    sym_login 2
    assert_raises(AccessDenied) do
      get :new
    end
  end

  test "new" do
    sym_login 1
    get :new
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_difference("Decision.count") do
      post :create, {
        :tag => {
          :name => 'good.name',
          :initial_contents => [
            Content.find(1).url,
            Content.find(2).url,
            Content.find(3).url,
            Content.find(4).url,
            Content.find(5).url,
          ],
        }
      }
    end

    assert_response :redirect
  end

end
