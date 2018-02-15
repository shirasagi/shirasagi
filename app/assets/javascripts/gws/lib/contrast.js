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
    _this.changeContrast($this.data('text-color'), $this.data('color'));
    Gws_Contrast.setContrastId(_this.opts.siteId, $this.data('id'));

    ev.preventDefault();
    ev.stopPropagation();
  });
};

Gws_Contrast.prototype.loadContrasts = function() {
  if (this.$el.data('loadedAt')) {
    return;
  }

  var _this = this;
  $.ajax({
    url: this.opts.url,
    type: 'GET',
    dataType: 'json',
    success: function(data) { _this.renderContrasts(data); },
    error: function(xhr, status, error) { _this.showError(xhr); },
    complete: function(xhr, status) { _this.completeLoading(xhr); }
  });
};

Gws_Contrast.prototype.completeLoading = function(xhr) {
  this.$el.data('loadedAt', Date.now());
  this.$el.find('.gws-contrast-loading').closest('li').hide();
};

Gws_Contrast.prototype.showError = function(xhr) {
  this.$el.append($('<li/>').html('<div class="gws-contrast-error">' + this.opts.loadError + '</div>'));
};

Gws_Contrast.prototype.renderContrasts = function(data) {
  var _this = this;
  $.each(data, function() {
    var $a = $('<a />', { class: 'gws-contrast-item', data: { id: this._id['$oid'], 'text-color': this.text_color, color: this.color } });
    $a.html(this.name)
    _this.$el.append($('<li/>').html($a));
  });
};

Gws_Contrast.prototype.changeContrast = function(color, textColor) {
  if (! this.$style) {
    this.$style = $('<style/>', { type: 'text/css' });
    $('head').append(this.$style);
  }

  this.$style.html(this.template.replace(/:color/g, color).replace(/:background/g, textColor));
};
