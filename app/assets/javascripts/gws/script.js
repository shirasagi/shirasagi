//= require sprintf-js/dist/sprintf.min.js
//= require gridster/jquery.gridster.min.js
//= require gws/lib/category
//= require gws/lib/tab
//= require gws/lib/popup
//= require gws/lib/member
//= require gws/lib/reminder
//= require gws/lib/bookmark
//= require gws/lib/readable_setting
//= require gws/lib/contrast
//= require gws/lib/workload
//= require gws/lib/search_form
//= require gws/schedule/lib/plan
//= require gws/schedule/lib/repeat_plan
//= require gws/schedule/lib/integration
//= require gws/schedule/lib/todo_search
//= require gws/schedule/lib/todo_index
//= require gws/schedule/lib/csv
//= require gws/schedule/lib/facility_reservation
//= require gws/memo/message
//= require gws/memo/folder
//= require gws/memo/filter
//= require gws/monitor/lib/monitor
//= require gws/portal/lib/portal
//= require gws/elasticsearch/highlighter
//= require gws/discussion/thread
//= require gws/discussion/lib/unseen
//= require gws/attendance/attendance
//= require gws/attendance/portlet
//= require gws/presence/user
//= require gws/share/folder_toolbar
//= require gws/affair/menu
//= require gws/affair/overtime_file
//= require gws/affair/shift_records

SS.ready(function () {
  // external link
  $('a[href^=http]').not('[href*="' + location.hostname + '"]').attr({ target: '_blank', rel: "noopener" });

  // tabs
  var path = location.pathname + "/";
  $(".gws-schedule-tabs a").each(function () {
    var menu = $(this);
    if (path.match(new RegExp('^' + menu.attr('href') + '(/|$)'))) {
      menu.addClass("current");
    }
  });

  Gws_Member.render();
});
