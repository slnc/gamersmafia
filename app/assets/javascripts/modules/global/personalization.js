Gm.Personalization = function() {
  return {
    name: 'Personalization',

    ContentInit: function() {
    },

    FullPageInit: function() {
      this.ContentInit();
    },

    set_default_portal: function(user_is_authed, new_portal) {
      if (user_is_authed)
        $.get('/cuenta/cuenta/set_default_portal?new_portal=' + new_portal);
      else
        Gm.Slnc.setPref('defportal', new_portal);
      return false;
    },

  }; // return
}();

Gm.registerModule(Gm.Personalization);
