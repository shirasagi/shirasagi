SS.ready(function() {
  window.Gws_Schedule_Multiple_Calendar = (function ($) {
    function Gws_Schedule_Multiple_Calendar() {
    }

    Gws_Schedule_Multiple_Calendar.render = function (selector, opts, init) {
      var params;
      if (opts == null) {
        opts = {};
      }
      if (init == null) {
        init = {};
      }
      params = Gws_Schedule_Calendar.defaultParams(selector, opts);
      if (opts['restUrl']) {
        $.extend(true, params, Gws_Schedule_Calendar.editableParams(selector, opts));
      }
      if (opts['restUrl']) {
        $.extend(true, params, Gws_Schedule_Calendar.tapMenuParams(selector, opts));
      }
      for (var i in opts.eventSources) {
        opts.eventSources[i]['error'] = function() { $(selector).data('resource-error', true); }
      }
      $.extend(true, params, this.defaultParams(selector, opts));
      $.extend(true, params, this.contentParams(selector, opts));
      $.extend(true, params, opts);
      if (init && init["date"]) {
        params["defaultDate"] = init["date"];
      }
      // To render gridster and/or other frames first, all fullCalendar initializations is delayed.
      // And a calendar is individually rendered from top to bottom.
      setTimeout(function () {
        $(selector).fullCalendar(params);
        Gws_Schedule_Calendar.renderInitialize(selector, init);

        Gws_Schedule_Multiple_Calendar.renderOnce();
      }, 0);
    };

    Gws_Schedule_Multiple_Calendar.onceRendered = false;

    // bind click handler once
    Gws_Schedule_Multiple_Calendar.renderOnce = function () {
      if (Gws_Schedule_Multiple_Calendar.onceRendered) {
        return;
      }

      $(document).on("click", function (ev) {
        $(".fc-event").not($(ev.target).closest(".fc-event")).find(".fc-popup").remove();
      });

      Gws_Schedule_Multiple_Calendar.onceRendered = true;
    };

    Gws_Schedule_Multiple_Calendar.defaultParams = function (_selector, _opts) {
      return {
        firstDay: 0,
        defaultView: 'basicWeek',
        header: {
          left: 'today prev next title reload',
          right: 'withAbsence withTodo basicWeek,timelineDay'
        },
        slotDuration: '01:00',
        slotLabelFormat: 'H',
        views: {
          basicHour: {
            type: 'day',
            buttonText: i18next.t("gws/schedule.options.interval.daily"),
            contentHeight: 25
          },
          timelineDay: {
            contentHeight: 25,
            minTime: '08:00',
            maxTime: '22:00'
          }
        }
      };
    };

    Gws_Schedule_Multiple_Calendar.controllerParams = function (_selector, _opts) {
      return {
        header: {
          left: 'today prev next title reload',
          right: 'withAbsence withTodo basicWeek,timelineDay'
        },
        eventSources: [],
        eventAfterAllRender: function (view) {
          if (view.name === 'basicWeek') {
            return view.el.find(".fc-body").hide();
          }
        }
      };
    };

    Gws_Schedule_Multiple_Calendar.contentParams = function (_selector, _opts) {
      return {
        eventRender: function (event, element, view) {
          var name = element.find('.fc-title').text();
          var span = $('<span class="fc-event-name"></span>').text(name);
          element.find('.fc-title').html(span);

          if (event.className.includes('fc-event-range')) {
            var fcClass = 'fc-datetime';
            var format = 'MM/DD HH:mm';
            var end = moment(event.end);
            if (event.className.includes('fc-event-allday')) {
              fcClass = 'fc-date';
              format = 'MM/DD';
              end = end.add(-1, 'days')
            } else {
              element.find('span.fc-time').remove();
            }
            var content = (event.start.format(format) + ' - ' + end.format(format));
            if (event.start.format(format) === end.format(format)) {
              content = end.format(format);
            }
            var spanBefore = $('<span></span>').addClass(fcClass).append(content);
            element.find('.fc-title').before(spanBefore);
          }
          if (event.category) {
            var spanPrepend = $('<span class="fc-category"></span>').append(event.category);
            element.find('.fc-title').prepend(spanPrepend);
          }
          if (event.facility) {
            var spanAfter = $('<span class="fc-facility"></span>').append(event.facility);
            element.find('.fc-title').after(spanAfter);
          }
          if (event.className.includes('fc-event-work')) {
            $(element).find(".fc-date").remove();
            $(element).find(".fc-resizer").remove();
            $(element).removeClass("fc-resizable");
          }
          if (view.name === 'basicHour') {
            return BasicHourView.eventRender(event, element, view);
          }
        },
        eventAfterAllRender: function (_view) {
          var attendance, todo;
          todo = $('.fc .fc-withTodo-button');
          if (todo.length) {
            if (todo.hasClass('fc-state-active')) {
              $('.fc .fc-event-todo').show();
            } else {
              $('.fc .fc-event-todo').hide();
            }
          }
          attendance = $('.fc .fc-withAbsence-button');
          if (attendance.length) {
            if (attendance.hasClass('fc-state-active')) {
              $('.fc .fc-event-user-attendance-absence').removeClass('hide');
            } else {
              $('.fc .fc-event-user-attendance-absence').addClass('hide');
            }
          }
          $(window).trigger('resize');
        }
      };
    };
    //view.el.find(".fctoolbar, .fc-head").remove("")

    Gws_Schedule_Multiple_Calendar.renderController = function (selector, opts, init) {
      var controller, controllerWrap, params;
      if (opts == null) {
        opts = {};
      }
      if (init == null) {
        init = {};
      }
      params = Gws_Schedule_Calendar.defaultParams(selector, opts);
      $.extend(true, params, this.defaultParams(selector, opts));
      $.extend(true, params, this.controllerParams(selector, opts));
      $.extend(true, params, opts);
      if (init && init["date"]) {
        params["defaultDate"] = init["date"];
      }
      $(selector).fullCalendar(params);
      Gws_Schedule_Calendar.renderInitialize(selector, init);
      Gws_Schedule_Calendar.overrideAddLink(selector);
      controller = $(selector);
      controllerWrap = controller.parent();
      controller.find('.fc-today-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-today-button').trigger("click");
      });
      controller.find('.fc-prev-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-prev-button').trigger("click");
      });
      controller.find('.fc-next-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-next-button').trigger("click");
      });
      controller.find('.fc-basicWeek-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-basicWeek-button').trigger("click");
      });
      controller.find('.fc-timelineDay-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-timelineDay-button').trigger("click");
      });
      controller.find('.fc-basicHour-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-basicHour-button').trigger("click");
      });
      controller.find('.fc-reload-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-reload-button').trigger("click");
      });
    };

    return Gws_Schedule_Multiple_Calendar;

  })($jQuery1);
});
