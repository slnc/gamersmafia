Gm.Decisions = function() {
  return {
    name: 'Decisions',

    ContentInit: function() {
      $('.decision-choices form').unbind('ajax:complete').on(
          'ajax:complete', function(event, xhr, status) {
        closeFacebox();
        $('#decision' + $(this).attr('data-decision-id')).fadeOut("normal");
      });

      // on submit update the hidden decision-choice-id
      $('.decision-choices input[type=submit]').unbind('click').click(
          function() {
            $('.decision-choices input[name=final_decision_choice]').val(
              $(this).attr('data-choice-id'));
      });

      $('.decision-pending').unbind('click').click(function() {
        var url = '/decisiones/' + $(this).attr('data-decision-id');
        $.facebox({ajax: url})
        return false;
      });
    },

    FullPageInit: function() {
      this.ContentInit();
    },

  }; // return
}();

Gm.registerModule(Gm.Decisions);
