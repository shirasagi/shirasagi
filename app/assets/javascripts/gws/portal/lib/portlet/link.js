function Gws_Portal_Portlet_Link(selector) {
  this.el = $(selector);
  this.tbody = this.el.find('table').first();
  this.base = this.tbody.find('[data-base]').clone();
  this.setEvents();
  //this.tbody.sortable();

  var _this = this;
  this.el.find('.add-item').click(function() {
    _this.tbody.append(_this.base.clone());
  });
}

Gws_Portal_Portlet_Link.prototype.render = function(items) {
  var _this = this;
  $.each(items.reverse(), function(index, data) {
    var item = _this.base.clone();
    item.find('input').eq(0).val(data.name);
    item.find('input').eq(1).val(data.url);
    _this.tbody.prepend(item);
  });
  this.setEvents();
};

Gws_Portal_Portlet_Link.prototype.setEvents = function() {
  this.tbody.find('tr').each(function(index, tr) {
    var tr = $(tr);
    if (tr.data('event')) return;
    tr.find('.remove-item').click(function() {
      tr.remove();
    });
  });
};
