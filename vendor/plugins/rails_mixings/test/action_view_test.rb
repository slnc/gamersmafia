require 'test_helper'

class ActionViewTestContainer
  include ActionViewMixings
end

class ActionViewMixingsTest < ActiveSupport::TestCase
  test "clean_html_shouldnt_mess_up_mailto_links" do
    str = '<a href="mailto:dharana@dharana.net">dharana@dharana.net</a>'
    assert_equal str, ActionViewTestContainer.new.clean_html(str).strip
  end
  
  test "clean html should remove harmful attributes" do
    str = 'foo <a href="mailto:dharana@dharana.net" onclick="alert(\'foo\');">dharana@dharana.net</a>'
    assert_equal 'foo <a href="mailto:dharana@dharana.net">dharana@dharana.net</a>', ActionViewTestContainer.new.clean_html(str).strip
  end
  
  #test "print_interval" do
  #  assert_equal '2 semanas', ActionViewTestContainer.new.format_interval(Time.now - 2.weeks.ago, 'horas', true).strip
  #end

  test "format interval should work" do
     assert_equal '1 semana', ActionViewTestContainer.new.format_interval(Time.now - 8.days.ago, 'semanas', true)
     assert_equal '1 hora', ActionViewTestContainer.new.format_interval(Time.now - 61.minutes.ago, 'horas', true)
     assert_equal '59 mins', ActionViewTestContainer.new.format_interval(Time.now - 1.hour.ago, 'horas', true)
  end
end

