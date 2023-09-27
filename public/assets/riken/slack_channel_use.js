function Riken_SlackChannelUse(el, options) {
  this.$el = $(el);
  this.options = options;

  this.render();
}

Riken_SlackChannelUse.prototype.render = function () {
  var self = this;

  self.$el.on("change", "[name=\"use\"]", function () {
    var $checkbox = $(this);
    var $container = $checkbox.closest("[data-id]");
    var id = $container.data("id");
    var value = $checkbox.prop("value");

    var action;
    if ($checkbox.prop("checked")) {
      action = "set";
    } else {
      action = "unset";
    }
    var url = self.options[action].replace(/:id/g, id);

    $container.find(".success").addClass("hide");
    $.ajax({
      url: url,
      method: "POST",
      data: { item: { value: value } },
      success: function () {
        self.showSuccess($checkbox);
      },
      error: function (_xhr, _status, _error) {
        alert("Error");
      }
    })
  });
};

Riken_SlackChannelUse.prototype.showSuccess = function ($checkbox) {
  var $success = $checkbox.siblings(".success");
  if ($success[0]) {
    $success.removeClass("hide");
    return;
  }

  $success = $("<i />", { class: "material-icons success", style: "color: #64dd17;" }).text("check");
  $checkbox.after($success);
};
