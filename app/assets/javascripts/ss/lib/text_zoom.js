function SS_TextZoom(el) {
  this.$el = $(el);
  this.render();
}

SS_TextZoom.render = function() {
  SS_Font.render();

  $('.text-zoom').each(function() {
    var element = this;
    SS.justOnce(this, "textZoom", function() {
      var textZoom = new SS_TextZoom(element);
      return textZoom;
    });
  });
};

SS_TextZoom.prototype.render = function() {
  var _this = this;
  this.$el.on('click', '.zoom-out', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomOut();
  });
  this.$el.on('click', '.zoom-in', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomIn();
  });
  this.$el.on('click', '.zoom-reset', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.zoomReset();
  });
};

SS_TextZoom.prototype.zoomIn = function() {
  SS_Font.set(true);
  var notice = i18next.t('ss.notice.text_zoomed', { count: SS_Font.size.toString() });
  SS.notice(notice);
};

SS_TextZoom.prototype.zoomOut = function() {
  SS_Font.set(false);
  var notice = i18next.t('ss.notice.text_zoomed', { count: SS_Font.size.toString() });
  SS.notice(notice);
};

SS_TextZoom.prototype.zoomReset = function() {
  SS_Font.set(100);
  var notice = i18next.t('ss.notice.text_zoomed', { count: SS_Font.size.toString() });
  SS.notice(notice);
};
