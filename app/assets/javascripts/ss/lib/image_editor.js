SS_ImageEditor = function (el) {
  var pThis = this;

  this.$el = $(el);
  this.cropper = new Cropper(
    this.$el.find('img.target')[0],
    {
      zoomOnWheel: false,
      ready: function(e) {
        pThis.updateInspect();
        pThis.chooseSize();
      },
      cropmove: function(e) {
        pThis.updateInspect();
        pThis.chooseSize();
      }
    }
  );

  this.$el.find('.ss-toolbar button').on('click', function (e) {
    var func = $(this).data('func');
    if (func && pThis[func]) {
      pThis[func]();
      pThis.updateInspect();
      pThis.chooseSize();

      e.preventDefault();
      return false;
    }
  });

  this.$el.find('.ss-toolbar select[name=size]').on('change', function () {
    var val = $(this).val();
    if (! val) {
      return;
    }

    var sizeArray = val.split(',');
    pThis.changeSize(parseInt(sizeArray[0], 10), parseInt(sizeArray[1], 10));
  });
};

SS_ImageEditor.prototype = {
  inspect: function () {
    if (!this.cropper) {
      return;
    }

    var data = this.cropper.getData(true);
    console.log(data);
    var imageData = this.cropper.getImageData();
    console.log(imageData);
    var canvasData = this.cropper.getCanvasData();
    console.log(canvasData);
  },

  updateInspect: function() {
    var data = this.cropper.getData(true);
    this.$el.find('.ss-toolbar input[name=x]').val(data.x);
    this.$el.find('.ss-toolbar input[name=y]').val(data.y);
    this.$el.find('.ss-toolbar input[name=width]').val(data.width);
    this.$el.find('.ss-toolbar input[name=height]').val(data.height);
  },

  changeSize: function(width, height) {
    var data = this.cropper.getData(true);

    data.width = width;
    data.height = height;

    this.cropper.setData(data);
    this.updateInspect();
  },

  chooseSize: function() {
    var data = this.cropper.getData(true);
    var val = data.width + ',' + data.height;

    this.$el.find('.ss-toolbar select[name=size] option').each(function() {
      this.selected = (this.value === val);
    });
  },

  zoomIn: function () {
    if (!this.cropper) {
      return;
    }
    var saveData = this.cropper.getData(true);
    this.cropper.zoom(0.1);

    var data = this.cropper.getData(true);
    data.width = saveData.width;
    data.height = saveData.height;

    this.cropper.setData(data);
  },

  zoomOut: function () {
    if (!this.cropper) {
      return;
    }
    var saveData = this.cropper.getData(true);
    this.cropper.zoom(-0.1);

    var data = this.cropper.getData(true);
    data.width = saveData.width;
    data.height = saveData.height;

    this.cropper.setData(data);
  },

  rotateLeft: function () {
    if (!this.cropper) {
      return;
    }
    this.cropper.rotate(-90);
  },

  rotateRight: function () {
    if (!this.cropper) {
      return;
    }
    this.cropper.rotate(90);
  },

  normalizeFormat: function(format) {
    if (format === 'image/jpeg' || format === 'image/png') {
      return format;
    }

    if (format === 'image/jpg') {
      return 'image/jpeg';
    }

    // this is default of html5 canvas
    return 'image/png';
  },

  submit: function () {
    if (!this.cropper) {
      return;
    }

    var format = this.normalizeFormat(this.$el.find('img.target').data('format'));
    var newImageData = this.cropper.getCroppedCanvas().toDataURL(format);
    this.cropper.destroy();
    this.cropper = null;

    this.$el.find('.ss-toolbar').hide();
    this.$el.find('img.target').attr('src', newImageData);
    this.$el.find("input[name='item[in_data_url]']").val(newImageData);
  },

  cancel: function () {
    this.cropper.destroy();
    this.cropper = null;

    this.$el.find('.ss-toolbar').hide();
  }
};
