this.Gws_Schedule_FacilityReservation = (function () {
  var requiredParams = function() {
    var repeatType = $('select[name="item[repeat_type]"]').val();
    var allday = $('input[type=checkbox][name="item[allday]"]').prop('checked');

    var $startOnEl;
    if (repeatType) {
      $startOnEl = $('input[name="item[repeat_start]"]');
    } else if (allday) {
      $startOnEl = $('input[name="item[start_on]"]');
    } else {
      $startOnEl = $('input[name="item[start_at]"]');
    }
    if (! $startOnEl || ! $startOnEl[0]) {
      return;
    }

    var startOn = SS_DateTimePicker.valueForExchange($startOnEl);
    if (! startOn) {
      return;
    }

    var $endOnEl;
    if (repeatType) {
      $endOnEl = $('input[name="item[repeat_end]"]');
    } else if (allday) {
      $endOnEl = $('input[name="item[end_on]"]');
    } else {
      $endOnEl = $('input[name="item[end_at]"]');
    }
    if (! $endOnEl || ! $endOnEl[0]) {
      return;
    }

    var endOn = SS_DateTimePicker.valueForExchange($endOnEl);
    if (! endOn) {
      return;
    }

    var facilityIds = [];
    $('.gws-schedule-facility table.ajax-selected tbody tr').each(function() {
      facilityIds.push($(this).data('id'));
    });
    if (facilityIds.length == 0) {
      return;
    }

    if (! repeatType) {
      repeatType = 'daily';
    }

    return {
      repeat_type: repeatType,
      allday: allday ? "allday" : "",
      start_on: startOn,
      end_on: endOn,
      facility_ids: facilityIds
    };
  };

  var optionalParams = function() {
    var params = {};
    var val;

    val = $('select[name="item[interval]"]').val();
    if (val) {
      params.interval = val;
    }

    var wdays = [];
    $('input[name="item[wdays][]"]:checked').each(function() {
      wdays.push($(this).val());
    });
    if (wdays.length > 0) {
      params.wdays = wdays;
    }

    val = $('input[name="item[repeat_base]"]:checked').val();
    if (val) {
      params.repeat_base = val;
    }

    return params;
  };

  var removeMisleadingOrUselessParams = function (formData) {
    var names = [];
    formData.forEach(function (value, name) {
      if (name.startsWith("item[") || name === "authenticity_token") {
        return;
      }
      if (names.includes(name)) {
        return;
      }
      names.push(name);
    });

    names.forEach(function (name) {
      formData.delete(name);
    });

    return formData;
  };

  var postData = function(extraParams) {
    var s = requiredParams();
    if (SS.isEmptyObject(s)) {
      return false;
    }

    var formData = new FormData($('form#item-form')[0]);
    removeMisleadingOrUselessParams(formData);

    formData.set("s[repeat_type]", s.repeat_type);
    formData.set("s[allday]", s.allday);
    formData.set("s[start_on]", s.start_on);
    formData.set("s[end_on]", s.end_on);
    s.facility_ids.forEach(function(value) {
      formData.append("s[facility_ids][]", value);
    });

    var o = optionalParams();
    if (!SS.isEmptyObject(o)) {
      if ("interval" in o) {
        formData.set("s[interval]", o.interval);
      }
      if ("wdays" in o) {
        o.wdays.forEach(function(value) { formData.append("s[wdays][]", value); });
      }
      if ("repeat_base" in o) {
        formData.set("s[repeat_base]", o.repeat_base);
      }
    }

    var allday = $('input[type=checkbox][name="item[allday]"]').prop('checked');
    var minHour = undefined;
    var maxHour = undefined;
    if (! allday) {
      try {
        var startAt = SS_DateTimePicker.momentValue($('input[name="item[start_at]"]'));
        var endAt = SS_DateTimePicker.momentValue($('input[name="item[end_at]"]'));
        minHour = startAt.hours();
        maxHour = endAt.hours() + (endAt.minutes() > 0 ? 1 : 0);
      } catch (e) {
        return false;
      }
    }
    if (minHour) {
      formData.set("d[min_hour]", minHour);
    }
    if (maxHour) {
      formData.set("d[max_hour]", maxHour);
    }

    var planId = $(".gws-schedule-facility").attr("data-plan-id");
    if (planId) {
      formData.set("item[id]", planId);
    }

    if (!SS.isEmptyObject(extraParams)) {
      for (var key in extraParams) {
        formData.set(key, extraParams[key]);
      }
    }

    return formData;
  }

  var changeVisibility = function() {
    var s = requiredParams();
    if (SS.isEmptyObject(s)) {
      $('.btn-confirm-facility-reservation').hide();
    } else {
      $('.btn-confirm-facility-reservation').show();
    }
  };

  function Gws_Schedule_FacilityReservation(options) {
    this.options = options;
    this.$html_facility_reservation = null;
    this.item_submit = null;
    this.confirm = this.options.confirm;

    this.render();
  }

  Gws_Schedule_FacilityReservation.prototype.render = function() {
    var self = this;

    $('.btn-confirm-facility-reservation').on('click', function (ev) {
      self.item_submit = false;
      self.confirmFacilityReservation();

      ev.preventDefault();
      return false;
    });

    $('form#item-form').on('submit', function(ev) {
      var data = postData({ submit: 1 });
      if (self.confirm || !data) {
        return true;
      }

      self.item_submit = true;
      $.ajax({
        method: 'POST',
        url: self.options.search_reservations_path,
        data: data,
        contentType: false,
        processData: false,
        cache: false,
        success: function(data) {
          self.$html_facility_reservation = $('<div></div>').html(data);
          if(self.$html_facility_reservation.find(".reservation-valid.free").length) {
            self.proceed();
            $('form#item-form').submit();
          } else {
            self.confirmFacilityReservation();
          }
        }
      });

      ev.preventDefault();
      return false;
    });

    $('select[name="item[repeat_type]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('input[name="item[repeat_start]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('input[name="item[repeat_end]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('.gws-schedule-facility .ajax-selected').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('.gws-schedule-start-end-combo').on('ss:initialized', function() {
      self.confirm = false;
      changeVisibility();
    });

    changeVisibility();
  };

  Gws_Schedule_FacilityReservation.prototype.confirmFacilityReservation = function() {
    var self = this;

    var data = postData();
    if (!data) {
      return false;
    }

    if (self.$html_facility_reservation && self.$html_facility_reservation.html()) {
      $.colorbox({
        html: self.$html_facility_reservation.html(),
        maxWidth: "80%",
        maxHeight: "80%",
        fixed: true,
        open: true,
        onComplete: function() {
          self.colorboxEvent();
        }
      });
    } else {
      $.ajax({
        method: 'POST',
        url: self.options.search_reservations_path,
        data: data,
        processData: false,
        contentType: false,
        cache: false,
        success: function (data) {
          $.colorbox({
            html: data,
            maxWidth: "80%",
            maxHeight: "80%",
            fixed: true,
            open: true,
            onComplete: function() {
              self.colorboxEvent();
            }
          });
        }
      });
    }

    self.$html_facility_reservation = null;
    return true;
  };

  Gws_Schedule_FacilityReservation.prototype.colorboxEvent = function() {
    var self = this;

    $('#cboxLoadedContent .send .confirm').on('click', function(ev) {
      self.proceed();
      if (self.item_submit) {
        $('form#item-form').submit();
      }
      ev.preventDefault();
      return false;
    });
    $('#cboxLoadedContent .send .cancel').on('click', function(ev) {
      self.cancel();
      ev.preventDefault();
      return false;
    });
  };

  Gws_Schedule_FacilityReservation.prototype.proceed = function() {
    $.colorbox.close();
    this.confirm = true;
  };

  Gws_Schedule_FacilityReservation.prototype.cancel = function() {
    $.colorbox.close();
    this.confirm = false;
  };

  return Gws_Schedule_FacilityReservation;
})();
