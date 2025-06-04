Gws_Affair2_Breaktime = function (el) {
  this.el = el;
  this.$el = $(el);

  this.$startHour = this.$el.find(".start-hour");
  this.$startMinute = this.$el.find(".start-minute");
  this.$closeHour = this.$el.find(".close-hour");
  this.$closeMinute = this.$el.find(".close-minute");
  this.$diff = this.$el.find(".diff");
  this.date = this.$el.attr("data-date");

  this.render();
};

Gws_Affair2_Breaktime.prototype.render = function() {
  var self = this;

  this.$el.on("ss:changeBreaktime", function() { self.showDiffLabel(); });
  this.$startHour.on("change", function() { self.$el.trigger('ss:changeBreaktime'); });
  this.$startMinute.on("change", function() { self.$el.trigger('ss:changeBreaktime'); });
  this.$closeHour.on("change", function() { self.$el.trigger('ss:changeBreaktime'); });
  this.$closeMinute.on("change", function() { self.$el.trigger('ss:changeBreaktime'); });
  this.showDiffLabel();
};

Gws_Affair2_Breaktime.prototype.showDiffLabel = function() {
  var startHour = this.$startHour.val();
  var startMinute = this.$startMinute.val();
  var closeHour = this.$closeHour.val();
  var closeMinute = this.$closeMinute.val();

  var start = this.formatTime(this.date, startHour, startMinute);
  var close = this.formatTime(this.date, closeHour, closeMinute);
  var start_time = moment(start);
  var close_time = moment(close);
  this.$diff.text(this.diffLabel(start_time, close_time));
};

Gws_Affair2_Breaktime.prototype.diffLabel = function(start_time, close_time) {
  var label, diff, hour, minute;

  diff = close_time.diff(start_time, 'minutes');
  if (diff <= 0) {
    return "";
  }

  label = "";
  hour = Math.floor(diff / 60);
  minute = diff % 60;

  if (hour) {
    label += hour + i18next.t("ss.hours");
  }
  label += minute + i18next.t("ss.minutes");
  return "(" + label + ")";
};

Gws_Affair2_Breaktime.prototype.formatTime = function (date, hour, minute) {
  var time = moment(date);
  time.add(Math.floor(hour / 24), 'days');
  time.add(hour % 24, 'hours');
  time.add(minute, 'minutes');
  return time;
};
