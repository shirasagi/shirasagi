this.Gws_Popup = (function () {
  function Gws_Popup() {
  }

  Gws_Popup.init = null;

  Gws_Popup.render = function (target, content) {
    var popup;
    if (!this.init) {
      this.init = true;
      $(window).resize(function () {
        return $('.gws-popup').remove();
      });
      $(document).on("click", function (ev) {
        if (!$(ev.target).closest('.gws-popup, .gws-popup-event').length) {
          return $('.gws-popup').remove();
        }
      });
    }
    $('.gws-popup').remove();
    popup = $("<div class='gws-popup'></div>").html($(content));
    $("body").append(popup);
    target.addClass('gws-popup-event');
    return this.renderPopup(target);

  };
  //$(window).resize(@render Popup)

  Gws_Popup.renderPopup = function (target) {
    var popup, pos_left, pos_top;
    popup = $('.gws-popup');
    if ($(window).width() < popup.outerWidth() * 1.5) {
      popup.css('max-width', $(window).width() / 2);
    } else {

    }
    //pop up.css(max'width',340 );
    pos_left = target.offset().left + (target.outerWidth() / 2) - (popup.outerWidth() / 2);
    pos_top = target.offset().top - popup.outerHeight() - 20;
    if (pos_left < 0) {
      pos_left = target.offset().left + target.outerWidth() / 2 - 20;
      popup.addClass('left');
    } else {
      popup.removeClass('left');
    }
    if (pos_left + popup.outerWidth() > $(window).width()) {
      pos_left = target.offset().left - popup.outerWidth() + target.outerWidth() / 2 + 20;
      popup.addClass('right');
    } else {
      popup.removeClass('right');
    }
    if (pos_top < 0) {
      pos_top = target.offset().top + target.outerHeight();
      popup.addClass('top');
    } else {
      popup.removeClass('top');
    }
    return popup.css({
      left: pos_left,
      top: pos_top
    }).animate({
      top: '+=10',
      opacity: 1
    }, 50);
  };

  return Gws_Popup;

})();
