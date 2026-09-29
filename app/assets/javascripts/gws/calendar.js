import '@fullcalendar/core';
import '@fullcalendar/interaction';
import '@fullcalendar/daygrid';
import '@fullcalendar/timegrid';
import '@fullcalendar/list';
import './schedule/lib/calendar';
import './schedule/lib/calendar_transition';
import './schedule/lib/multiple_calendar';
import './schedule/lib/view';
import './notice/lib/calendar';

SS.ready(function() {
  setTimeout(function() {
    document.dispatchEvent(new Event('gws:calendarInitialized'));
  }, 0)
});
