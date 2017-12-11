(function() {
  var FC = $.fullCalendar;

  var renderTitle = function(event) {
    if (!event.title) {
      return '';
    }

    var commonPart = '<div class="fc-title">' + FC.htmlEscape('[' + event.title + ']');
    if (event.sanitizedHtml) {
      return commonPart + ' ' + FC.htmlEscape(event.sanitizedHtml) + '</div>';
    } else {
      return commonPart + '</div>';
    }
  };

  var SS_TimeGrid = FC.TimeGrid.extend({
    fgSegHtml: function(seg, disableResizing) {
      var view = this.view;
      var event = seg.event;
      var isDraggable = view.isEventDraggable(event);
      var isResizableFromStart = !disableResizing && seg.isStart && view.isEventResizableFromStart(event);
      var isResizableFromEnd = !disableResizing && seg.isEnd && view.isEventResizableFromEnd(event);
      var classes = this.getSegClasses(seg, isDraggable, isResizableFromStart || isResizableFromEnd);
      var skinCss = FC.cssToStr(this.getSegSkinCss(seg));
      var timeText;
      var fullTimeText; // more verbose time text. for the print stylesheet
      var startTimeText; // just the start time text

      classes.unshift('fc-time-grid-event', 'fc-v-event');

      if (view.isMultiDayEvent(event)) { // if the event appears to span more than one day...
        // Don't display time text on segments that run entirely through a day.
        // That would appear as midnight-midnight and would look dumb.
        // Otherwise, display the time text for the *segment's* times (like 6pm-midnight or midnight-10am)
        if (seg.isStart || seg.isEnd) {
          timeText = this.getEventTimeText(seg);
          fullTimeText = this.getEventTimeText(seg, 'LT');
          startTimeText = this.getEventTimeText(seg, null, false); // displayEnd=false
        }
      } else {
        // Display the normal time text for the *event's* times
        timeText = this.getEventTimeText(event);
        fullTimeText = this.getEventTimeText(event, 'LT');
        startTimeText = this.getEventTimeText(event, null, false); // displayEnd=false
      }

      return '<a class="' + classes.join(' ') + '"' +
        (event.url ?
            ' href="' + FC.htmlEscape(event.url) + '"' :
            ''
        ) +
        (skinCss ?
            ' style="' + skinCss + '"' :
            ''
        ) +
        '>' +
        '<div class="fc-content">' +
        (timeText ?
            '<div class="fc-time"' +
            ' data-start="' + FC.htmlEscape(startTimeText) + '"' +
            ' data-full="' + FC.htmlEscape(fullTimeText) + '"' +
            '>' +
            '<span>' + FC.htmlEscape(timeText) + '</span>' +
            '</div>' :
            ''
        ) +
        renderTitle(event) +
        '</div>' +
        '<div class="fc-bg"/>' +
        /* TODO: write CSS for this
        (isResizableFromStart ?
            '<div class="fc-resizer fc-start-resizer" />' :
            ''
            ) +
        */
        (isResizableFromEnd ?
            '<div class="fc-resizer fc-end-resizer" />' :
            ''
        ) +
        '</a>';
    }
  });

  var SS_AgendaView = FC.AgendaView.extend({
    timeGridClass: SS_TimeGrid
  });

  FC.views.agendaDay = {
    'class': SS_AgendaView,
    defaults: {
      allDaySlot: true,
      allDayText: 'all-day',
      slotDuration: '00:30:00',
      minTime: '00:00:00',
      maxTime: '24:00:00',
      slotEventOverlap: true // a bad name. confused with overlap/constraint system
    },
    duration: { days: 1 }
  };
})();
