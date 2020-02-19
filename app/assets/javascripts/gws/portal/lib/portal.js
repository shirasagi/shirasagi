function Gws_Portal(selector, settings) {
  var options = {
    autogenerate_stylesheet: true,
    resize: {
      enabled: true,
      max_size: [4, 10]
    },
    widget_base_dimensions: ['auto', 120],
    widget_margins: [10, 10],
    min_cols: 1,
    max_cols: 4
  };
  if (settings && settings['readonly']) {
    this.readonly = true;
    options['resize'] = { enabled: false };
    options['draggable'] = { enabled: false, handle: 'disable' };
  }

  this.el = $(selector);
  this.gs = this.el.find("ul.portlets").gridster(options).data('gridster');
}

Gws_Portal.prototype.addItems = function(items) {
  var _this = this;
  $.each(items, function(idx, item) {
    _this.addItem(item);
  });
};

Gws_Portal.prototype.addItem = function(item) {
  var id = item._id.$oid;

  var li = this.gs.add_widget(
    '<li class="portlet-item" data-id="' + id + '"></li>',
    item.grid_data.size_x,
    item.grid_data.size_y,
    item.grid_data.col,
    item.grid_data.row
  );
  if (! li) {
    return;
  }
  li.data('id', id);

  var html = this.el.find(".portlet-html[data-id='" + id + "']");
  if (html.length) {
    var height = html.height();
    html.prependTo(li);
    //this.autoResizeItem(li, height);
  }
};

Gws_Portal.prototype.autoResizeItem = function(widget, height) {
  var base_y = this.gs.options.widget_base_dimensions[1];
  var extra  = ((height % base_y) > (base_y / 2)) ? 1 : 0;
  var size_x = widget.data('sizex');
  var size_y = Math.floor(height / base_y) + extra;

  if (widget.data('sizey') < size_y) {
    this.gs.resize_widget(widget, size_x, size_y);
  }
};

Gws_Portal.prototype.setSerializeEvent = function(selector) {
  var _this = this;
  _this.updateUrl = $(selector).data('href');
  $(selector).click(function() {
    _this.serialize();
  });
};

Gws_Portal.prototype.setResetEvent = function(selector) {
  var _this = this;
  $(selector).click(function() {
    var list = [];
    _this.el.find(".portlet-item").each(function(index) {
      list.push($(this).clone());
    });
    _this.gs.remove_all_widgets();

    $.each(list, function(index, li) {
      _this.gs.add_widget(li, li.data('sizex'), li.data('sizey'));
    });
  });
};

Gws_Portal.prototype.serialize = function() {
  var _this = this;
  var list = {};
  _this.el.find("li.portlet-item").each(function() {
    var li = $(this);
    var id = li.data('id');
    list[id] = _this.gs.serialize(li)[0];
  });

  $.ajax({
    url: _this.updateUrl,
    method: 'POST',
    dataType: 'json',
    data: {
      _method: 'put',
      authenticity_token: $('meta[name="csrf-token"]').attr('content'),
      json: JSON.stringify(list)
    },
    success: function(data) {
      SS.notice(data.message);
    }
  });
};
