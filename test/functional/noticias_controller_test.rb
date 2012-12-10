# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class NoticiasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'News',
                           :form_vars => {:title => 'footapang',
                                          :description => 'bartapang'},
                           :root_terms => 1

  test "close should work with valid reason" do
    sym_login 1
    n = News.published.first
    assert !n.closed?
    n.close(User.find(1), 'me caía mal')
    assert n.closed?
    assert_equal 1, n.closed_by_user.id
    assert 'me caía mal', n.reason_to_close

    # @request = ActionController::TestRequest.new
    @request.host = "ut.test.host"
    sym_login 1
    get :show, :id => n.id
    assert_response :success
    assert_not_nil @response.body.index('me caía mal')
  end

  test "reopen should work" do
    sym_login 1
    n = News.published.first
    assert !n.closed?
    n.close(User.find(1), 'me caía mal')
    assert n.closed?
    assert_equal 1, n.closed_by_user.id
    assert 'me caía mal', n.reason_to_close

    @request = ActionController::TestRequest.new
    @request.host = "ut.test.host"
    sym_login 1
    get :reopen, :id => n.id
    assert_response :redirect

    n.reload
    assert !n.closed?
  end

  test "update_should_save_contents_version" do
    sym_login 1
    n = News.published.first
    prev_attrs = n.attributes

    assert_count_increases(ContentsVersion) do
      post :update, :id => n.id, :news => {
          :title => "cachan chan",
          :description => "description NN",
          :main => "main NN",
      }
      assert_response :redirect
    end
    n.reload
    cv = ContentsVersion.find(:first, :order => 'id DESC')
    %w(title main description).each do |attr|
      assert_not_equal cv.data[attr], n.send(attr)
      assert_not_equal prev_attrs[attr], n.send(attr)
      assert_equal prev_attrs[attr], cv.data[attr]
    end
  end

  test "create_without_subcat_should_work" do
    sym_login 1
    assert_count_increases(News) do
      post :create, { :news => {:title => 'footapang', :description => 'bartapang'}, :root_terms => 1, :new_subcategory_name => '' }
    end
    assert_equal 1, News.find(:first, :order => 'id desc').terms[0].id
  end

  test "content locked" do
    get :index

    @controller.instance_variable_set(:@_response_body, nil)
    @controller.send(:render_error, ContentLocked.new)
    assert_response 403
    # assert_template 'application/content_locked' doesn't seem to works (rails 2.3.5)
    assert @response.body.include?('El contenido especificado est')
  end
end
