this.SS_PopupNotice = (function () {
  SS_PopupNotice.ajaxTriggered = false;

  SS_PopupNotice.render = function () {
    return $(document).on("click", (function (_this) {
      return function (e) {
        return SS_PopupNotice.closePopup();
      };
    })(this));
  };

  SS_PopupNotice.closePopup = function () {
    return $(".popup-notice").hide();
  };

  SS_PopupNotice.closeDropdown = function () {
    return $(".dropdown,.dropdown-menu").removeClass('active');
  };

  function SS_PopupNotice(target) {
    this.target = target;
    this.loading = SS.loading;
  }

  SS_PopupNotice.prototype.render = function () {
    $(this.target).find(".popup-notice").hide();
    $(this.target).on("click", (function (_this) {
      return function (e) {
        return e.stopPropagation();
      };
    })(this));
    return $($(this.target).find(".ajax-popup-notice")).on("click", (function (_this) {
      return function (e) {
        var url;
        if (SS_PopupNotice.ajaxTriggered) {
          return false;
        }
        SS_PopupNotice.closeDropdown();
        if ($(e.currentTarget).hasClass("toggle-popup-notice") && $(_this.target).find(".popup-notice").is(":visible")) {
          $(_this.target).find(".popup-notice").hide();
          return false;
        }
        SS_PopupNotice.closePopup();
        $(_this.target).find(".popup-notice").show();
        $(_this.target).find(".popup-notice-items").html(_this.loading).addClass("popup-notice-loading");
        url = $(e.currentTarget).attr("data-url") || $(e.currentTarget).attr("href");
        $.ajax({
          url: url,
          beforeSend: function () {
            return SS_PopupNotice.ajaxTriggered = true;
          },
          success: function (data) {
            $(".popup-notice-loading").html(data).removeClass("popup-notice-loading");
            return SS_PopupNotice.ajaxTriggered = false;
          }
        });
        return false;
      };
    })(this));
  };

  return SS_PopupNotice;

})();

