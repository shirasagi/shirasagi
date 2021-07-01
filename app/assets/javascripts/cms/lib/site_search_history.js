this.Cms_Site_Search_History = (function () {
  function Cms_Site_Search_History(selector, url) {
    this.selector = selector;
    this.url = url;

    this.form = $(selector);
    this.keyword = $(selector).find('[name="s[keyword]"]');
    this.history = $(selector).find('.site-search-history');
    this.histories = [];

    this.maxHistoryLength = 6;
    this.maxKeywordLength = 30;

    if (this.keyword.length > 0 && this.history.length > 0) {
      this.render();
    }
  };

  Cms_Site_Search_History.prototype.storageKey = function (key) {
    if (!this.formKey) {
      this.formKey = CryptoJS.MD5(this.url).toString();
    }
    return "ss_site_search_" + this.formKey + "_" + key;
  };

  Cms_Site_Search_History.prototype.getHistories = function () {
    var _this = this;
    var histories = [];
    var length = 0;

    try {
      length = localStorage.getItem(_this.storageKey("history_length"));
      if (length && (length = parseInt(length))) {
        var history;
        for (var i = 0; i < length; i++) {
          history = localStorage.getItem(_this.storageKey("history_" + i));
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

  Cms_Site_Search_History.prototype.setHistories = function (histories) {
    var _this = this;

    try {
      localStorage.setItem(_this.storageKey("history_length"), histories.length);
      $.each(histories, function (idx, history) {
        localStorage.setItem(_this.storageKey("history_" + idx), history);
      });
    } catch (error) {
      console.warn(error);
    }
  };

  Cms_Site_Search_History.prototype.renderHistories = function () {
    var _this = this;

    _this.histories = _this.getHistories();
    if (_this.histories.length > 0) {
      $(_this.histories).each(function () {
        var li = $('<li><a href="#">' + this + '</a></li>');
        li .find("a").on("click", function () {
          _this.keyword.val($(this).text());
          _this.form.trigger("submit");
          return false;
        });
        _this.history.append(li);
      });
    }

    this.index = 0;
    this.indexLength = this.histories.length;
  };

  Cms_Site_Search_History.prototype.renderEvents = function () {
    var _this = this;

    this.form.on("submit", function(){
      var histories = _this.histories;
      var keyword = _this.keyword.val();

      keyword = _this.formatKeyword(keyword);
      if (keyword) {
        _this.keyword.val(keyword);
        histories = histories.filter(function (v) { return v != keyword; });
        histories.unshift(keyword);
        histories = histories.slice(0, _this.maxHistoryLength);
        _this.setHistories(histories);
      }
    });

    if (this.histories.length > 0) {
      this.keyword.on("focus", function(){
        _this.history.show();
      });
      this.keyword.on("blur", function(){
        _this.index = 0;
        _this.history.find("li").removeClass("selected");
        _this.history.hide();
      });
      this.history.find("a").on("mousedown", function(){
        _this.keyword.off("blur");
      });
      this.keyword.on("keydown", function(e) {
        if (e.which != 13 && e.which != 38 && e.which != 40) {
          return;
        }

        if (e.which == 13) {
          if ((_this.index - 1) >= 0) {
            _this.keyword.val(_this.histories[_this.index - 1]);
          }
          return true;
        }
        if (e.which == 38) {
          _this.index -= 1;
        }
        if (e.which == 40) {
          _this.index += 1;
        }
        if (_this.index > _this.indexLength) {
          _this.index = 1;
        } else if (_this.index <= 0) {
          _this.index = _this.indexLength;
        }
        _this.history.find("li").removeClass("selected");
        _this.history.find("li:nth-child(" + _this.index + ")").addClass("selected");
        _this.keyword.val(_this.history.find("li.selected a").data("value"));
      });
    }
  };

  Cms_Site_Search_History.prototype.render = function () {
    this.renderHistories();
    this.renderEvents();
  };

  Cms_Site_Search_History.prototype.formatKeyword = function (keyword) {
    if (!keyword) {
      return keyword;
    }

    keyword = keyword.replace(/[\s　]{1,}/g, ' ');
    keyword = keyword.trim();

    if (keyword.length > this.maxKeywordLength) {
      keyword = keyword.substr(0, this.maxKeywordLength);
      keyword = keyword.trim();
    }
    return keyword;
  };

  return Cms_Site_Search_History;

})();
