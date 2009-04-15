require File.dirname(__FILE__) + '/../../../test/test_helper'

class CommentsTest < ActiveSupport::TestCase
  def test_formatize_should_correctly_translate_known_tags
    t = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t_formatized = "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>mwahwahwa</blockquote>"
    assert_equal t_formatized, Comments.formatize(t)
  end

  def test_unformatize_should_correctly_translate_known_tags
    t_unformatized = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t = "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>mwahwahwa</blockquote>"
    assert_equal t_unformatized, Comments.unformatize(t)
  end

  #def test_formatize_should_close_unclosed_tags
  #  t_unclosed = '[b]hola'
  #  assert_equal '[b]hola[/b]'
  #end
  
  # TODO
  def atest_fix_malformed_comment
    assert_equal '', Comments.fix_malformed_comment('')
    assert_equal 'hola', Comments.fix_malformed_comment('hola')
    assert_equal '[b]hola[/b]', Comments.fix_malformed_comment('[b]hola[/b]')
    assert_equal '[b][i]hola[/i][/b]', Comments.fix_malformed_comment('[b][i]hola[/i][/b]')
    puts "!!!"
    assert_equal '[b][i]hola[/i][/b]', Comments.fix_malformed_comment('[b][i]hola[/b][/i]')
    assert_equal 'hola', Comments.fix_malformed_comment('hola[/b]')
    assert_equal '[url=http://gamersmafia.com]hola[/url]', Comments.fix_malformed_comment('[url=http://gamersmafia.com]hola[/url]')
    assert_equal '[b]hola[/b] adios', Comments.fix_malformed_comment('[b]hola[/b] adios')
    assert_equal '[i][b]hola[/b] [b]adios[\b][/i]', Comments.fix_malformed_comment('[i][b]hola[/b] [b]adios[\b][/i]')    
  end
    
  def test_sicario_can_edit_comments_of_own_district
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.add_sicario(u59)
    n65 = News.find(65)
    c = Comment.new(:content_id => n65.unique_content.id, :user_id => 1, :host => '127.0.0.1', :comment => 'comentario')
    assert c.save
    assert Comments.user_can_edit_comment(u59, c, bd.user_is_moderator(u59)) 
  end
end
