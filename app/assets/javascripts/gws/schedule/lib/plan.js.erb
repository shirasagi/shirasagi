this.Gws_Schedule_Plan = (function () {
  function Gws_Schedule_Plan() {
  }

  Gws_Schedule_Plan.diffOn = 3600000;

  Gws_Schedule_Plan.renderForm = function (opts) {
    if (opts == null) {
      opts = {};
    }
    $("input.date").datetimepicker({
      lang: "ja",
      timepicker: false,
      format: 'Y/m/d',
      closeOnDateSelect: true,
      scrollInput: false,
      maxDate: opts["maxDate"]
    });
    $("input.datetime").datetimepicker({
      lang: "ja",
      roundTime: 'ceil',
      step: 30,
      maxDate: opts["maxDate"]
    });
    this.relateDateForm();
    return this.relateDateTimeForm();
  };

  Gws_Schedule_Plan.renderAlldayForm = function () {
    this.changeDateForm();
    return $('#item_allday').on("change", function () {
      Gws_Schedule_Plan.changeDateValue();
      return Gws_Schedule_Plan.changeDateForm();
    });
  };
  // @example
  //   2015/09/29 00:00 => 2015/09/29
  //   2015/09/29 => 2015/09/29 00:00

  Gws_Schedule_Plan.changeDateValue = function () {
    var etime, stime;
    if ($('#item_allday').prop('checked')) {
      $('#item_start_on').val($('#item_start_at').val().replace(/ .*/, ''));
      return $('#item_end_on').val($('#item_end_at').val().replace(/ .*/, ''));
    } else {
      stime = $('#item_start_at').val().replace(/.* /, '');
      etime = $('#item_end_at').val().replace(/.* /, '');
      if (stime === '' && $('#item_start_on').val() !== '') {
        stime = '00:00';
      }
      if (etime === '' && $('#item_end_on').val() !== '') {
        etime = '00:00';
      }
      $('#item_start_at').val($('#item_start_on').val() + (" " + stime));
      return $('#item_end_at').val($('#item_end_on').val() + (" " + etime));
    }
  };

  Gws_Schedule_Plan.changeDateForm = function () {
    if ($('#item_allday').prop('checked')) {
      $('.dates-field').show();
      return $('.datetimes-field').hide();
    } else {
      $('.dates-field').hide();
      return $('.datetimes-field').show();
    }
  };

  Gws_Schedule_Plan.relateDateForm = function (start_sel, end_sel) {
    if (start_sel == null) {
      start_sel = '.date.start';
    }
    if (end_sel == null) {
      end_sel = '.date.end';
    }
    $(start_sel + ", " + end_sel).on("click", function () {
      return Gws_Schedule_Plan.diffOn = Gws_Schedule_Plan.diffDates($(start_sel).val(), $(end_sel).val());
    });
    $(start_sel).on("change", function () {
      var date, format, start;
      start = $(start_sel).val();
      if (!start) {
        return;
      }
      start = (new Date(start)).getTime();
      if (isNaN(start)) {
        return;
      }
      date = new Date();
      date.setTime(start + Gws_Schedule_Plan.diffOn);
      format = '%d/%02d/%02d';
      if ($(start_sel).hasClass('datetime')) {
        format = '%d/%02d/%02d %02d:%02d';
      }
      return $(end_sel).val(sprintf(format, date.getFullYear(), date.getMonth() + 1, date.getDate(), date.getHours(), date.getMinutes()));
    });
    if ($(end_sel).val() === "") {
      return $(start_sel).trigger("change");
    }
  };

  Gws_Schedule_Plan.relateDateTimeForm = function () {
    return this.relateDateForm('.datetime.start', '.datetime.end');
  };

  Gws_Schedule_Plan.diffDates = function (src, dst) {
    var diff;
    if (!src || !dst) {
      return 1000 * 60 * 60;
    }
    diff = (new Date(dst)).getTime() - (new Date(src)).getTime();
    if (diff < 0) {
      return 0;
    }
    return diff;
  };

  Gws_Schedule_Plan.transferEnd2Start = function () {
    if ($('#item_allday').prop('checked')) {
      return $('#item_start_on').val($('#item_end_on').val());
    } else {
      return $('#item_start_at').val($('#item_end_at').val());
    }
  };

  return Gws_Schedule_Plan;

})();
