this.Gws_Schedule_Plan = (function () {
  var convertToTime = function(date, templateTime) {
    if (templateTime) {
      return date.millisecond(templateTime.millisecond())
        .second(templateTime.second())
        .minute(templateTime.minute())
        .hour(templateTime.hour());
    } else {
      return date.millisecond(0).second(0).minute(0).hour(9);
    }
  }

  function Gws_Schedule_Plan(el) {
    this.$el = $(el);

    this.$datetimeStartEl = this.$el.find(".datetime.start");
    this.$datetimeEndEl = this.$el.find(".datetime.end");
    this.$dateStartEl = this.$el.find(".date.start");
    this.$dateEndEl = this.$el.find(".date.end");
    this.$allday = this.$el.find('#item_allday');

    this.context = {
      startAt: SS_DateTimePicker.momentValue(this.$datetimeStartEl) || SS_DateTimePicker.momentValue(this.$dateStartEl),
      endAt: SS_DateTimePicker.momentValue(this.$datetimeEndEl) || SS_DateTimePicker.momentValue(this.$dateEndEl)
    }
    this.context.difference = SS_StartEndSynchronizer.calcDifference(this.context.startAt, this.context.endAt);
    // console.log({ startAt: this.context.startAt.format(), endAt: this.context.endAt.format(), difference: this.context.difference });

    this.render();
  }

  Gws_Schedule_Plan.renderForm = function () {
    $(".gws-schedule-start-end-combo").each(function() { new Gws_Schedule_Plan(this) });
  };

  Gws_Schedule_Plan.prototype.isAllDay = function() {
    return this.$allday.prop('checked');
  };

  Gws_Schedule_Plan.prototype.render = function() {
    var self = this;

    self.$datetimeStartEl.on("ss:changeDateTime", function() {
      self.context.startAt = SS_DateTimePicker.momentValue(self.$datetimeStartEl);
      if (self.context.startAt) {
        self.context.endAt = moment(self.context.startAt).add(self.context.difference, "milliseconds");
      }
      // update $datetimeEndEl, $dateStartEl, $dateEndEl
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
      SS_DateTimePicker.momentValue(self.$dateStartEl, self.context.startAt);
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$datetimeEndEl.on("ss:changeDateTime", function() {
      self.context.endAt = SS_DateTimePicker.momentValue(self.$datetimeEndEl);
      if (self.context.endAt) {
        self.context.difference = SS_StartEndSynchronizer.calcDifference(self.context.startAt, self.context.endAt);
      }
      // update $dateEndEl
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$dateStartEl.on("ss:changeDateTime", function() {
      var startDate = SS_DateTimePicker.momentValue(self.$dateStartEl);
      if (startDate) {
        self.context.startAt = convertToTime(startDate, self.context.startAt);
        self.context.endAt = moment(self.context.startAt).add(self.context.difference, "milliseconds");
      } else {
        self.context.startAt = null;
      }
      // update $datetimeStartEl, $datetimeEndEl, $dateEndEl
      SS_DateTimePicker.momentValue(self.$datetimeStartEl, self.context.startAt);
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$dateEndEl.on("ss:changeDateTime", function() {
      var endDate = SS_DateTimePicker.momentValue(self.$dateEndEl);
      if (endDate) {
        self.context.endAt = convertToTime(endDate, self.context.endAt);
        self.context.difference = SS_StartEndSynchronizer.calcDifference(self.context.startAt, self.context.endAt);
      } else {
        self.context.endAt = null;
      }
      // update $datetimeEndEl
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
    });

    self.$el.find("[data-sync-with]").each(function() {
      var $this = $(this);
      self.$el.find("[name='" + $this.data("sync-with") + "']").on("ss:changeDateTime", function(ev) {
        SS_DateTimePicker.momentValue($this, SS_DateTimePicker.momentValue(ev.target));
      });
    });

    self.$allday.on("change", function () {
      self.changeDateForm();
    });
    self.changeDateForm();
    self.$el.trigger("ss:initialized");
  };

  Gws_Schedule_Plan.prototype.changeDateForm = function () {
    if (this.isAllDay()) {
      this.$el.find('.dates-field').removeClass("hide");
      this.$el.find('.datetimes-field').addClass("hide");
    } else {
      this.$el.find('.dates-field').addClass("hide");
      this.$el.find('.datetimes-field').removeClass("hide");
    }
  };

  return Gws_Schedule_Plan;

})();
