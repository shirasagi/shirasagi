this.SS_Login = (function () {
  function SS_Login() {
  }

  SS_Login.defaultIntervalTime = 600;
  SS_Login.intervalTime = null;

  SS_Login.render = function () {
    $(document).on('ajaxComplete', function (e, xhr, status) {
      if (xhr.getResponseHeader('ajaxRedirect')) {
        if (xhr.readyState === 4 && xhr.status === 200) {
          location.reload();
        }
      }
    });
    var intervalTime = SS_Login.intervalTime || SS_Login.defaultIntervalTime;
    setTimeout(this.loggedinCheck, intervalTime * 1000);
  };

  SS_Login.loggedinCheck = function () {
    $.ajax({
      url: '/.mypage/status',
      complete: function (xhr, status) {
        var retryAfter = xhr.getResponseHeader("Retry-After");

        var intervalTime;
        if (retryAfter) {
          intervalTime = parseInt(retryAfter);
        }
        if (!intervalTime || intervalTime <= 0) {
          intervalTime = SS_Login.intervalTime || SS_Login.defaultIntervalTime;
        }

        if (xhr.readyState !== 4) {
          setTimeout(SS_Login.loggedinCheck, intervalTime * 1000);
          return;
        }
        if (xhr.status === 200) {
          // session is not expired
          document.body.setAttribute("data-ss-session", "alive");
          //$(document).trigger("ss:sessionAlive");
          setTimeout(SS_Login.loggedinCheck, intervalTime * 1000);
        }
        if (xhr.status === 403) {
          // session is expired
          document.body.setAttribute("data-ss-session", "expired");
          $(document).trigger("ss:sessionExpired");
          alert(i18next.t("ss.warning.session_timeout"));
        }
      }
    });
  };

  return SS_Login;
})();
