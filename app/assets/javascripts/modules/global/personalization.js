Gm.Personalization = function() {
  return {
    name: 'Personalization',

    ContentInit: function() {
    },

    FullPageInit: function() {
      this.ContentInit();
    },

  }; // return
}();

Gm.registerModule(Gm.Personalization);
