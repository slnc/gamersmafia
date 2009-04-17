require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'imagenes_controller'

# Re-raise errors caught by the controller.
class ImagenesController; def rescue_action(e) raise e end; end

class ImagenesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Image', :form_vars => {:description => 'footapang', :file => ActionController::TestUploadedFile.new("#{RAILS_ROOT}/test/fixtures/files/buddha.jpg", nil, nil)}, :categories_terms => 18


  
  def test_category_404_if_invalid
    assert_raises(ActiveRecord::RecordNotFound) { get :category, :id => 'foo' }
  end
  
  
  def test_image_nil_file
    User.db_query("UPDATE images SET file = NULL WHERE id = 1")
    @request.host = "ut.#{App.domain}"
    get :show, :id => 1
    assert_response :success
  end
    
  def test_category_404_if_unexistant
    assert_raises(ActiveRecord::RecordNotFound) { get :category }
  end

  def test_toplevel_through_category
    tld = Term.single_toplevel(:slug => 'ut')
    assert_not_nil tld
    get :category, :category => tld.id
    assert_response :success
    assert_template 'imagenes/toplevel'
  end

  def test_gallery_through_category
    tld = Term.single_toplevel(:slug => 'ut')
    assert_not_nil tld
    sld = tld.children.create({:name => 'gallery', :taxonomy => 'ImagesCategory'})
    assert_not_nil sld
    im = Image.create({:user_id => 1, :description => 'foo', :file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg'), :terms => sld.id})
    im.change_state(Cms::PUBLISHED, User.find(1))
    im.reload
    assert_equal true, im.is_public?

    get :category, :category => sld.id
    assert_response :success
    assert_template 'imagenes/gallery'
  end

  def test_potds
    get :potds
    assert_response :success
    assert_template 'imagenes/potds'
  end

  def test_should_add_multiple_images_from_zip # TEMP disabled
    tld = Term.single_toplevel(:slug => 'ut')
    assert_not_nil tld
    sld = tld.children.create({:name => 'gallery', :taxonomy => 'ImagesCategory'})
    assert_not_nil sld
    images_count_before = Image.count
    post :create_from_zip, {:categories_terms => [sld.id], :image => {:file => fixture_file_upload('/files/images.zip', 'application/zip')}}, {:user => 1}
    assert_redirected_to '/imagenes'
    assert_equal images_count_before + 2, Image.count # el zip tiene 2 archivos
    im = Image.find(:first, :order => 'id DESC')
    assert_equal sld.id, im.terms[0].id
  end
  
  def test_babes_gallery_visible_from_factions_portal
    @request.host = 'ut.gamersmafia.com'
    get :category, { :category => Term.single_toplevel(:slug => 'bazar').children.find(:first, :conditions => "slug = 'babes' AND taxonomy = 'ImagesCategory'").id }
    assert_response :success
  end
  
  def test_babes_image_visible_from_factions_portal
    User.db_query("UPDATE images_categories SET root_id = (select id from images_categories WHERE code = 'bazar'), parent_id = (select id from images_categories WHERE code = 'bazar') WHERE code = 'babes'") 
    User.db_query("UPDATE images_categories SET root_id = (select id from images_categories WHERE code = 'bazar'), parent_id = (select id from images_categories WHERE code = 'bazar') WHERE code = 'dudes'")
    User.db_query("UPDATE images SET state = #{Cms::PUBLISHED} WHERE images_category_id = (select id from images_categories where code = 'babes')")
    @request.host = 'ut.gamersmafia.com'
    get :show, { :id => 4 }
    assert_response :redirect
  end
  
  def test_imagenes_bazar_should_work
    @request.host = "bazar.#{App.domain}"
    get :index
    assert_response :success, @response.body
  end
end
