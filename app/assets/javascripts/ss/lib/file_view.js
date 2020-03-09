function SS_FileView(el, options) {
  this.$el = $(el);
  this.options = options;

  this.$canvasContainer = this.$el.find(".canvas-container");
  this.$canvasContainer.html(SS.loading);

  this.canvas = document.createElement("canvas");
  this.ctx = this.canvas.getContext("2d");

  this.scale = 1;
  this.$slider = this.$el.find("#zoom-slider");
  this.$slider.prop({ value: this.scale * 100, min: SS_FileView.MIN_SCALE * 100, max: SS_FileView.MAX_SCALE * 100, step: "any" });
  this.$slider.on("input", this.zooming.bind(this)).on("change", this.zoomChanged.bind(this));

  this.dragInfo = {
    isDragging: false,
    start: { x: 0, y: 0 },
    diff: { x: 0, y: 0 },
    canvas: { x: 0, y: 0 }
  };

  var self = this;

  // ダイアログが完全に開かないと、キャンバスサイズを計算できないので、完全に開くまで待つ
  var d1 = $.Deferred();
  this.$el.one("ss:cboxCompleted", function() { d1.resolve(); });
  // // 3 秒以内にダイアログが開かなければ失敗。
  // setTimeout(function() { d1.rejectWith(self, [ "failed to open dialog" ]); }, 3000);
  // 3 秒以内にダイアログが開かなければダイアログが開いたとみなす。
  setTimeout(function() { d1.resolve(); }, 3000);

  // 仕様で画像は非同期で読み込まれるので、画像読み込み完了まで待つ
  var d2 = $.Deferred();
  this.image = new Image();
  this.image.src = this.options.itemUrl;
  this.image.onload = function() { d2.resolve(); };
  this.image.onerror = function() { d2.rejectWith(self, [ "failed to load image" ]); };

  // ダイアログが完全に開いて、かつ、画像の読み込みが完了したら、残りの初期化が可能となる。
  $.when(d1.promise(), d2.promise())
    .done(this.initializationComplete.bind(this))
    .fail(function(msg) { self.$canvasContainer.html(msg); });

  SS_Color.render();
}

SS_FileView.HEX_DECIMAL = "0123456789abcdef";
SS_FileView.CANVAS_SAFE_MARGIN = 10;
SS_FileView.MIN_SCALE = 0.1;
SS_FileView.MAX_SCALE = 2;
SS_FileView.SCALE_STEPS = [ 0.1, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2.0 ];

SS_FileView.listenTo = function(el, options) {
  $(el).on("click", function(ev) {
    SS_FileView.open(ev, options);
  });
};

SS_FileView.open = function(ev, options) {
  var $this = $(ev.currentTarget);
  if ($this.find("img").length === 0) {
    return true;
  }

  var path = $this.attr("href");
  if (path.startsWith("/fs/")) {
    if (options && options.viewPath) {
      var $fileView = $this.closest(".file-view");
      if ($fileView.length > 0) {
        var fileId = $fileView.data("file-id");
        if (fileId) {
          path = options.viewPath.replace(":id", fileId);
        }
      }
    }
  }
  if (path.startsWith("/fs/")) {
    return true;
  }

  $.colorbox({
    href: path,
    width: "90%",
    height: "90%",
    fixed: true,
    open: true,
    onComplete: function() { $("#ss-file-view").trigger("ss:cboxCompleted"); }
  });

  ev.preventDefault();
  return false;
};

SS_FileView.toHex = function(n) {
  if (isNaN(n)) {
    return "00";
  }

  n = Math.max(0, Math.min(n, 255));
  return SS_FileView.HEX_DECIMAL.charAt((n - n % 16) / 16) + SS_FileView.HEX_DECIMAL.charAt(n % 16);
};

SS_FileView.calcPositionAndScale = function(image, canvas) {
  var position = 0;
  var scale = 1;

  if (image > canvas) {
    position = 0;
    scale = canvas / image;
    if (scale < SS_FileView.MIN_SCALE) {
      scale = SS_FileView.MIN_SCALE;
    }
  } else {
    position = (canvas - image) / 2;
    scale = 1;
  }

  return { position: position, scale: scale };
};

SS_FileView.findScaleStepIndex = function(scale) {
  var found = -1;
  if (scale < SS_FileView.SCALE_STEPS[0]) {
    found = 0;
  } else if (scale > SS_FileView.SCALE_STEPS[SS_FileView.SCALE_STEPS.length - 1]) {
    found = SS_FileView.SCALE_STEPS.length - 1;
  } else {
    for (var i = 0; i < SS_FileView.SCALE_STEPS.length - 1; i += 1) {
      if (SS_FileView.SCALE_STEPS[i] <= scale && scale < SS_FileView.SCALE_STEPS[i + 1]) {
        found = i;
        break;
      }
      if (found === -1) {
        found = SS_FileView.SCALE_STEPS.length - 1;
      }
    }
  }

  return found;
};

SS_FileView.prototype.initializationComplete = function() {
  var canvasWidth = this.$el.width();

  var $ajaxBox = $("#ajax-box");
  var canvasHeight = $("#cboxLoadedContent").height();
  // minus padding
  canvasHeight -= $ajaxBox.outerHeight(true) - $ajaxBox.height();
  // minus toolbar height
  canvasHeight -= Math.ceil(this.$canvasContainer.offset().top) - Math.floor(this.$el.offset().top);
  canvasHeight -= SS_FileView.CANVAS_SAFE_MARGIN;

  this.canvas.width = canvasWidth;
  this.canvas.height = canvasHeight;

  var x = SS_FileView.calcPositionAndScale(this.image.width, canvasWidth);
  var y = SS_FileView.calcPositionAndScale(this.image.height, canvasHeight);

  if (y.scale > x.scale) {
    this.scale = x.scale;
    this.dragInfo.diff.x = x.position;
    this.dragInfo.diff.y = ((canvasHeight - this.image.height * this.scale) / 2) / this.scale;
    if (this.dragInfo.diff.y < 0) {
      this.dragInfo.diff.y = 0;
    }
  } else {
    this.scale = y.scale;
    this.dragInfo.diff.x = ((canvasWidth - this.image.width * this.scale) / 2) / this.scale;
    if (this.dragInfo.diff.x < 0) {
      this.dragInfo.diff.x = 0;
    }
    this.dragInfo.diff.y = y.position;
  }
  this.dragInfo.canvas.x = this.dragInfo.diff.x;
  this.dragInfo.canvas.y = this.dragInfo.diff.y;
  this.redrawImage();

  this.$slider.prop({ value: this.scale * 100 });

  this.$el.find(".btn-zoom-out").on("click", this.prevScale.bind(this));
  this.$el.find(".btn-zoom-in").on("click", this.nextScale.bind(this));

  this.$el.find("#foreground-color").minicolors("value", this.rgbAt(canvasWidth / 2, canvasHeight / 2));
  this.$el.find("#background-color").minicolors("value", "#ffffff");
  this.calculateContrastRatio();

  this.$el.find(".btn-contrast-ratio").on("click", this.calculateContrastRatio.bind(this));

  this.canvas.addEventListener("click", this.pickUpColor.bind(this));
  this.canvas.addEventListener("mousedown", this.dragStart.bind(this));
  this.canvas.addEventListener("mousemove", this.dragging.bind(this));
  this.canvas.addEventListener("mouseup", this.dragEnd.bind(this));

  this.$el.find(".btn-color-picker").on("click", this.pickUpColorStart.bind(this));

  this.$el.find(".canvas-container").html(this.canvas);
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
  this.scale = ev.target.value / 100.0;

  if (this.$sliderTimeoutId) {
    clearTimeout(this.$sliderTimeoutId);
  }

  this.$sliderTimeoutId = setTimeout(this.zoomCommitted.bind(this), 10);
};

SS_FileView.prototype.zoomChanged = function(ev) {
  this.scale = ev.target.value / 100.0;
  if (this.$sliderTimeoutId) {
    clearTimeout(this.$sliderTimeoutId);
  }
  this.zoomCommitted();
};

SS_FileView.prototype.zoomCommitted = function() {
  this.$sliderTimeoutId = null;
  this.redrawImage();
};

SS_FileView.prototype.nextScale = function(_ev) {
  var current = SS_FileView.findScaleStepIndex(this.scale);
  var next = current + 1;
  if (next >= SS_FileView.SCALE_STEPS.length) {
    next = SS_FileView.SCALE_STEPS.length - 1;
  }

  this.scale = SS_FileView.SCALE_STEPS[next];
  this.$slider.prop({ value: this.scale * 100 });

  this.redrawImage();
};

SS_FileView.prototype.prevScale = function(_ev) {
  var prev = SS_FileView.findScaleStepIndex(this.scale);
  if (SS_FileView.SCALE_STEPS[prev] === this.scale) {
    prev -= 1;
  }
  if (prev < 0) {
    prev = 0;
  }

  this.scale = SS_FileView.SCALE_STEPS[prev];
  this.$slider.prop({ value: this.scale * 100 });

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
  var $target = $(ev.currentTarget);
  if ($target.hasClass("btn-active")) {
    // cancel picking
    $target.removeClass("btn-active");
    this.isPickingUpColor = false;
    this.canvas.style.cursor = "auto";
  } else {
    this.$el.find(".btn-color-picker.btn-active").removeClass("btn-active");

    this.isPickingUpColor = true;
    $target.addClass("btn-active");
    this.canvas.style.cursor = "crosshair";
  }
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
