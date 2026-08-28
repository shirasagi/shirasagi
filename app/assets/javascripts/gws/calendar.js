//= require @fullcalendar/core/index.global.min.js
//= require @fullcalendar/interaction/index.global.min.js
//= require @fullcalendar/daygrid/index.global.min.js
//= require @fullcalendar/timegrid/index.global.min.js
//= require @fullcalendar/list/index.global.min.js
//= require gws/schedule/lib/calendar
//= require gws/schedule/lib/calendar_transition
//= require gws/schedule/lib/multiple_calendar
//= require gws/schedule/lib/view
//= require gws/notice/lib/calendar

SS.ready(function() {
  setTimeout(function() {
    // $(document).trigger("gws:calendarInitialized");
    document.dispatchEvent(new Event('gws:calendarInitialized'));
  }, 0)
});
