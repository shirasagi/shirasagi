this.SS_Dropdown = (function () {
  // private methods
  var cancelEvent = function (event) {
    event.preventDefault();
    event.stopPropagation();
  };

  SS_Dropdown.onceRendered = false;

  SS_Dropdown.renderOnce = function() {
    if (SS_Dropdown.onceRendered) {
      return;
    }

    //focusout
    $(document).on("click", function (ev) {
      $("button.dropdown").each(function () {
        if (this.ss && this.ss.dropdown) {
          if (!this.ss.dropdown.isTarget(ev)) {
            return this.ss.dropdown.closeDropdown();
          }
        }
      });
    });

    SS_Dropdown.onceRendered = true;
  };

  SS_Dropdown.render = function () {
    SS_Dropdown.renderOnce();

    $("button.dropdown").each(function () {
      var element = this;
      SS.justOnce(element, "dropdown", function() {
        var target = $(element).parent().find(".dropdown-container")[0];
        return new SS_Dropdown(element, {
          target: target
        });
      });
    });
  };

  function SS_Dropdown(elem, options) {
    this.$element = $(elem);
    this.$target = $(options.target);
    this.bindEvents();
    if (this.$target.data("opened")) {
      this.openDropdown();
    }
  }

  SS_Dropdown.prototype.bindEvents = function () {
    var _this = this;

    this.$element.on("click", function (ev) {
      _this.toggleDropdown();
      cancelEvent(ev);
      return false;
    });
    this.$element.on("keydown", function (ev) {
      if (ev.keyCode === 27) {  //ESC
        _this.closeDropdown();
        cancelEvent(ev);
        return false;
      }
    });
  };

  SS_Dropdown.prototype.isTarget = function (event) {
    return (event.target === this.$element || event.target === this.$target);
  }

  SS_Dropdown.prototype.openDropdown = function () {
    this.$target.show();
  };

  SS_Dropdown.prototype.closeDropdown = function () {
    this.$target.hide();
  };

  SS_Dropdown.prototype.toggleDropdown = function () {
    this.closeOtherDropdowns();
    this.$target.toggle();
  };

  SS_Dropdown.prototype.closeOtherDropdowns = function () {
    $(".dropdown-container").not(this.$target.get(0)).each(function () {
      $(this).hide();
    });
  };

  return SS_Dropdown;

})();
