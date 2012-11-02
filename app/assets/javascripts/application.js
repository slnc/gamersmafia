//= require jquery
//= require jquery_ujs
//= require_tree ./external
//= require gm
//= require_tree ./modules

$(document).ready(function() {
  /*
   * TODO(slnc): temporarily disabled until we can make sure that calls to
   * refresh outside boxes are called after page refresh via pjax.
  $('body').pjax('a', {container: "#ccontent"})
    .on('pjax:start', function() { $('#loading').show() })
    .on('pjax:end', function() {
      $('#loading').hide();
      var modules = Gm.getModules();
      for (var i in modules) {
        modules[i].ContentInit();
      }
    });
    */

  var modules = Gm.getModules();
  for (var i in modules) {
    modules[i].FullPageInit();
  }
});
