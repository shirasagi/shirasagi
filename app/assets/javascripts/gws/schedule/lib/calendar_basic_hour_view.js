/**
 * BasicHour View
 */
var FC = $.fullCalendar;
var View = FC.View;

BasicHourView = FC.views.basicHour = FC.BasicView.extend({

  renderEvents: function(events) {
    this.dayGrid.renderEvents(events);

    head  = '<tr><td class="fc-head-container fc-widget-header">'
    head += '<div class="fc-row fc-widget-header">'
    head += '<table><thead><tr>'
    for (i in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]) {
      head += '<th class="fc-day-header fc-widget-header fc-hour-' + i + '">' + i + '</th>'
    }
    head += '</tr></thead></table>'
    head += '</div>'
    head += '</td></tr>'

    this.el.find('.fc-head').html(head)
  },
});

BasicHourView.eventRender = function(event, element, view) {
  var left = BasicHourView.eventLeftPosition(event, view);
  var right = BasicHourView.eventRightPosition(event, view);
  var width = right - left;
  if (width < 1) width = 1;

  element.find('.fc-time').remove()
  element.css({
    'position': 'absolute',
    'top': '2px',
    'width': (width.toString() + '%'),
    'margin-left': left + '%',
  });
}

BasicHourView.eventLeftPosition = function(event, view) {
  nums = BasicHourView.datesToNum(event.start, view.start);
  if (nums[0] < nums[1]) return 0;

  var date = new Date(event.start._i);
  return (date.getHours() * 60 + date.getMinutes()) * 0.0694;
}

BasicHourView.eventRightPosition = function(event, view) {
  if (!event.end) return 1; // start == end

  nums = BasicHourView.datesToNum(event.end, view.end);
  if (nums[0] == nums[1]) return 99.5;

  var date = new Date(event.end._i);
  return (date.getHours() * 60 + date.getMinutes()) * 0.0694;
}

BasicHourView.datesToNum = function(date1, date2) {
  num1 = date1.year() * 10000 + (date1.month() + 1) * 100 + date1.date();
  num2 = date2.year() * 10000 + (date2.month() + 1) * 100 + date2.date();
  return [num1, num2];
}
