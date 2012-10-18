//= require jquery
//= require jquery_ujs
//= require_tree .

$(document).ready(function() {
    $('body').pjax('a', {container: "#main"})
    .on('pjax:start', function() { $('#loading').show() })
    .on('pjax:end', function() { $('#loading').hide() });
});
