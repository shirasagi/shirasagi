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
      if (opts['restUrl']) {
        $.extend(true, params, this.editableParams(selector, opts));
      }
      if (opts['restUrl']) {
        $.extend(true, params, this.tapMenuParams(selector, opts));
      }
      for (var i in opts.eventSources) {
        opts.eventSources[i]['error'] = function() { $(selector).data('resource-error', true); }
      }
      $.extend(true, params, opts);
      Gws_Notice_Calendar.calendar = $(selector).fullCalendar(params);
      this.renderInitialize(selector, init);
    };

    Gws_Notice_Calendar.renderInitialize = function (selector, init) {
      if (init == null) {
        init = {};
      }
      if (init['date']) {
        $(selector).fullCalendar('gotoDate', init['date']);
      }
      if (init['viewFormat'] === 'list') {
        $.fullCalendar.toggleListFormat(selector);
        $(selector).find('.fc-withListView-button').addClass("fc-state-active");
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
          listMonth: i18next.t('gws/schedule.calendar.buttonText.listMonth')
        },
        columnFormat: {
          month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.month')),
          week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.week'))
        },
        customButtons: {
          withListView: {
            text: i18next.t('gws/schedule.calendar.buttonText.listMonth'),
            click: function (_ev) {
              $.fullCalendar.toggleListFormat(selector);
              $(selector).fullCalendar('refetchEvents');
              $(window).trigger('resize'); //for AgendaView

              return $(this).toggleClass("fc-state-active");
            }
          },
          reload: {
            text: i18next.t('ss.buttons.reload'),
            icon: "gws-schedule-calendar-reload",
            click: function (_ev) {
              $(selector).fullCalendar('refetchEvents');
            }
          }
        },
        contentHeight: 'auto',
        displayEventEnd: {
          month: true,
          basicWeek: true
        },
        endParam: 's[end]',
        fixedWeekCount: false,
        slotEventOverlap: false,
        header: {
          left: 'today prev next title reload',
          right: 'month,basicWeek withListView'
        },
        lang: document.documentElement.lang || 'ja',
        nextDayThreshold: '00:00:00', // 複数日表示の閾値
        schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
        slotLabelFormat: 'HH:mm',
        startParam: 's[start]',
        timeFormat: 'HH:mm',
        titleFormat: {
          month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.month')),
          week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.week'))
        },
        loading: function (isLoading, _view) {
          var target = $(selector).hasClass("fc-list-format") ? $(this).find('.fc-view') : $(this).find('.fc-widget-content').eq(0)

          $(this).find('.fc-loading').remove();
          if (isLoading) {
            return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.loading")));
          }
          if ($(selector).data('resource-error')) {
            $(selector).data('resource-error', null);
            return target.prepend($('<span />', { class: "fc-loading" }).text(i18next.t("gws/schedule.errors.resource_error")));
          }
        },
        eventRender: function(event, element) {
          if (event.abbrTitle) {
            var title = element.find('.fc-title');
            var tippyOptions = { trigger: 'mouseenter', theme: 'light-border ss-tooltip', interactive: false };

            tippyOptions["content"] = event.title;
            title.text(event.abbrTitle);
            tippy(element[0], tippyOptions);
          }

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
            span = $('<span></span>').addClass(fcClass).append(content);
            element.find('.fc-title').before(span);
          }
          //if (event.categories) {
          //  $(event.categories).each(function() {
          //    span = $('<span class="fc-category" style=""></span>').append(this.name);
          //    if (this.color) {
          //      span.css("background-color", this.color);
          //      span.css("color", this.text_color);
          //    }
          //    element.find('.fc-title').append(span);
          //  });
          //}
        },
        eventAfterAllRender: function (view) {
          if (opts.eventAfterAllRenderCallback) {
            opts.eventAfterAllRenderCallback();
          }
          Gws_Notice_Calendar.updateNoPlanVisibility(view.el.closest(".fc"));
          return Gws_Notice_Calendar.changePrintPreviewPortrait(view);
        }
      };
    };

    Gws_Notice_Calendar.viewStateQuery = function (view) {
      var format = view.el.closest(".fc").hasClass('fc-list-format') ? 'list' : 'default';
      return "calendar[path]=" + location.pathname + "&calendar[view]=" + view.name + "&calendar[viewFormat]=" + format;
    };

    Gws_Notice_Calendar.tapMenuParams = function (_selector, _opts) {
      var $controller = $('#calendar-controller');
      return {
        dayClick: function (date, event, view) {
          var links = "";
          var headerOptions = []
          $.map(view.options.header, function(v) { headerOptions = headerOptions.concat(v.split(/\W/)) });
          if ($controller.length === 0) {
            if (view.name !== 'month' && headerOptions.includes('month')) {
              links += $('<a href="" data-view="month"/>').text(i18next.t("gws/schedule.links.show_month")).prop("outerHTML");
            }
            if (view.name !== 'basicWeek' && headerOptions.includes('basicWeek')) {
              links += $('<a href="" data-view="basicWeek"/>').text(i18next.t("gws/schedule.links.show_week")).prop("outerHTML");
            }
          }
          if (links) {
            $("body").append('<div class="tap-menu">' + links + '</div>');
            if (event.pageX + $(".tap-menu").width() > $(window).width()) {
              $(".tap-menu").css("top", event.pageY - 5).css("right", 5).show();
            } else {
              $(".tap-menu").css("top", event.pageY - 5).css("left", event.pageX - 5).show();
            }
            $(".tap-menu a").on("click", function () {
              var cal;
              if ($(this).data('view')) {
                cal = view.calendar.getCalendar();
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
      var url = opts['restUrl'];
      return {
        editable: true,
        eventClick: function (event, jsEvent, view) {
          if (event.noPopup) {
            return;
          }
          var popup_url = event.restUrl ? event.restUrl : url;
          var state = ("calendar[date]=" + (event.start.format('YYYY-MM-DD')) + "&") + Gws_Notice_Calendar.viewStateQuery(view);

          jsEvent.preventDefault();
          event.url = popup_url + "/" + event.id + "?" + state;
          location.href = event.url;
        },
      };
    };

    Gws_Notice_Calendar.changePrintPreviewPortrait = function (view) {
      if ($('body').hasClass('print-preview')) {
        if (view.type === 'agendaDay' || view.type === 'listMonth' || view.el.closest(".fc").hasClass("fc-list-format")) {
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

  })($jQuery1);
});
