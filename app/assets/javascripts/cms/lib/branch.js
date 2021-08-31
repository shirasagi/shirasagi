Cms_Branch = function (el, options) {
  this.$el = $(el);
  this.options = options;

  this.$result = this.$el.find(".result");

  this.render();
}

Cms_Branch.prototype.render = function() {
  var self = this;

  self.toggleCreateBranchButton();
  self.$el.on("click", ".create-branch", function () {
    self.createBranch();
  });

  self.$el.find(".create-branch").prop("disabled", false);
};

Cms_Branch.prototype.createBranch = function() {
  var self = this;
  var token = $('meta[name="csrf-token"]').attr('content');

  $.ajax({
    url: self.options.path,
    type: "POST",
    data: { authenticity_token: token },
    beforeSend: function () {
      self.$result.addClass("wide").show().html(SS.loading);
      self.$el.find(".create-branch").prop("disabled", true);
    },
    success: function (data) {
      self.$result.removeClass("wide").html(data).find("a").removeClass();
      self.$el.find(".create-branch").prop("disabled", false);
      self.toggleCreateBranchButton();
    },
    error: function (data, status) {
      self.$result.html("<div class=\"errorExplanation\">" + ["== Error =="].concat(data.responseJSON).join("\n") + "</div>");
      self.$el.find(".create-branch").prop("disabled", false);
    }
  });
};

Cms_Branch.prototype.toggleCreateBranchButton = function() {
  var self = this;

  var $dt = self.$el.find(".create-branch").closest("dt");
  if (self.$el.find(".branches .name").length) {
    $dt.hide();
    $dt.next("dt").show();
    self.$result.show();
  } else {
    $dt.show();
    $dt.next("dt").hide();
    self.$result.hide();
  }
};
