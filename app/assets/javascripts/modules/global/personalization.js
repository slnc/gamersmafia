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

    add_quicklink: function(code, url) {
      $.get('/cuenta/cuenta/add_quicklink?code=' + code + '&url=' + url);
      //$('#add-to-quicklinks').remove();
      // TODO habría que actualizar la caja de quicklinks para hacer return
      // false;
    },

    del_quicklink: function(code) {
      $.get('/cuenta/cuenta/del_quicklink?code=' + code);
      // TODO habría que actualizar la caja de quicklinks para hacer return
      // false;
    },

    add_user_forum: function(id, url) {
      $.get('/cuenta/cuenta/add_user_forum?id=' + id + '&url=' + url);
      $('#add-to-user-forums').addClass('hidden');
      $('#del-from-user-forums').removeClass('hidden');
      return false;
    },

    del_user_forum: function(id) {
      $.get('/cuenta/cuenta/del_user_forum?id=' + id);
      $('#del-from-user-forums').addClass('hidden');
      $('#add-to-user-forums').removeClass('hidden');
      return false;
    },

    update_user_forums_order: function(user_id, buckets1, buckets2, buckets3) {
      $.get('/cuenta/cuenta/update_user_forums_order?user_id=' + user_id + '&' + buckets1 + '&' + buckets2 + '&' + buckets3);
    }
  }; // return
}();

Gm.registerModule(Gm.Personalization);
