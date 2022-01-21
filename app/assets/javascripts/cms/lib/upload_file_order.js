Cms_Upload_File_Order = function ($el, options) {
  this.$el = $el;
  this.render();
};

Cms_Upload_File_Order.prototype.render = function () {
  var selectedVal = this.$el.val();
  var classes = this.$el.attr('class');
  var btnClass = classes.split(" ")[1];

  this.changeFileOrder(btnClass, selectedVal);
};


Cms_Upload_File_Order.prototype.changeFileOrder = function (btnClass, selectedVal) {
  var $filesEl = $('.file-view').sort(function (a, b) {
    if (selectedVal === 'upload') {
      if (btnClass === 'file-order-btn') {
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

  this.appendOrderedFiles($filesEl, btnClass);
};

Cms_Upload_File_Order.prototype.appendOrderedFiles = function ($filesEl, btnClass) {
  if (btnClass === 'file-order-btn') {
    $('#selected-files').append($filesEl);
  } else {
    $('.column-value-files').append($filesEl);
  }
};
