Gws_Affair2_LeaveFile = function (el, paidLeaveUrl) {
  this.$el = $(el);
  this.paidLeaveUrl = paidLeaveUrl;

  this.$dateField = this.$el.find(".date-field");
  this.$datetimesField = this.$el.find(".datetimes-field");

  this.$startDate1 = this.$dateField.find('[name="item[in_start_date]"]');
  this.$closeDate1 = this.$dateField.find('[name="item[in_close_date]"]');
  this.$startDate2 = this.$datetimesField.find('[name="item[in_start_date]"]');

  this.$allday = this.$el.find('[name="item[allday]"][value="allday"]');
  this.$leaveType = this.$el.find('[name="item[leave_type]"]');

  this.render();
};

Gws_Affair2_LeaveFile.prototype.render = function() {
  var self = this;

  // 開始日
  var context = {
    startAt: SS_DateTimePicker.momentValue(self.$startDate1),
    endAt: SS_DateTimePicker.momentValue(self.$closeDate1)
  }
  context.difference = SS_StartEndSynchronizer.calcDifference(context.startAt, context.endAt);

  self.$startDate1.on("ss:changeDateTime", function() {
    context.startAt = SS_DateTimePicker.momentValue(self.$startDate1);
    if (context.startAt) {
      context.endAt = moment(context.startAt).add(context.difference, "milliseconds");
    }
    SS_DateTimePicker.momentValue(self.$startDate2, context.startAt);
    SS_DateTimePicker.momentValue(self.$closeDate1, context.endAt);
    self.showRemindMinutes();
  });
  self.$startDate2.on("ss:changeDateTime", function() {
    context.startAt = SS_DateTimePicker.momentValue(self.$startDate2);
    if (context.startAt) {
      context.endAt = moment(context.startAt).add(context.difference, "milliseconds");
    }
    SS_DateTimePicker.momentValue(self.$startDate1, context.startAt);
    SS_DateTimePicker.momentValue(self.$closeDate1, context.endAt);
  });
  self.$closeDate1.on("ss:changeDateTime", function() {
    context.endAt = SS_DateTimePicker.momentValue(self.$closeDate1);
    if (context.endAt) {
      context.difference = SS_StartEndSynchronizer.calcDifference(context.startAt, context.endAt);
    }
  });

  // 終日
  self.$allday.on("change", function() { self.toggleDate(); });
  self.toggleDate();

  // 休暇区分の変更
  self.$leaveType.on("change", function(){
    self.toggleSpecialLeave();
    self.showRemindMinutes();
  });
  self.toggleSpecialLeave();
  self.showRemindMinutes();
};

Gws_Affair2_LeaveFile.prototype.toggleDate = function() {
  var self = this;
  if (self.$allday.prop("checked")){
    self.$dateField.removeClass("hide");
    self.$datetimesField.addClass("hide");
  } else {
    self.$datetimesField.removeClass("hide");
    self.$dateField.addClass("hide");
  }
};

Gws_Affair2_LeaveFile.prototype.toggleSpecialLeave = function() {
  var self = this;
  if (self.$leaveType.val() == "special") {
    $(".special-leave").show();
  } else {
    $(".special-leave").hide();
  }
};

Gws_Affair2_LeaveFile.prototype.showRemindMinutes = function() {
  var self = this;

  self.$el.find(".leave-count").html("");
  if (self.$leaveType.val() != "paid") {
    return;
  }

  var date = SS_DateTimePicker.momentValue(self.$startDate1);
  if (date) {
    var url = self.paidLeaveUrl.replace("YMD", date.format("YYYYMMDD"));
    console.log(url);
    $.get(url, function(html) {
      $(".leave-count").html(html);
    });
  }
}
