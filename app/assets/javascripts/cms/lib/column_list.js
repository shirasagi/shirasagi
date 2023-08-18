Cms_Column_List = function(el) {
  this.$el = $(el);
};

Cms_Column_List.render = function(el) {
  var instance = new Cms_Column_List(el);
  instance.render();
  return instance;
};

Cms_Column_List.prototype.render = function() {
  var self = this;

  this.$el.on('click', '.btn-add-list', function() {
    self.addList($(this));
  });

  this.$el.on('click', '.btn-delete-list', function() {
    self.removeList($(this));
  });
};

Cms_Column_List.prototype.addList = function($target) {
  var $columnValue = $target.closest(".column-value");
  var template = $columnValue.find(".template").html();

  var list = $columnValue.find(".list");
  list.append(template);
};

Cms_Column_List.prototype.removeList = function($target) {
  var $columnValue = $target.closest(".column-value");
  var $li = $target.closest("li");
  $li.remove();
};
