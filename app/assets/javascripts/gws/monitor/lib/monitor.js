this.Gws_Monitor_Topic = (function () {
  function Gws_Monitor_Topic() {
  }

  Gws_Monitor_Topic.render = function () {
    $(".public").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".preparation").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".question_not_applicable").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/question_not_applicable",
        method: "post",
        data: {
          confirm: i18next.t('gws/monitor.confirm.question_not_applicable')
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    return $(".answered").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/answered",
        method: "post",
        data: {
          confirm: i18next.t('gws/monitor.confirm.answer')
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
  };

  Gws_Monitor_Topic.buildForm = function (action, confirm) {
    var checked, form, i, id, len, token;
    checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    token = $('meta[name="csrf-token"]').attr('content');
    form = $("<form/>", {
      action: action,
      method: "post",
      data: {
        confirm: confirm
      }
    });
    form.append($("<input/>", {
      name: "authenticity_token",
      value: token,
      type: "hidden"
    }));
    for (i = 0, len = checked.length; i < len; i++) {
      id = checked[i];
      form.append($("<input/>", {
        name: "ids[]",
        value: id,
        type: "hidden"
      }));
    }
    return form;
  };

  Gws_Monitor_Topic.renderForm = function (opts) {
    if (opts == null) {
      opts = {};
    }
    $("input.date").datetimepicker({
      lang: "ja",
      timepicker: false,
      format: 'Y/m/d',
      closeOnDateSelect: true,
      scrollInput: false,
      maxDate: opts["maxDate"]
    });
    return $("input.datetime").datetimepicker({
      lang: "ja",
      roundTime: 'ceil',
      step: 30,
      maxDate: opts["maxDate"]
    });
  };

  return Gws_Monitor_Topic;

})();
