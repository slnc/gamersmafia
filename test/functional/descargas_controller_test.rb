require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class DescargasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Download', :form_vars => {:title => 'footapang', :mirrors_new => ["http://google.com/foo.zip\nhttp://kamasutra.com/porn.zip"]}, :categories_terms => ['16']
  

  
  test "download_counter_should_increment_when_viewing_download" do
    add_file_to_d1
    d = Download.find(1)
    orig = d.downloaded_times
    @request.host = "ut.#{App.domain}"
    
    assert_count_increases(DownloadedDownload) do
      get :download, :id => d.id, :h => 0
      assert_response :success
      # assert_template 'descargas/download'
      d.reload
      assert_equal orig + 1, d.downloaded_times
    end
  end
  
  test "create_with_mirrors_should_work" do
    sym_login 1
    assert_count_increases(Download) do
      post :create, { :download => { :title => 'titulin', :file => fixture_file_upload('/files/images.zip', 'application/zip'), :mirrors_new => ['http://unmirror.com'] }, :categories_terms => [Term.find(:first, :conditions => 'taxonomy = \'DownloadsCategory\'').id] } 
      assert_response :redirect
    end
   d = Download.find(:first, :order => 'id DESC')
   assert_equal 1, d.download_mirrors.count
   assert_equal 'http://unmirror.com', d.download_mirrors[0].url
  end
  
  test "create_from_zip_should_work_if_good_guy" do
    sym_login 1
    d_count = Download.count
    post :create_from_zip, { :categories_terms => [Term.with_taxonomy('DownloadsCategory').find(:first).id], :download => { :file => fixture_file_upload('/files/images.zip', 'application/zip') } } 
    assert_response :redirect
    assert_equal d_count + 2, Download.count
  end
  
  test "download_should_create_cookie_symlink" do
    # TODO chequear cuando no es local
    add_file_to_d1
    @request.host = "ut.#{App.domain}"
    d = Download.find(1)
    assert_count_increases(DownloadedDownload) { get :download, :id => d.id, :h => 0 }
    dd = DownloadedDownload.find(:first, :order => 'id DESC', :limit => 1)
    end_file = d.file.gsub("#{Rails.root}/public/storage", '').gsub('storage/downloads/', '')
    # TODO hay que redirigir a pag de download creada, no? 
    assert_response :success
    assert_equal "http://#{App.domain}/d/#{dd.download_cookie}/#{end_file}", @controller.instance_variable_get(:@download_link)
  end
  
  test "dauth" do
    test_create_from_zip_should_work_if_good_guy
    User.db_query("UPDATE downloads SET state = #{Cms::PUBLISHED}")
    d = Download.find(:first, :order => 'id desc')
    mcookie = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    get :dauth, {:gmk => App.mirror_auth_key, :ddc => mcookie, :f => d.file}
    assert_response :success
  end
  
  def add_file_to_d1
    User.db_query("UPDATE downloads SET file = 'storage/downloads/tall.jpg' WHERE id = 1")
    dstdir = "#{Rails.root}/public/storage/downloads"
    FileUtils.mkdir(dstdir) unless File.exists?(dstdir)
    FileUtils.copy("#{Rails.root}/test/fixtures/files/tall.jpg", dstdir)
  end

  test "descargas with invalid r should show error" do
      dm = DownloadMirror.find(:first)
      assert dm
      get :download, :id => dm.download_id, :r => dm.url
      assert_response :success
      assert flash[:error].nil?
  end
end
