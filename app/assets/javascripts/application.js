//= require jquery
//= require jquery_ujs
//= require_tree ./external
//= require gm
//= require_tree ./modules

$(document).ready(function() {
  $('body').pjax('a', {container: "#main"})
    .on('pjax:start', function() { $('#loading').show() })
    .on('pjax:end', function() {
      $('#loading').hide();
      var modules = Gm.getModules();
      for (var i in modules) {
        modules[i].ContentInit();
      }
    });

  var modules = Gm.getModules();
  for (var i in modules) {
    modules[i].FullPageInit();
  }
});
