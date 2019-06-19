this.Cms_EditLock = (function () {
  var bind = function (fn, me) {
    return function () {
      return fn.apply(me, arguments);
    };
  };

  function Cms_EditLock(selector, lock_url, unlock_url) {
    this.releaseLockOnCancel = bind(this.releaseLockOnCancel, this);
    this.releaseLock = bind(this.releaseLock, this);
    this.refreshLock = bind(this.refreshLock, this);
    //must return void
    this.selector = selector;
    this.lock_url = lock_url;
    this.unlock_url = unlock_url;
    this.unloading = false;
    this.interval = 2 * 60 * 1000;
    if ($.support.opacity) {
      //above IE9
      $(window).bind('beforeunload', this.releaseLock);
    } else {
      //below IE8
      $('button[type="reset"]').bind('click', this.releaseLockOnCancel);
      $('a.back-to-index').bind('click', this.releaseLockOnCancel);
      $('a.back-to-show').bind('click', this.releaseLockOnCancel);
    }
    this.refreshLock();
  }

  Cms_EditLock.prototype.updateView = function (lock_until) {
    $(this.selector + " .lock_until").text('');
    if (!lock_until) {
      return;
    }
    return $(this.selector + " .lock_until").text(lock_until);
  };

  Cms_EditLock.prototype.refreshLock = function () {
    if (this.unloading) {
      return;
    }
    $.ajax({
      type: "GET",
      url: this.lock_url,
      dataType: "json",
      cache: false,
      statusCode: {
        200: (function (_this) {
          return function (data, status, xhr) {
            if (data.lock_until_pretty) {
              return _this.updateView(data.lock_until_pretty);
            } else {
              return _this.updateView(null);
            }
          };
        })(this)
      }
    });
    return setTimeout(this.refreshLock, this.interval);
  };

  Cms_EditLock.prototype.releaseLock = function () {
    this.unloading = true;
    $.ajax({
      type: "POST",
      url: this.unlock_url,
      dataType: "json",
      data: {
        _method: "delete"
      },
      timeout: 5000
    });
  };

  Cms_EditLock.prototype.releaseLockOnCancel = function () {
    this.releaseLock();
    return true;
  };

  return Cms_EditLock;

})();

