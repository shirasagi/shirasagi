(function() {
  if (document.getElementById("multiple-files-upload-styles")) return;
  var style = document.createElement("style");
  style.id = "multiple-files-upload-styles";
  // 先頭ファイルのドラッグハンドルアイコンのみ視覚的に隠す。先頭は別ファイルをドラッグして
  // 入れ替える運用想定だが、ハンドル自体は残しドラッグ操作は維持する。
  style.textContent =
    ".multiple-files-upload .cms-addon-file-selected-files > .file-view:first-child .sortable-handle .material-icons { visibility: hidden; }";
  document.head.appendChild(style);
})();

Cms_Column_MultipleFilesUpload = function(el) {
  this.$el = $(el);
};

Cms_Column_MultipleFilesUpload.render = function(el) {
  var ret = new Cms_Column_MultipleFilesUpload(el);
  ret.render();
  return ret;
};

Cms_Column_MultipleFilesUpload.prototype.render = function() {
  var self = this;
  var $container = this.$el.find(".multiple-files-upload");
  var $resultTarget = $container.find(".cms-addon-file-selected-files");

  this.labelName = $container.data("label-name");
  this.placeholder = $container.data("label-placeholder");
  this.initialLabels = $container.data("file-labels") || {};

  this.injectControls($resultTarget);
  this.initSortable($resultTarget);

  $resultTarget.on("ss:change", function() {
    self.injectControls($resultTarget);
  });
};

Cms_Column_MultipleFilesUpload.prototype.injectControls = function($container) {
  var self = this;
  $container.find(".file-view").each(function() {
    var $fileView = $(this);
    if ($fileView.find(".multiple-files-upload-label").length > 0) return;

    var fileId = $fileView.data("file-id");
    var initialValue = self.initialLabels[fileId] || "";

    var $handle = $('<span class="sortable-handle" style="cursor: move;"><i class="material-icons">&#xe8d4;</i></span>');
    $fileView.prepend($handle);

    var $label = $('<input type="text" class="multiple-files-upload-label">');
    $label.attr("name", self.labelName + "[" + fileId + "]");
    $label.attr("placeholder", self.placeholder);
    $label.val(initialValue);
    $fileView.append($label);
  });
};

Cms_Column_MultipleFilesUpload.prototype.initSortable = function($container) {
  if ($container.hasClass("ui-sortable")) return;
  $container.sortable({
    handle: ".sortable-handle",
    items: "> .file-view"
  });
};
