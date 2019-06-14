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

  this.$el.find(".btn-rename-folder").on("click", function() {
    self.renameFolder($(this));
  });

  this.$el.find(".btn-delete-folder").on("click", function() {
    self.deleteFolder($(this));
  });

  this.$el.find(".btn-edit-folder").on("click", function() {
    var href = $(this).data("href");
    if (! href) {
      return;
    }

    location.href = href;
  });

  this.$el.find(".btn-refresh-folder").on("click", function() {
    console.log("on click");
    self.refreshFolder();
  });
};

Gws_Share_FolderToolbar.prototype.createFolder = function ($button) {
  var href = $button.data("href");
  if (! href) {
    return;
  }

  $.colorbox({
    href: href, open: true, fixed: true, with: "90%", height: "90%",
    onComplete: function() {
      console.log("on complete");
      SS.ajaxForm("#cboxLoadedContent form", {
        success: function(data) {
          console.log("success");
        },
        error: function(xhr) {
          console.log("error");
        }
      });
    }
  });
};

Gws_Share_FolderToolbar.prototype.renameFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.deleteFolder = Gws_Share_FolderToolbar.prototype.createFolder;

Gws_Share_FolderToolbar.prototype.refreshFolder = function () {
  if (!this.options.treeNavi) {
    return;
  }

  this.options.treeNavi.refresh();
};
