function SS_TextZoom() {
}

SS_TextZoom.render = function() {
  SS_Font.render();

  var _this = this;
  this.$el = $('.text-zoom');

  this.$el.on('click', '.zoom-out', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomOut($(this));
  });
  this.$el.on('click', '.zoom-in', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomIn($(this));
  });
  this.$el.on('click', '.zoom-reset', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomReset($(this));
  });
};

SS_TextZoom.zoomIn = function($btn) {
  SS_Font.set(true);
  SS.notice($btn.closest('.text-zoom').data('notice').replace(':size', SS_Font.size.toString()));
};

SS_TextZoom.zoomOut = function($btn) {
  SS_Font.set(false);
  SS.notice($btn.closest('.text-zoom').data('notice').replace(':size', SS_Font.size.toString()));
};

SS_TextZoom.zoomReset = function($btn) {
  SS_Font.set(100);
  SS.notice($btn.closest('.text-zoom').data('notice').replace(':size', SS_Font.size.toString()));
};
