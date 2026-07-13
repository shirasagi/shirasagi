SS.ready(function() {
  function Gws_Notice_Calendar() {
  }

  Gws_Notice_Calendar.calendar = null;

  Gws_Notice_Calendar.messages = {
    noPlan: i18next.t("gws/schedule.no_plan")
  };

  Gws_Notice_Calendar.render = function (selector, opts, init) {
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

    // custom params
    delete params.tapMenu
    delete params.useWorkload

    var calendarEl = document.querySelector(selector);
    var calendar = new FullCalendar.Calendar(calendarEl, params);
    calendar.render();
    calendarEl.calendar = calendar;

    this.renderInitialize(selector, init);
  };

  Gws_Notice_Calendar.renderInitialize = function (selector, init) {
    var calendarEl = document.querySelector(selector);
    var calendar = calendarEl.calendar;

    if (init == null) {
      init = {};
    }
    if (init['date']) {
      calendar.gotoDate(init['date']);
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

  Gws_Notice_Calendar.defaultParams = function (selector, opts) {
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
      // dayHeaderFormat: {
      //   weekday: 'short', month: 'numeric', day: 'numeric'
      //   // month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.month')),
      //   // week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.week'))
      // },
      customButtons: {
        reload: {
          text: i18next.t('ss.buttons.reload'),
          icon: "gws-schedule-calendar-reload",
          click: function (ev) {
            ev.target.closest('.calendar').calendar.refetchEvents();
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
        right: 'dayGridMonth,dayGridWeek listMonth'
      },
      locale: document.documentElement.lang || 'ja',
      nextDayThreshold: '00:00:00', // 複数日表示の閾値
      slotLabelFormat: { hour: '2-digit', minute: '2-digit', meridiem: false, hour12: false },
      startParam: 's[start]',
      titleFormat: {
        year: 'numeric', month: 'short', day: 'numeric'
        // month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.month')),
        // week: '(' + SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.week')) + ')'
      },
      eventTimeFormat: {
        hour: '2-digit', minute: '2-digit', meridiem: false, hour12: false
      },
      views: {
        dayGridMonth: {
          titleFormat: { year: 'numeric', month: 'long' }
        },
        dayGridWeek: {
          titleFormat: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'narrow' }
        },
        timeGridDay: {
          titleFormat: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'narrow' }
        },
        listMonth: {
          titleFormat: { year: 'numeric', month: 'long' },
          listDayFormat: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'narrow' },
          listDaySideFormat: false
        }
      },
      loading: function (isLoading, _view) {
        var calendar = document.querySelector(selector).calendar;
        var target = document.querySelector(selector)

        target.querySelector('.fc-loading')?.remove();

        if (isLoading) {
          return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.loading"))[0]);
        }
        if (target.dataset.resourceError) {
          target.dataset.resourceError = null;
          return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.errors.resource_error")));
        }

        if (!isLoading) {
          requestAnimationFrame(function() {
            if (opts.eventAfterAllRenderCallback) {
              opts.eventAfterAllRenderCallback();
            }
            Gws_Notice_Calendar.updateNoPlanVisibility(calendar.el.closest(".fc"));
            return Gws_Notice_Calendar.changePrintPreviewPortrait(calendar.view);
          });
        }
      },
      eventDidMount: function(arg) {
        var event = arg.event;
        var el = arg.el;

        if (event.extendedProps.abbrTitle) {
          var title = (el.querySelector('.fc-event-title') || el.querySelector('.fc-list-event-title a'));
          var tippyOptions = { trigger: 'mouseenter', theme: 'light-border ss-tooltip', interactive: false };

          tippyOptions["content"] = event.title;
          title.textContent = event.extendedProps.abbrTitle;
          tippy(el, tippyOptions);
        }

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
      }
    };
  };

  Gws_Notice_Calendar.viewStateQuery = function (info) {
    var format = $(info.el).closest(".fc").hasClass('fc-list-format') ? 'list' : 'default';
    return "calendar[path]=" + location.pathname + "&calendar[view]=" + info.view.type + "&calendar[viewFormat]=" + format;
  };

  Gws_Notice_Calendar.tapMenuParams = function (_selector, _opts) {
    var $controller = $('#calendar-controller');
    return {
      dateClick: function (info) {
        // var _event = info.event;
        var jsEvent = info.jsEvent;
        var view = info.view;
        var date = info.date;

        var links = "";
        var headerOptions = [];
        $.map(view.getOption('headerToolbar'), function(v) { headerOptions = headerOptions.concat(v.split(/\W/)) });
        if ($controller.length === 0) {
          if (view.type !== 'dayGridMonth' && headerOptions.includes('dayGridMonth')) {
            links += $('<a href="" data-view="dayGridMonth"/>').text(i18next.t("gws/schedule.links.show_month")).prop("outerHTML");
          }
          if (view.type !== 'dayGridWeek' && headerOptions.includes('dayGridWeek')) {
            links += $('<a href="" data-view="dayGridWeek"/>').text(i18next.t("gws/schedule.links.show_week")).prop("outerHTML");
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
          $(".tap-menu").on("mouseleave", function () {
            $(".tap-menu").remove();
          });
        }
      }
    };
  };

  Gws_Notice_Calendar.editableParams = function (selector, opts) {
    var url = opts['events'].replace(/\.json/, '');
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
        var state = ("calendar[date]=" + start + "&") + Gws_Notice_Calendar.viewStateQuery(info);

        jsEvent.preventDefault();
        location.href = popup_url + "/" + event.id + "?" + state;
      },
    };
  };

  Gws_Notice_Calendar.changePrintPreviewPortrait = function (view) {
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

  Gws_Notice_Calendar.updateNoPlanVisibility = function (selector) {
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

  window.Gws_Notice_Calendar = Gws_Notice_Calendar;
});
