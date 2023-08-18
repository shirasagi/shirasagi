function Gws_Workload_Navi(selector) {
  this.el = $(selector);
}

Gws_Workload_Navi.prototype.setBaseUrl = function(url) {
  this.baseUrl = url;
};

Gws_Workload_Navi.prototype.render = function(items) {
  if (items.length == 0) {
    this.el.hide();
    return;
  }
  var _this = this;
  var list = [];

  $.each(items, function(idx, item) {
    var url = _this.baseUrl.replace('ID', item._id);
    list.push('<a class="link-item" href="' + url + '" data-id="' + item._id + '">' + item.name + '</a>');
  });

  var html = [];
  $.each(list, function(idx, data) {
    html.push(data);
  });
  this.el.find('.dropdown-menu').append(html.join(''));

  var toggle = this.el.find('.dropdown-toggle');
  toggle.on("click", function() {
    return false;
  });
};
