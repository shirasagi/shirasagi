this.SS_HtmlMessage = (function () {
  function SS_HtmlMessage(el) {
    this.$el = $(el);
    this.render();
  }

  SS_HtmlMessage.prototype.render = function () {
    var self = this;

    if (this.$el.find('img[data-url]').length) {
      this.$el.find('img[data-url][height]').each(function () {
        $(this).css('height', $(this).attr('height') + 'px');
      });

      var $a = $("<a />", { class: "show-image", href: "#" }).html(i18next.t('webmail.links.show_image'));
      $a.on("click", function() {
        $(this).hide();
        self.loadImages();
        return false;
      });

      this.$el.before($a);
    }
  };

  SS_HtmlMessage.prototype.loadImages = function () {
    return this.$el.find("img[data-url]").each(function () {
      var $img = $(this);
      var url = $img.data('url');
      if (url.match(/^parts\//)) {
        url = location.pathname + "/" + url;
      }
      $img.attr('src', url);
      $img.css('height', 'auto');
      $img.removeAttr('data-url');
    });
  };

  return SS_HtmlMessage;

})();
