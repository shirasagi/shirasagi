this.Gws_Memo_Message = (function () {
  function Gws_Memo_Message() {
  }

  Gws_Memo_Message.render = function () {
    $(".list-head .search").on("click", function () {
      $(".gws-memo-search").animate({ height: "toggle" }, "fast");
    });

    $(".gws-memo-search .reset").on("click", function () {
      $(".gws-memo-search input[type=text]").val("");
      $(".gws-memo-search input[type=checkbox]").val("");
      $(".gws-memo-search .search").trigger("click");
    });

    $('.cc-bcc-label').on("click", function () {
      $('.gws-addon-memo-member .cc-bcc').animate({ height: 'toggle' }, 'fast');
      return false;
    });

    $('.add-template').on("change", function () {
      if ($(this).val() === "") {
        return;
      }
      if ($('#item_format').val() === "html") {
        CKEDITOR.instances['item_html'].insertText($(this).val());
      } else {
        Webmail_Mail_Form.insertText($("#item_text"), $(this).val());
      }
      $(this).val("");
    });

    $(".send-mdn,.ignore-mdn").on("click", function () {
      if ($(this).hasClass('disabled')) {
        return false;
      }

      $.ajax({
        url: $(this).attr("href"),
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content')
        },
        beforeSend: function () {
          return $(".send-mdn,.ignore-mdn").addClass('disabled');
        },
        success: function (data) {
          SS.notice(data.notice);
          return $(".request-mdn-notice").remove();
        }
      });
    });

    $(".icon-star a").on("click", function () {
      var $wrap = $(this).parent();
      var url;
      if ($wrap.hasClass('on')) {
        url = $(this).attr('href') + '/unset_star';
      } else {
        url = $(this).attr('href') + '/set_star';
      }
      $.ajax({
        url: url,
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put'
        },
        success: function (data) {
          if (data.action === 'set_star') {
            $wrap.removeClass('off').addClass('on');
          } else {
            $wrap.removeClass('on').addClass('off');
          }
          if (data.notice) {
            SS.notice(data.notice);
          }
        }
      });
      return false;
    });
  };

  Gws_Memo_Message.buildForm = function (action, confirm) {
    var checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    var token = $('meta[name="csrf-token"]').attr("content");
    var form = $("<form/>", { action: action, method: "post", data: { confirm: confirm } });
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
    var i, len;
    for (i = 0, len = checked.length; i < len; i++) {
      var id = checked[i];
      form.append($("<input/>", { name: "ids[]", value: id, type: "hidden" }));
    }
    return form;
  };

  return Gws_Memo_Message;

})();
