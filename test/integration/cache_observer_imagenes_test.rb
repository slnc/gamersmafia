require "#{File.dirname(__FILE__)}/../test_helper"

class CacheObserverImagenesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end
  
  def test_should_clear_imagenes_index_galleries_after_creating_a_new_category
    get '/imagenes'
    assert_cache_exists '/gm/imagenes/index/galleries'
    ImagesCategory.create({:name => 'foocat', :code => 'codecot'})
    assert_cache_dont_exist '/gm/imagenes/index/galleries'
  end
  
  def test_should_clear_imagenes_index_galleries_after_updating_a_category
    test_should_clear_imagenes_index_galleries_after_creating_a_new_category
    get '/imagenes'
    assert_cache_exists '/gm/imagenes/index/galleries'
    ImagesCategory.find_by_code('codecot').save
    assert_cache_dont_exist '/gm/imagenes/index/galleries'
  end

  def test_should_clear_imagenes_index_galleries_after_deleting_a_category
    test_should_clear_imagenes_index_galleries_after_creating_a_new_category
    get '/imagenes'
    assert_cache_exists '/gm/imagenes/index/galleries'
    ImagesCategory.find_by_code('codecot').destroy
    assert_cache_dont_exist '/gm/imagenes/index/galleries'
  end
  
  def test_should_clear_toplevel_cache_after_changing_a_gallery_that_is_toplevel
    @ic = ImagesCategory.create({:name => 'foocat', :code => 'codecot'})
    get "/imagenes/#{@ic.id}"
    assert_cache_exists "/common/imagenes/toplevel/#{@ic.id}/page_"
    @ic.save
    assert_cache_dont_exist "/common/imagenes/toplevel/#{@ic.id}/page_"
  end
  
  def test_should_clear_toplevel_from_previous_cache_after_changing_a_gallery_that_has_toplevel_above
    test_should_clear_toplevel_cache_after_changing_a_gallery_that_is_toplevel
    ic_child = @ic.children.create({:name => 'subcat', :code => 'subcat'})
    @ic2 = ImagesCategory.create({:name => 'foocat2', :code => 'codecot2'})
    get "/imagenes/#{@ic.id}"
    get "/imagenes/#{@ic2.id}"
    assert_cache_exists "/common/imagenes/toplevel/#{@ic.id}/page_"
    assert_cache_exists "/common/imagenes/toplevel/#{@ic2.id}/page_"

    ic_child.parent_id = @ic2.id
    assert_equal true, ic_child.save
    assert_cache_dont_exist "/common/imagenes/toplevel/#{@ic.id}/page_"
    assert_cache_dont_exist "/common/imagenes/toplevel/#{@ic2.id}/page_"
    ic_child.destroy
    assert_cache_dont_exist "/common/imagenes/toplevel/#{@ic2.id}/page_"
  end
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
