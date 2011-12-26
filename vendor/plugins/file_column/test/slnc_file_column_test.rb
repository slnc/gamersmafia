require File.dirname(__FILE__) + '/../../../../test/test_helper'

class SlncFileColumnTest < ActiveSupport::TestCase
  def setup
    # Creamos dummy arecord object
    #@ct = ContentsType.create({:name => 'ActsAsTaggableMockRecord'})
    #raise 'Error creando \'silencecore_taggable_mock_record\'' unless @ct
    ActiveRecord::Base.db_query('CREATE TABLE slnc_file_column_mock_records (id serial primary key not null unique, name varchar, file varchar)')
    ActiveRecord::Base.db_query('CREATE TABLE slnc_file_column_mock_multiple_records (id serial primary key not null unique, name varchar, file1 varchar, file2 varchar)')
    ActiveRecord::Base.db_query('CREATE TABLE slnc_file_column_mock_format_jpgs (id serial primary key not null unique, name varchar, file varchar)')
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_records")
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_multiple_records")
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_format_jpg")
  end
  
  test "should_save_record_if_file_empty_and_not_required" do
    mock = SlncFileColumnMockRecord.create({:name => 'foo'})
    assert_equal true, mock.save, mock.errors.to_yaml
    assert_nil mock.file
    assert_not_nil mock.destroy
  end
  
  test "should_save_record_if_file_not_empty_and_not_required" do
    @mock = SlncFileColumnMockRecord.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    assert_equal true, @mock.save, @mock.errors.to_yaml
    assert_equal 'storage/slnc_file_column_mock_records/0000/001_image.jpg', @mock.file
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  test "should_delete_file_when_destroyed" do
    test_should_save_record_if_file_not_empty_and_not_required
    assert_not_nil @mock.destroy
    assert_equal false, File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  test "should_delete_previous_file_when_updating" do
    mock = SlncFileColumnMockRecord.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    prev = mock.file
    assert_equal true, mock.update_attributes({:file => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}), mock.errors.to_yaml
    assert_equal false, File.exists?("#{RAILS_ROOT}/public/#{prev}")
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file}")
    assert_equal 'storage/slnc_file_column_mock_records/0000/001_buddha.jpg', mock.file
    mock.destroy
  end
  
  test "should_not_modify_file_record_if_updated_with_nothing" do
    mock = SlncFileColumnMockRecord.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    mock.update_attributes({})
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file}")
    assert_equal 'storage/slnc_file_column_mock_records/0000/001_image.jpg', mock.file
  end
  
  test "should_not_modify_file_record_if_updated_with_invalid_file" do
    mock = SlncFileColumnMockRecord.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    mock.update_attributes({:file => 'wahariibii'})
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file}")
    assert_equal 'storage/slnc_file_column_mock_records/0000/001_image.jpg', mock.file
  end
  
  test "should_set_to_nil_if_updated_with_nil" do
    mock = SlncFileColumnMockRecord.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    prev_file = mock.file
    mock.update_attributes({:file => nil})
    assert_equal false, File.exists?("#{RAILS_ROOT}/public/#{prev_file}")
    assert_nil mock.file
  end
  
  test "should_work_with_multiple_files" do
    mock = SlncFileColumnMockMultipleRecord.create({:name => 'foo', :file1 => fixture_file_upload('files/image.jpg', 'image/jpeg'), :file2 => fixture_file_upload('files/buddha.jpg', 'image/jpeg')})
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file1}")
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file2}")
    assert_equal 'storage/slnc_file_column_mock_multiple_records/0000/001_image.jpg', mock.file1
    assert_equal 'storage/slnc_file_column_mock_multiple_records/0000/001_buddha.jpg', mock.file2
    
    # update with nothing
    mock.update_attributes({})
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file1}")
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file2}")
    assert_equal 'storage/slnc_file_column_mock_multiple_records/0000/001_image.jpg', mock.file1
    assert_equal 'storage/slnc_file_column_mock_multiple_records/0000/001_buddha.jpg', mock.file2
  end
  
  test "should_work_with_multiple_files_and_same_name" do
    mock = SlncFileColumnMockMultipleRecord.create({:name => 'foo', :file1 => fixture_file_upload('files/image.jpg', 'image/jpeg'), :file2 => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file1}")
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{mock.file2}")
    f1 = 'storage/slnc_file_column_mock_multiple_records/0000/001_image.jpg'
    f2 = 'storage/slnc_file_column_mock_multiple_records/0000/001_1_image.jpg'
    # hacemos esta comprobación pq el array no va en orden
    assert (f1 == mock.file2 && f2 == mock.file1) || (f1 == mock.file1 && f2 == mock.file2)
    #assert_equal , mock.file2
    #assert_equal , mock.file1
  end
  
  def atest_should_save_record_if_format_jpg_and_is_jpg
    @mock = SlncFileColumnMockFormatJpg.create({:name => 'foo', :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    assert_equal true, @mock.save, @mock.errors.to_yaml
    assert_equal 'storage/slnc_file_column_mock_format_jpgs/0000/001_image.jpg', @mock.file
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  def atest_should_save_record_if_format_jpg_and_is_gif
    @mock = SlncFileColumnMockFormatJpg.create({:name => 'foo', :file => fixture_file_upload('files/lines.gif', 'image/gif')})
    assert_equal @mock.save, @mock.errors.to_yaml
    assert_equal 'storage/slnc_file_column_mock_format_jpgs/0000/001_lines.jpg', @mock.file
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  def atest_should_save_record_if_format_jpg_and_is_png
    @mock = SlncFileColumnMockFormatJpg.create({:name => 'foo', :file => fixture_file_upload('files/pokemon.png', 'image/png')})
    assert_equal true, @mock.save, @mock.errors.to_yaml
    assert_equal 'storage/slnc_file_column_mock_format_jpgs/0000/001_pokemon.jpg', @mock.file
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  def atest_should_save_record_if_format_jpg_and_is_bmp
    @mock = SlncFileColumnMockFormatJpg.new({:name => 'foo', :file => fixture_file_upload('files/lines.bmp', 'image/bmp')})
    assert @mock.save, @mock.errors.to_yaml
    assert_equal 'storage/slnc_file_column_mock_format_jpgs/0000/001_lines.jpg', @mock.file
    assert File.exists?("#{RAILS_ROOT}/public/#{@mock.file}")
  end
  
  def atest_should_not_save_record_if_format_jpg_but_not_image    
    @mock = SlncFileColumnMockFormatJpg.create({:name => 'foo', :file => fixture_file_upload('files/images.zip', 'application/zip')})
    assert_equal false, @mock.save, @mock.errors.to_yaml
  end
  
  # TODO cuando hay un tag con más de una referencia comprobar que
  # last_tagged_on y que references se guardan bien
  
  def teardown
    # destruimos objeto de prueba
    # TODO: necesario, no?
    #@ct.destroy
    ActiveRecord::Base.db_query('DROP TABLE slnc_file_column_mock_records')
    ActiveRecord::Base.db_query('DROP TABLE slnc_file_column_mock_multiple_records')
    ActiveRecord::Base.db_query('DROP TABLE slnc_file_column_mock_format_jpgs')
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_records")
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_multiple_records")
    FileUtils.rm_rf("#{RAILS_ROOT}/public/storage/slnc_file_column_mock_format_jpgs")
  end
end

class SlncFileColumnMockRecord < ActiveRecord::Base
  file_column :file
end

class SlncFileColumnMockMultipleRecord < ActiveRecord::Base
  file_column :file1
  file_column :file2
end

class SlncFileColumnMockFormatJpg < ActiveRecord::Base
  file_column :file, :format => :jpg
end
