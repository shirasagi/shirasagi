this.Gws_Schedule_View = (function ($) {
  function Gws_Schedule_View() {
  }

  Gws_Schedule_View.getCalendar = function () {
    var cal;
    cal = $('#calendar-controller');
    if (cal.length === 0) {
      cal = $('#calendar');
    }
    if (cal.fullCalendar('getView').calendar) {
      return cal;
    }
    return null;
  };

  Gws_Schedule_View.getCalendarDate = function () {
    var cal;
    cal = Gws_Schedule_View.getCalendar();
    if (cal) {
      return cal.fullCalendar('getDate').format('YYYY-MM-DD');
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
      date = Gws_Schedule_View.getCalendarDate();
      date = $.fullCalendar.moment(date);
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

  return Gws_Schedule_View;

})($jQuery1);

(function ($) {
  // datetimepicker プラグイン は jQuery3 にだけ存在する。
  // このプラグインを jQuery1 へ組み込んでも jQuery3 の側と競合するのかうまく動作しない。少なくとも言語が英語になってしまう。
  // そこで、Gws_Schedule_View.crenderSideCalendars() のみ jQuery3 で動作させる。
  // Gws_Schedule_View.crenderSideCalendars() は fullcalendar の機能を利用しないため、jQuery3 で動作させても問題ない。
  Gws_Schedule_View.crenderSideCalendars = function (name, date) {
    var h, i, j;
    h = ("<div class='" + name + "'>") + "<div class='xdsoft_datetimepicker controller'>" + "<button type='button' class='xdsoft_prev' />" + "<button type='button' class='xdsoft_next' />" + "</div></div>";
    $('#menu').before(h);
    for (i = j = 0; j <= 3; i = ++j) {
      if (i > 0) {
        date.add(1, 'months');
      }
      $("." + name).append("<div class='" + name + "-cal" + i + "'></div>");
      $("." + name + "-cal" + i).datetimepicker({
        timepicker: false,
        format: 'Y/m/d',
        closeOnDateSelect: true,
        scrollInput: false,
        scrollMonth: false,
        inline: true,
        defaultDate: date.format('YYYY-MM-DD'),
        defaultSelect: false,
        todayButton: false,
        onGenerate: function (time, el) {
          $(this).find('.xdsoft_today').removeClass('xdsoft_today');
          return $(this).find('.xdsoft_current').removeClass('xdsoft_current');
        },
        onSelectDate: function (ct, i) {
          date = sprintf("%d-%02d-%02d", ct.getFullYear(), ct.getMonth() + 1, ct.getDate());
          return $jQuery1('.calendar').fullCalendar('gotoDate', date);
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
})($jQuery3);
