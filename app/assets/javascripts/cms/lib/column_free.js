Cms_Column_Free = function(el, options) {
  this.$el = $(el);
  this.options = options || {};
};

Cms_Column_Free.userId = null;
Cms_Column_Free.fileUploadPath = null;
Cms_Column_Free.fileSelectPath = null;

Cms_Column_Free.render = function(el, options) {
  var instance = new Cms_Column_Free(el, options);
  instance.render();
  return instance;
};

Cms_Column_Free.prototype.getUserId = function() {
  return this.options.userId || Cms_Column_Free.userId;
};

Cms_Column_Free.prototype.getEditorId = function() {
  return this.options.editorId;
};

Cms_Column_Free.prototype.getObjectName = function() {
  return this.options.objectName;
};

Cms_Column_Free.prototype.getFileUploadPath = function() {
  return this.options.fileUploadPath || Cms_Column_Free.fileUploadPath;
};

Cms_Column_Free.prototype.getFileSelectPath = function() {
  return this.options.fileSelectPath || Cms_Column_Free.fileSelectPath;
};

Cms_Column_Free.prototype.getTempFileOptions = function() {
  var self = this;
  var ret = {};

  ret.uploadUrl = function() {
    return self.getFileUploadPath();
  };

  ret.select = function(files, dropArea) {
    if (! files[0]) {
      return;
    }

    var $fileView = self.$el.find(".column-value-files");
    $fileView.addClass("hide");

    var promises = [];
    $.each(files, function() {
      var fileId = this["_id"];
      var promise = $.ajax({
        url: self.getFileSelectPath().replace(":fileId", fileId),
        type: 'GET',
        success: function(html) {
          self.addFile(html);
        }
      });

      promises.push(promise);
    });

    $.when.apply($, promises).fail(function(xhr, status, error) {
      $fileView.html(error);
    }).always(function() {
      $fileView.removeClass("hide");
    });
  };

  return ret;
};

Cms_Column_Free.prototype.render = function() {
  this.tempFile = new SS_Addon_TempFile(
    this.$el.find(".column-value-upload-drop-area"), this.getUserId(), this.getTempFileOptions()
  );

  var self = this;
  this.$el.find('.btn-file-upload').each(function() {
    $(this).data("on-select", function($item) { self.selectFile($item) });
  });

  this.$el.on("click", ".btn-file-attach", function(e) {
    self.insertAttachment($(this).closest(".file-view"));

    e.preventDefault();
    return false;
  });

  this.$el.on("click", ".btn-file-image-paste", function(e) {
    self.insertImage($(this).closest(".file-view"));

    e.preventDefault();
    return false;
  });

  this.$el.on("click", ".btn-file-thumb-paste", function(e) {
    self.insertThumb($(this).closest(".file-view"));

    e.preventDefault();
    return false;
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

Cms_Column_Free.prototype.selectFile = function($item) {
  var $fileView = this.$el.find(".column-value-files");
  $fileView.addClass("hide");

  $.colorbox.close();

  var $data = $item.closest('[data-id]');
  var fileId = $data.data('id');
  if (! fileId) {
    return;
  }

  var self = this;
  $.ajax({
    url: this.getFileSelectPath().replace(":fileId", fileId),
    type: 'GET',
    success: function(html) {
      self.addFile(html);
    },
    error: function(xhr, status, error) {
      if (xhr.responseJSON && Array.isArray(xhr.responseJSON)) {
        return alert(["== Error(ColumnFree) =="].concat(xhr.responseJSON).join("\n"));
      }
      $fileView.html(error);
    },
    complete: function() {
      $fileView.removeClass("hide");
    }
  });
};

Cms_Column_Free.prototype.addFile = function(html) {
  var $fileView = this.$el.find(".column-value-files");
  var $html = $("<div>" + html + "</div>");
  $fileView.append($html.html());
};

Cms_Column_Free.prototype.insertContent = function(content) {
  if ((typeof tinymce) != "undefined") {
    tinymce.get(this.getEditorId()).execCommand("mceInsertContent", false, content);
  } else if (typeof CKEDITOR != "undefined") {
    var editor = $(this.getEditorId()).data("ckeditorInstance");
    editor.insertHtml(content);
  }
};

Cms_Column_Free.prototype.insertAttachment = function($fileView) {
  var text = $fileView.data("humanized-name");
  var $a = $("<a/>", { href: $fileView.data("url"), class: "icon-" + $fileView.data("extname") }).html(text);
  this.insertContent($a.prop('outerHTML'));
};

Cms_Column_Free.prototype.insertImage = function($fileView) {
  var $img = $("<img/>", { src: $fileView.data("url"), alt: $fileView.data("name") });
  this.insertContent($img.prop('outerHTML'));
};

Cms_Column_Free.prototype.insertThumb = function($fileView) {
  var $img = $("<img/>", { src: $fileView.data("thumb-url"), alt: $fileView.data("name") });
  var $a = $("<a/>", { href: $fileView.data("url"), class: "ajax-box", target: "_blank", rel: "noopener" }).html($img);
  this.insertContent($a.prop('outerHTML'));
};
