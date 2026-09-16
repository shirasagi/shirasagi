Cms_Column_Select_Page = function(el) {
  this.$el = $(el);
};

Cms_Column_Select_Page.defaultTemplate = '\
  <tr data-id="<%= data.id %>"> \
    <td><%= data.name %></td> \
    <td><a class="deselect btn" href="#"><%= label.delete %></a></td> \
  </tr>';

Cms_Column_Select_Page.render = function(el) {
  var instance = new Cms_Column_Select_Page(el);
  instance.render();
  return instance;
};

Cms_Column_Select_Page.prototype.render = function() {
  var self = this;
  SS_SearchUI.render();
  self.$el.find(".ajax-box").data("on-select", function($item) {
    var $data = $item.closest("[data-id]");
    var id = $data.data("id");
    self.$el.find(".hidden-ids").val(id);

    var  deleteLabel = i18next.t("ss.buttons.delete");
    var tr = ejs.render(Cms_Column_Select_Page.defaultTemplate, { data: $data[0].dataset, label: { delete: deleteLabel } });

    self.$el.find(".ajax-selected tbody tr:not(.selected-self)").remove();
    self.$el.find(".ajax-selected tbody").prepend(tr);
    self.$el.find(".ajax-selected").show();
    self.$el.find(".ajax-selected").trigger("change");
  });
  self.$el.find(".ajax-selected").data("on-deselect", function(item) {
    SS_SearchUI.defaultDeselector(item);
    self.$el.find(".hidden-ids").val("");
  });
};
