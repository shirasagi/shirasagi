// 複数ファイルアップロード（画像／添付）共通の編集UI。
// 画像／添付の `_column_form.html.erb` は共通パーシャルに委譲され、
// このスクリプト 1 本でラベル入力欄の注入・並べ替え（ドラッグ / 数字プルダウン）を担う。
// 並べ替え方式は `ss/lib/sortable_form.js` と同じく `.sortable-handle` + jQuery UI sortable を採用。

Cms_Column_MultipleFilesUpload = function(el) {
  this.$el = $(el);
};

Cms_Column_MultipleFilesUpload.render = function(el) {
  var instance = new Cms_Column_MultipleFilesUpload(el);
  instance.render();
  return instance;
};

Cms_Column_MultipleFilesUpload.prototype.render = function() {
  var self = this;
  var $container = this.$el.find(".multiple-files-upload");
  var $resultTarget = $container.find(".cms-addon-file-selected-files");

  this.labelName = $container.data("label-name");
  this.placeholder = $container.data("label-placeholder");
  this.initialLabels = $container.data("file-labels") || {};
  this.orderAriaLabel = $container.data("order-aria-label") || "";

  this.injectControls($resultTarget);
  this.initSortable($resultTarget);

  $resultTarget.on("ss:change", function() {
    self.injectControls($resultTarget);
  });
};

Cms_Column_MultipleFilesUpload.prototype.injectControls = function($container) {
  var self = this;
  $container.find("> .file-view").each(function() {
    var $fileView = $(this);

    if ($fileView.find("> .sortable-handle").length === 0) {
      var $handle = $(
        '<span class="sortable-handle" style="cursor: move;" aria-hidden="true">' +
          '<i class="material-icons">&#xe8d4;</i>' + // open_with
        '</span>'
      );
      $fileView.prepend($handle);
    }

    if ($fileView.find("> .multiple-files-upload-order").length === 0) {
      var $order = $('<select class="multiple-files-upload-order no-form-control"></select>');
      $order.attr("aria-label", self.orderAriaLabel);
      $fileView.prepend($order);
    }

    if ($fileView.find("> .multiple-files-upload-label").length === 0) {
      var fileId = $fileView.data("file-id");
      var $label = $('<input type="text" class="multiple-files-upload-label">');
      $label.attr("name", self.labelName + "[" + fileId + "]");
      $label.attr("placeholder", self.placeholder);
      $label.val(self.initialLabels[fileId] || "");
      $fileView.append($label);
    }
  });

  this.refreshOrderSelects($container);
};

Cms_Column_MultipleFilesUpload.prototype.refreshOrderSelects = function($container) {
  var self = this;
  var $items = $container.find("> .file-view");
  var total = $items.length;

  $items.each(function(index) {
    var $fileView = $(this);
    var $select = $fileView.find("> .multiple-files-upload-order");
    if ($select.length === 0) return;

    var current = String(index + 1);
    var options = "";
    for (var i = 1; i <= total; i++) {
      options += '<option value="' + i + '"' + (String(i) === current ? ' selected' : '') + '>' + i + '</option>';
    }
    $select.html(options);

    if (!$select.data("ss-order-bound")) {
      $select.data("ss-order-bound", true);
      $select.on("change", function() {
        var $currentFileView = $(this).closest(".file-view");
        self.moveByOrder($container, $currentFileView, parseInt($(this).val(), 10));
      });
    }
  });
};

Cms_Column_MultipleFilesUpload.prototype.moveByOrder = function($container, $fileView, newPosition) {
  var $items = $container.find("> .file-view");
  if (newPosition < 1) newPosition = 1;
  if (newPosition > $items.length) newPosition = $items.length;

  var currentIndex = $items.index($fileView);
  var targetIndex = newPosition - 1;
  if (currentIndex === targetIndex) return;

  var $target = $items.eq(targetIndex);
  if (targetIndex < currentIndex) {
    $target.before($fileView);
  } else {
    $target.after($fileView);
  }
  this.refreshOrderSelects($container);
};

Cms_Column_MultipleFilesUpload.prototype.initSortable = function($container) {
  if ($container.hasClass("ui-sortable")) return;
  var self = this;
  $container.sortable({
    handle: ".sortable-handle",
    items: "> .file-view",
    forcePlaceholderSize: true,
    tolerance: "pointer",
    update: function() {
      self.refreshOrderSelects($container);
    }
  });
};
