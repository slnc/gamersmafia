require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'noticias_controller'

class NoticiasController; def rescue_action(e) raise e end; end

class NoticiasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'News', :form_vars => {:title => 'footapang', :description => 'bartapang'}, :root_terms => 1
  
  def setup
    @controller = NoticiasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_update_should_save_contents_version
    sym_login 1
    n = News.find(1)
    prev_attrs = n.attributes
    
    assert_count_increases(ContentsVersion) do
      post :update, :id => 1, :news => { :title => "cachan chan", :description => "description NN", :main => "main NN"} 
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
  
  def atest_index_should_work_in_clans_portal
    setup_clan_skin
    cp = ClansPortal.find(:first)
    @request.host = "#{cp.code}.#{App.domain}"
    get :index
    assert @controller.portal.kind_of?(ClansPortal), @controller.portal.class.name
    assert_response :success
  end
  
  def atest_news_should_work_in_clans_portal
    setup_clan_skin
    cp = ClansPortal.find(:first)
    @request.host = "#{cp.code}.#{App.domain}"
    get :show, :id => News.find(:published, :conditions => "news_category_id IN (SELECT id FROM news_categories WHERE clan_id = #{cp.clan.id} AND id = root_id)", :limit => 1)[0].id
    assert @controller.portal.kind_of?(ClansPortal), @controller.portal.class.name
    assert_response :success
  end
  
  def test_create_without_subcat_should_work
    sym_login 1
    assert_count_increases(News) do 
      post :create, { :news => {:title => 'footapang', :description => 'bartapang'}, :root_terms => 1, :new_subcategory_name => '' }
    end
    assert_equal 1, News.find(:first, :order => 'id desc').terms[0].id
  end
end
