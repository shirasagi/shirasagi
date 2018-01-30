function Gws_Link_List(selector) {
  this.el = $(selector);
  this.body = this.el.find('table').first();
  this.base = this.body.find('[data-base]').clone();
  //this.body.sortable();

  var _this = this;
  this.body.find('tr').each(function(idx, tr) {
    _this.setEvent($(tr));
  });
  this.el.find('.add-item').click(function() {
    var item = _this.base.clone();
    _this.body.append(item);
    _this.setEvent(item);
  });
}

Gws_Link_List.prototype.renderItems = function(items) {
  var _this = this;
  $.each(items.reverse(), function(index, data) {
    var item = _this.base.clone();
    item.find('input').eq(0).val(data.name);
    item.find('input').eq(1).val(data.url);
    _this.body.prepend(item);
    _this.setEvent(item);
  });
};

Gws_Link_List.prototype.setEvent = function(item) {
  item.find('.remove-item').click(function() {
    item.remove();
  });
};
