$(function() {
  $(".lang_opt").hide();

  $(".langswitch").hover(function() {
    $(".lang_opt").toggle();
    $("span#lang_arrow").toggleClass("rotate");
  });

  //2020.2.6 初回訪問時のみ、ブラウザ言語によりサイト表示を変更
  var jumpPage = function(lang) {
    var url = location.href;
    var path = location.pathname;

    if (lang === "en") {
      var prefix = "";
      var prefixCnt = 0;

var $dir = $("link[type='text/css']")[0];
$dir = $($dir).attr("href").split("/");

      for (var i = 0; $dir[i].indexOf("common") == -1; i++) {
        prefix += "../";
        prefixCnt++;
      }
      var enDir = "";
      var patharr = path.split("/");
      if (patharr.length > 1 && prefixCnt > 0) {
        for (var i = prefixCnt; i > 0; i--) {
          enDir += patharr[patharr.length - i - 1] + "/";
        }
      }
      var enUrl =
        location.protocol +
        "//" +
        location.host +
        path.substring(0, path.lastIndexOf("/")) +
        "/" +
        prefix +
        "en/" +
        enDir +
        patharr[patharr.length - 1];
      if (existEnPage(enDir + patharr[patharr.length - 1])) {
        //英語サイトに飛ばす時はページが存在する場合に該当ページへ移動する
        location.href = enUrl;
      } else {
        if (url.indexOf("/ir/") != -1) {
          location.href =
            enUrl.substring(0, enUrl.lastIndexOf("/en/")) + "/en/ir/";
        } else {
          location.href =
            enUrl.substring(0, enUrl.lastIndexOf("/en/")) + "/en/";
        }
      }
    } else {
      //日本語ページを表示
      location.href =
        location.protocol + "//" + location.host + path.replace("en/", "");
    }
  };

  //英語ページの一覧(カンマ区切りで入力してください)
  var enPageStr =
    "/,/index.html,/care/,/care/houkatsu.html,/care/kyotaku.html,/care/houmon.html,/care/tsusho.html,/care/shisetsu.html,/care/yougu.html,/care/chiikimitchaku.html,/care/shogai.html,/medical/index.html,/medical/,/medical/index.html,/child-care/index.html,/company/,/company/index.html,/company/concept.html,/company/message.html,/company/outline.html,/company/officer/,/company/officer.html,/company/officer/bio_01.html,/company/officer/bio_02.html,/company/officer/bio_03.html,/company/officer/bio_04.html,/company/officer/bio_05.html,/company/officer/bio_07.html,/company/officer/bio_08.html,/company/officer/bio_10.html,/company/officer/bio_11.html,/company/officer/bio_13.html,/company/officer/bio_15.html,/company/officer/bio_16.html,/company/officer/bio_17.html,/company/officer/bio_18.html,/company/access.html,/company/group.html,/ir/,/ir/index.html,/ir/management.html,/ir/governance.html,/ir/esg.html,/ir/environment.html,/ir/social.html,/ir/stock.html,/ir/quote.html,/ir/calendar.html,/ir/faq.html,/ir/irpolicy.html,/ir/disclimer.html,/sitemap/,/sitemap/index.html,";
  //    "/,/index.html,/care/,/care/houkatsu.html,/care/kyotaku.html,/care/houmon.html,/care/tsusho.html,/care/shisetsu.html,/care/yougu.html,/care/chiikimitchaku.html,/care/shogai.html,/medical/index.html,/medical/,/medical/index.html,/child-care/index.html,/company/,/company/index.html,/company/concept.html,/company/message.html,/company/outline.html,/company/officer.html,/company/access.html,/ir/,/ir/index.html,/ir/management.html,/ir/library.html,/ir/stock.html,/ir/calendar.html,/ir/faq.html,/ir/notice.html,/ir/irpolicy.html,/ir/disclimer.html,/sitemap/,/sitemap/index.html,";
  var existEnPage = function(path) {
    var regexp = new RegExp(path + "(,|$|index.html,)", "g");
    return enPageStr.match(regexp);
  };

//   if (!document.cookie.match(/firstvisit=1/)) {
//     //cookieセット
//     var day30 = 86400 * 30; /* 削除時間を１ヶ月の秒数にする */
//     document.cookie = "firstvisit=1; path=/; max-age=" + day30;

// //    if (document.cookie.match(/firstvisit=1;/)) {
//       //cookieが有効な場合のみ判定できます
//       // ブラウザの言語設定取得
//       var browserLang =
//         (window.navigator.languages && window.navigator.languages[0]) ||
//         window.navigator.language ||
//         window.navigator.userLanguage ||
//         window.navigator.browserLanguage;

//       if (browserLang.match(/^en.*/)) {
//         if (!location.href.match(/.*\/en\/.*/)) {
//           //英語設定で日本語サイトを見ている時は英語サイトにリダイレクト
//           jumpPage("en");
//         }
//       } else {
//         if (location.href.match(/.*\/en\/.*/)) {
//           //英語以外の設定で英語のサイトを見ている時は日本語サイトにリダイレクト
//           jumpPage("ja");
//         }
//       }
// //    }
//   } else {
//     //cookieセット
//     var day30 = 86400 * 30; /* 削除時間を１ヶ月の秒数にする */
//     document.cookie = "firstvisit=1; path=/; max-age=" + day30;
//   }
  
  $(".langswitchJa").on("click", function() {
    jumpPage("ja");
    return false;
  });
  $(".langswitchEn").on("click", function() {
    jumpPage("en");
    return false;
  });
  /* 言語切り替えエンド */
});
