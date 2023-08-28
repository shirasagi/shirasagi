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
    $el.find(".list-item").each(function () {
      var list;
      list = $(this);
      list.find("input:checkbox").on("change", function () {
        return list.toggleClass("checked", $(this).prop("checked"));
      });
      list.on("mouseup", function (e) {
        var menu, offset, relX, relY;
        if ($(e.target).is('a') || $(e.target).closest('a,label').length) {
          return;
        }
        menu = list.find(".tap-menu");
        if (menu.is(':visible')) {
          return menu.hide();
        }
        if (menu.hasClass("tap-menu-relative")) {
          offset = $(this).offset();
          relX = e.pageX - offset.left;
          relY = e.pageY - offset.top;
        } else {
          relX = e.pageX;
          relY = e.pageY;
        }
        return menu.css("left", relX - menu.width() + 5).css("top", relY).show();
      });
      return list.on("mouseleave", function () {
        return $el.find(".tap-menu").hide();
      });
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
  };

  return SS_ListUI;

})();
