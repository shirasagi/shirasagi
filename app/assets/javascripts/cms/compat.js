// CMS 公開画面では application.js に変えて compat.js が読み込まれる。
import 'moment/moment.js';

(function () {
  var isDocumentReady = function() {
    return document.readyState === "interactive" || document.readyState === "complete"
  };

  var isJQueryReady = function () {
    return ("jQuery" in window) && jQuery.isReady;
  };

  var setReady = function() {
    if (isDocumentReady() && isJQueryReady()) {
      SS.doneReady();
      return;
    }

    setTimeout(setReady, 11);
  }

  setTimeout(setReady, 11);
})();
