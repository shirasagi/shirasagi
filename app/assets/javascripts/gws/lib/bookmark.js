function Gws_Bookmark(el, defaultName) {
  this.$el = $(el);
  this.$form = this.$el.find("form");
  this.defaultName = defaultName;
  this.loading = false;
}

Gws_Bookmark.prototype.renderCreate = function() {
  var self = this;

  self.$el.on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;
    self.$form.ajaxForm({
      type: "post",
      data: {
        default_name: self.defaultName,
      },
      dataType: 'html',
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });
};

Gws_Bookmark.prototype.renderUpdate = function() {
  var self = this;

  self.$el.on("click", function() {
    $(this).find(".dropdown-menu").addClass("active");
    return false;
  });

  self.$el.find("input").on('keypress', function (ev) {
    if ((ev.which && ev.which === SS.KEY_ENTER) || (ev.keyCode && ev.keyCode === SS.KEY_ENTER)) {
      return false;
    } else {
      return true;
    }
  });

  // click update button
  self.$form.find("button.update").on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;

    self.$form.ajaxForm({
      type: "post",
      dataType: 'html',
      data: {
        default_name: self.defaultName,
      },
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });

  // click delete button
  self.$form.find("button.delete").on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;

    self.$form.ajaxForm({
      type: "delete",
      dataType: 'html',
      data: {
        default_name: self.defaultName,
      },
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });
};
