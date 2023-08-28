function Riken_LdapCustomGroupForm(el) {
  this.$el = $(el);

  this.render();
}

Riken_LdapCustomGroupForm.prototype.render = function() {
  var self = this;

  self.$el.on("click", ".btn-custom-group-condition-add", function(ev) {
    self.addCustomGroupForm(ev.target);
  });
  self.$el.on("click", ".btn-custom-group-condition-delete", function(ev) {
    self.deleteCustomGroupForm(ev.target);
  });
  self.$el.on("change", ".index", function(ev) {
    self.resetIndex();
  });

  self.resetIndex();
};

Riken_LdapCustomGroupForm.prototype.addCustomGroupForm = function(el) {
  var $el = $(el);
  var $template = $el.siblings("script");

  $($template.html()).insertBefore($el.closest(".operations"));
  $el.closest(".index").trigger("change");
};

Riken_LdapCustomGroupForm.prototype.deleteCustomGroupForm = function(el) {
  var $el = $(el);
  var table = $el.closest(".index")[0]
  $el.closest(".custom-group-condition").remove();
  $(table).trigger("change");
};

Riken_LdapCustomGroupForm.prototype.resetIndex = function() {
  var self = this;
  var index = 0;

  self.$el.find(".custom-group-condition").each(function () {
    this.dataset.index = index;
    var $tr = $(this);
    // $tr.attr("data-index", index);

    var $btn = $tr.find(".btn-custom-group-condition-test");
    $btn.data("params", { index: index });

    index++;

    if ($btn.data("ldap_test")) {
      return;
    }

    $btn.data("ldap_test", new Riken_LdapTest($btn));
  });
};
