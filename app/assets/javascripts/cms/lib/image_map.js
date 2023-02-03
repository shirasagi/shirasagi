this.Cms_Image_Map_Area_Cropper = (function () {
  function Cms_Image_Map_Area_Cropper(el, opts) {
    if (!opts) {
      opts = {};
    }
    this.$el = $(el);
    this.$currentArea = this.$el.find(".areas .area");
    this.$image = this.$el.find(".image-warp img");
    this.readonly = opts["readonly"];
    this.render();
  };

  Cms_Image_Map_Area_Cropper.prototype.render = function () {
    var self = this;
    self.cropper = new Cropper(
      self.$image[0],
      {
        viewMode: 1,
        zoomOnWheel: false,
        background: true,
        autoCrop: false,
        ready: function(e) {
          self.cropCurrentArea();
        },
        cropmove: function(e) {
          self.setCroppedArea();
        }
      }
    );

    self.$el.find(".reset-area").on("click", function() {
      self.$currentArea.find('[name="item[in_area][x]"]').val("");
      self.$currentArea.find('[name="item[in_area][y]"]').val("");
      self.$currentArea.find('[name="item[in_area][width]"]').val("");
      self.$currentArea.find('[name="item[in_area][height]"]').val("");
      self.cropper.clear();
      return false;
    });
  };

  Cms_Image_Map_Area_Cropper.prototype.cropCurrentArea = function () {
    var self = this;
    var x = self.$currentArea.find('input[name="item[in_area][x]"]').val();
    var y = self.$currentArea.find('input[name="item[in_area][y]"]').val();
    var width = self.$currentArea.find('input[name="item[in_area][width]"]').val();
    var height = self.$currentArea.find('input[name="item[in_area][height]"]').val();

    if (x && y && width && height) {
      var data = self.cropper.getData(true);
      Object.assign(data, { x: parseInt(x), y: parseInt(y), width: parseInt(width), height: parseInt(height) });
      self.cropper.enable();
      self.cropper.crop();
      self.cropper.setData(data);
    } else {
      self.cropper.enable();
      self.cropper.clear();
    }

    if (self.readonly) {
      self.cropper.disable();
    }
  };

  Cms_Image_Map_Area_Cropper.prototype.setCroppedArea = function () {
    var self = this;
    var data = self.cropper.getData(true);
    self.$currentArea.find('input[name="item[in_area][x]"]').val(data.x);
    self.$currentArea.find('input[name="item[in_area][y]"]').val(data.y);
    self.$currentArea.find('input[name="item[in_area][width]"]').val(data.width);
    self.$currentArea.find('input[name="item[in_area][height]"]').val(data.height);
  };

  return Cms_Image_Map_Area_Cropper;
})();
