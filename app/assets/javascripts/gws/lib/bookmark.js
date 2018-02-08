function Gws_Bookmark() {
  this.bookmarkId = null;
  this.defaultName = null;
  this.url = null;
  this.model = null;
  this.el = $('.gws-bookmark');
  this.bookmarkIcon = "&#xE838;";
  this.unbookmarkIcon = "&#xE83A;";
  this.loading = false;
}

Gws_Bookmark.prototype.render = function(opts) {
  if (opts === null) {
    opts = {};
  }
  var _this = this;
  this.bookmarkId = opts['id'];
  this.defaultName = opts['default_name'];
  this.url = opts['url'];
  this.model = opts['model'];

  var icon;
  if (this.bookmarkId) {
    icon = this.bookmarkIcon;
  } else {
    icon = this.unbookmarkIcon;
  }
  var bookmarkName = opts['name'] || this.defaultName;

  var span = $('<span class="bookmark-icon"></span>').append($('<i class="material-icons"></i>').html(icon));
  var ul = $('<ul class="dropdown-menu"></ul>');
  var li = $('<li></li>');
  li.append($('<input name="bookmark[name]" id="bookmark_name" class="bookmark-name" type="text">').val(bookmarkName));
  li.append($('<input name="button" type="button" class="btn update" />').val(opts['save']));
  li.append($('<input name="button" type="button" class="btn delete" />').val(opts['delete']));
  ul.append($('<li><div class="bookmark-notice"></div></li>')).append(li);
  this.el.html(span).append(ul);

  this.el.click(function(e) {
    if (_this.loading) {
      return false;
    } else if ($(e.target).hasClass('update')) {
      _this.update();
    } else if ($(e.target).hasClass('delete')) {
      _this.delete();
    } else if (_this.bookmarkId) {
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
        name: this.defaultName,
        url: location.pathname + location.search,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
      _this.el.find('.material-icons').html(_this.bookmarkIcon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(_this.defaultName);
      _this.bookmarkId = data['bookmark_id'];
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
  var newName = this.el.find('.bookmark-name').val() || this.defaultName;
  var uri = this.url + '/' + this.bookmarkId;
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
        name: newName,
        url: location.pathname + location.search,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.bookmarkIcon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(newName);
      _this.bookmarkId = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.delete = function() {
  var _this = this;
  if (!this.bookmarkId) {
    return false;
  }
  this.loading = true;
  var uri = this.url + '/' + this.bookmarkId;
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
        url: location.pathname + location.search
      }
    },
    success: function() {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.unbookmarkIcon);
      _this.bookmarkId = null;
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};
