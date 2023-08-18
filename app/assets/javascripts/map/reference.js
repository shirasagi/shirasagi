function Map_Reference(addon) {
  this.$addon = $(addon);
  this.$pseudoSelect = this.$addon.find("[name=\"pseudo_map_reference_method\"]");
  this.$referenceMethod = this.$addon.find("[name=\"item[map_reference_method]\"]");
  this.$referenceColumnName = this.$addon.find("[name=\"item[map_reference_column_name]\"]");

  this.render();
}

Map_Reference.prototype.render = function() {
  var self = this;

  var handler = function() { self.reload() };
  self.$addon.on("ss:addonShown", handler);
  $(document).on("ss:formActivated", handler);
  $(document).on("ss:columnAdded", handler);
  $(document).on("ss:columnDeleted", handler);
  $(document).on("ss:formDeactivated", function() { self.clear(); });

  this.$pseudoSelect.on("change", function() { self.onChange(); });
};

Map_Reference.prototype.reload = function() {
  var self = this;
  var selected = self.$pseudoSelect.val();
  if (!selected) {
    selected = self.$pseudoSelect.data("selected");
  }

  self.clear();

  var selectOptions = [];
  var $formAddon = $("#addon-cms-agents-addons-form-page");
  $formAddon.find(".column-value-cms-column-selectpage").each(function() {
    var $columnSelectPage = $(this);
    var firstLabel = $columnSelectPage.find(".column-value-header label")[0];
    var label = firstLabel.textContent;
    if (label) {
      label = label.trim();
    }
    if (label) {
      selectOptions.push(label);
    }
  });

  console.log(selectOptions);
  $.each(selectOptions, function() {
    var value = this.toString();
    var $option = $("<option />", { value: value }).text(value);
    if (value === selected) {
      $option.prop("selected", true);
    }
    self.$pseudoSelect.append($option);
  });
};

Map_Reference.prototype.clear = function() {
  var self = this;
  var removeElements = [];
  self.$pseudoSelect.find("option").each(function() {
    if (this.value) {
      removeElements.push(this);
    }
  });

  $.each(removeElements, function() {
    this.remove();
  });
};

Map_Reference.prototype.onChange = function() {
  var self = this;
  var value = self.$pseudoSelect.val();
  if (value) {
    self.$referenceMethod.val("page");
    self.$referenceColumnName.val(value);
  } else {
    self.$referenceMethod.val("direct");
    self.$referenceColumnName.val("");
  }
};
