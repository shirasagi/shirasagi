//= require gws/schedule/lib/save_jquery3_and_load_jquery1
//= require fullcalendar
//= require fullcalendar/gcal
//= require fullcalendar/lang/ja
//= require fullcalendar-scheduler/scheduler.min.js
//= require gws/schedule/lib/restore_jquery3
//= require gws/schedule/lib/calendar
//= require gws/schedule/lib/calendar_basic_hour_view
//= require gws/schedule/lib/calendar_list_month_view
//= require gws/schedule/lib/calendar_day_view
//= require gws/schedule/lib/calendar_list_view_format
//= require gws/schedule/lib/calendar_transition
//= require gws/schedule/lib/multiple_calendar
//= require gws/schedule/lib/view
//= require gws/notice/lib/calendar

SS.ready(function() {
  setTimeout(function() {
    $(document).trigger("gws:calendarInitialized");
  }, 0)
});
