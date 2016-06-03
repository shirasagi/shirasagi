/**
 * ListMonth View
 */
var FC = $.fullCalendar;
var View = FC.View;

var ListMonthView = FC.ListMonthView = FC.BasicView.extend({
  renderEvents: function(events) {
    //this.dayGrid.renderEvents([]);
    var calendar = this.calendar;

    var view  = $('<div class="fc-listMonth-view-container"></div>').appendTo('.fc-listMonth-view');
    var table = $('<div class="fc-listMonth-view-table"></div>')

    for (var i in events) {
      var event = events[i];
      if (event.className.indexOf('fc-holiday') != -1) continue;

      var evEl = $('<a class="fc-event fc-event-point"></a>').text(event.title);
      evEl.css({ 'color': event.textColor, 'background-color': event.backgroundColor });
      //evEl.addClass(event.className.join(' '));

      evEl.bind('click', function(ev) {
        var eventNo = $(this).data('eventNo');
        return calendar.view.trigger('eventClick', $(this), events[eventNo], ev);
      }).data('eventNo', i);

      var info = $('<div class="td info"></div>').append(evEl);
      var date = $('<div class="td date"></div>').text(event.startDateLabel);
      var time = $('<div class="td time"></div>').text(event.startTimeLabel);
      if (event.allDay) time.text(event.allDayLabel);

      $('<div class="tr"></div>').appendTo(table).append(date).append(time).append(info);
      table.appendTo(view);
    }

    if ($('.fc-event').length == 0) {
      var noPlan = $('<div class="td">' + Gws_Schedule_Calendar.messages.noPlan + '</div>')
      $('<div class="tr"></div>').appendTo(table).append(noPlan);
      table.appendTo(view);
    }
  },
});

FC.views.listMonth = {
  'class': ListMonthView,
  duration: { months: 1 },
  defaults: {
    fixedWeekCount: false
  }
};
