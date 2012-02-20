require 'test_helper'

class SkinTextureTest < ActiveSupport::TestCase

  test "create_should_work" do
    t = Texture.find_by_name('GrayscalePatternChecker')
    assert_not_nil t
    @sk = SkinTexture.new({:skin_id => 1, :texture_id => t.id, :element => 'body'})
    assert @sk.save, @sk.errors.full_messages_html
  end

  test "process_should_work_with_grayscale_pattern_checker" do
    test_create_should_work
    css, files = @sk.process
    assert_equal File.open("#{@sk.texture.dir}/style.css").read.gsub('${element_selector}', 'body'), css
    assert_equal 1, files.size
    assert File.exists?(files[0])
    FileUtils.rm(files[0]) # cleanup
  end
end
