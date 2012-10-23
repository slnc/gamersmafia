Gm.Comments = function() {
  return {
    name: 'Comments',

    ContentInit: function() {
      $('.comments form').sisyphus({
        timeout: 30,
      onSave: Gm.Comments.DraftSaved,
      });

      $('.spoiler').click(function(e) {
        $(e.currentTarget).find('.spoiler-content').toggle();
        e.stopPropagation();
      });
    },

    DraftSaved: function() {
      // TODO(slnc): use the new showAlert mechanism
      var now = new Date();
      if ($(".comments form textarea").val() != "") {
        $(".draft-feedback").html(
            "(" + now.toLocaleTimeString() + ") Borrador guardado");
      }
    },

    FullPageInit: function() {
      this.ContentInit();
    },
  }; // return
}();

Gm.registerModule(Gm.Comments);
