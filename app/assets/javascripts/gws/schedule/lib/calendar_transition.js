function Gws_Schedule_CalendarTransition(params) {
  if (params) {
    this.date = "calendar[date]=" + params.date;
    this.path = "calendar[path]=" + params.path;
    this.view = "calendar[view]=" + params.view;
    this.format = "calendar[viewFormat]=" + params.viewFormat;
    this.todo = "calendar[viewTodo]=" + params.viewTodo;
    this.atendance = "calendar[viewAttendance]=" + params.viewAttendance;
    this.state = [this.date, this.view, this.path, this.format, this.todo, this.attendance].join("&");
  }
}

Gws_Schedule_CalendarTransition.prototype.renderLinks = function(selector) {
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
