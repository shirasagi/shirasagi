import 'sprintf-js/dist/sprintf.min.js';
import 'dsmorse-gridster';
import './lib/category';
import './lib/tab';
import './lib/popup';
import './lib/member';
import './lib/reminder';
import './lib/bookmark';
import './lib/readable_setting';
import './lib/workload';
import './lib/search_form';
import './schedule/lib/plan';
import './schedule/lib/repeat_plan';
import './schedule/lib/integration';
import './schedule/lib/todo_search';
import './schedule/lib/todo_index';
import './schedule/lib/csv';
import './schedule/lib/facility_reservation';
import './memo/message';
import './memo/folder';
import './memo/filter';
import './monitor/lib/monitor';
import './portal/lib/portal';
import './elasticsearch/highlighter';
import './discussion/thread';
import './discussion/lib/unseen';
import './attendance/attendance';
import './attendance/portlet';
import './presence/user';
import './share/folder_toolbar';
import './share/file';
import './affair/menu';
import './affair/overtime_file';
import './affair/shift_records';

SS.ready(function () {
  var renderExternalLinks = function($box) {
    // external link
    $box.find('a[href^=http]').not('[href*="' + location.hostname + '"]').attr({ target: '_blank', rel: "noopener" });
  }
  renderExternalLinks($(document));
  $(document).on("cbox_complete", function() {
    renderExternalLinks($("#cboxLoadedContent"))
  }).on("ss:dialog:opened", function(ev) {
    renderExternalLinks($(ev.target))
  });

  // tabs
  var path = location.pathname + "/";
  $(".gws-schedule-tabs a").each(function () {
    var menu = $(this);
    if (path.match(new RegExp('^' + menu.attr('href') + '(/|$)'))) {
      menu.addClass("current");
    }
  });

  Gws_Member.render();

  // user detail
  $(".user-detail").colorbox({
    maxWidth: "80%",
    maxHeight: "80%",
    fixed: true
  });
});
