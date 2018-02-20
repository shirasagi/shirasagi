function Gws_Contrast(opts) {
  this.opts = opts;
  this.$el = $('#user-contrast-menu');
  this.template = 'body * { color: :color !important; border-color: :color !important; background: :background !important; }';

  this.render();
}

Gws_Contrast.getContrastId = function(siteId) {
  return Cookies.get("gws-contrast-" + siteId);
};

Gws_Contrast.setContrastId = function(siteId, contrastId) {
  Cookies.set("gws-contrast-" + siteId, contrastId, { expires: 7, path: '/' });
};

Gws_Contrast.removeContrastId = function(siteId) {
  Cookies.remove("gws-contrast-" + siteId);
};

Gws_Contrast.prototype.render = function() {
  var _this = this;

  this.$el.data('load', function() {
    _this.loadContrasts();
  });

  this.$el.on('click', '.gws-contrast-item', function(ev) {
    var $this = $(this);
    var id = $this.data('id');
    if (id === 'default') {
      _this.removeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.removeContrastId(_this.opts.siteId);
    } else {
      _this.changeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.setContrastId(_this.opts.siteId, id);
    }
    SS.notice(_this.opts.notice.replace(':name', $this.text()));

    ev.stopPropagation();
  });
};

Gws_Contrast.prototype.loadContrasts = function() {
  if (this.$el.data('loadedAt')) {
    this.checkActiveContrast();
    return;
  }

  var _this = this;
  $.ajax({
    url: this.opts.url,
    type: 'GET',
    dataType: 'json',
    success: function(data) { _this.renderContrasts(data); },
    error: function(xhr, status, error) { _this.showMessage(this.opts.loadError); },
    complete: function(xhr, status) { _this.completeLoading(xhr); }
  });
};

Gws_Contrast.prototype.completeLoading = function(xhr) {
  this.$el.data('loadedAt', Date.now());
  this.$el.find('.gws-contrast-loading').closest('li').hide();
};

Gws_Contrast.prototype.showMessage = function(message) {
  this.$el.append($('<li/>').html('<div class="gws-contrast-error">' + message + '</div>'));
};

Gws_Contrast.prototype.renderContrasts = function(data) {
  if (data.length === 0) {
    this.showMessage(this.opts.noContrasts);
    return;
  }

  this.renderContrast('default', this.opts.defaultContrast);

  var _this = this;
  $.each(data, function() {
    _this.renderContrast(this._id['$oid'], this.name, this.color, this.text_color);
  });

  this.checkActiveContrast();
};

Gws_Contrast.prototype.renderContrast = function(id, name, color, textColor) {
  var dataAttrs = { id: id };
  if (color) {
    dataAttrs.color = color;
  }
  if (textColor) {
    dataAttrs.textColor = textColor;
  }

  var $input = $('<input/>', { type: 'radio', name: 'gws-contrast-item', value: id });
  var $label = $('<label/>', { class: 'gws-contrast-item', data: dataAttrs });
  $label.append($input);
  $label.append('<span class="gws-contrast-name">' + name + '</span>');

  this.$el.append($('<li/>').append($label));
};

Gws_Contrast.prototype.checkActiveContrast = function() {
  var contrastId = Gws_Contrast.getContrastId(this.opts.siteId);
  if (! contrastId) {
    $('input[name="gws-contrast-item"]').val(['default']);
    return;
  }

  $('input[name="gws-contrast-item"]').val([contrastId]);
};

Gws_Contrast.prototype.changeContrast = function(textColor, color) {
  if (! this.$style) {
    this.$style = $('<style/>', { type: 'text/css' });
    $('head').append(this.$style);
  }

  this.$style.html(this.template.replace(/:color/g, textColor).replace(/:background/g, color));
};

Gws_Contrast.prototype.removeContrast = function() {
  if (! this.$style) {
    return;
  }

  this.$style.html('');
};
