//= require jquery3
//= require jquery-migrate/src/migratemute.js
//= require jquery-migrate/dist/jquery-migrate.js
//= require jquery_ujs
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/draggable
//= require jquery-ui/widgets/droppable
//= require jquery-ui/widgets/autocomplete
//= require jquery-ui/widgets/tooltip
//= require js.cookie
//= require jquery.form
//= require jquery-datetimepicker/build/jquery.datetimepicker.full.js
//= require jquery.multi-select
//= require jquery.minicolors
//= require jquery.autosize
//= require marked
//= require mdn-polyfills/Array.from.js
//= require mdn-polyfills/Array.prototype.find.js
//= require mdn-polyfills/Array.prototype.findIndex.js
//= require mdn-polyfills/Array.prototype.forEach.js
//= require mdn-polyfills/Array.prototype.includes.js
//= require mdn-polyfills/Number.isInteger.js
//= require mdn-polyfills/Number.isNaN.js
//= require mdn-polyfills/Object.assign.js
//= require mdn-polyfills/String.prototype.endsWith.js
//= require mdn-polyfills/String.prototype.includes.js
//= require mdn-polyfills/String.prototype.padEnd.js
//= require mdn-polyfills/String.prototype.padStart.js
//= require mdn-polyfills/String.prototype.repeat.js
//= require mdn-polyfills/String.prototype.startsWith.js
//= require mdn-polyfills/String.prototype.trim.js
//= require popper.js/dist/umd/popper.js
//= require tippy.js/dist/tippy-bundle.iife.js
//= require crypto-js/crypto-js.js
//= require ejs/ejs.min.js
//= require ss/lib/base
//= require_self
//= require ss/chart
//= require ss/lib/form
//= require ss/lib/font
//= require ss/lib/module
//= require ss/lib/login
//= require ss/lib/addon_tabs
//= require ss/lib/addon/markdown
//= require ss/lib/addon/temp_file
//= require ss/lib/edit_lock
//= require ss/lib/image_editor
//= require ss/lib/list_ui
//= require ss/lib/tree_ui
//= require ss/lib/tree_navi
//= require ss/lib/mobile
//= require ss/lib/search_ui
//= require ss/lib/popup
//= require ss/lib/dropdown
//= require ss/lib/dropdown_toggle
//= require ss/lib/clipboard
//= require ss/lib/color
//= require ss/lib/workflow
//= require ss/lib/sortable_form
//= require ss/lib/start_end_synchronizer
//= require ss/lib/text_zoom
//= require ss/lib/popup_notice
//= require ss/lib/cascade_menu
//= require ss/lib/html_message
//= require ss/lib/file_view
//= require ss/lib/validation
//= require ss/lib/ajax_file
//= require ss/lib/replace_file
//= require ss/lib/button_to
//= require ss/lib/open_in_new_window
//= require ss/lib/emoji
//= require ss/lib/role
//= require ss/lib/date_time_picker
//= require ss/lib/pdfjs
//= require chat/lib/chart
//= require cms/lib/base
//= require cms/lib/editor
//= require cms/lib/form
//= require cms/lib/source_cleaner
//= require cms/lib/template_form
//= require cms/lib/column_file_upload
//= require cms/lib/column_free
//= require cms/lib/column_list
//= require cms/lib/column_table
//= require cms/lib/column_radio_button
//= require cms/lib/column_select
//= require cms/lib/column_select_page
//= require cms/lib/file_highlighter
//= require cms/lib/move
//= require cms/lib/line
//= require cms/lib/upload_file_order
//= require cms/lib/image_map
//= require event/lib/form
//= require guide/lib/diagnostic
//= require map/googlemaps/map
//= require map/googlemaps/form
//= require map/googlemaps/facility/search
//= require map/googlemaps/member/photo/form
//= require map/openlayers/map
//= require map/openlayers/form
//= require map/openlayers/facility/search
//= require map/openlayers/member/photo/form
//= require map/lgwan/form
//= require map/reference
//= require webmail/lib/mail
//= require webmail/lib/address
//= require cropperjs/dist/cropper.js
//= require service/lib/quota.js
//= require flexibility/flexibility.js
//= require cms/lib/readable_setting
//= require cms/lib/michecker
//= require cms/lib/condition_forms
//= require ss/lib/usage
//= require cms/preview/jquery-ui
//= require datatables.net/js/jquery.dataTables.js

//#
//  $(".js-date").datetimepicker { lang: "ja", timepicker: false, format: "Y/m/d" }
//#
SS.ready(function () {
  $.ajaxSetup({
    // prevent caching ajax response. see #596.
    cache: false,
    global: true
  });
  // headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
  SS.render();
  // head
  if ($(window).width() >= 800 && 0) {
    var menu = $("#head .pulldown-menu");
    var link = menu.find("a");
    menu.each(function () {
      link.not(".current").hide();
      return link.filter(".current").prependTo(menu).on("click", function () {
        link.not(".current").slideToggle("fast");
        return false;
      });
    });
  }
  // toggle navi
  var toggleNavi = function() {
    return $("#toggle-navi").hasClass("opened") ? closeNavi() : openNavi();
  };
  var openNavi = function() {
    $("#navi").css("margin-left", "-200px");
    $("#navi").show();
    $("#navi").animate({"margin-left":"0px"}, 200, function(){
      $(window).trigger('resize');
    });
    var toggle = $("#toggle-navi");
    toggle.addClass("opened").removeClass("closed");
    toggle.attr("aria-label", i18next.t("ss.navi_close"));

    Cookies.set("ss-navi", "opened", { expires: 7, path: '/' });
    return false;
  };
  var closeNavi = function() {
    $("#navi").animate({"margin-left":"-200px"}, 200, function(){
      $(this).hide();
      $(this).css("margin-left", "0px");
      $(window).trigger('resize');
    });
    var toggle = $("#toggle-navi");
    toggle.addClass("closed").removeClass("opened");
    toggle.attr("aria-label", i18next.t("ss.navi_open"));

    Cookies.set("ss-navi", "closed", { expires: 7, path: '/' });
    return false;
  };
  $("#toggle-navi").on("click", toggleNavi);
  // navi
  var path = location.pathname + "/";
  var longestMatchedElement = function (selector) {
    var matchedElement = null, hrefLength = 0;
    $(selector).each(function() {
      var $this = $(this);
      var href = $this.attr('href');
      if (!href) {
        return true;
      }
      if (path === href || path.startsWith(href + "/")) {
        if (hrefLength < href.length) {
          matchedElement = this;
          hrefLength = href.length;
        }
      }
    });
    return matchedElement;
  };
  var addCurrent = function (selector) {
    var elem = longestMatchedElement(selector);
    if (! elem) {
      return false;
    }

    $(elem).addClass("current").parent().addClass("current");
    return true;
  };
  addCurrent("#navi .mod-navi a") || addCurrent("#navi .main-navi a");
  addCurrent("#main .main-navi a");
  $('#navi .main-navi h3.current').parent().prev('h2').addClass('current');
  // navi
  $('.sp-menu-button a').on("click", function (e) {
    $('#navi').slideToggle();
    $(this).toggleClass("active");
    return false;
  });
  SS_DropdownToggle.render();
  $("select").on("change", function () {
    if ($(this).val() === "") {
      return $(this).addClass("blank-value has-blank-value");
    } else {
      return $(this).removeClass("blank-value");
    }
  });
  $("select").trigger("change");
  SS_ListUI.render();
  SS_Mobile.render();
  SS_AddonTabs.render();
  SS_Form.render();
  SS_Popup.render(".tooltip", { "ss-popup-inline": true, "ss-popup-href": ".tooltip-content", "tippy-theme": "light-border ss-tooltip" });
  SS_SearchUI.render();
  SS_Color.render();
  SS_TextZoom.render();
  SS_PopupNotice.render();
  SS_CascadeMenu.render();
  SS_ButtonTo.render();
  SS.enableDoubleClickGuard();
  SS_OpenInNewWindow.render();
  SS_Emoji.render();
  Cms.render();
});
