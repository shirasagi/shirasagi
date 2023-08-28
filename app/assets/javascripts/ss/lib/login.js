this.SS_Login = (function () {
  function SS_Login() {
  }

  SS_Login.intervalID = null;

  SS_Login.intervalTime = 600000;

  SS_Login.render = function () {
    $(document).on('ajaxComplete', function (e, xhr, status) {
      if (xhr.getResponseHeader('ajaxRedirect')) {
        if (xhr.readyState === 4 && xhr.status === 200) {
          return location.reload();
        }
      }
    });
    return setTimeout(this.startLoggedinCheck, this.intervalTime);
  };

  SS_Login.startLoggedinCheck = function () {
    return $.ajax({
      url: '/.mypage/status',
      complete: function (xhr, status) {
        if (xhr.readyState === 4 && xhr.status === 200) {
          return SS_Login.intervalID = setInterval(SS_Login.keepLoggedinCheck, SS_Login.intervalTime);
        }
      }
    });
  };

  SS_Login.keepLoggedinCheck = function () {
    return $.ajax({
      url: '/.mypage/status',
      complete: function (xhr, status) {
        if (xhr.readyState === 4 && xhr.status === 403) {
          if (SS_Login.intervalID) {
            clearInterval(SS_Login.intervalID);
          }
          return alert(i18next.t("ss.warning.session_timeout"));
        }
      }
    });
  };

  return SS_Login;

})();

