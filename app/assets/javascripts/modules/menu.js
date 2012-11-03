Gm.Menu = function() {
  var sawbottom_mode = 'comunidad';
  var sawbottom_cur = '';
  var sawbottom_cur_int = '';

  return {
    name: 'Menu',

    ContentInit: function() {
    },

    FullPageInit: function() {
      // add event handlers to arrows
      var fn = function() {
        Gm.Menu.sawbottom_cancel();
      }
      $('.sawtop-arrow').mouseout(fn);
      this.ContentInit();
    },

    sawbottom: function(mode) {
      this.sawbottom_cancel();
      sawbottom_cur = mode;
      if (sawbottom_cur_int) {
        window.status = 'int found, deleting';
        clearTimeout(sawbottom_cur_int);
      }
      sawbottom_cur_int = setTimeout("Gm.Menu.sawbottom_real('" + mode + "')", 200);
    },

    sawbottom_real: function(mode) {
      if (mode == sawbottom_cur || arguments.length == 2) {

        $('#sawli-' + sawbottom_mode).removeClass('alter');
        $('#sawbody-' + sawbottom_mode).addClass('hidden');

        var d = $('#sawli-' + mode);
        if (d) {
          d.addClass('alter');
          $('#sawbody-' + mode).removeClass('hidden');
          sawbottom_mode = mode;
        }
      }
    },

    sawbottom_cancel: function() {
      if (sawbottom_cur_int)
        clearTimeout(sawbottom_cur_int);
      sawbottom_cur = '';
    },

    sawdropdown_hide: function(id) {
      var the_dropdown = $('#' + id);
      the_dropdown.addClass('hidden');
    },

    sawdropdown_cancel_hiding: function(id) {
      var the_dropdown = $('#' + id);
      var theint = the_dropdown.data('outint');
      if (theint) {
        clearInterval(theint);
        the_dropdown.data('outint', undefined);
      }
    },

    showSawDropDown: function(id) {
      var the_dropdown = $('#' + id);

      $('body').bind('mouseover', function(event) {
        // Creo y lanzo un timeout para cerrar el menú si dentro de 1000ms no se
        // ha eliminado el timeout
        var newint = the_dropdown.data('outint');
        if (newint)
          clearInterval(newint);
        the_dropdown.data('outint', setTimeout("Gm.Menu.sawdropdown_hide('" + id + "')", 750));
      });
      the_dropdown.bind('mouseover', function(e) {
        e.stopPropagation();
        Gm.Menu.sawdropdown_cancel_hiding(id);
      });
      the_dropdown.children('.saw-dropdownlist').bind('mouseover', function(e) {
        e.stopPropagation();
        Gm.Menu.sawdropdown_cancel_hiding(id);
      });
      // TODO no estamos haciendo unbind

      the_dropdown.removeClass('hidden');
      return false;
    }

  }; // return
}();

Gm.registerModule(Gm.Menu);
