function Gws_Contrast() {
}

Gws_Contrast.prototype.render = function() {
  var _this = this;

  $('#user-contrast-menu').data('load', function() {
    _this.loadContrasts();
  });
};

Gws_Contrast.prototype.loadContrasts = function() {
  console.log('Gws_Contrast#loadContrasts');
};
