this.Gws_Schedule_StartEndSynchronizer = (function () {
  var defaultStartEndDifferenceInMillis = 1000 * 60 * 60;

  var calcDifference = Gws_Schedule_StartEndSynchronizer.calcDifference = function (start, end) {
    if (!start || !end) {
      return defaultStartEndDifferenceInMillis;
    }

    var diff = end.valueOf() - start.valueOf();
    if (diff < 0) {
      return 0;
    }
    return diff;
  };

  function Gws_Schedule_StartEndSynchronizer(startEl, endEl, callback) {
    this.$startEl = $(startEl);
    this.$endEl = $(endEl);
    this.difference = defaultStartEndDifferenceInMillis;

    this.render(callback);
  }

  Gws_Schedule_StartEndSynchronizer.prototype.render = function(callback) {
    var self = this;

    var handler = function() { self.calcDifference() };
    self.$startEl.on("click", handler);
    self.$endEl.on("click", handler);

    self.$startEl.on("ss:changeDateTime", function() { self.updateEndValue(); });
    if (!SS_DateTimePicker.momentValue(self.$endEl)) {
      self.updateEndValue();
    }
    if (callback) {
      callback();
    }
  };

  Gws_Schedule_StartEndSynchronizer.prototype.calcDifference = function() {
    var self = this;

    var startValue = SS_DateTimePicker.momentValue(self.$startEl);
    var endValue = SS_DateTimePicker.momentValue(self.$endEl);
    self.difference = calcDifference(startValue, endValue);
  };

  Gws_Schedule_StartEndSynchronizer.prototype.updateEndValue = function() {
    var self = this;

    var endValue = SS_DateTimePicker.momentValue(self.$startEl);
    if (!endValue) {
      return;
    }
    if (!endValue.isValid()) {
      return;
    }

    endValue.add(self.difference, "milliseconds");
    SS_DateTimePicker.momentValue(self.$endEl, endValue);
  };

  return Gws_Schedule_StartEndSynchronizer;
})();
