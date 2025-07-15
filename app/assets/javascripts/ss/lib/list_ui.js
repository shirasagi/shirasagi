this.SS_ListUI = (function () {
  function SS_ListUI() { }

  SS_ListUI.render = function (el) {
    var $el;
    if (el) {
      $el = $(el);
    } else {
      $el = $(document);
    }

    $el.find(".list-head input:checkbox").on("change", function () {
      var chk = $(this).prop('checked');
      $el.find('.list-item').each(function () {
        var $listItem = $(this);
        var modified = false;
        $listItem.find('input:checkbox').each(function() {
          if (!this.disabled) {
            this.checked = chk;
            modified = true;
          }
        });

        if (modified) {
          if (chk) {
            $listItem.addClass('checked', chk);
          } else {
            $listItem.removeClass('checked', chk);
          }
        }
      });
      $(this).trigger("ss:checked-all-list-items");
    });
    $el.find(".message-list-head .checkbox-to-all input:checkbox").on("change", function () {
      var chk;
      chk = $(this).prop('checked');
      $el.find('.list-item').each(function () {
        $(this).toggleClass('checked', chk);
        return $(this).find('.to-checkbox input:checkbox').prop('checked', chk);
      });
      $(this).trigger("ss:checked-all-list-items");
    });
    $el.find(".message-list-head .checkbox-cc-all input:checkbox").on("change", function () {
      var chk;
      chk = $(this).prop('checked');
      $el.find('.list-item').each(function () {
        $(this).toggleClass('checked', chk);
        return $(this).find('.cc-checkbox input:checkbox').prop('checked', chk);
      });
      $(this).trigger("ss:checked-all-list-items");
    });
    $el.find(".message-list-head .checkbox-bcc-all input:checkbox").on("change", function () {
      var chk;
      chk = $(this).prop('checked');
      $el.find('.list-item').each(function () {
        $(this).toggleClass('checked', chk);
        return $(this).find('.bcc-checkbox input:checkbox').prop('checked', chk);
      });
      $(this).trigger("ss:checked-all-list-items");
    });
    $el.on("change", ".list-item input:checkbox", function () {
      var $list = $(this);
      return $list.toggleClass("checked", $list.prop("checked"));
    });
    $el.on("mouseup", ".list-item", function (ev) {
      var $list = $(this);
      var $menu, offset, relX, relY;
      var $target = $(ev.target);
      if ($target.is('a') || $target.closest('a,label').length) {
        return;
      }
      $menu = $list.find(".tap-menu");
      if ($menu.is(':visible')) {
        return $menu.hide();
      }
      if ($menu.hasClass("tap-menu-relative")) {
        offset = $list.offset();
        relX = ev.pageX - offset.left;
        relY = ev.pageY - offset.top;
      } else {
        relX = ev.pageX;
        relY = ev.pageY;
      }
      return $menu.css("left", relX - $menu.width() + 5).css("top", relY).show();
    });
    $el.on("mouseleave", ".list-item", function (_ev) {
      return $el.find(".tap-menu").hide();
    });
    $el.find(".list-head .destroy-all").each(function() {
      if (this.classList.contains("btn-list-head-action")) {
        return;
      }
      // for backward compatibility
      this.dataset.ssButtonToAction = "";
      this.dataset.ssButtonToMethod = "delete";
      this.dataset.ssConfirmation = i18next.t('ss.confirm.delete');
      this.classList.add("btn-list-head-action");
    });
    $el.find(".list-head [data-ss-list-head-method]").each(function() {
      if (this.classList.contains("btn-list-head-action")) {
        return;
      }
      // for backward compatibility
      if (this.dataset.ssListHeadAction) {
        this.dataset.ssButtonToAction = this.dataset.ssListHeadAction;
        delete this.dataset.ssListHeadAction;
      }
      if (this.dataset.ssListHeadMethod) {
        this.dataset.ssButtonToMethod = this.dataset.ssListHeadMethod;
        delete this.dataset.ssListHeadMethod;
      }
      this.classList.add("btn-list-head-action");
    });
    $el.find(".list-head .btn-list-head-action").each(function () {
      $(this).on("ss:beforeSend", function(ev) {
        console.log("ss:beforeSend");
        var checked = $el.find(".list-item input:checkbox:checked").map(function () {
          return $(this).val();
        });
        if (checked.length === 0) {
          ev.preventDefault();
          return false;
        }

        for (var i = 0, len = checked.length; i < len; i++) {
          var id = checked[i];
          ev.$form.append($("<input/>", { name: "ids[]", value: id, type: "hidden" }));
        }
      });
    });
    $el.find('.list-head [name="expiration_setting_all"]').on("click", function (ev) {
      SS_ListUI.changeAllExpirationSetting($el, $(this), ev.target.value);
      ev.preventDefault();
    });
  };

  SS_ListUI.changeAllExpirationSetting = function($el, $this, state) {
    if (!state) {
      return;
    }

    var checkedIds = $el.find(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checkedIds.length === 0) {
      return false;
    }

    var confirmation = $this.data('confirm') || '';
    if (confirmation) {
      if (!confirm(confirmation)) {
        return false;
      }
    }

    $this.attr("disabled", true);

    var promises = [];
    $.each(checkedIds, function() {
      var id = this;
      var action = window.location.pathname + "/" + id + ".json";

      var formData = new FormData();
      formData.append("_method", "put");
      formData.append("authenticity_token", $('meta[name="csrf-token"]').attr('content'));
      formData.append("item[expiration_setting_type]", state);

      var promise = $.ajax({
        type: "POST",
        url: action,
        data: formData,
        processData: false,
        contentType: false,
        cache: false
      });

      promises.push(promise);
    });

    $.when.apply($, promises).done(function() {
      alert(i18next.t("ss.notice.changed"));
      window.location.reload();
    }).fail(function(xhr, status, error) {
      alert("Error!");
    }).always(function() {
      $this.attr("disabled", false);
    });
  };

  return SS_ListUI;

})();
