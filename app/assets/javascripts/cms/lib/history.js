this.Cms_History = (function () {
  function Cms_History(selector, listIdentity, opts) {
    if (!opts) {
      opts = {};
    }

    this.selector = selector;
    this.listIdentity = listIdentity;
    this.limit = opts["limit"] ? opts["limit"] : 5;
    this.render();
  }

  Cms_History.prototype.storageKey = function (key) {
    return "ss_cms_history_" + this.listIdentity + "_" + key;
  };

  Cms_History.prototype.render = function () {
    var _this = this;
    var histories = _this.getHistories();
    var current = $(_this.selector).find(".current");

    if (!current.length) {
      return;
    }

    var warp = $(current).parent();
    var html = $(warp).html();
    $(current).remove();

    if (histories.length > 0) {
      $(histories).each(function () {
        $(warp).append(this);
      });
    }

    histories = histories.filter(function (v) { return v != html; });
    histories.unshift(html);
    histories = histories.slice(0, _this.limit);
    _this.setHistories(histories);
  };

  Cms_History.prototype.setHistories = function (histories) {
    var _this = this;

    try {
      localStorage.setItem(_this.storageKey("length"), histories.length);
      $.each(histories, function (i, history) {
        localStorage.setItem(_this.storageKey(i), history);
      });
    } catch (error) {
      console.warn(error);
    }
  };

  Cms_History.prototype.getHistories = function () {
    var _this = this;
    var histories = [];
    var length = 0;

    try {
      length = localStorage.getItem(_this.storageKey("length"));
      if (length && (length = parseInt(length))) {
        var history;
        for (var i = 0; i < length; i++) {
          history = localStorage.getItem(_this.storageKey(i));
          if (history) {
            histories.push(history);
          }
        }
      }
    } catch (error) {
      console.warn(error);
    }
    return histories;
  };

  return Cms_History;

})();
