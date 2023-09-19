function Riken_RadioGroup(el) {
  this.$el = $(el);
  this.render();
}

Riken_RadioGroup.render = function() {
  $(document).find(".riken-radio-group").each(function() {
    new Riken_RadioGroup(this)
  });
};

Riken_RadioGroup.prototype.render = function() {
  var self = this;

  var from = self.$el.data("from");
  var to = self.$el.data("to");
  if (!from || !to) {
    return;
  }

  var $from = self.$el.find("[name='" + from + "']");
  var $to = self.$el.find("[name='" + to + "']");
  if (!$from[0] || !$to[0]) {
    return;
  }

  self.$el.on("change", "[name='" + from + "']", function(ev) {
    $to.val(ev.target.value);
  });
};
