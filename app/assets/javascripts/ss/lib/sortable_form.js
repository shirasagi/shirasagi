function SS_SortableForm(selector, opts) {
  this.opts  = opts || {}
  this.el    = $(selector);
  this.limit = this.opts.limit || 0;
  this.head  = this.el.find('thead');
  this.body  = this.el.find('tbody');

  this.head.find('tr').prepend('<th class="sortable-handle-head"></th>');
  this.body.find('tr').prepend('<td class="sortable-handle"></td>');
  this.head.find('tr').append('<th class="sortable-buttons-head"></th>');
  this.body.find('tr').append('<td class="sortable-buttons">' +
    '<button class="btn action-insert" type="button"><i class="material-icons md-13">&#xE145;</i></button> ' +
    '<button class="btn action-remove" type="button"><i class="material-icons md-13">&#xE15B;</i></button>' +
    '</td>');

  this.base = this.body.find('tr[data-base]').last().clone();
  this.el.find('tbody').sortable({ handle: '.sortable-handle' });

  var _this = this;
  this.body.find('tr').each(function(idx, tr) {
    _this.setEvent($(tr));
  });
}

SS_SortableForm.prototype.renderItems = function(items) {
  var _this = this;
  $.each(items.reverse(), function(index, data) {
    var newItem = _this.base.clone();
    $.each(data, function(key, val) {
      newItem.find('[name*=\\[' + key + '\\]]').val(val);
    });
    _this.body.prepend(newItem);
    _this.setEvent(newItem);
  });
};

SS_SortableForm.prototype.setEvent = function(item) {
  var _this = this;

  item.find('.action-insert').click(function() {
    if (_this.limit && _this.body.find('tr').length >= _this.limit) return false;

    var newItem = _this.base.clone();
    $(this).closest('tr').after(newItem);
    _this.setEvent(newItem);
    return false;
  });

  item.find('.action-remove').click(function() {
    item.remove();
    if (_this.body.find('tr').length == 0) {
      var newItem = _this.base.clone();
      _this.body.append(newItem);
      _this.setEvent(newItem);
    }
    return false;
  });
};
