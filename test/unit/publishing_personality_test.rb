require 'test_helper'

class PublishingPersonalityTest < ActiveSupport::TestCase
  #def test_by_default_user_has_0_weight
  #  panzer = User.find_by_login(:panzer)
  #  assert_in_delta 0.00, Cms.get_user_exp_with('News', panzer), 0.001
  #end

  def test_find_or_create_should_work
    panzer = User.find_by_login(:panzer)
    ct = ContentType.find_by_name('News')
    assert_not_nil panzer
    assert_not_nil ct
    p = PublishingPersonality.find_or_create(panzer, ct)
    assert_not_nil p
    assert_equal ct.id, p.content_type_id
    assert_equal panzer.id, p.user_id
    assert_equal 0.00, p.experience

    # ahora ya no creará, buscará
    p = PublishingPersonality.find_or_create(panzer, ct)
    assert_not_nil p
    assert_equal ct.id, p.content_type_id
    assert_equal panzer.id, p.user_id
    assert_equal 0.00, p.experience
  end
end
