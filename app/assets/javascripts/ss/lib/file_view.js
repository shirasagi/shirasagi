function SS_FileView(el, options) {
  this.$el = $(el);
  this.options = options;

  this.canvas = this.$el.find(".canvas")[0];
  this.ctx = this.canvas.getContext("2d");

  this.image = new Image();
  this.image.src = this.options.itemUrl;

  var self = this;
  this.image.onload = function() {
    self.initImage();
  };

  this.$el.find(".btn-contrast-ratio").on("click", function() {
    self.calculateContrastRatio();
  });

  this.$slider = this.$el.find("#zoom-slider");
  this.$slider.prop({ value: 1, min: 0.1, max: 2, step: "any" });
  this.$slider.on("input", function(ev) {
    if (self.$sliderTimeoutId) {
      clearTimeout(self.$sliderTimeoutId);
    }

    self.$sliderTimeoutId = setTimeout(function() {
      self.zoomImage(ev.target.value);
    }, 10);
  });

  SS_Color.render();
}

SS_FileView.HEX_DECIMAL = "0123456789abcdef";

SS_FileView.toHex = function(n) {
  if (isNaN(n)) {
    return "00";
  }

  n = Math.max(0, Math.min(n, 255));
  return SS_FileView.HEX_DECIMAL.charAt((n - n % 16) / 16) + SS_FileView.HEX_DECIMAL.charAt(n % 16);
};

SS_FileView.prototype.initImage = function() {
  this.canvas.width = this.image.width;
  this.canvas.height = this.image.height;
  this.ctx.drawImage(this.image, 0, 0);

  this.$el.find("#foreground-color").minicolors("value", this.rgbAt(0, 0));
  this.$el.find("#background-color").minicolors("value", this.rgbAt(this.image.width - 1, this.image.height - 1));

  this.calculateContrastRatio();
};

SS_FileView.prototype.calculateContrastRatio = function() {
  var foregroundColor = this.$el.find("#foreground-color").minicolors("value");
  var backgroundColor = this.$el.find("#background-color").minicolors("value");
  if (!foregroundColor || !backgroundColor) {
    return;
  }

  this.$el.find(".contrast-ratio").html(SS.loading);
  $.ajax({
    url: this.options.contrastRatioPath,
    type: 'GET',
    data: { f: foregroundColor, b: backgroundColor, _: Date.now() }
  }).done(function(data) {
    $(".contrast-ratio").html(data.contrast_ratio_human);
  }).fail(function(xhr, status, error) {
    $(".contrast-ratio").html(error);
  });
};

SS_FileView.prototype.zoomImage = function(scale) {
  this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

  this.ctx.scale(scale, scale);

  this.ctx.drawImage(this.image, 0, 0);

  this.ctx.scale(1 / scale, 1 / scale);
};

SS_FileView.prototype.rgbAt = function(x, y) {
  var pixels = this.ctx.getImageData(x, y, 1, 1).data;
  return "#" + SS_FileView.toHex(pixels[0]) + SS_FileView.toHex(pixels[1]) + SS_FileView.toHex(pixels[2]);
};
