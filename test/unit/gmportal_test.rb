require 'test_helper'

class GmPortalTest < ActiveSupport::TestCase

  test "has_name" do
    assert_not_nil GmPortal.new.name
  end

  test "should_respond_to_all_content_classes" do
    p = GmPortal.new
    Cms::contents_classes_symbols.each do |s|
      assert_not_nil p.send(s)
    end
  end

  test "should return question from a game's subcategory" do
    t = Term.single_toplevel(:slug => 'ut')
    tquestion = t.children.create(:taxonomy => 'QuestionsCategory', :name => 'General')

    assert !tquestion.new_record?
    q = Question.create(:user_id => 1, :title => 'holaaaaa')
    assert !q.new_record?
    Cms.publish_content(q, User.find(1))
    q.reload
    
    assert_equal Cms::PUBLISHED, q.state
    assert_nil GmPortal.new.question.find(:first, :conditions => ['questions.id = ?', q.id])
    tquestion.link(q.unique_content)
    assert_not_nil GmPortal.new.question.find(:first, :conditions => ['questions.id = ?', q.id])
  end
end
