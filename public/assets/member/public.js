var PostalCodeSearch,
  slice = [].slice;

PostalCodeSearch = (function () {
  PostalCodeSearch.prototype.defaults = {
    postal_code: "input[name='item[postal_code]']",
    addr: "input[name='item[addr]']",
    error: '.postal-code-search-error',
    error_message: "郵便番号が見つかりません"
  };

  function PostalCodeSearch(el, options) {
    if (options == null) {
      options = {};
    }
    this.el = $(el);
    this.options = $.extend({}, this.defaults, options);
    this.el.on('click', (function (_this) {
      return function (e) {
        return _this.search();
      };
    })(this));
  }

  PostalCodeSearch.prototype.search = function () {
    var postal_code;
    this.clear_error();
    postal_code = $(this.options.postal_code).val();
    this.el.css('cursor', 'wait');
    return $.ajax({
      type: "POST",
      url: this.options.path,
      data: {
        code: postal_code
      },
      success: (function (_this) {
        return function (data) {
          return _this.set_address(data);
        };
      })(this),
      error: (function (_this) {
        return function () {
          return _this.set_error();
        };
      })(this),
      complete: (function (_this) {
        return function () {
          return _this.el.css('cursor', '');
        };
      })(this)
    });
  };

  PostalCodeSearch.prototype.set_address = function (data) {
    var addr;
    if (!data.prefecture) {
      return;
    }
    addr = data.prefecture;
    if (data.city) {
      addr += data.city;
    }
    if (data.town) {
      addr += data.town;
    }
    return $(this.options.addr).val(addr);
  };

  PostalCodeSearch.prototype.set_error = function () {
    return $(this.options.error).html(this.options.error_message);
  };

  PostalCodeSearch.prototype.clear_error = function () {
    return $(this.options.error).html("");
  };

  return PostalCodeSearch;

})();

$.fn.extend({
  postalCodeSearch: function () {
    var args, options;
    options = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    return this.each(function () {
      var $this, data;
      $this = $(this);
      data = $this.data('postalCodeSearch');
      if (!data) {
        $this.data('postalCodeSearch', (data = new PostalCodeSearch(this, options)));
      }
      if (typeof options === 'string') {
        return data[options].apply(data, args);
      }
    });
  }
});
