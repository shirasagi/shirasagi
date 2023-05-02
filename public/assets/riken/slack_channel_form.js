function Riken_SlackChannelForm(el) {
  this.$el = $(el);

  this.render();
}

Riken_SlackChannelForm.prototype.render = function() {
  var self = this;

  self.$el.on("click", ".btn-slack-channel-add", function(ev) {
    self.addSlackChannel(ev.target);
  });
  self.$el.on("click", ".btn-slack-channel-delete", function(ev) {
    self.deleteSlackChannel(ev.target);
  });
  self.$el.on("change", ".index", function(ev) {
    self.resetIndex();
  });

  self.resetIndex();
};

Riken_SlackChannelForm.prototype.addSlackChannel = function(el) {
  var $el = $(el);
  var $template = $el.siblings("script");

  $($template.html()).insertBefore($el.closest(".operations"));
  $el.closest(".index").trigger("change");
};

Riken_SlackChannelForm.prototype.deleteSlackChannel = function(el) {
  var $el = $(el);
  var table = $el.closest(".index")[0]
  $el.closest(".slack-channel").remove();
  $(table).trigger("change");
};

Riken_SlackChannelForm.prototype.resetIndex = function() {
  var self = this;
  var index = 0;

  self.$el.find(".slack-channel").each(function () {
    this.dataset.index = index;
    var $tr = $(this);
    // $tr.attr("data-index", index);

    $([ ".btn-slack-channel-test", ".btn-slack-channel-join", ".btn-slack-channel-test-post" ]).each(function() {
      var $btn = $tr.find(this.toString());
      $btn.data("params", { index: index });
      if (!$btn.data("ldap_test")) {
        $btn.data("ldap_test", new Riken_LdapTest($btn));
      }
    });

    index++;
  });
};
