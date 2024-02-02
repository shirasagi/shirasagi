this.Gws_Member = (function () {
  function Gws_Member() {
  }

  Gws_Member.groups = null;

  Gws_Member.users = null;

  Gws_Member.render = function (box) {
    if ($('.js-copy-groups').length < 2) {
      $('.js-copy-groups').addClass("hide");
      $('.js-paste-groups').addClass("hide");
    } else {
      $('.js-copy-groups').removeClass("hide");
      $('.js-paste-groups').removeClass("hide");
    }
    if ($('.js-copy-users').length < 2) {
      $('.js-copy-users').addClass("hide");
      $('.js-paste-users').addClass("hide");
    } else {
      $('.js-copy-users').removeClass("hide");
      $('.js-paste-users').removeClass("hide");
    }

    if (!box) {
      box = document;
    }
    box = $(box);

    box.find('.js-copy-groups').each(function() {
      var $copyEl = $(this);
      SS.justOnce(this, "copyGroups", function() {
        $copyEl.on("click", function () {
          return Gws_Member.copyGroups($copyEl);
        });
      });
    });
    box.find('.js-paste-groups').each(function() {
      var $pasteEl = $(this);
      SS.justOnce(this, "pasteGroups", function() {
        $pasteEl.on("click", function () {
          return Gws_Member.pasteGroups($pasteEl);
        });
      });
    });
    box.find('.js-copy-users').each(function() {
      var $copyEl = $(this);
      SS.justOnce(this, "copyUsers", function() {
        $copyEl.on("click", function () {
          return Gws_Member.copyUsers($copyEl);
        });
      });
    });
    box.find('.js-paste-users').each(function() {
      var $pasteEl = $(this);
      SS.justOnce(this, "pasteUsers", function() {
        $pasteEl.on("click", function () {
          return Gws_Member.pasteUsers($(this));
        });
      });
    })
  };

  Gws_Member.confirmReadableSetting = function () {
    return $('.save').on('click', function () {
//$(submit).trigger("click")
      if ($('.gws-addon-readable-setting tbody tr').length === 0) {
        return confirm(i18next.t("gws.confirm.readable_setting.empty"));
      }
    });
  };

  Gws_Member.copyGroups = function (el) {
    this.groups = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.groups.length + i18next.t('gws.member_log.copy_groups'));
    return false;
  };

  Gws_Member.pasteGroups = function (el) {
    var num;
    num = this.pasteItems(el, this.groups);
    this.showLog(el, num + i18next.t('gws.member_log.paste_groups'));
    return false;
  };

  Gws_Member.copyUsers = function (el) {
    this.users = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.users.length + i18next.t('gws.member_log.copy_users'));
    return false;
  };

  Gws_Member.pasteUsers = function (el) {
    var num;
    num = this.pasteItems(el, this.users);
    this.showLog(el, num + i18next.t('gws.member_log.paste_users'));
    return false;
  };

  Gws_Member.pasteItems = function (el, list) {
    var dl, name, num, tbody;
    if (!list || list.length === 0) {
      return 0;
    }
    dl = el.closest('dl');
    dl.find('table').show();
    tbody = dl.find('tbody');
    name = dl.find('.hidden-ids').attr('name');
    num = 0;
    list.each(function () {
      var tr;
      if (tbody.find('tr[data-id="' + $(this).data('id') + '"]').length === 0) {
        tr = $(this).clone(true);
        tr.find('input').attr('name', name);
        tbody.append(tr);
        return num += 1;
      }
    });
    return num;
  };

  Gws_Member.showLog = function (el, msg) {
    $(".gws-member-log").remove();
    return $("<span class='gws-member-log'>" + msg + "</span>").appendTo(el.parent()).hide().fadeIn(200);
  };

  return Gws_Member;

})();
