Cms_UploadFileOrder = function (addonName, btnClass) {
  this.addonName = addonName;
  this.btnClass = btnClass;
  this.render();
};

Cms_UploadFileOrder.prototype.render = function () {
  var _this = this;
  $(this.btnClass).on('click', function () {
    var selectedVal = $(this).val();
    _this.changeFileOrder(selectedVal);
  });
};

Cms_UploadFileOrder.prototype.changeFileOrder = function (selectedVal) {
  var $filesEl = $('.file-view').sort(function (a, b) {
    if (selectedVal === 'upload') {
      if (this.addonName === 'file') {
        a = $(a).attr('id').replace(/[^0-9]/g, '');
        b = $(b).attr('id').replace(/[^0-9]/g, '');
      } else {
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
    $('#selected-files').append($filesEl);
  } else {
    $('.column-value-files').append($filesEl);
  }
};
