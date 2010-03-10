require File.dirname(__FILE__) + '/../../../test/test_helper'

class CommentsTest < ActiveSupport::TestCase
  test "formatize_should_correctly_translate_known_tags" do
    t = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t_formatized = "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>mwahwahwa</blockquote>"
    assert_equal t_formatized, Comments.formatize(t)
  end

  test "unformatize_should_correctly_translate_known_tags" do
    t_unformatized = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t = "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>mwahwahwa</blockquote>"
    assert_equal t_unformatized, Comments.unformatize(t)
  end

  #test "formatize_should_close_unclosed_tags" do
  #  t_unclosed = '[b]hola'
  #  assert_equal '[b]hola[/b]'
  #end
  test "should fix incorrectly nested bbcodes" do
    assert_equal "[b]hola[/b]", Comments.fix_incorrect_bbcode_nesting("[b]hola")
    assert_equal '[B]hola[/B]', Comments.fix_incorrect_bbcode_nesting('[B]hola')
    assert_equal "[URL=http://google.com]hola[img]aa[/img][/URL]", Comments.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img]')
    assert_equal '[URL=http://google.com]hola[img]aa[/img][img][/img][img][/img][/URL]', Comments.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img][/img][/img]')
  end  


  # TODO
  def test_fix_incorrect_bbcode_nesting
    assert_equal '', Comments.fix_incorrect_bbcode_nesting('')
    assert_equal 'hola', Comments.fix_incorrect_bbcode_nesting('hola')
    assert_equal '[b]hola[/b]', Comments.fix_incorrect_bbcode_nesting('[b]hola[/b]')
    assert_equal '[b][i]hola[/i][/b]', Comments.fix_incorrect_bbcode_nesting('[b][i]hola[/i][/b]')
    
    assert_equal '[b][i]hola[/i][/b]', Comments.fix_incorrect_bbcode_nesting('[b][i]hola[/b][/i]')
    assert_equal 'hola', Comments.fix_incorrect_bbcode_nesting('hola[/b]')
    assert_equal '[url=http://gamersmafia.com]hola[/url]', Comments.fix_incorrect_bbcode_nesting('[url=http://gamersmafia.com]hola[/url]')
    assert_equal '[b]hola[/b] adios', Comments.fix_incorrect_bbcode_nesting('[b]hola[/b] adios')
    assert_equal '[i][b]hola[/b] [b]adios[/b][/i]', Comments.fix_incorrect_bbcode_nesting('[i][b]hola[/b] [b]adios[/b][/i]')    
  end
    
  test "sicario_can_edit_comments_of_own_district" do
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.add_sicario(u59)
    n65 = News.find(65)
    c = Comment.new(:content_id => n65.unique_content.id, :user_id => 1, :host => '127.0.0.1', :comment => 'comentario')
    assert c.save
    assert Comments.user_can_edit_comment(u59, c, bd.user_is_moderator(u59)) 
  end
end
