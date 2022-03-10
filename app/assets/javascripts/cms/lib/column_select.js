Cms_Column_Select = function() {
};

Cms_Column_Select.renderChild = function(el, options) {
  new Cms_Column_ChildSelect(el, options);
};

Cms_Column_ChildSelect = function(el, options) {
  this.$el = $(el);
  this.$container = this.$el.closest("#addon-cms-agents-addons-form-page");
  this.options = options;
  this.render();
};

Cms_Column_ChildSelect.prototype.lazyThisSelect = function() {
  var $select = this.$el.find("[name='item[column_values][][in_wrap][value]']");
  if ($select[0]) {
    this.thisSelect = function() { return $select; };
  } else {
    this.thisSelect = function() { return null; };
  }
  return $select;
};
Cms_Column_ChildSelect.prototype.thisSelect = Cms_Column_ChildSelect.prototype.lazyThisSelect;

Cms_Column_ChildSelect.prototype.render = function() {
  var self = this;

  this.$container.on("change", function(ev) { self.maybeChanged(ev.target) });
  $(document).on("ss:columnAdded", function(ev, el) { self.maybeAdded(el); });
  $(document).on("ss:columnDeleted", function() { self.reload(); });
  self.reload();
};

Cms_Column_ChildSelect.isParent = function(el, parentColumnId) {
  var columnId = $(el).closest(".column-value-body").find('[name="item[column_values][][column_id]"]').val();
  return columnId === parentColumnId;
}

Cms_Column_ChildSelect.prototype.maybeChanged = function(el) {
  var self = this;

  if (Cms_Column_ChildSelect.isParent(el, self.options.parent_column_id)) {
    self.reload(el);
  }
}

Cms_Column_ChildSelect.prototype.maybeAdded = function(el) {
  var self = this;
  var $select = $(el).find('[name="item[column_values][][in_wrap][value]"]');
  if (!$select[0]) {
    return;
  }

  if (Cms_Column_ChildSelect.isParent($select[0], self.options.parent_column_id)) {
    self.reload($select[0]);
  }
}

Cms_Column_ChildSelect.prototype.findParentSelect = function() {
  var self = this;
  var $column = this.$container.find('[name="item[column_values][][column_id]"][value="' + self.options.parent_column_id + '"]');
  if (!$column[0]) {
    return;
  }

  return $column.closest(".column-value-body").find('[name="item[column_values][][in_wrap][value]"]')[0];
}

Cms_Column_ChildSelect.prototype.reload = function(el) {
  var self = this;
  var $select = self.thisSelect();
  var currentlySelected = $select.val();
  var initiallySelected = $select.data("initially-selected");

  self.clear();

  if (!el) {
    el = self.findParentSelect();
  }
  if (!el) {
    self.setDefaultOptions();
    return;
  }

  var $el = $(el);
  var val = $el.val();
  if (!val) {
    return;
  }

  var $datalist = self.$el.find("datalist");
  if (!$datalist[0]) {
    return;
  }

  var selected = currentlySelected || initiallySelected;
  $datalist.find("option[data-parent='" + val + "']").each(function() {
    var $option = $(this);
    $option = $option.clone();
    if ($option.attr("value") === selected) {
      $option.attr("selected", "selected");
    }
    $select.append($option);
  });
  $select.trigger("change");
};

Cms_Column_ChildSelect.prototype.setDefaultOptions = function() {
  var self = this;
  var $datalist = self.$el.find("datalist");
  if (!$datalist[0]) {
    return;
  }

  var $select = self.thisSelect();
  var initiallySelected = $select.data("initially-selected");
  $datalist.find("option").each(function() {
    var $option = $(this);
    $option = $option.clone();
    $option.html($option.attr("value"));
    if ($option.attr("value") === initiallySelected) {
      $option.attr("selected", "selected");
    }
    $select.append($option);
  });
  $select.trigger("change");
};

Cms_Column_ChildSelect.prototype.clear = function() {
  var $select = this.thisSelect();
  $select.find("option").each(function() {
    var $option = $(this);
    if ($option.attr("value")) {
      $option.remove();
    }
  });
};
