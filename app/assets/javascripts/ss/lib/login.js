this.SS_Login = (function () {
  function SS_Login() {
  }

  var DEFAULT_INTERVAL_TIME = 60; // 1 minute
  var MAX_INTERVAL_TIME = 1800; // 30 minutes = 30 * 60 = 1800 secs

  SS_Login.intervalTime = null;
  SS_Login.loginPath = null;

  function normalizeInterval(interval) {
    if (!interval || !Number.isInteger(interval)) {
      return DEFAULT_INTERVAL_TIME;
    }
    if (interval <= 0) {
      return DEFAULT_INTERVAL_TIME;
    }
    if (interval > MAX_INTERVAL_TIME) {
      return MAX_INTERVAL_TIME;
    }
    return interval;
  }

  // to protect from vulnerabilities like XSS, test logout path.
  function isValidLoginPath(loginPath) {
    if (loginPath === "/.mypage/login" || loginPath === "/.webmail/login") {
      return true;
    }
    if (/^\/\.s\d+\/login$/.test(loginPath)) {
      return true;
    }
    if (/^\/\.g\d+\/login$/.test(loginPath)) {
      return true;
    }

    return false;
  }

  SS_Login.render = function () {
    $(document).on('ajaxComplete', function (e, xhr, status) {
      if (xhr.getResponseHeader('ajaxRedirect')) {
        if (xhr.readyState === 4 && xhr.status === 200) {
          location.reload();
        }
      }
    });
    var intervalTime = normalizeInterval(SS_Login.intervalTime);
    setTimeout(this.loggedinCheck, intervalTime * 1000);
  };

  SS_Login.loggedinCheck = function () {
    $.ajax({
      url: '/.mypage/status',
      complete: function (xhr, status) {
        var retryAfter = xhr.getResponseHeader("Retry-After");

        var intervalTime;
        if (retryAfter) {
          intervalTime = normalizeInterval(parseInt(retryAfter));
        }
        if (!intervalTime || intervalTime <= 0) {
          intervalTime = DEFAULT_INTERVAL_TIME;
        }

        if (xhr.readyState !== 4) {
          document.body.setAttribute("data-ss-session", "unknown");
          $(document).trigger("ss:sessionUnknown");
          setTimeout(SS_Login.loggedinCheck, intervalTime * 1000);
          return;
        }
        if (xhr.status === 200) {
          // session is not expired
          document.body.setAttribute("data-ss-session", "alive");
          $(document).trigger("ss:sessionAlive");
          setTimeout(SS_Login.loggedinCheck, intervalTime * 1000);
          return;
        }
        if (xhr.status === 403) {
          // session is expired
          document.body.setAttribute("data-ss-session", "expired");
          $(document).trigger("ss:sessionExpired");
          alert(i18next.t("ss.warning.session_timeout"));

          if (SS_Login.loginPath && isValidLoginPath(SS_Login.loginPath)) {
            var params = new URLSearchParams();
            params.append("ref", location.href);
            location.href = SS_Login.loginPath + "?" + params.toString();
          }
        }
      }
    });
  };

  return SS_Login;
})();
