import './lib/jquery';
import 'jquery-migrate';
import 'jquery-ujs';
import 'jquery-ui';
import Cookies from 'js-cookie';
import 'jquery-form';
import 'jquery-datetimepicker/build/jquery.datetimepicker.full.js';
import 'multiselect';
import '@claviska/jquery-minicolors/jquery.minicolors.js';
import 'mdn-polyfills/Array.from.js';
import 'mdn-polyfills/Array.prototype.find.js';
import 'mdn-polyfills/Array.prototype.findIndex.js';
import 'mdn-polyfills/Array.prototype.forEach.js';
import 'mdn-polyfills/Array.prototype.includes.js';
import 'mdn-polyfills/Number.isInteger.js';
import 'mdn-polyfills/Number.isNaN.js';
import 'mdn-polyfills/Object.assign.js';
import 'mdn-polyfills/String.prototype.endsWith.js';
import 'mdn-polyfills/String.prototype.includes.js';
import 'mdn-polyfills/String.prototype.padEnd.js';
import 'mdn-polyfills/String.prototype.padStart.js';
import 'mdn-polyfills/String.prototype.repeat.js';
import 'mdn-polyfills/String.prototype.startsWith.js';
import 'mdn-polyfills/String.prototype.trim.js';
import 'crypto-js/crypto-js.js';
import './lib/base';
import './chart';
import './lib/form';
import './lib/font';
import './lib/module';
import './lib/login';
import './lib/addon_tabs';
import './lib/addon/markdown';
import './lib/addon/temp_file';
import './lib/edit_lock';
import './lib/image_editor';
import './lib/list_ui';
import './lib/tree_ui';
import './lib/tree_navi';
import './lib/mobile';
import './lib/search_ui';
import './lib/popup';
import './lib/dropdown';
import './lib/dropdown_toggle';
import './lib/clipboard';
import './lib/workflow';
import './lib/sortable_form';
import './lib/start_end_synchronizer';
import './lib/text_zoom';
import './lib/popup_notice';
import './lib/cascade_menu';
import './lib/html_message';
import './lib/file_view';
import './lib/validation';
import './lib/ajax_file';
import './lib/replace_file';
import './lib/button_to';
import './lib/open_in_new_window';
import './lib/emoji';
import './lib/date_time_picker';
import './lib/pdfjs';
import '../chat/lib/chart';
import '../cms/lib/base';
import '../cms/lib/editor';
import '../cms/lib/loop_snippet';
import '../cms/lib/form';
import '../cms/lib/form_alert';
import '../cms/lib/form_preview';
import '../cms/lib/inplace_form';
import '../cms/lib/syntax_checker';
import '../cms/lib/form_checker';
import '../cms/lib/mobile_size_checker';
import '../cms/lib/link_checker';
import '../cms/lib/backlink_checker';
import '../cms/lib/source_cleaner';
import '../cms/lib/template_form';
import '../cms/lib/column_file_upload';
import '../cms/lib/column_multiple_files_upload';
import '../cms/lib/column_free';
import '../cms/lib/column_list';
import '../cms/lib/column_table';
import '../cms/lib/column_radio_button';
import '../cms/lib/column_select';
import '../cms/lib/column_select_page';
import '../cms/lib/file_highlighter';
import '../cms/lib/move';
import '../cms/lib/line';
import '../cms/lib/upload_file_order';
import '../cms/lib/image_map';
import '../event/lib/form';
import '../guide/lib/diagnostic';
import '../map/googlemaps/map';
import '../map/googlemaps/form';
import '../map/googlemaps/facility/search';
import '../map/googlemaps/member/photo/form';
import '../map/openlayers/map';
import '../map/openlayers/form';
import '../map/openlayers/facility/search';
import '../map/openlayers/member/photo/form';
import '../map/lgwan/form';
import '../map/reference';
import '../webmail/lib/mail';
import '../webmail/lib/address';
import 'cropperjs/dist/cropper.js';
import '../service/lib/quota.js';
import 'flexibility/flexibility.js';
import '../cms/lib/readable_setting';
import '../cms/lib/michecker';
import '../cms/lib/condition_forms';
import './lib/usage';
import 'datatables.net/js/dataTables.js';

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
  // if ($(window).width() >= 800 && 0) {
  //   var menu = $("#head .pulldown-menu");
  //   var link = menu.find("a");
  //   menu.each(function () {
  //     link.not(".current").hide();
  //     return link.filter(".current").prependTo(menu).on("click", function () {
  //       link.not(".current").slideToggle("fast");
  //       return false;
  //     });
  //   });
  // }
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
    toggle.attr("aria-label", i18next.t("ss.links.navi_close"));

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
    toggle.attr("aria-label", i18next.t("ss.links.navi_open"));

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
  $('.sp-menu-button a').on("click", function (_ev) {
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
  SS_TextZoom.render();
  SS_PopupNotice.render();
  SS_CascadeMenu.render();
  SS_ButtonTo.render();
  SS.enableDoubleClickGuard();
  SS_OpenInNewWindow.render();
  SS_Emoji.render();
  Cms.render();
});
