this.SS_Clipboard = (function () {
  function SS_Clipboard() {
  }

  SS_Clipboard.successAlertMessage = 'コピーしました。';

  SS_Clipboard.failedAlertMessage = 'コピーできませんでした。クリップボードがサポートされていません。';

  SS_Clipboard.copyButtonLabel = 'コピー';

  SS_Clipboard.copy = function (text, opts) {
    var copy, e, message, style, $body;

    if (opts == null) {
      opts = {};
    }
    if (document.queryCommandSupported('copy')) {
      try {
        style = 'position: absolute; overflow: hidden; width: 0; height: 0;';
        style += 'border: none; box-shadow: none; background: transparent; resize: none;';
        copy = $("<textarea style='" + style + "'>" + text + "</textarea>");
        $body = ($("#ajax-box").length > 0) ? $("#ajax-box") : $('body');
        $body.after(copy);
        copy.select();
        document.execCommand('copy');
        copy.remove();
        if (opts["success_alert"]) {
          message = SS_Clipboard.successAlertMessage;
          if ("i18next" in window) {
            message = i18next.t("ss.notice.clipboard_copied");
          }
          alert(message);
        }
        return true;
      } catch (_error) {
        e = _error;
        console.warn(e);
        message = SS_Clipboard.failedAlertMessage;
        if ("i18next" in window) {
          message = i18next.t("ss.notice.clipboard_copy_failed");
        }
        alert(message);
        return false;
      }
    }
  };

  SS_Clipboard.renderCopy = function () {
    $('.js-clipboard-copy').each(function () {
      var label, text;
      text = $(this).text();
      if (!text) {
        return true;
      }
      label = SS_Clipboard.copyButtonLabel;
      if ("i18next" in window) {
        label = i18next.t("ss.buttons.copy");
      }
      return $(this).append("<a href='#' class='clipboard-copy-button' data-text='" + text + "'>" + label + "</a>");
    });
    return $('.clipboard-copy-button').on("click", function () {
      $('.clipboard-copy-button').removeClass('copied');
      if (SS_Clipboard.copy($(this).data('text'))) {
        $(this).addClass('copied');
      }
      return false;
    });
  };

  return SS_Clipboard;

})();

