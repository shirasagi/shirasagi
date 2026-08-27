SS.ready(function() {
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
    if (init && init["view"]) {
      params["initialView"] = init["view"];
    }

    // custom params
    delete params.tapMenu

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
    controller.find('.fc-reload-button').on("click", function () {
      return controllerWrap.find('.calendar.multiple .fc-reload-button').trigger("click");
    });
    controller.find('.fc-dayGridWeek-button').on("click", function () {
      return controllerWrap.find('.calendar.multiple .fc-dayGridWeek-button').trigger("click");
    });
    controller.find('.fc-timeGridDay-button').on("click", function () {
      return controllerWrap.find('.calendar.multiple .fc-timeGridDay-button').trigger("click");
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
    if (init && init["view"]) {
      params["initialView"] = init["view"];
    }

    // custom params
    delete params.tapMenu
    delete params.useWorkload

    // To render gridster and/or other frames first, all fullCalendar initializations is delayed.
    // And a calendar is individually rendered from top to bottom.
    setTimeout(function () {
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
        right: 'withAbsence withTodo dayGridWeek,timeGridDay'
      },
      slotDuration: '00:30:00',
      slotLabelFormat: { hour: '2-digit', minute: '2-digit', meridiem: false, hour12: false },
      views: {
        timeGridDay: {
          contentHeight: 25,
          slotMinTime: '08:00',
          slotMaxTime: '22:00'
        }
      }
    };
  };

  Gws_Schedule_Multiple_Calendar.controllerParams = function (_selector, _opts) {
    return {
      eventSources: [],
      headerToolbar: {
        left: 'today prev next title reload',
        right: 'withAbsence withTodo dayGridWeek,timeGridDay'
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

  Gws_Schedule_Multiple_Calendar.contentParams = function (selector, _opts) {
    return {
      loading: function (isLoading) {
        // var calendar = document.querySelector(selector).calendar;
        var target = document.querySelector(selector)

        target.querySelector('.fc-loading')?.remove();

        if (isLoading) {
          return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.loading"))[0]);
        }
        if (target.dataset.resourceError) {
          delete target.dataset.resourceError;
          return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.errors.resource_error"))[0]);
        }

        if (!isLoading) {
          requestAnimationFrame(function() {
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
      eventDidMount: function(arg) {
        var event = arg.event;
        var el = arg.el;
        // var view = arg.view;

        var start = moment(event.start)
        var name = el.querySelector('.fc-event-title')?.textContent;
        var span = $('<span class="fc-event-name"></span>').text(name);
        el.querySelector('.fc-event-title').innerHTML = span[0].outerHTML;
        el.style.color = event.textColor;

        if (el.className.includes('fc-event-range')) {
          var fcClass = 'fc-datetime';
          var format = 'MM/DD HH:mm';
          var end = moment(event.end);
          if (el.className.includes('fc-event-allday')) {
            fcClass = 'fc-date';
            format = 'MM/DD';
            end = end.add(-1, 'days')
          } else {
            el.querySelector('span.fc-event-time')?.remove();
          }
          var content = (start.format(format) + ' - ' + end.format(format));
          if (start.format(format) === end.format(format)) {
            content = end.format(format);
          }
          var dateTimeSpan = $('<span></span>').addClass(fcClass).append(content);
          el.querySelector('.fc-event-title').before(dateTimeSpan[0]);
          el.querySelector(".fc-event-time")?.remove();
        }
        if (event.extendedProps.category) {
          var categorySpan = $('<span class="fc-category"></span>').append(event.extendedProps.category);
          el.querySelector('.fc-event-title').prepend(categorySpan[0]);
        }
        if (event.extendedProps.facility) {
          var facilitySpan = $('<span class="fc-facility"></span>').append(event.extendedProps.facility);
          el.querySelector('.fc-event-title').append(facilitySpan[0]);
        }

        if (el.className.includes('fc-event-work')) {
          el.querySelector(".fc-date")?.remove();
          el.querySelector(".fc-resizer")?.remove();
          el.classList.remove("fc-resizable");
        }
      }
    };
  };

  window.Gws_Schedule_Multiple_Calendar = Gws_Schedule_Multiple_Calendar;
});
