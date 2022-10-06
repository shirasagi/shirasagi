function Gws_Schedule_CalendarTransition(params) {
  if (params) {
    this.state = $.param({ calendar: params });
  }
}

Gws_Schedule_CalendarTransition.prototype.renderLinks = function(selector) {
  if (!this.state) {
    return
  }

  var _this = this;
  $(selector).each(function() {
    if ($(this).hasClass('no-calendar-state')) {
      return;
    }

    var href = $(this).attr('href');
    if (href.indexOf('?') >= 0) {
      href += "&" + _this.state;
    } else {
      href += "?" + _this.state;
    }
    $(this).attr('href', href);
  });
};

Gws_Schedule_CalendarTransition.prototype.renderCancelButton = function(selector, link) {
  var url = $(link).attr("href");
  $(selector).each(function() {
    if (url) {
      $(this).attr("onclick", "");
      $(this).on("click", function(){
        location.href= url;
      });
    }
  });
};
