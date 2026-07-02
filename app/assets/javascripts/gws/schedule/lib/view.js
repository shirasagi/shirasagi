SS.ready(function() {
  window.Gws_Schedule_View = (function ($) {
    function Gws_Schedule_View() {
    }

    Gws_Schedule_View.getCalendar = function () {
      var cal;
      cal = $('#calendar-controller');
      if (cal.length === 0) {
        cal = $('#calendar');
      }
      if (cal.get(0).calendar) {
        return cal;
      }
      return null;
    };

    Gws_Schedule_View.getCalendarDate = function (selector) {
      var calendar;
      if (selector) {
        calendar = document.querySelector(selector).calendar;
      } else {
        calendar = Gws_Schedule_View.getCalendar();
      }
      if (calendar) {
        return Gws_Schedule_Calendar.dateToString(calendar.getDate());
        // return cal.getDate().format('YYYY-MM-DD');
      }
      return null;
    };
    // Schedule tabs

    Gws_Schedule_View.renderTabs = function (selector) {
      return $(selector).find('a').on("click", function () {
        var date, url;
        date = Gws_Schedule_View.getCalendarDate();
        if (!date) {
          return true;
        }
        url = $(this).attr('href');
        url = url.replace(/(\?.*)?$/, "?calendar[date]=" + date);
        $(this).attr('href', url);
        return true;
      });
    };
    // 4 months calendars

    Gws_Schedule_View.renderSideCalendars = function (selector) {
      return $(selector).find('.fc-toolbar h2').on("click", function () {
        var date, name;
        name = "gws-schedule-tool-calendars";
        date = Gws_Schedule_View.getCalendarDate(selector);

        // date = $.fullCalendar.moment(date);
        date = new Date(Date.parse(date))

        if ($("." + name).is(':hidden')) {
          $("." + name).remove();
        }
        if ($("." + name).length === 0) {
          Gws_Schedule_View.crenderSideCalendars(name, date);
        }
        return $("." + name).animate({
          width: 'toggle'
        }, 'fast');
      });
    };

    Gws_Schedule_View.addMonths = function(date, months = 1) {
      var resultDate = new Date(date.getTime());
      resultDate.setMonth(date.getMonth() + months);
      if (date.getDate() > date.getDate()) {
        resultDate.setDate(0);
      }
      return resultDate;
    }

    Gws_Schedule_View.crenderSideCalendars = function (name, date) {
      var h, i, j;
      h = $("<div />", { class: name })
        .append($("<div class='xdsoft_datetimepicker controller' />")
          .append("<button type='button' class='xdsoft_prev' />")
          .append("<button type='button' class='xdsoft_next' />"));
      $('#menu').before(h);
      for (i = j = 0; j <= 3; i = ++j) {
        if (i > 0) {
          date = Gws_Schedule_View.addMonths(date, 1);
          //date.add(1, 'months');
        }
        $("." + name).append($("<div />", { class: name + "-cal" + i }));
        $("." + name + "-cal" + i).datetimepicker({
          timepicker: false,
          format: 'YYYY/MM/DD',
          closeOnDateSelect: true,
          scrollInput: false,
          scrollMonth: false,
          inline: true,
          // defaultDate: date.format('YYYY-MM-DD'),
          defaultDate: Gws_Schedule_Calendar.dateToString(date),
          defaultSelect: false,
          todayButton: false,
          onGenerate: function (_time, _el) {
            $(this).find('.xdsoft_today').removeClass('xdsoft_today');
            return $(this).find('.xdsoft_current').removeClass('xdsoft_current');
          },
          onSelectDate: function (ct, _i) {
            date = sprintf("%d-%02d-%02d", ct.getFullYear(), ct.getMonth() + 1, ct.getDate());

            document.querySelectorAll('.calendar').forEach(el => {
              el.calendar.gotoDate(date);
            });
          }
        });
      }
      $("." + name).find(".xdsoft_month, .xdsoft_year").unbind('mousedown').find("i").remove();
      $("." + name + " .xdsoft_datetimepicker").not(".controller.controller").find(".xdsoft_prev, .xdsoft_next").hide();
      $("." + name + " .controller .xdsoft_prev").on("mousedown", function () {
        var k, results;
        results = [];
        for (i = k = 1; k <= 4; i = ++k) {
          results.push($("." + name + " .xdsoft_prev").not(this).trigger("mousedown").trigger("mouseup"));
        }
        return results;
      });
      return $("." + name + " .controller .xdsoft_next").on("mousedown", function () {
        var k, results;
        results = [];
        for (i = k = 1; k <= 4; i = ++k) {
          results.push($("." + name + " .xdsoft_next").not(this).trigger("mousedown").trigger("mouseup"));
        }
        return results;
      });
    };

    return Gws_Schedule_View;

  })($jQuery3);
});
