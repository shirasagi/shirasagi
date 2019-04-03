Cms_Column_RadioButton = function(el) {
  this.$el = $(el);
};

Cms_Column_RadioButton.render = function(el) {
  var instance = new Cms_Column_RadioButton(el);
  instance.render();
  return instance;
};

Cms_Column_RadioButton.prototype.render = function() {
  var self = this;

  this.$el.find(".clear-radio").on("click", function() {
    self.$el.find('input[type=radio]').prop('checked', false);
  });
};
