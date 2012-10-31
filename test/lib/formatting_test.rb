# -*- encoding : utf-8 -*-
require 'test_helper'

class FormattingTest < ActiveSupport::TestCase

  test "comment_with_expanded_short_replies and other quotes" do
    c1 = create_a_comment(
        :comment => "hola guapo\n[img]http://www.example.com/foo.png[/img]")
    c2 = create_a_comment(
        :comment => "##{c1.position_in_content} no, eres feo [quote]wiiii[/quote]")
    assert_equal(
        "[fullquote=2]hola guapo\n[img]http://www.example.com/foo.png[/img][/fullquote] no, eres feo [quote]wiiii[/quote]",
        Formatting.comment_with_expanded_short_replies(c2.comment, c2))
  end

  test "format_bbcode with quotes with other bbcodes inside" do
    c1 = create_a_comment(
        :comment => "hola guapo\n[img]http://www.example.com/foo.png[/img]")
    c2 = create_a_comment(
        :comment => "comment2 [quote]Cirano de Bergerac[/quote]")
    c3 = create_a_comment(
        :comment => "##{c1.position_in_content} no, eres feo [quote]wiiii[/quote]\n##{c2.position_in_content} ")
    assert_equal(
        "<abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"2\">#2</abbr> no, eres feo <blockquote><p>wiiii</p></blockquote>\n" +
        "<abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"3\">#3</abbr>\n" +
        "<div class=\"hidden fullquote-comment fullquote-comment2\"><p>hola guapo</p>\n" +
        "<p><img src=\"http://www.example.com/foo.png\" /></p></div>\n" +
        "<div class=\"hidden fullquote-comment fullquote-comment3\"><p>comment2 </p></div>",
        Formatting.replace_bbcodes(
            Formatting.comment_with_expanded_short_replies(c3.comment, c3)))
  end

  test "format_bbcode with fullquotes and other bbcodes inside" do
    c0 = create_a_comment
    c1 = create_a_comment(:comment => "##{c0.position_in_content} hellou")
    c2 = create_a_comment(
        :comment => "##{c1.position_in_content} ##{c1.position_in_content} obnubilado")
    assert_equal(
        "<abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"3\">#3</abbr> <abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"3\">#3</abbr> obnubilado\n<div class=\"hidden fullquote-comment fullquote-comment3\"><p>#2 hellou</p></div>",
        Formatting.replace_bbcodes(
            Formatting.comment_with_expanded_short_replies(c2.comment, c2)))
  end

  test "format_bbcode with same replies within quote and outside" do
    c0 = create_a_comment
    c1 = create_a_comment(:comment => "##{c0.position_in_content} hellou")
    c2 = create_a_comment(
        :comment => "##{c1.position_in_content} obnubilado ##{c0.position_in_content}")
    assert_equal(
        "<abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"3\">#3</abbr> obnubilado <abbr class=\"fullquote-opener\" title=\"Ver comentario original\" data-quote=\"2\">#2</abbr>\n<div class=\"hidden fullquote-comment fullquote-comment3\"><p>#2 hellou</p></div>\n<div class=\"hidden fullquote-comment fullquote-comment2\"><p>hola panzer</p></div>",
        Formatting.replace_bbcodes(
            Formatting.comment_with_expanded_short_replies(c2.comment, c2)))
  end

  test "remove_quotes" do
    assert_equal(
        "foo bar baz",
        Formatting.remove_quotes(
            "foo [quote]wiki[/quote]bar [quote]tapang[/quote]baz"))
  end

  test "remove_quotes with ids" do
    assert_equal(
        "foo bar baz",
        Formatting.remove_quotes(
            "foo [quote=3]wiki[/quote]bar [quote]tapang[/quote]baz"))
  end

  test "comment_without_quoted_text" do
    assert_equal(
        "foo [quote=3][/quote]bar\nbaz [quote][/quote]baz",
        Formatting.comment_without_quoted_text(
            "foo [quote=3]wiki[/quote]bar\nbaz [quote]tapang[/quote]baz"))
  end

  test "html_to_bbcode user login" do
    formatized_comment = (
        "hello <span class=\"user-login\"><a href=\"/miembros/nagato\">nagato</a>" +
        "</span>!")
    assert_equal "hello @nagato!", Formatting.html_to_bbcode(formatized_comment)
  end

  test "html_to_bbcode_should_correctly_translate_known_tags" do
    t_html_to_bbcoded = (
        "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\n" +
        "Además tengo saltos de línea, [~dharana], [flag=es]," +
        " [img]http://domain.test[/img] y [url=http://otherdomain.test]" +
        "enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote][code=python]foo" +
        "[/code][spoiler]foo[/spoiler]")

    t = (
        "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />" +
        "Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana" +
        "</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img" +
        " src=\"http://domain.test\" /> y <a href=\"http://otherdomain." +
        "test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>" +
        "mwahwahwa</blockquote><pre class=\"brush: python\">foo</pre><span" +
        " class=\"spoiler\">spoiler <span class=\"spoiler-content hidden\">foo" +
        "</span></span>")

    assert_equal t_html_to_bbcoded, Formatting.html_to_bbcode(t)
  end

  test "should fix incorrectly nested bbcodes" do
    assert_equal "[b]hola[/b]", Formatting.fix_incorrect_bbcode_nesting("[b]hola")
    assert_equal '[B]hola[/B]', Formatting.fix_incorrect_bbcode_nesting('[B]hola')
    assert_equal "[URL=http://google.com]hola[img]aa[/img][/URL]", Formatting.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img]')
    assert_equal '[URL=http://google.com]hola[img]aa[/img][img][/img][img][/img][/URL]', Formatting.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img][/img][/img]')
  end

  test "fix_incorrect_bbcode_nesting" do
    assert_equal '', Formatting.fix_incorrect_bbcode_nesting('')
    assert_equal 'hola', Formatting.fix_incorrect_bbcode_nesting('hola')
    assert_equal '[b]hola[/b]', Formatting.fix_incorrect_bbcode_nesting('[b]hola[/b]')
    assert_equal '[b][i]hola[/i][/b]', Formatting.fix_incorrect_bbcode_nesting('[b][i]hola[/i][/b]')

    assert_equal '[b][i]hola[/i][/b]', Formatting.fix_incorrect_bbcode_nesting('[b][i]hola[/b][/i]')
    assert_equal 'hola', Formatting.fix_incorrect_bbcode_nesting('hola[/b]')
    assert_equal '[url=http://gamersmafia.com]hola[/url]', Formatting.fix_incorrect_bbcode_nesting('[url=http://gamersmafia.com]hola[/url]')
    assert_equal '[b]hola[/b] adios', Formatting.fix_incorrect_bbcode_nesting('[b]hola[/b] adios')
    assert_equal '[i][b]hola[/b] [b]adios[/b][/i]', Formatting.fix_incorrect_bbcode_nesting('[i][b]hola[/b] [b]adios[/b][/i]')
  end

  test "should replace all urls in a line" do
    assert_equal(
        "<p><a href=\"foo\">fóo</a> <a href=\"bar\">bAr</a></p>",
        Formatting.format_bbcode('[url=foo]fóo[/url] [url=bar]bAr[/url]'))
  end

  test "formatize_should_correctly_translate_known_tags" do
    t = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t_formatized = "<p>Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i></p>\n<p>Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote><p>mwahwahwa</p></blockquote></p>"
    assert_equal t_formatized, Formatting.format_bbcode(t)
  end

  test "formatize user login" do
    expected = (
        "<p><span class=\"user-login\"><a href=\"/miembros/nagato\">nagato</a>" +
        "</span></p>")
    assert_equal expected, Formatting.format_bbcode("@nagato")
  end

  test "formatize spoiler" do
    expected = (
        "<p><span class=\"spoiler\">spoiler <span class=\"spoiler-content" +
        " hidden\">el mayordomo</span></span></p>")
    assert_equal expected, Formatting.format_bbcode("[spoiler]el mayordomo[/spoiler]")
  end


  test "formatize should properly formatize code tags" do
    assert_equal "<p><pre class=\"brush: js\">hola[]</pre></p>", Formatting.format_bbcode("[code]hola[][/code]")
    assert_equal "<p><pre class=\"brush: js\">hola \n*argv[]</pre></p>", Formatting.format_bbcode("[code]hola \n*argv[][/code]")

    assert_equal "<p><pre class=\"brush: cpp\">\nint main(int argc, char *argv[]) { }</pre></p>", Formatting.format_bbcode("[code=cpp]\nint main(int argc, char *argv[]) { }[/code]")

    assert_equal "<p><pre class=\"brush: python\">hola</pre></p>", Formatting.format_bbcode("[code=python]hola[/code]")
    assert_equal "<p><pre class=\"brush: js\">hola\n  mundo</pre></p>", Formatting.format_bbcode("[code]hola\n  mundo[/code]")
  end

  test "should formatize 2 urls in the same line" do
    assert_equal "<p><a href=\"http://example.com/1\">hello</a> <a href=\"http://example.com/2\">world</a></p>", Formatting.format_bbcode("[url=http://example.com/1]hello[/url] [url=http://example.com/2]world[/url]")
end

  test "xss1 in url tag" do
    assert_equal(
      "<p>[url=blag\" onclick=\"alert('foo');]Click me![/url]</p>",
      Formatting.format_bbcode("[url=blag\" onclick=\"alert('foo');]Click me![/url]"))
  end

  test "xss2 in url tag" do
    assert_equal(
      "<p>[url=blag\" onclick=\"alert('foo');]Click me![/url]</p>",
      Formatting.format_bbcode("[url=blag\" onclick=\"alert('foo');]Click me![/url]"))
  end

  test "xss3 in url tag" do
    assert_equal(
        "<p><a href=\"http://example.com/\">Click me!\"&gt;&lt;script" +
        " type=\"text/javascript\"&gt;&lt;/script&gt;</a></p>",
      Formatting.format_bbcode(
          "[url=http://example.com/]Click me!\"><script type=" +
          "\"text/javascript\"></script>[/url]"))
  end

  test "invalid img tag" do
    invalid_img_tag = (
        "[img]http://www.frank151.com/wp-content/uploads/2009/07/chief_wiggum" +
        ".png\" onload=\"alert('foo');[/img]")
    assert_equal "<p>[img]<a href=\"http://www.frank151.com/wp-content/uploads/2009/07/chief_wiggum.png\">www.frank151.com/wp-content/uploads/2009/07/chie..</a>\" onload=\"alert('foo');[/img]</p>", Formatting.format_bbcode(invalid_img_tag)
  end
end
