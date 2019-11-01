function SS_FileView(el, options) {
  this.$el = $(el);
  this.options = options;

  this.canvas = this.$el.find(".canvas")[0];
  this.ctx = this.canvas.getContext("2d");

  this.scale = 1;

  this.dragInfo = {
    isDragging: false,
    start: { x: 0, y: 0 },
    diff: { x: 0, y: 0 },
    canvas: { x: 0, y: 0 }
  };

  this.$el.one("ss:cboxCompleted", this.resizeCanvas.bind(this));

  this.image = new Image();
  this.image.src = this.options.itemUrl;
  this.image.onload = this.initImage.bind(this);

  this.$el.find(".btn-contrast-ratio").on("click", this.calculateContrastRatio.bind(this));

  this.$slider = this.$el.find("#zoom-slider");
  this.$slider.prop({ value: this.scale, min: 0.1, max: 2, step: "any" });
  this.$slider.on("input", this.zooming.bind(this));

  this.canvas.addEventListener("click", this.pickUpColor.bind(this));
  this.canvas.addEventListener("mousedown", this.dragStart.bind(this));
  this.canvas.addEventListener("mousemove", this.dragging.bind(this));
  this.canvas.addEventListener("mouseup", this.dragEnd.bind(this));

  this.$el.find(".btn-color-picker").on("click", this.pickUpColorStart.bind(this));

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
  this.ctx.drawImage(this.image, 0, 0);

  var width, height;
  if (this.image.width > this.canvas.width) {
    width = this.canvas.width;
  } else {
    width = this.image.width;
  }
  if (this.image.height > this.canvas.height) {
    height = this.canvas.height;
  } else {
    height = this.image.height;
  }

  this.$el.find("#foreground-color").minicolors("value", this.rgbAt(width / 2, height / 2));
  this.$el.find("#background-color").minicolors("value", this.rgbAt(0, 0));

  this.calculateContrastRatio();
};

SS_FileView.prototype.resizeCanvas = function() {
  var maxWidth = this.$el.width();

  var maxHeight = $("#cboxLoadedContent").height();
  // minus padding
  maxHeight -= $("#ajax-box").outerHeight(true) - $("#ajax-box").height();
  // minus toolbar height
  maxHeight -= Math.ceil($(this.canvas).offset().top) - Math.floor(this.$el.offset().top);
  maxHeight -= 10;

  this.canvas.width = maxWidth;
  this.canvas.height = maxHeight;
  this.redrawImage();
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

SS_FileView.prototype.redrawImage = function() {
  this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
  this.ctx.scale(this.scale, this.scale);
  this.ctx.drawImage(this.image, this.dragInfo.diff.x, this.dragInfo.diff.y);
  // reset scale
  this.ctx.setTransform(1, 0, 0, 1, 0, 0);
};

SS_FileView.prototype.zooming = function(ev) {
  this.scale = ev.target.value;

  if (this.$sliderTimeoutId) {
    clearTimeout(this.$sliderTimeoutId);
  }

  this.$sliderTimeoutId = setTimeout(this.zoomCommitted.bind(this), 10);
};

SS_FileView.prototype.zoomCommitted = function() {
  this.$sliderTimeoutId = null;
  this.redrawImage();
};

SS_FileView.prototype.dragStart = function(ev) {
  if (this.isPickingUpColor) {
    return;
  }

  this.dragInfo.isDragging = true;
  this.dragInfo.start.x = ev.clientX;
  this.dragInfo.start.y = ev.clientY;

  this.canvas.style.cursor = "move";
};

SS_FileView.prototype.dragging = function(ev) {
  if (!this.dragInfo.isDragging) {
    return;
  }

  this.dragInfo.diff.x = this.dragInfo.canvas.x + (ev.clientX - this.dragInfo.start.x) / this.scale;
  this.dragInfo.diff.y = this.dragInfo.canvas.y + (ev.clientY - this.dragInfo.start.y) / this.scale;
  this.redrawImage();
};

SS_FileView.prototype.dragEnd = function(_ev) {
  if (!this.dragInfo.isDragging) {
    return;
  }

  this.canvas.style.cursor = "auto";

  this.dragInfo.isDragging = false;
  this.dragInfo.canvas.x = this.dragInfo.diff.x;
  this.dragInfo.canvas.y = this.dragInfo.diff.y;
};

SS_FileView.prototype.pickUpColorStart = function(ev) {
  this.isPickingUpColor = true;
  $(ev.currentTarget).addClass("btn-active");
  this.canvas.style.cursor = "crosshair";
};

SS_FileView.prototype.pickUpColor = function(ev) {
  if (!this.isPickingUpColor) {
    return;
  }

  var x = ev.offsetX;
  var y = ev.offsetY;
  if (x < 0) {
    x = 0;
  }
  if (x >= this.canvas.width) {
    x = this.canvas.width - 1;
  }
  if (y < 0) {
    y = 0;
  }
  if (y >= this.canvas.height) {
    y = this.canvas.height - 1;
  }

  var rgb = this.rgbAt(x, y);
  this.$el.find(".btn-color-picker.btn-active").closest(".btn-group").find(".js-color").minicolors("value", rgb);

  this.canvas.style.cursor = "auto";
  this.$el.find(".btn-color-picker").removeClass("btn-active");
  this.isPickingUpColor = false;

  this.calculateContrastRatio();
};

SS_FileView.prototype.rgbAt = function(x, y) {
  this.ctx.scale(this.scale, this.scale);
  var pixels = this.ctx.getImageData(x, y, 1, 1).data;
  // reset scale
  this.ctx.setTransform(1, 0, 0, 1, 0, 0);

  var red = pixels[0];
  var green = pixels[1];
  var blue = pixels[2];
  var alpha = pixels[3];

  if (alpha === 0) {
    return "#ffffff";
  }

  red = SS_FileView.toHex(red);
  green = SS_FileView.toHex(green);
  blue = SS_FileView.toHex(blue);
  return "#" + red + green + blue;
};
