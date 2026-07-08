this.Gws_Share_File = (function () {
  function Gws_Share_File() {}

  // チェックされたファイルの ids[] を載せた一括操作用フォームを生成する。
  // チェックが無い場合は false を返す。
  Gws_Share_File.buildForm = function (action, confirm) {
    var checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }

    var token = $('meta[name="csrf-token"]').attr("content");
    var form = $("<form/>", { action: action, method: "post", data: { confirm: confirm } });
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));

    for (var i = 0, len = checked.length; i < len; i++) {
      form.append($("<input/>", { name: "ids[]", value: checked[i], type: "hidden" }));
    }
    return form;
  };

  return Gws_Share_File;
})();
