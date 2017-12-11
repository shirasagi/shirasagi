/**
 * ListMonth View
 */
(function() {
  var FC = $.fullCalendar;
  var View = FC.View;
  var installedWithTodoClick = false;

  var firstOrCreateView = function() {
    var view = $('.fc-listMonth-view .fc-listMonth-view-container')[0];
    if (view) {
      return $(view);
    }

    view = $('<div class="fc-listMonth-view-container"></div>').appendTo('.fc-listMonth-view');
    return view;
  };

  var clearView = function(view) {
    view.html('');
    return view;
  };

  var updateNoPlanVisibility = function() {
    var noPlan = $('.fc-listMonth-view .no-plan');
    if ($('.fc-event:visible').length == 0) {
      noPlan.show();
    } else {
      noPlan.hide();
    }
  };

  var ListMonthView = FC.ListMonthView = FC.BasicView.extend({
    renderEvents: function(events) {
      //this.dayGrid.renderEvents([]);
      var calendar = this.calendar;

      var view  = clearView(firstOrCreateView());
      var table = $('<div class="fc-listMonth-view-table"></div>');
      var eventCount = 0;

      var noPlan = $('<div class="td no-plan" style="display: none;">' + Gws_Schedule_Calendar.messages.noPlan + '</div>')
      $('<div class="tr"></div>').appendTo(table).append(noPlan);

      for (var i in events) {
        var event = events[i];
        if (event.className.indexOf('fc-holiday') !== -1) continue;

        var evEl = $('<a class="fc-event fc-event-point"></a>').text(event.title);
        evEl.css({ 'color': event.textColor, 'background-color': event.backgroundColor });
        //evEl.addClass(event.className.join(' '));

        evEl.bind('click', function(ev) {
          var eventNo = $(this).data('eventNo');
          return calendar.view.trigger('eventClick', $(this), events[eventNo], ev);
        }).data('eventNo', i);

        var info = $('<div class="td info"></div>').append(evEl);
        if (event.sanitizedHtml) {
          info.append('<p>' + event.sanitizedHtml + '</p>');
        }
        var date = $('<div class="td date"></div>').text(event.startDateLabel);
        var time = $('<div class="td time"></div>').text(event.startTimeLabel);
        if (event.allDay) time.text(event.allDayLabel);
        eventCount++;

        var tr = $('<div class="tr"></div>').appendTo(table).append(date).append(time).append(info);
        if (event.className.indexOf('fc-event-todo') !== -1) {
          tr.addClass('fc-event-todo');
        }
        if (event.className.indexOf('fc-event-user-attendance-absence') !== -1) {
          tr.addClass('fc-event-user-attendance-absence');
          tr.css('display', 'none');
        }
      }
      table.appendTo(view);
      updateNoPlanVisibility();

      if (! installedWithTodoClick) {
        installedWithTodoClick = true;
        $('.fc-withTodo-button').on('click', function (e) {
          var viewName = $('#calendar').fullCalendar('getView').name;
          if (!viewName) {
            viewName = $('#calendar-controller').fullCalendar('getView').name;
          }

          if (viewName === 'listMonth') {
            setTimeout(updateNoPlanVisibility, 0);
          }
        });
      }
    }
  });

  FC.views.listMonth = {
    'class': ListMonthView,
    duration: { months: 1 },
    defaults: {
      fixedWeekCount: false
    }
  };
})();
