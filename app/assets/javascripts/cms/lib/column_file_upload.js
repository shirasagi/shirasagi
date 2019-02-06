Cms_Column_FileUpload = function(el, options) {
  this.$el = $(el);
  this.options = options || {};
};

Cms_Column_FileUpload.userId = null;
Cms_Column_FileUpload.fileSelectPath = null;

Cms_Column_FileUpload.render = function(el, options) {
  var ret = new Cms_Column_FileUpload(el, options);
  ret.render();
  return ret;
};

Cms_Column_FileUpload.prototype.getUserId = function() {
  return this.options.userId || Cms_Column_FileUpload.userId;
};

Cms_Column_FileUpload.prototype.getFileSelectPath = function() {
  return this.options.fileSelectPath || Cms_Column_FileUpload.fileSelectPath;
};

Cms_Column_FileUpload.prototype.getTempFileOptions = function() {
  var self = this;
  var ret = {};

  ret.uploadUrl = function() {
    return "/.s" + self.getUserId() + "/cms/apis/temp_files.json";
  };

  ret.select = function(files, dropArea) {
    if (! files[0]) {
      return;
    }

    var $fileView = self.$el.find(".column-value-files");
    $fileView.addClass("hide");

    var fileId = files[0]["_id"];
    $.ajax({
      url: self.getFileSelectPath().replace(":fileId", fileId),
      type: 'GET',
      success: function(html) {
        $fileView.html(html);
      },
      error: function(xhr, status, error) {
        $fileView.html(error);
      },
      complete: function() {
        $fileView.removeClass("hide");
      }
    });
  };

  return ret;
};

Cms_Column_FileUpload.prototype.render = function() {
  this.tempFile = new SS_Addon_TempFile(
    this.$el.find(".column-value-upload-drop-area"), this.getUserId(), this.getTempFileOptions()
  );

  var self = this;
  this.$el.find('.btn-file-upload').each(function() {
    $(this).data("on-select", function($item) { self.selectFile($item) });
  });

  this.$el.on("click", ".btn-file-delete", function(e) {
    var $this = $(this);
    var $fileView = $this.closest(".file-view");

    $fileView.fadeOut(Cms_TemplateForm.duration || 400).queue(function() {
      $fileView.remove();
    });

    e.preventDefault();
    return false;
  });
};

Cms_Column_FileUpload.prototype.selectFile = function($item) {
  var $fileView = this.$el.find(".column-value-files");
  $fileView.addClass("hide");

  $.colorbox.close();

  var fileId = $item.data('id');
  if (! fileId) {
    return;
  }

  $.ajax({
    url: this.getFileSelectPath().replace(":fileId", fileId),
    type: 'GET',
    success: function(html) {
      $fileView.html(html);
    },
    error: function(xhr, status, error) {
      $fileView.html(error);
    },
    complete: function() {
      $fileView.removeClass("hide");
    }
  });
};
