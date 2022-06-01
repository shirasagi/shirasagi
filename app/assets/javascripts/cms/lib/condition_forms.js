function Cms_ConditionForms(el, options) {
  this.$el = $(el);
  this.options = options;

  this.render();
}

Cms_ConditionForms.prototype.render = function() {
  var self = this;

  self.$el.on("change", ".ajax-selected", function() { self.reloadColumnList(); });
  self.$el.on("click", ".filter-table .deselect", function(ev) { return self.onDeleteFilter(ev); });
  self.$el.on("click", ".add-filter-btn", function(ev) { return self.onAddFilter(ev); });
};

Cms_ConditionForms.prototype.reloadColumnList = function() {
  var self = this;

  var formIds = [];
  self.$el.find("[name=\"item[condition_forms][form_ids][]\"]").each(function() {
    var value = $(this).val();
    if (value) {
      formIds.push(value);
    }
  });

  if (formIds.length === 0) {
    self.$el.find(".empty-message").removeClass("hide");
    self.$el.find(".filter-table, .sort-column").addClass("hide");
    self.clearAndSetColumnList({ column_names: [] });
    return;
  }

  $.ajax({
    type: "GET",
    url: self.options.url,
    dataType: "json",
    data: { ids: formIds },
    success: function (data, _status) {
      self.clearAndSetColumnList(data);

      self.$el.find(".empty-message").addClass("hide");
      self.$el.find(".filter-table, .sort-column").removeClass("hide");
    },
    error: function (_xhr, _status, _error) {
    },
  });
};

Cms_ConditionForms.prototype.clearAndSetColumnList = function(data) {
  console.log("clearAndSetColumnList");
  var self = this;
  var columnNames = data["column_names"];
  var targets = [];

  targets.push('[name="item[condition_forms][filters][][column_name]"]');
  targets.push('[name="item[sort_column_name]"]');

  self.$el.find(targets.join(',')).each(function() {
    var $select = $(this);
    var currentValue = $select.val();

    $select.empty();
    $select.append("<option value label=' '></option>");

    $.each(columnNames, function() {
      var value = this.toString();
      var $option = $("<option />", { value: value, selected: currentValue === value }).html(value);
      $select.append($option);
    });
  });
};

Cms_ConditionForms.prototype.onAddFilter = function(ev) {
  var $table = $(ev.target).closest(".filter-table");
  var $currentTemplate = $table.find(".new-filter");

  var $newTemplate = $currentTemplate.clone();
  $newTemplate.insertAfter($currentTemplate);
  $newTemplate.find("select").val("");
  $newTemplate.find("input").val("");

  $currentTemplate.removeClass("new-filter");
  var $operations = $currentTemplate.find(".operations");
  $operations.html($operations.find("script").html());

  ev.preventDefault();
  return false;
};

Cms_ConditionForms.prototype.onDeleteFilter = function(ev) {
  var self = this;
  var $tr = $(ev.target).closest("tr");

  $tr.fadeOut("fast").queue(function() {
    $tr.remove();
    self.$el.trigger("ss:conditionFormFilterRemoved");
  });

  ev.preventDefault();
  return false;
};
