# -*- encoding : utf-8 -*-
require 'test_helper'

class ContentTest < ActiveSupport::TestCase

  def setup
    @content = Content.find(1)
  end

  test "published_counts_by_user" do
    expected = {
        "Bet"=>1,
        "Blogentry"=>1,
        "Column"=>1,
        "Coverage"=>1,
        "Demo"=>1,
        "Download"=>1,
        "Event"=>361,
        "Funthing"=>1,
        "Image"=>3,
        "Interview"=>1,
        "News"=>5,
        "Poll"=>2,
        "Question"=>1,
        "Review"=>1,
        "RecruitmentAd" => 0,
        "Topic"=>1,
        "Tutorial"=>1,
    }
    assert_equal expected.sort_by {|a, b| a}, Content.published_counts_by_user(User.find(1)).sort_by {|a, b| a}
  end

  test "refered_people_should_work_with_content_title" do

  end

  test "refered_people_should_work_with_content_description" do

  end

  test "refered_people_should_work_with_content_main" do

  end

  test "refered_people_should_work_with_content_comments" do

  end


  test "locked_for_user_when_unlocked" do
    c = Content.find(1)
    assert !c.locked_for_user?(User.find(1))
  end

  test "locked_for_user_when_locked" do
    assert_not_nil ContentsLock.create({:content_id => 1, :user_id => 1})
    c = Content.find(1)
    assert c.locked_for_user?(User.find(2))
  end

  test "locked_for_user_when_lock_expired" do
    lock = ContentsLock.create({:content_id => 1, :user_id => 1})
    assert_not_nil lock
    ContentsLock.db_query("UPDATE contents_locks set updated_on = now() - '1 minute'::interval WHERE id = #{lock.id}")
    c = Content.find(1)
    assert !c.locked_for_user?(User.find(2))
  end


  test "del_recommendations_after_delete_content" do
    c = Content.find(:first, :conditions => "state = #{Cms::PUBLISHED}")
    cr = ContentsRecommendation.create(:sender_user_id => 1, :content_id => c.id, :receiver_user_id => 3)
    assert !cr.new_record?
    assert c.update_attributes(:state => Cms::DELETED)
    assert ContentsRecommendation.find_by_id(cr.id).nil?
  end

  test "linked_terms" do
    c = Content.find(1)
    assert_equal 'News', c.content_type.name
    lterms = c.linked_terms
    assert_equal 1, lterms.size
    assert_nil lterms[0].taxonomy
    assert_equal 1, lterms[0].id
  end

  test "linked_terms_taxonomy" do
    c = Content.find(5)
    lterms = c.linked_terms('DownloadsCategory')
    assert_equal 1, lterms.size
    assert_equal 16, lterms[0].id
  end

  test "linked_terms_null" do
    c = Content.find(1)
    lterms = c.linked_terms('NULL')
    assert_equal 1, lterms.size
    assert_equal 1, lterms[0].id
  end

  test "recover_content shouldnt create decision" do
    c = Content.deleted.first
    assert_difference("Decision.count", 0) do
      Content.recover_content(c.real_content, Ias.mrman)
    end
  end

  test "recover_content shouldnt create decision via recover2" do
    c = Content.deleted.first
    assert_difference("Decision.count", 0) do
      c.real_content.recover(Ias.mrman)
    end
  end
end
