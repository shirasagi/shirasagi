SS.ready(function() {
  window.Gws_Schedule_Multiple_Calendar = (function ($) {
    function Gws_Schedule_Multiple_Calendar() {
    }

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
        params["initialDate"] = init["date"];
      }

      // params.titleFormat = { year: 'numeric', month: '2-digit', day: '2-digit' }
      // params.titleFormat = { year: 'numeric', month: 'long' }
      // params.eventTimeFormat = { hour: '2-digit', minute: '2-digit', second: '2-digit', meridiem: false, hour12: false }
      // params.views.week = {
      //   titleFormat: { year: 'numeric', month: '2-digit', day: '2-digit' }
      // }

      delete params.titleFormat // error
      delete params.slotLabelFormat
      delete params.schedulerLicenseKey
      delete params.timeFormat
      delete params.eventRender
      delete params.tapMenu
      delete params.useWorkload
      delete params.minTime
      delete params.maxTime

      console.log('params', params);

      var calendarEl = document.querySelector(selector);
      var calendar = new FullCalendar.Calendar(calendarEl, params);
      calendar.render();
      calendarEl.calendar = calendar;

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
      controller.find('.fc-dayGridWeek-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-dayGridWeek-button').trigger("click");
      });
      controller.find('.fc-timeGridDay-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-timeGridDay-button').trigger("click");
      });
      controller.find('.fc-basicHour-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-basicHour-button').trigger("click");
      });
      controller.find('.fc-reload-button').on("click", function () {
        return controllerWrap.find('.calendar.multiple .fc-reload-button').trigger("click");
      });
    };

    Gws_Schedule_Multiple_Calendar.render = function (selector, opts, init) {
      var params;
      if (opts == null) {
        opts = {};
      }
      if (init == null) {
        init = {};
      }
      params = Gws_Schedule_Calendar.defaultParams(selector, opts);
      if (opts['events']) {
        $.extend(true, params, Gws_Schedule_Calendar.editableParams(selector, opts));
      }
      if (opts['events']) {
        $.extend(true, params, Gws_Schedule_Calendar.tapMenuParams(selector, opts));
      }
      for (var i in opts.eventSources) {
        opts.eventSources[i]['error'] = function() { $(selector).data('resource-error', true); }
      }
      $.extend(true, params, this.defaultParams(selector, opts));
      $.extend(true, params, this.contentParams(selector, opts));
      $.extend(true, params, opts);
      if (init && init["date"]) {
        params["initialDate"] = init["date"];
      }

      // To render gridster and/or other frames first, all fullCalendar initializations is delayed.
      // And a calendar is individually rendered from top to bottom.
      setTimeout(function () {
        delete params.titleFormat
        delete params.slotLabelFormat
        delete params.schedulerLicenseKey
        delete params.timeFormat
        delete params.eventRender
        delete params.useWorkload

        // custom
        delete params.tapMenu

        var calendarEl = document.querySelector(selector);
        var calendar = new FullCalendar.Calendar(calendarEl, params);
        calendar.render();
        calendarEl.calendar = calendar;

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
        initialView: 'dayGridWeek',
        headerToolbar: {
          left: 'today prev next title reload',
          right: 'withAbsence withTodo dayGridWeek timeGridDay'
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
        eventSources: [],
        headerToolbar: {
          left: 'today prev next title reload',
          right: 'withAbsence withTodo dayGridWeek timeGridDay'
        },
        // ビュー変更時 ... より適切なイベントがあれば変更
        datesSet: function(info) {
          var container = document.querySelector('.calendar-multiple-container')
          container.dataset.viewType = info.view.type;
        },

        // eventAfterAllRender
        // datesSet: function(info) {
        //   var view = info.view;
        //   if (view.type === 'dayGridWeek') {
        //     return $(info.el).find(".fc-body").hide();
        //   }
        // }
      };
    };

    Gws_Schedule_Multiple_Calendar.contentParams = function (_selector, _opts) {
      return {
        loading: function (isLoading) {
          if (!isLoading) {
            requestAnimationFrame(function() {
              // eventAfterAllRender
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
            });
          }
        },
        eventRender: function (event, element, view) {
          var name = element.find('.fc-evnet-title').text();
          var span = $('<span class="fc-event-name"></span>').text(name);
          element.find('.fc-evnet-title').html(span);

          if (event.className.includes('fc-event-range')) {
            var fcClass = 'fc-datetime';
            var format = 'MM/DD HH:mm';
            var end = moment(event.end);
            if (event.className.includes('fc-event-allday')) {
              fcClass = 'fc-date';
              format = 'MM/DD';
              end = end.add(-1, 'days')
            } else {
              element.find('span.fc-event-time').remove();
            }
            var content = (event.start.format(format) + ' - ' + end.format(format));
            if (event.start.format(format) === end.format(format)) {
              content = end.format(format);
            }
            var spanBefore = $('<span></span>').addClass(fcClass).append(content);
            element.find('.fc-evnet-title').before(spanBefore);
          }
          if (event.category) {
            var spanPrepend = $('<span class="fc-category"></span>').append(event.category);
            element.find('.fc-evnet-title').prepend(spanPrepend);
          }
          if (event.facility) {
            var spanAfter = $('<span class="fc-facility"></span>').append(event.facility);
            element.find('.fc-evnet-title').after(spanAfter);
          }
          if (event.className.includes('fc-event-work')) {
            $(element).find(".fc-date").remove();
            $(element).find(".fc-resizer").remove();
            $(element).removeClass("fc-resizable");
          }
          if (view.type === 'basicHour') {
            return BasicHourView.eventRender(event, element, view);
          }
        }
      };
    };

    return Gws_Schedule_Multiple_Calendar;

  })($jQuery3);
});
