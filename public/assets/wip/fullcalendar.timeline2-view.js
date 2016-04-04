/**
 * TimelineAlign View
 */
var FC = $.fullCalendar;
var View = FC.View;

TimelineAlign2View = FC.views.timelineAlign2 = FC.BasicView.extend({
  xinitialize: function() {
  },

  render: function() {
  },

  renderEvents: function(events) {
    head  = '<tr><td class="fc-head-container fc-widget-header">'
    head += '<div class="fc-row fc-widget-header">'
    head += '<table><thead><tr>'
    for (i in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]) {
      head += '<th class="fc-day-header fc-widget-header">' + i + '</th>'
    }
    head += '</tr></thead></table>'
    head += '</div>'
    head += '</td></tr>'

    this.el.find('.fc-head').html(head)
    this.dayGrid.renderEvents(events);
  },
});

TimelineAlign2View.eventRender = function(event, element, view) {
  start = new Date(event.start._i);
  startMin = start.getHours() * 60 + start.getMinutes();
  left = 0.0694 * startMin;

  if (event.end) {
    end = new Date(event.end._i);
    endMin = end.getHours() * 60 + end.getMinutes();
    right = 0.0694 * endMin;
  } else {
    right = left + 1;
  }
  width = right - left;

  element.find('.fc-time').remove()
  element.css({
    'position': 'absolute',
    'width': (width.toString() + '%'),
    'margin-left': left + '%',
  });
}
