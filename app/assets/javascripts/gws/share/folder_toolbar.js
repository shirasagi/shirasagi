function Gws_Share_FolderToolbar(el, options) {
  this.$el = $(el);
  this.options = options;
  this.render();
}

Gws_Share_FolderToolbar.prototype.render = function () {
  var self = this;

  this.$el.find(".btn-create-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-create-root-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-rename-folder").on("click", function() {
    self.renameFolder($(this), { success: { callback: self.refresh } });
  });

  this.$el.find(".btn-delete-folder").on("click", function() {
    self.deleteFolder($(this));
  });

  this.$el.find(".btn-edit-folder").on("click", function() {
    self.editFolder($(this));
  });

  this.$el.find(".btn-refresh-folder").on("click", function() {
    self.refreshFolder();
  });
};

Gws_Share_FolderToolbar.prototype.createFolder = function ($button, options) {
  var href = $button.data("href");
  if (href) {
    location.href = href;
    return;
  }

  var api = $button.data("api");
  if (! api) {
    return;
  }

  var success = $button.data("success");
  if (! success && options) {
    success = options.success;
  }
  var error = $button.data("error");
  if (! error && options) {
    error = options.error;
  }

  var self = this;

  $.colorbox({
    href: api, open: true, fixed: true, with: "90%", height: "90%",
    onComplete: function() {
      SS.ajaxForm("#cboxLoadedContent form", {
        success: function(data) {
          $.colorbox.close();
          if (success && success.redirect_to) {
            var id;
            if (data) {
              id = data.id;
              if (! id) {
                id = data._id;
              }
            }

            location.href = success.redirect_to.replace(/:id/, id);
            return;
          }
          if (success && success.reload) {
            location.reload();
            return;
          }
          if (success && success.callback) {
            success.callback.call(self, data);
          }
        },
        error: function(xhr) {
          $.colorbox.close();

          if (xhr.responseJSON && xhr.responseJSON.length > 0) {
            alert(xhr.responseJSON.join("\n"));
          } else if (error && error.message) {
            alert(error.message);
          }
        }
      });
    }
  });
};

Gws_Share_FolderToolbar.prototype.refresh = function (data) {
  if (! data) {
    return;
  }

  this.$el.find(".folder-name").text(data.name);
  this.refreshFolder();
};

Gws_Share_FolderToolbar.prototype.renameFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.deleteFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.editFolder = Gws_Share_FolderToolbar.prototype.createFolder;

Gws_Share_FolderToolbar.prototype.refreshFolder = function () {
  if (!this.options.treeNavi) {
    return;
  }

  this.options.treeNavi.refresh();
};
