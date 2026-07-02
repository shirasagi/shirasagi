SS.ready(function() {
  window.Gws_Notice_Calendar = (function ($) {
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
        opts.eventSources[i]['error'] = function() { $(selector).data('resource-error', true); }
      }
      $.extend(true, params, opts);

      delete params.titleFormat // error
      delete params.eventTimeFormat
      delete params.slotLabelFormat
      delete params.schedulerLicenseKey
      delete params.timeFormat
      delete params.eventRender
      delete params.useWorkload
      delete params.minTime
      delete params.maxTime

      // custom
      delete params.tapMenu

      var calendarEl = document.querySelector(selector);
      var calendar = new FullCalendar.Calendar(calendarEl, params);
      calendar.render();
      calendarEl.calendar = calendar;

      // Gws_Notice_Calendar.calendar = $(selector).fullCalendar(params);
      // this.renderInitialize(selector, init);
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
        firstDay: 0,
        buttonText: {
          today: i18next.t('gws/schedule.calendar.buttonText.today'),
          month: i18next.t('gws/schedule.calendar.buttonText.month'),
          week: i18next.t('gws/schedule.calendar.buttonText.week'),
          day: i18next.t('gws/schedule.calendar.buttonText.day'),
          listMonth: i18next.t('gws/schedule.calendar.buttonText.listMonth'),
          listWeek: i18next.t('gws/schedule.calendar.buttonText.listMonth')
        },
        // columnHeaderFormat: {
        //   month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.month')),
        //   week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.week'))
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
        schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
        slotLabelFormat: 'HH:mm',
        startParam: 's[start]',
        timeFormat: 'HH:mm',
        // '(' と ')' とで囲むと「2025年 1月 26日（日） — 2025年 2月 1日（土）」のような表示になり、
        // '(' と ')' とで囲まない場合、共通部分が collapse され「2025年 1月 26日（日） — 2月 1日（土）」のような表示になる。
        // しかし、日本語の場合、FullCalendarの formatRange バグ（？）で、うまく collapse されないので、week の場合は collapse 禁止、それ以外は collapse 許可。
        // 参考: https://fullcalendar.io/docs/v3/formatRange
        titleFormat: {
          month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.month')),
          week: '(' + SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.week')) + ')'
        },
        loading: function (isLoading, _view) {
          var calendar = document.querySelector(selector).calendar;
          var target = $(selector).hasClass("fc-list-format") ? $(this).find('.fc-view') : $(this).find('.fc-widget-content').eq(0)

          $(this).find('.fc-loading').remove();
          if (isLoading) {
            return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.loading")));
          }
          if ($(selector).data('resource-error')) {
            $(selector).data('resource-error', null);
            return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.errors.resource_error")));
          }

          if (!isLoading) {
            requestAnimationFrame(function() {
              // eventAfterAllRender
              if (opts.eventAfterAllRenderCallback) {
                opts.eventAfterAllRenderCallback();
              }
              Gws_Notice_Calendar.updateNoPlanVisibility(calendar.el.closest(".fc"));
              return Gws_Notice_Calendar.changePrintPreviewPortrait(calendar.view);
            });
          }
        },
        eventRender: function(event, element) {
          if (event.abbrTitle) {
            var title = element.find('.fc-evnet-title');
            var tippyOptions = { trigger: 'mouseenter', theme: 'light-border ss-tooltip', interactive: false };

            tippyOptions["content"] = event.title;
            title.text(event.abbrTitle);
            tippy(element[0], tippyOptions);
          }

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
            span = $('<span></span>').addClass(fcClass).append(content);
            element.find('.fc-evnet-title').before(span);
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
        if (view.type === 'timeGridDay' || view.type === 'timeGridDay' || $(view.el).closest(".fc").hasClass("fc-list-format")) {
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

    return Gws_Notice_Calendar;

  })($jQuery3);
});
