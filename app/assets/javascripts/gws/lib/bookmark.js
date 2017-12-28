function Gws_Bookmark() {
  this.bookmark_id = null;
  this.default_name = null;
  this.url = null;
  this.model = null;
  this.el = $('.gws-bookmark');
  this.bookmark_icon = "&#xE866;";
  this.unbookmark_icon = "&#xE867;";
  this.loading = false;
}

Gws_Bookmark.prototype.render = function(opts) {
  if (opts === null) {
    opts = {};
  }
  var _this = this;
  this.bookmark_id = opts['id'];
  this.default_name = opts['default_name'];
  this.url = opts['url'];
  this.model = opts['model'];

  if (this.bookmark_id) {
    var icon = this.bookmark_icon;
  } else {
    var icon = this.unbookmark_icon;
  }
  var bookmark_name = opts['name'] || this.default_name;

  var span = $('<span class="bookmark-icon"></span>');
  span.append($('<i class="material-icons">' + icon + '</i>'));
  this.el.html(span);
  var ul = $('<ul class="dropdown-menu"></ul>');
  ul.append($('<li><div class="bookmark-notice"></div></li>'));
  var li = $('<li></li>');
  li.append($('<input name="bookmark[name]" id="bookmark_name" class="bookmark-name" type="text">').val(bookmark_name));
  li.append($('<input name="button" type="button" class="btn update" />').val(opts['save']));
  li.append($('<input name="button" type="button" class="btn delete" />').val(opts['delete']));
  ul.append(li);
  this.el.append(ul);

  this.el.click(function(e) {
    if (_this.loading) {
      return false;
    } else if ($(e.target).hasClass('update')) {
      _this.update();
    } else if ($(e.target).hasClass('delete')) {
      _this.delete();
    } else if (_this.bookmark_id) {
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
    } else {
      _this.create();
    }
  });
};

Gws_Bookmark.prototype.create = function() {
  this.loading = true;
  var _this = this;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  $.ajax({
    url: this.url,
    method: 'POST',
    data: {
      item: {
        name: this.default_name,
        url: location.pathname,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
      _this.el.find('.material-icons').html(_this.bookmark_icon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(_this.default_name);
      _this.bookmark_id = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.update = function() {
  this.loading = true;
  var _this = this;
  var new_name = this.el.find('.bookmark-name').val() || this.default_name;
  var uri = this.url + '/' + this.bookmark_id;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  this.el.addClass('active');
  this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'patch',
      item: {
        name: new_name,
        url: location.pathname,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.bookmark_icon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(new_name);
      _this.bookmark_id = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.delete = function() {
  var _this = this;
  if (!this.bookmark_id) {
    return false;
  }
  this.loading = true;
  var uri = this.url + '/' + this.bookmark_id;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  this.el.addClass('active');
  this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'delete',
      item: {
        url: location.pathname
      }
    },
    success: function() {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.unbookmark_icon);
      _this.bookmark_id = null;
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};
