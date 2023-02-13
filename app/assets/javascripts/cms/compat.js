// CMS 公開画面では application.js に変えて compat.js が読み込まれる。
//= require promise-polyfill/dist/polyfill.js
//= require moment/moment.js
//= require_self

(function () {
  var setReady = function() {
    if ("jQuery" in window) {
      if (jQuery.isReady) {
        SS.doneReady();
        return;
      }

      jQuery(function() {
        SS.doneReady();
      });
    }

    setTimeout(setReady, 11);
  }

  setTimeout(setReady, 11);
})();
