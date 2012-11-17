/*
 * jQuery Litelighter
 * By: Trent Richardson [http://trentrichardson.com]
 *
 * Copyright 2012 Trent Richardson
 * Dual licensed under the MIT or GPL licenses.
 * http://trentrichardson.com/Impromptu/GPL-LICENSE.txt
 * http://trentrichardson.com/Impromptu/MIT-LICENSE.txt
 *
 * Here are the extra languages, I suggest take what you
 * need and delete the rest in your application
 */
(function($){

  /* jQuery Litelighter syntax definition for SQL */
  $.litelighter.languages.sql = {
    comment: { re: /(\-\-.*|\#.*)/g, style: 'comment' },
    string: $.litelighter.languages.generic.string,
    numbers: $.litelighter.languages.generic.numbers,
    keywords: { re: /(?:\b)(select|insert|update|delete|where|from|set|create|alter|drop|values|and|or|order|by|group|having|view|table|function|procedure|return|begin|end|with|as|into|false|true|null)(?:\b)/gi, style: 'keyword' },
    operators: $.litelighter.languages.generic.operators
  };

  /* jQuery Litelighter syntax definition for php */
  $.litelighter.languages.php = $.extend({},$.litelighter.languages.generic);

  /* jQuery Litelighter syntax definition for php embedded in html */
  $.litelighter.languages.htmlphp = $.extend({},$.litelighter.languages.html, {
    php: { re: /(?:\&lt;\?php)([\s\S]+?)(?:\?\&gt;)/gi, language: 'php'}
  });

})(jQuery);
