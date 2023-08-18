Gws_Affair_OvertimeFile = function (options) {
  this.holidayUrl = options["holidayUrl"];
  this.capitalUrl = options["capitalUrl"];
  this.$dateStartEl = $('[name="item[start_at_date]"]');
  this.$dateEndEl = $('[name="item[end_at_date]"]');
  this.render();
};

Gws_Affair_OvertimeFile.prototype.render = function() {
  var self = this;

  // 開始日を変更した際に、終了日を設定する
  // 開始日が週休日、祝日の場合、振替申請を切り替える
  self.$dateStartEl.on("ss:changeDateTime", function() {
    var startDate = SS_DateTimePicker.momentValue(self.$dateStartEl);
    if (startDate) {
      SS_DateTimePicker.momentValue(self.$dateEndEl, startDate);
      self.toggleCompensatory(startDate);
    }
  });
  //self.$dateStartEl.trigger("ss:changeDateTime");
  self.toggleCompensatory(SS_DateTimePicker.momentValue(self.$dateStartEl));

  // 申請対象を選択した際に、原資区分を設定する
  $(".mod-gws-affair_file_target_user .ajax-box").data("on-select", function($item) {
    SS_SearchUI.defaultSelector($item);

    var data = $item.closest("[data-id]");
    var uid = data.data("id");
    self.loadEffectiveCapital(uid);
  });
  if ($(".selected-capital .capital").length == 0) {
    self.loadEffectiveCapital(self.findTargetUser());
  } else {
    $(".selected-capital .deselect").on("click", function() {
      $(".selected-capital").html("");
      self.loadEffectiveCapital(self.findTargetUser());
      return false;
    });
  }

  // 振替申請
  $(".open-compensatory").on("click", self.openCompensatory);
  $(".select-compensatory").on("change", self.toggleSelectCompensatoryMinute);
  $(".select-compensatory").trigger("change");

  // 振替申請が未設定の場合の警告を表示する（基本的に土日・祝日は振替として申請しなければならない）
  $("input:submit").on("click.form_alert", self.compensatoryFormAlert);

  // 緊急時はこちら
  $(".select-capital .ajax-box").data("on-select", function($item) {
    self.selectCapital($item);
  });
};

Gws_Affair_OvertimeFile.prototype.findTargetUser = function() {
  var $user = $(".mod-gws-affair_file_target_user .ajax-selected [data-id]:first");
  if ($user.length > 0) {
    return $user.closest("[data-id]").data("id");
  } else {
    return null;
  }
};

Gws_Affair_OvertimeFile.prototype.toggleCompensatory = function(startDate) {
  var self = this;
  var url = self.holidayUrl;
  var uid = self.findTargetUser();
  var ymd = startDate.format("YYYYMMDD");
  if (!uid) {
    return
  }

  url = url.replace("UID", uid);
  url = url.replace("YMD", ymd);
  $.get(url, function(data){
    // class と label の追加
    var label = [];
    $('.overtime-date').text("");
    $('.overtime-date').removeClass("leave-day");
    $('.overtime-date').removeClass("weekly-leave-day");
    $('.overtime-date').removeClass("holiday");
    if (data["leave_day"]) {
      $('.overtime-date').addClass("leave-day");
    }
    if (data["weekly_leave_day"]) {
      $('.overtime-date').addClass("weekly-leave-day");
      label.push('週休日');
    }
    if (data["holiday"]) {
      $('.overtime-date').addClass("holiday");
      label.push('祝日');
    }
    if (label.length > 0) {
      $('.overtime-date').text(" (" + label.join(",") + "）");
    }

    // 振替表示、非表示
    if (data["holiday"] && data["weekly_leave_day"]) {
      // 祝日かつ週休日
      $(".default-compensatory").show();
      $(".holiday-compensatory").show();
    } else if (data["holiday"]) {
      // 祝日
      $(".default-compensatory").hide();
      $(".holiday-compensatory").show();
    } else {
      $(".default-compensatory").show();
      $(".holiday-compensatory").hide();
    }
  });
};

Gws_Affair_OvertimeFile.prototype.openCompensatory = function() {
  $(this).next(".compensatory-with-date").show();
  $(this).remove();
  return false;
};

Gws_Affair_OvertimeFile.prototype.toggleSelectCompensatoryMinute = function() {
  $(".select-compensatory").each(function() {
    var val = $(this).val();
    if (val && val > 0) {
      $(this).closest("dd").find(".open-compensatory").show();
    } else {
      $(this).closest("dd").find(".open-compensatory").hide();
    }
  });
};

Gws_Affair_OvertimeFile.prototype.compensatoryFormAlert = function(e) {
  var submit = this;

  // 土日・祝日
  if (!$('.overtime-date').hasClass("leave-day")) {
    return true;
  }

  // 振替なし
  var minute = 0;
  $(".select-compensatory").map(function() {
    var val = parseInt($(this).val());
    if (Number.isInteger(val)) {
      minute += val;
    }
  });
  if (minute > 0) {
    return true;
  }

  // show alert
  var div = $('<div id="alertExplanation" class="errorExplanation">');
  div.append("<h2>時間外申請</h2>");
  div.append("<p>週休日・祝日の時間外について</p>")
  div.append('<ul><li style="white-space: nowrap;">週休日の振替又は代休日の設定がされておりません。<br />入力画面に戻るをクリックして、振替日等を設定してから保存をお願いします。<br />なお、特別な理由で時間外勤務又は休日勤務の場合は、このまま保存してください。</li></ul>');
  var footer = $(document.createElement("footer")).addClass('send');
  footer.append('<button name="button" type="button" class="btn-primary save">保存する</button>');
  footer.append('<button name="button" type="button" class="btn-default cancel">入力画面に戻る</button>');
  $.colorbox({
    html: div.get(0).outerHTML + footer.get(0).outerHTML,
    maxHeight: "80%",
    fixed: true
  });
  $("#cboxLoadedContent").find(".save").on("click", function () {
    $(submit).off(".form_alert");
    return $(submit).trigger("click");
  });
  $("#cboxLoadedContent").find(".cancel").on("click", function () {
    $.colorbox.close();
    return false;
  });

  e.preventDefault();
  return false;
};

Gws_Affair_OvertimeFile.prototype.loadEffectiveCapital = function(uid) {
  var self = this;
  var url = self.capitalUrl.replace("UID", uid);

  $(".selected-capital").html(SS.loading);
  $.get(url, function(html){
    $(".selected-capital").html(html);
  });
};

Gws_Affair_OvertimeFile.prototype.selectCapital = function($item) {
  var self = this;
  var anchorAjaxBox = SS_SearchUI.anchorAjaxBox;

  var data = $item.closest("[data-id]");
  var id = data.data("id");
  var div = $('<div class="caiptal emergency" />').attr("data-id", id);
  var name = data.data("name") || data.find(".select-item").text() || item.text() || data.text();
  var input1 = anchorAjaxBox.closest("dl").find(".hidden-ids").clone(false);
  var input2 = anchorAjaxBox.closest("dl").find(".capital-state").clone(false);
  var a = $('<a class="deselect btn" href="#">取消</a>');

  a.on("click", function() {
    $(".selected-capital").html("");
    self.loadEffectiveCapital(self.findTargetUser());
    return false;
  });

  input1 = input1.val(id).removeClass("hidden-ids");
  name += "（緊急）"
  input2.attr("value", "emergency");

  div.append(input1);
  div.append(input2);
  div.append(name);
  div.append(a);

  anchorAjaxBox.closest("dl").find(".selected-capital").html(div);
  anchorAjaxBox.closest("dl").find(".selected-capital").trigger("change");
};
