SS.ready(function() {
  function Gws_Schedule_Calendar() {
  }

  Gws_Schedule_Calendar.messages = {
    noPlan: i18next.t("gws/schedule.no_plan")
  };

  Gws_Schedule_Calendar.dateToString = function (date) {
    if (!date) return;
    var d = date;
    return sprintf("%d-%02d-%02d", d.getFullYear(), d.getMonth() + 1, d.getDate());
  };

  Gws_Schedule_Calendar.datetimeToString = function (date) {
    var d = date;
    return sprintf("%d-%02d-%02dT%02d:%02d", d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes());
  };

  Gws_Schedule_Calendar.render = function (selector, opts, init) {
    var params;
    if (opts == null) {
      opts = {};
    }
    if (init == null) {
      init = {};
    }
    params = this.defaultParams(selector, opts);
    if (opts['events']) {
      $.extend(true, params, this.editableParams(selector, opts));
    }
    if (opts['events']) {
      $.extend(true, params, this.tapMenuParams(selector, opts));
    }
    for (var i in opts.eventSources) {
      opts.eventSources[i]['error'] = function() { document.querySelector(selector).dataset.resourceError = true; }
    }
    $.extend(true, params, opts);
    if (init && init["date"]) {
      params["initialDate"] = init["date"];
    }
    if (init && init["view"]) {
      params["initialView"] = init["view"];
    }

    // custom params
    delete params.useWorkload
    delete params.tapMenu

    var calendarEl = document.querySelector(selector);
    var calendar = new FullCalendar.Calendar(calendarEl, params);
    calendar.render();
    calendarEl.calendar = calendar;

    this.renderInitialize(selector, init);
    this.overrideAddLink(selector);
  };

  Gws_Schedule_Calendar.renderInitialize = function (selector, init) {
    var calendarEl = document.querySelector(selector);
    var calendar = calendarEl.calendar;

    if (init == null) {
      init = {};
    }

    init['viewTodo'] || (init['viewTodo'] = 'active');
    if (init['viewTodo'] === 'active') {
      $(selector).find('.fc-withTodo-button').addClass("fc-state-active");
    }
    if (init['viewAttendance'] === 'active') {
      $(selector).find('.fc-withAbsence-button').addClass("fc-state-active");
    }
    Gws_Schedule_View.renderSideCalendars(selector);
    return $(selector + "-header .calendar-text").each(function () {
      var data, wrap;
      wrap = $(this);
      data = $(this).find('.calendar-text-popup').prop('outerHTML');
      return wrap.find('.calendar-text-link').on("click", function () {
        Gws_Popup.render($(this), $(data).show());
        return false;
      });
    });
  };

  Gws_Schedule_Calendar.defaultParams = function (selector, _opts) {
    return {
      noEventsText: i18next.t("gws/schedule.no_plan"),
      allDayText: i18next.t('gws/schedule.calendar.buttonText.allDay'),
      firstDay: 0,
      buttonText: {
        today: i18next.t('gws/schedule.calendar.buttonText.today'),
        month: i18next.t('gws/schedule.calendar.buttonText.month'),
        week: i18next.t('gws/schedule.calendar.buttonText.week'),
        day: i18next.t('gws/schedule.calendar.buttonText.day'),
        listMonth: i18next.t('gws/schedule.calendar.buttonText.listMonth'),
        listWeek: i18next.t('gws/schedule.calendar.buttonText.listMonth')
      },
      customButtons: {
        withTodo: {
          text: i18next.t('gws/schedule.calendar.buttonText.withTodo'),
          click: function (_ev) {
            $('.fc-event-todo').toggle(!$(this).hasClass('fc-state-active'));
            $(this).toggleClass("fc-state-active");
            return Gws_Schedule_Calendar.updateNoPlanVisibility($(this).closest(".fc"));
          }
        },
        withAbsence: {
          text: i18next.t('gws/schedule.calendar.buttonText.withAbsence'),
          click: function (_ev) {
            $(".fc-event-user-attendance-absence").each(function() {
              $(this).toggleClass("hide");
            });
            $('.fc-event-user-attendance-absence').toggle(!$(this).hasClass('fc-state-active'));
            $(this).toggleClass("fc-state-active");
            return Gws_Schedule_Calendar.updateNoPlanVisibility($(this).closest(".fc"));
          }
        },
        listMonth_x: {
          text: i18next.t('gws/schedule.calendar.buttonText.listMonth'),
          click: function (ev) {
            var calendar = ev.target.closest('.calendar').calendar;
            var current = ev.target.closest('.fc-toolbar').querySelector('[aria-pressed="true"]').className;
            if (current.match('Month')) {
              calendar.changeView('listMonth');
            }
            if (current.match('Week')) {
              calendar.changeView('listWeek');
            }
            if (current.match('Day')) {
              calendar.changeView('listDay');
            }
          }
        },
        reload: {
          text: i18next.t('ss.buttons.reload'),
          icon: "gws-schedule-calendar-reload",
          click: function (ev) {
            var calendar = ev.target.closest('.calendar').calendar;
            if (calendar) calendar.refetchEvents();
          }
        }
      },
      contentHeight: 'auto',
      displayEventEnd: {
        month: true,
        timeGridWeek: true
      },
      endParam: 's[end]',
      fixedWeekCount: false,
      slotEventOverlap: false,
      headerToolbar: {
        left: 'today prev next title reload',
        right: 'withAbsence withTodo dayGridMonth,dayGridWeek,timeGridDay listMonth'
      },
      locale: document.documentElement.lang || 'ja',
      nextDayThreshold: '00:00:00', // 複数日表示の閾値
      slotDuration: '00:30',
      slotLabelFormat: { hour: '2-digit', minute: '2-digit', meridiem: false, hour12: false },
      startParam: 's[start]',
      eventTimeFormat: {
        hour: '2-digit', minute: '2-digit', meridiem: false, hour12: false
      },
      views: {
        dayGridMonth: {
          titleFormat: i18next.t('gws/schedule.calendar.titleFormat.dayGridMonth', { returnObjects: true }),
        },
        dayGridWeek: {
          titleFormat: i18next.t('gws/schedule.calendar.titleFormat.dayGridWeek', { returnObjects: true }),
          dayHeaderFormat: i18next.t('gws/schedule.calendar.dayHeaderFormat.dayGridWeek', { returnObjects: true }),
        },
        timeGridDay: {
          titleFormat: i18next.t('gws/schedule.calendar.titleFormat.timeGridDay', { returnObjects: true }),
          dayHeaderFormat: i18next.t('gws/schedule.calendar.dayHeaderFormat.timeGridDay', { returnObjects: true }),
        },
        listMonth: {
          titleFormat: i18next.t('gws/schedule.calendar.titleFormat.listMonth', { returnObjects: true }),
          listDayFormat: i18next.t('gws/schedule.calendar.dayHeaderFormat.listMonth', { returnObjects: true }),
          listDaySideFormat: false
        }
      },
      loading: function (isLoading) {
        var calendar = document.querySelector(selector).calendar;
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
            Gws_Schedule_Calendar.updateNoPlanVisibility(calendar.el.closest(".fc"));
            return Gws_Schedule_Calendar.changePrintPreviewPortrait(calendar.view);
          });
        }
      },
      eventDidMount: function(arg) {
        var event = arg.event;
        var el = arg.el;

        var nameEl = (el.querySelector('.fc-event-title') || el.querySelector('.fc-list-event-title a'))
        var name = nameEl?.textContent;
        var span = $('<span class="fc-event-name"></span>').text(name);
        nameEl.innerHTML = span[0].outerHTML;
        el.style.color = event.textColor;
        el.style.backgroundColor = event.backgroundColor;

        if (el.className.includes('fc-event-range')) {
          var fcClass = 'fc-datetime';
          var format = 'MM/DD HH:mm';
          var start = moment(event.start)
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
          nameEl.before(dateTimeSpan[0]);
          el.querySelector(".fc-event-time")?.remove();
        }

        // only listMonth
        if (arg.view.type == "listMonth") {
          el.querySelector(".fc-list-event-title a").style.color = el.style.color;
          el.querySelector(".fc-list-event-title a").style.backgroundColor = el.style.backgroundColor;
          el.style.color = '#000';
          el.style.backgroundColor = '#fff';
          (el.querySelector(".fc-datetime") || el.querySelector(".fc-date"))?.remove();
        }

        if (event.extendedProps.category) {
          var categorySpan = $('<span class="fc-category"></span>').append(event.extendedProps.category);
          nameEl.prepend(categorySpan[0]);
        }
        if (event.extendedProps.facility) {
          var facilitySpan = $('<span class="fc-facility"></span>').append(event.extendedProps.facility);
          nameEl.append(facilitySpan[0]);
        }
        if (el.className.includes('fc-event-work')) {
          el.querySelector(".fc-date")?.remove();
          el.querySelector(".fc-resizer")?.remove();
          el.classList.remove("fc-resizable");
        }
      }
    };
  };

  Gws_Schedule_Calendar.viewStateQuery = function (info) {
    var attendance, format, todo, path;
    format = $(info.el).closest(".fc").hasClass('fc-list-format') ? 'list' : 'default';
    todo = $('.fc .fc-withTodo-button').hasClass("fc-state-active") ? 'active' : 'inactive';
    attendance = $('.fc .fc-withAbsence-button').hasClass("fc-state-active") ? 'active' : 'inactive';

    path = "calendar[path]=" + location.pathname;
    path += "&calendar[view]=" + info.view.type;
    path += "&calendar[viewFormat]=" + format;
    path += "&calendar[viewTodo]=" + todo;
    path += "&calendar[viewAttendance]=" + attendance;
    if ($('[name="s[facility_category_id]"]').val()) {
      path += "&calendar[facilityCategory]=" + $('[name="s[facility_category_id]"]').val();
    }
    return path
  };

  Gws_Schedule_Calendar.tapMenuParams = function (selector, opts) {
    var url = opts['events'].replace(/\.json/, '');

    return {
      dateClick: function (info) {
        // var event = info.event;
        var jsEvent = info.jsEvent;
        var view = info.view;
        var date = info.date
        var dateFormatted = Gws_Schedule_Calendar.dateToString(date);

        var links, now, start, state, todo;
        links = '';
        if (opts['tapMenu']) {
          now = new Date;

          start = dateFormatted + "T" + (now.getHours()) + ":00:00";
          state = ("calendar[date]=" + dateFormatted + "&") + Gws_Schedule_Calendar.viewStateQuery(info);
          links = ejs.render(
            "<a href='<%= url %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
            { url: url, start: start, state: state, text: i18next.t('gws/schedule.links.add_plan') });
          todo = url.replace(/schedule\/.*/, 'schedule/todo/-/readables');
          links += ejs.render(
            "<a href='<%= todo %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
            { todo: todo, start: start, state: state, text: i18next.t('gws/schedule.links.add_todo') });

          if (opts['useWorkload']) {
            var workload = url.replace(/schedule\/.*/, 'workload/-/-/-/-/-/works');
            links += ejs.render(
              "<a href='<%= workload %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
              { workload: workload, start: start, state: state, text: i18next.t('gws/schedule.links.add_workload') });
          }
        }
        if ($('#calendar-controller').length === 0) {
          if (view.type !== 'dayGridMonth') {
            links += $('<a href="" data-view="dayGridMonth"/>').text(i18next.t("gws/schedule.links.show_month")).prop("outerHTML");
          }
          if (view.type !== 'dayGridWeek') {
            links += $('<a href="" data-view="dayGridWeek"/>').text(i18next.t("gws/schedule.links.show_week")).prop("outerHTML");
          }
          if (view.type !== 'timeGridDay') {
            links += $('<a href="" data-view="timeGridDay"/>').text(i18next.t("gws/schedule.links.show_day")).prop("outerHTML");
          }
        }
        if (links) {
          $("body").append('<div class="tap-menu">' + links + '</div>');
          if (jsEvent.pageX + $(".tap-menu").width() > $(window).width()) {
            $(".tap-menu").css("top", jsEvent.pageY - 5).css("right", 5).show();
          } else {
            $(".tap-menu").css("top", jsEvent.pageY - 5).css("left", jsEvent.pageX - 5).show();
          }
          $(".tap-menu a").on("click", function () {
            var cal;
            if ($(this).data('view')) {
              cal = view.calendar;
              cal.changeView($(this).data('view'));
              cal.gotoDate(date);
              $(".tap-menu").remove();
              return false;
            }
          });
          return $(".tap-menu").on("mouseleave", function () {
            return $(".tap-menu").remove();
          });
        }
      }
    };
  };

  Gws_Schedule_Calendar.editableParams = function (selector, opts) {
    var url = opts['events'].replace(/\.json/, '');
    var token = $('meta[name="csrf-token"]').attr('content');

    return {
      editable: true,
      eventClick: function (info) {
        var event = info.event;
        var jsEvent = info.jsEvent;

        var start = Gws_Schedule_Calendar.dateToString(event.start);

        if (event.extendedProps?.noPopup) {
          return;
        }
        var popup_url = event.extendedProps?.events ? event.extendedProps.events.replace(/\.json/, '') : url;
        var state = ("calendar[date]=" + start + "&") + Gws_Schedule_Calendar.viewStateQuery(info);

        jsEvent.preventDefault();
        location.href = popup_url + "/" + event.id + "?" + state;
      },
      eventAllow: function(dropInfo, draggedEvent) {
        if (draggedEvent._context.viewSpec.type === 'timeGridDay') {
          if (dropInfo.allDay || draggedEvent.allDay) {
            return false;
          }
        }
        return true;
      },
      eventDrop: function (info) {
        var event = info.event;
        var start, end = null;
        var asyncUrl = event.extendedProps?.events ? event.extendedProps.events.replace(/\.json/, '') : url;

        if (event.allDay) {
          start = moment(event.start).format('YYYY/MM/DD');
          if (event.end) end = event.end;
        } else {
          start = moment(event.start).format('YYYY/MM/DDTHH:mm:ss');
          end = new Date(event.start.getTime() + (1000 * 60 * 60 * 1)); // + 1 hour
        }

        return $.ajax({
          type: 'PUT',
          url: `${asyncUrl}/${event.id}.json`,
          data: {
            item: {
              api: 'drop',
              api_start: start,
              api_end: end
            },
            authenticity_token: token
          },
          success: function (_data, _dataType) {
            var viewId = $(info.el).closest('.calendar').attr('id');
            $.each($('.calendar.multiple').not("#" + viewId), (_i, item) => {
              item.calendar.refetchEvents();
            });
          },
          error: function (xhr, _status, _error) {
            alert(xhr.responseJSON.join("\n"));
            return info.revert();
          }
        });
      },
      eventResize: function (info) {
        var event = info.event;

        var start, end = null;
        if (event.allDay) {
          start = Gws_Schedule_Calendar.dateToString(event.start);
          if (event.end) end = Gws_Schedule_Calendar.dateToString(event.end);
        } else {
          start = Gws_Schedule_Calendar.datetimeToString(event.start);
          if (event.end) end = Gws_Schedule_Calendar.datetimeToString(event.end);
        }

        var asyncUrl = event.extendedProps?.events ? event.extendedProps.events.replace(/\.json/, '') : url;

        return $.ajax({
          type: 'PUT',
          url: `${asyncUrl}/${event.id}.json`,
          data: {
            item: {
              api: 'resize',
              api_start: start,
              api_end: end
            },
            authenticity_token: token
          },
          success: function (_data, _dataType) {
            var viewId = $(info.el).closest('.calendar').attr('id');
            $.each($('.calendar.multiple').not("#" + viewId), (_i, item) => {
              item.calendar.refetchEvents();
            });
          },
          error: function (xhr, _status, _error) {
            alert(xhr.responseJSON.join("\n"));
            return info.revert();
          }
        });
      }
    };
  };

  Gws_Schedule_Calendar.changePrintPreviewPortrait = function (view) {
    if ($('body').hasClass('print-preview')) {
      if (view.type === 'timeGridDay' || view.type === 'listMonth' || $(view.el).closest(".fc").hasClass("fc-list-format")) {
        $('body').removeClass('horizontal');
        return $('body').addClass('vertical');
      } else {
        $('body').removeClass('vertical');
        return $('body').addClass('horizontal');
      }
    }
  };

  Gws_Schedule_Calendar.overrideAddLink = function (selector) {
    $('.add-plan').on("click", function (_ev) {
      var calendar = document.querySelector(selector).calendar;
      var date, href, now, start, state, view;
      now = new Date;
      date = calendar.getDate();
      date = Gws_Schedule_Calendar.dateToString(date)
      view = calendar.view;

      href = $(this).attr('href').replace(/\?.*/, '');
      if (!(view.activeStart < now && view.activeEnd > now)) {
        start = date + "T" + (now.getHours()) + ":00:00";
        state = ("calendar[date]=" + date + "&") + Gws_Schedule_Calendar.viewStateQuery(calendar);
        href = href + ("?start=" + start + "&" + state);
      } else {
        href = href + "?" + Gws_Schedule_Calendar.viewStateQuery(calendar);
      }
      $(this).attr('href', href);
    });
  };

  Gws_Schedule_Calendar.updateNoPlanVisibility = function (selector) {
    var no_plan;
    no_plan = $(selector).find('.fc-listMonth-view-container .no-plan');
    if (no_plan.length !== 0) {
      if ($('.fc-event:visible').length === 0) {
        return no_plan.show();
      } else {
        return no_plan.hide();
      }
    }
  };

  window.Gws_Schedule_Calendar = Gws_Schedule_Calendar;
});
