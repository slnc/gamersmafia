# -*- encoding : utf-8 -*-
require 'test_helper'

class GmPortalTest < ActiveSupport::TestCase

  test "has_name" do
    assert_not_nil GmPortal.new.name
  end

  test "should_respond_to_all_content_classes" do
    portal = GmPortal.new
    Cms::contents_classes_symbols.each do |class_symbol|
      assert_not_nil portal.send(class_symbol)
    end
  end

  test "should return question from a game's subcategory" do
    term_ut = Term.single_toplevel(:slug => 'ut')

    question = Question.create(:user_id => 1, :title => 'holaaaaa')
    assert !question.new_record?
    Content.publish_content_directly(question, User.find(1))
    question.reload

    assert_equal Cms::PUBLISHED, question.state
    assert_nil GmPortal.new.question.find(
        :first, :conditions => ['questions.id = ?', question.id])
    term_ut.link(question)
    assert_not_nil GmPortal.new.question.find(
        :first, :conditions => ['questions.id = ?', question.id])
  end
end
