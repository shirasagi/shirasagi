this.SS_EditLock = (function () {
  var bind = function (fn, me) {
    return function () {
      return fn.apply(me, arguments);
    };
  };

  function SS_EditLock(selector, lock_url, unlock_url) {
    this.releaseLockOnCancel = bind(this.releaseLockOnCancel, this);
    this.releaseLock = bind(this.releaseLock, this);
    this.refreshLock = bind(this.refreshLock, this);
    //must return void
    this.selector = selector;
    this.lock_url = lock_url;
    this.unlock_url = unlock_url;
    this.unloading = false;
    this.interval = 2 * 60 * 1000;
    $(window).bind('beforeunload', this.releaseLock);

    var alreadyLocked = ($(this.selector + " .lock_until").text() !== '');
    if (alreadyLocked) {
      setTimeout(this.refreshLock, this.interval);
    } else {
      this.refreshLock();
    }
  }

  SS_EditLock.prototype.updateView = function (lock_until) {
    $(this.selector + " .lock_until").text('');
    if (!lock_until) {
      return;
    }
    return $(this.selector + " .lock_until").text(lock_until);
  };

  SS_EditLock.prototype.refreshLock = function () {
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
          return function (data, _status, _xhr) {
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

  SS_EditLock.prototype.releaseLock = function () {
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

  SS_EditLock.prototype.releaseLockOnCancel = function () {
    this.releaseLock();
    return true;
  };

  return SS_EditLock;

})();

