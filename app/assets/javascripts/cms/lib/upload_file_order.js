Cms_UploadFileOrder = function (el, addonName, btnClass) {
  this.$el = $(el);
  this.addonName = addonName;
  this.btnClass = btnClass;
  this.render();
};

Cms_UploadFileOrder.prototype.render = function () {
  var _this = this;
  _this.$el.on('click', _this.btnClass, function () {
    this.disabled = true;

    var selectedVal = $(this).val();
    _this.changeFileOrder(selectedVal);

    if (selectedVal === 'upload') {
      SS.notice(i18next.t('ss.notice.ordered_by_file_upload_order'));
    } else {
      // name
      SS.notice(i18next.t('ss.notice.ordered_by_file_name_order'));
    }

    this.disabled = false;
  });
};

Cms_UploadFileOrder.prototype.changeFileOrder = function (selectedVal) {
  var $filesEl = this.$el.find('.file-view').sort(function (a, b) {
    if (selectedVal === 'upload') {
      if (this.addonName === 'file') {
        a = $(a).attr('id').replace(/[^0-9]/g, '');
        b = $(b).attr('id').replace(/[^0-9]/g, '');
      } else {
        // columsForm
        a = $(a).attr('data-file-id');
        b = $(b).attr('data-file-id');
      }
    } else {
      a = $(a).attr('data-name');
      b = $(b).attr('data-name');
    }
    return a > b ? 1 : -1;
  });

  this.appendOrderedFiles($filesEl);
};

Cms_UploadFileOrder.prototype.appendOrderedFiles = function ($filesEl) {
  if (this.addonName === 'file') {
    this.$el.find('#selected-files').append($filesEl);
  } else {
    // columsForm
    this.$el.find('.column-value-files').append($filesEl);
  }
};
