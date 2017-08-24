SS_ImageEditor = function (el) {
  this.$el = $(el);
  this.cropper = new Cropper(this.$el.find('img.target')[0], {zoomOnWheel: false});

  var pThis = this;
  this.$el.find('.toolbar button').on('click', function (e) {
    var func = $(this).data('func');
    if (func && pThis[func]) {
      pThis[func]();
      pThis.inspect();

      e.preventDefault();
      return false;
    }
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

  zoomIn: function () {
    if (!this.cropper) {
      return;
    }
    this.cropper.zoom(0.1);
  },

  zoomOut: function () {
    if (!this.cropper) {
      return;
    }
    this.cropper.zoom(-0.1);
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

  submit: function () {
    if (!this.cropper) {
      return;
    }

    var newImage = this.cropper.getCroppedCanvas().toDataURL('image/jpeg');
    this.cropper.destroy();
    this.cropper = null;

    this.$el.find('.toolbar').hide();
    this.$el.find('img.target').attr('src', newImage);
  },

  cancel: function () {
    this.cropper.destroy();
    this.cropper = null;

    this.$el.find('.toolbar').hide();
  }
};
