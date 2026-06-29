//= require sprintf-js/dist/sprintf.min.js
//= require gridster/jquery.gridster.min.js
//= require gws/lib/category
//= require gws/lib/tab
//= require gws/lib/popup
//= require gws/lib/member
//= require gws/lib/reminder
//= require gws/lib/bookmark
//= require gws/lib/readable_setting
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
//= require gws/share/file
//= require gws/affair/menu
//= require gws/affair/overtime_file
//= require gws/affair/shift_records

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

  // メインナビのヘルプアイコン: クリックでモジュール説明＋マニュアルリンクのポップアップを表示する。
  // リンク集アイコンと同様、開いている状態で同じアイコンを再クリックしたら閉じる（トグル）。
  // （アイコン以外をクリックした場合は Gws_Popup の document ハンドラが閉じる）
  $(document).on("click", ".gws-menu-help__icon", function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    var $icon = $(this);
    // このアイコンで既に開いている場合は閉じる
    if ($icon.hasClass("gws-popup-event") && $(".gws-popup").length) {
      $(".gws-popup").remove();
      $icon.removeClass("gws-popup-event");
      return;
    }
    var content = $icon.closest(".gws-menu-help").find(".gws-menu-help__content").html();
    if (content) {
      Gws_Popup.render($icon, content);
    }
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
