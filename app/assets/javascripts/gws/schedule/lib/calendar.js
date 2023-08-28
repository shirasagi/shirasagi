SS.ready(function() {
  window.Gws_Schedule_Calendar = (function ($) {
    function Gws_Schedule_Calendar() {
    }

    Gws_Schedule_Calendar.messages = {
      noPlan: i18next.t("gws/schedule.no_plan")
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
      $(selector).fullCalendar(params);
      this.renderInitialize(selector, init);
      this.overrideAddLink(selector);
    };

    Gws_Schedule_Calendar.renderInitialize = function (selector, init) {
      if (init == null) {
        init = {};
      }
      init['viewTodo'] || (init['viewTodo'] = 'active');
      if (init['view']) {
        $(selector).fullCalendar('changeView', init['view']);
      }
      if (init['date']) {
        $(selector).fullCalendar('gotoDate', init['date']);
      }
      if (init['viewFormat'] === 'list') {
        $.fullCalendar.toggleListFormat(selector);
        $(selector).find('.fc-withListView-button').addClass("fc-state-active");
      }
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
        firstDay: 0,
        buttonText: {
          listMonth: i18next.t('gws/schedule.calendar.buttonText.listMonth')
        },
        columnFormat: {
          month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.month')),
          week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.week')),
          day: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.columnFormat.day'))
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
          basicWeek: true
        },
        endParam: 's[end]',
        fixedWeekCount: false,
        slotEventOverlap: false,
        header: {
          left: 'today prev next title reload',
          right: 'withAbsence withTodo month,basicWeek,agendaDay withListView'
        },
        lang: document.documentElement.lang || 'ja',
        nextDayThreshold: '00:00:00', // 複数日表示の閾値
        schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
        slotLabelFormat: 'HH:mm',
        startParam: 's[start]',
        timeFormat: 'HH:mm',
        titleFormat: {
          month: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.month')),
          week: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.week')),
          day: SS.convertDateTimeFormat(i18next.t('gws/schedule.calendar.titleFormat.day'))
        },
        loading: function (isLoading, view) {
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
            var span = $('<span></span>').addClass(fcClass).append(content);
            element.find('.fc-title').before(span);
          }
          if (event.category) {
            var span = $('<span class="fc-category"></span>').append(event.category);
            element.find('.fc-title').prepend(span);
          }
          if (event.facility) {
            var span = $('<span class="fc-facility"></span>').append(event.facility);
            element.find('.fc-title').append(span);
          }
          if (event.className.includes('fc-event-work')) {
            $(element).find(".fc-date").remove();
            $(element).find(".fc-resizer").remove();
            $(element).removeClass("fc-resizable");
          }
        },
        eventAfterAllRender: function (view) {
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
              $('.fc .fc-event-user-attendance-absence').removeClass("hide")
            }
          }
          Gws_Schedule_Calendar.updateNoPlanVisibility(view.el.closest(".fc"));
          return Gws_Schedule_Calendar.changePrintPreviewPortrait(view);
        }
      };
    };

    Gws_Schedule_Calendar.viewStateQuery = function (view) {
      var attendance, format, todo;
      format = view.el.closest(".fc").hasClass('fc-list-format') ? 'list' : 'default';
      todo = $('.fc .fc-withTodo-button').hasClass("fc-state-active") ? 'active' : 'inactive';
      attendance = $('.fc .fc-withAbsence-button').hasClass("fc-state-active") ? 'active' : 'inactive';
      return "calendar[path]=" + location.pathname + "&calendar[view]=" + view.name + "&calendar[viewFormat]=" + format + "&calendar[viewTodo]=" + todo + "&calendar[viewAttendance]=" + attendance;
    };

    Gws_Schedule_Calendar.tapMenuParams = function (selector, opts) {
      var url;
      url = opts['restUrl'];
      return {
        dayClick: function (date, event, view) {
          var links, now, start, state, todo;
          links = '';
          if (opts['tapMenu']) {
            now = new Date;
            start = (date.format()) + "T" + (now.getHours()) + ":00:00";
            state = ("calendar[date]=" + (date.format()) + "&") + Gws_Schedule_Calendar.viewStateQuery(view);
            links = ejs.render(
              "<a href='<%= url %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
              { url: url, start: start, state: state, text: i18next.t('gws/schedule.links.add_plan') });
            todo = url.replace(/schedule\/.*/, 'schedule/todo/-/readables');
            links += ejs.render(
              "<a href='<%= todo %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
              { todo: todo, start: start, state: state, text: i18next.t('gws/schedule.links.add_todo') });

            if (opts['useWorkload']) {
              workload = url.replace(/schedule\/.*/, 'workload/-/-/-/-/-/works');
              links += ejs.render(
                "<a href='<%= workload %>/new?start=<%= start %>&<%= state %>' class='add-plan'><%= text %></a>",
                { workload: workload, start: start, state: state, text: i18next.t('gws/schedule.links.add_workload') });
            }
          }
          if ($('#calendar-controller').length === 0) {
            if (view.name !== 'month') {
              links += $('<a href="" data-view="month"/>').text(i18next.t("gws/schedule.links.show_month")).prop("outerHTML");
            }
            if (view.name !== 'basicWeek') {
              links += $('<a href="" data-view="basicWeek"/>').text(i18next.t("gws/schedule.links.show_week")).prop("outerHTML");
            }
            if (view.name !== 'agendaDay') {
              links += $('<a href="" data-view="agendaDay"/>').text(i18next.t("gws/schedule.links.show_day")).prop("outerHTML");
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
            return $(".tap-menu").on("mouseleave", function () {
              return $(".tap-menu").remove();
            });
          }
        }
      };
    };

    Gws_Schedule_Calendar.editableParams = function (selector, opts) {
      var url = opts['restUrl'];
      var token = $('meta[name="csrf-token"]').attr('content');
      return {
        editable: true,
        eventClick: function (event, jsEvent, view) {
          if (event.noPopup) {
            return;
          }
          var popup_url = event.restUrl ? event.restUrl : url;
          var state = ("calendar[date]=" + (event.start.format('YYYY-MM-DD')) + "&") + Gws_Schedule_Calendar.viewStateQuery(view);

          jsEvent.preventDefault();
          event.url = popup_url + "/" + event.id + "?" + state;
          location.href = event.url;

          // var target = $(this);
          // var popupContent = ejs.render(
          //  "<div class='fc-popup'><span class='fc-loading'><%= text %></span></div>",
          //  { text: i18next.t('gws/schedule.loading') });
          // Gws_Popup.render(target, popupContent);
          //
          // $.ajax({
          //  url: popup_url + "/" + event.id + "/popup",
          //  success: function (data) {
          //    $('.fc-popup').html(data);
          //    $('.fc-popup').find('a').each(function () {
          //      return $(this).attr('href', $(this).attr('href') + ("?" + state));
          //    });
          //    return Gws_Popup.renderPopup(target);
          //  }
          //});
        },
        eventDrop: function (event, delta, revertFunc, jsEvent, ui, view) {
          var drop_url, end;
          end = null;
          if (event.end) {
            end = event.end.format();
          }
          drop_url = event.restUrl ? event.restUrl : url;
          return $.ajax({
            type: 'PUT',
            url: (drop_url + "/") + event.id + ".json",
            data: {
              item: {
                api: 'drop',
                api_start: event.start.format(),
                api_end: end
              },
              authenticity_token: token
            },
            success: function (data, dataType) {
              var viewId;
              viewId = view.el.closest('.calendar').attr('id');
              return $('.calendar.multiple').not("#" + viewId).fullCalendar('refetchEvents');
            },
            error: function (xhr, status, error) {
              alert(xhr.responseJSON.join("\n"));
              return revertFunc();
            }
          });
        },
        eventResize: function (event, delta, revertFunc, jsEvent, ui, view) {
          return $.ajax({
            type: 'PUT',
            url: (url + "/") + event.id + ".json",
            data: {
              item: {
                api: 'resize',
                api_start: event.start.format(),
                api_end: event.end.format()
              },
              authenticity_token: token
            },
            success: function (data, dataType) {
              var viewId;
              viewId = view.el.closest('.calendar').attr('id');
              return $('.calendar.multiple').not("#" + viewId).fullCalendar('refetchEvents');
            },
            error: function (xhr, status, error) {
              alert(xhr.responseJSON.join("\n"));
              return revertFunc();
            }
          });
        }
      };
    };

    Gws_Schedule_Calendar.changePrintPreviewPortrait = function (view) {
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

    Gws_Schedule_Calendar.overrideAddLink = function (selector) {
      $('.add-plan').on("click", function () {
        var date, href, now, start, state, view;
        now = new Date;
        date = $(selector).fullCalendar('getDate');
        view = $(selector).fullCalendar('getView');
        href = $(this).attr('href').replace(/\?.*/, '');
        if (!(view.start.isBefore(now) && view.end.isAfter(now))) {
          start = (date.format('YYYY-MM-DD')) + "T" + (now.getHours()) + ":00:00";
          state = ("calendar[date]=" + (date.format()) + "&") + Gws_Schedule_Calendar.viewStateQuery(view);
          href = href + ("?start=" + start + "&" + state);
        } else {
          href = href + "?" + Gws_Schedule_Calendar.viewStateQuery(view);
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

    return Gws_Schedule_Calendar;

  })($jQuery1);
});
