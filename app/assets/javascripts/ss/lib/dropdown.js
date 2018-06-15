this.SS_Dropdown = (function () {
  SS_Dropdown.render = function () {
    return $("button.ss-dropdown").each(function () {
      var dropdown, target;
      target = $(this).parent().find(".ss-dropdown-container")[0];
      dropdown = new SS_Dropdown(this, {
        target: target
      });
      if (!SS_Dropdown.dropdown) {
        return SS_Dropdown.dropdown = dropdown;
      }
    });
  };

  SS_Dropdown.openDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.openDropdown();
    }
  };

  SS_Dropdown.closeDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.closeDropdown();
    }
  };

  SS_Dropdown.toggleDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.toggleDropdown();
    }
  };

  function SS_Dropdown(elem, options) {
    this.elem = $(elem);
    this.options = options;
    this.target = $(this.options.target);
    this.bindEvents();
  }

  SS_Dropdown.prototype.bindEvents = function () {
    this.elem.on("click", (function (_this) {
      return function (e) {
        _this.toggleDropdown();
        return _this.cancelEvent(e);
      };
    })(this));
    //focusout
    $(document).on("click", (function (_this) {
      return function (e) {
        if (e.target !== _this.elem && e.target !== _this.target) {
          return _this.closeDropdown();
        }
      };
    })(this));
    return this.elem.on("keydown", (function (_this) {
      return function (e) {
        if (e.keyCode === 27) {  //ESC
          _this.closeDropdown();
          return _this.cancelEvent(e);
        }
      };
    })(this));
  };

  SS_Dropdown.prototype.openDropdown = function () {
    return this.target.show();
  };

  SS_Dropdown.prototype.closeDropdown = function () {
    return this.target.hide();
  };

  SS_Dropdown.prototype.toggleDropdown = function () {
    return this.target.toggle();
  };

  SS_Dropdown.prototype.cancelEvent = function (e) {
    e.preventDefault();
    e.stopPropagation();
    return false;
  };

  return SS_Dropdown;

})();
