this.Gws_Schedule_Repeat_Plan = (function () {
  function Gws_Schedule_Repeat_Plan() {
  }

  Gws_Schedule_Repeat_Plan.renderForm = function () {
    this.changeRepeatForm();
    this.relateDateForm();
    return $('#item_repeat_type').on("change", function () {
      return Gws_Schedule_Repeat_Plan.changeRepeatForm();
    });
  };

  Gws_Schedule_Repeat_Plan.changeRepeatForm = function () {
    var repeatType = $('#item_repeat_type').val();
    if (!repeatType) {
      $('.gws-schedule-repeat').addClass("hide");
      return;
    }

    $('.gws-schedule-repeat').removeClass("hide");
    $(".repeat-daily, .repeat-weekly, .repeat-monthly").hide();
    $(".repeat-" + repeatType).show();
  };

  Gws_Schedule_Repeat_Plan.relateDateForm = function () {
    new SS_StartEndSynchronizer('.date.repeat_start', '.date.repeat_end');
  };

  Gws_Schedule_Repeat_Plan.renderSubmitButtons = function () {
    var b1, b2, b3, buttons, form, sp;
    form = $("#main form");
    sp = '<span class="gws-schedule-btn-space"></span>';
    b1 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_one") });
    b2 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_later") });
    b3 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_all") });
    b1.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="one" />')[0].requestSubmit();
    });
    b2.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="later" />')[0].requestSubmit();
    });
    b3.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="all" />')[0].requestSubmit();
    });
    buttons = $('<div class="gws-schedule-repeat-submit"></div>');
    buttons.append(b1).append(sp).append(b2).append(sp).append(b3);
    return $('.send .save, .send .delete').on("click", function () {
      if ($("#item_repeat_type").val() !== "") {
        $.colorbox({
          inline: true,
          href: buttons
        });
        return false;
      }
    });
  };

  return Gws_Schedule_Repeat_Plan;

})();
