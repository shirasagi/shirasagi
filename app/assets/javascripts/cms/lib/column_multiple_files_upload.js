Cms_Column_MultipleFilesUpload = function(el, options) {
  this.$el = $(el);
  this.options = options || {};
};

Cms_Column_MultipleFilesUpload.render = function(el, options) {
  var ret = new Cms_Column_MultipleFilesUpload(el, options);
  ret.render();
  return ret;
};

Cms_Column_MultipleFilesUpload.prototype.getUserId = function() {
  return Cms_Column_FileUpload.userId;
};

Cms_Column_MultipleFilesUpload.prototype.getFileUploadPath = function() {
  return Cms_Column_FileUpload.fileUploadPath;
};

Cms_Column_MultipleFilesUpload.prototype.getFileSelectPath = function() {
  return Cms_Column_FileUpload.fileSelectPath;
};

Cms_Column_MultipleFilesUpload.prototype.render = function() {
  var self = this;

  this.$el.find(".images-upload-files").sortable({
    axis: "y",
    handle: ".sortable-handle",
    items: "> .images-upload-item",
    update: function() {
      self.resetFileIds();
    }
  });

  this.tempFile = new SS_Addon_TempFile(
    this.$el.find(".column-value-upload-drop-area"), this.getUserId(), this.getTempFileOptions()
  );

  this.$el.find('.btn-file-upload').each(function() {
    $(this).data("on-select", function($item) { self.selectFile($item) });
  });

  this.$el.on("click", ".images-upload-delete", function(e) {
    var $item = $(this).closest(".images-upload-item");
    $item.fadeOut(400).queue(function() {
      $item.remove();
      self.resetFileIds();
    });

    e.preventDefault();
    return false;
  });
};

Cms_Column_MultipleFilesUpload.prototype.getTempFileOptions = function() {
  var self = this;
  var ret = {};

  ret.uploadUrl = function() {
    return self.getFileUploadPath();
  };

  ret.select = function(files, _dropArea) {
    if (!files[0]) {
      return;
    }

    var fileId = files[0]["_id"];
    self.addFile(fileId);
  };

  return ret;
};

Cms_Column_MultipleFilesUpload.prototype.selectFile = function($item) {
  $.colorbox.close();

  var $data = $item.closest('[data-id]');
  var fileId = $data.data('id');
  if (!fileId) {
    return;
  }

  this.addFile(fileId);
};

Cms_Column_MultipleFilesUpload.prototype.addFile = function(fileId) {
  var self = this;
  var selectPath = this.getFileSelectPath().replace(":fileId", fileId);

  $.ajax({
    url: selectPath,
    type: 'GET',
    success: function(html) {
      var $html = $(html);
      var $fileView = $html.filter(".file-view").add($html.find(".file-view")).first();
      if (!$fileView.length) {
        return;
      }

      var fileName = $fileView.find(".name label").first().text().trim();
      var humanizedName = $fileView.data("humanized-name") || fileName;
      var isImage = $fileView.find("img").length > 0;

      var $filesContainer = self.$el.find(".images-upload-files");
      var fieldPrefix = $filesContainer.closest(".column-value-body")
        .find("input[name$='[_type]']").attr("name");
      if (fieldPrefix) {
        fieldPrefix = fieldPrefix.replace("[_type]", "");
      } else {
        fieldPrefix = "item[column_values][]";
      }

      var $row = $('<div class="images-upload-item"></div>');
      $row.append('<span class="sortable-handle"><i class="material-icons">drag_handle</i></span>');

      var $thumb = $('<span class="images-upload-thumb"></span>');
      if (isImage) {
        var thumbSrc = $fileView.find("img").first().attr("src");
        $thumb.append('<img src="' + thumbSrc + '" alt="' + self.escapeHtml(humanizedName) + '" />');
      } else {
        var ext = fileName.split('.').pop();
        $thumb.append('<span class="ext icon-' + ext + '">' + ext + '</span>');
      }
      $row.append($thumb);

      $row.append('<span class="images-upload-name">' + self.escapeHtml(fileName) + '</span>');
      $row.append('<input type="hidden" name="' + fieldPrefix + '[in_wrap][file_ids][]" value="' + fileId + '" class="file-id" />');
      $row.append('<input type="text" name="' + fieldPrefix + '[in_wrap][file_labels][' + fileId + ']" value="" class="images-upload-label" placeholder="' + self.escapeHtml(self.getPlaceholder()) + '" />');
      $row.append('<button type="button" class="images-upload-delete"><i class="material-icons md-14">delete</i></button>');

      $filesContainer.append($row);
      self.resetFileIds();
    },
    error: function(xhr, status, error) {
      if (xhr.responseJSON && Array.isArray(xhr.responseJSON)) {
        alert(["== Error(ColumnMultipleFilesUpload) =="].concat(xhr.responseJSON).join("\n"));
      }
    }
  });
};

Cms_Column_MultipleFilesUpload.prototype.resetFileIds = function() {
  // no-op: hidden fields are already in correct DOM order
};

Cms_Column_MultipleFilesUpload.prototype.getPlaceholder = function() {
  return this.$el.find(".images-upload-label").first().attr("placeholder") || "";
};

Cms_Column_MultipleFilesUpload.prototype.escapeHtml = function(str) {
  if (!str) return "";
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
};
