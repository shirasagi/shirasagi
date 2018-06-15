/**
 * Category Navi
 */
function Gws_Category_Navi(selector) {
  this.el = $(selector);
}

Gws_Category_Navi.prototype.setBaseUrl = function(url) {
  this.baseUrl = url;
};

Gws_Category_Navi.prototype.render = function(items) {
  if (items.length == 0) {
    this.el.hide();
    return;
  }
  var _this = this;
  var list = [];
  var line = list[0];
  var last_depth = -1;
  var path = location.href.replace(/https?:\/\/.*?\//, '/');
  var isCate = null;

  $.each(items, function(idx, item) {
    var depth = (item.name.match(/\//g) || []).length;
    var url = _this.baseUrl.replace('ID', item._id);

    if (depth == 0 || depth != last_depth) {
      list.push({ depth: depth, items: []});
      line = list[list.length - 1];
    }
    if (path.startsWith(url)) {
      isCate = item._id;
    }
    line.items.push('<a class="link-item" href="' + url + '">' + item.trailing_name + '</a>');
    last_depth = depth;
  });

  var html = [];
  $.each(list, function(idx, data) {
    html.push('<div class="depth depth-' + data.depth + '">');
    html.push(data.items.join('<span class="separator"></span>'));
    html.push('</div>');
  });
  this.el.find('.ss-dropdown-menu').append(html.join(''));

  var toggle = this.el.find('.ss-dropdown-toggle');
  if (isCate) {
    var icon = '<i class="material-icons md-18 md-dark">&#xE14C;</i>';
    toggle.after('<a class="ml-1" href="' + toggle.attr('href') + '">' + icon + '</a>');
  }
  toggle.click(function() {
    return false;
  });
};
