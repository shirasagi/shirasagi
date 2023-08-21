this.Cms = (function () {
  function Cms() {
  }

  Cms.render = function () {
    Cms.renderPreviewLinks();
  };

  Cms.renderPreviewLinks = function () {
    $('.cms-preview-sp').on('click', function(ev) {
      window.open($(this).attr('href'), '_blank', 'resizable=yes,scrollbars=yes,width=520,height=800');
      ev.preventDefault();
    });
    $('.cms-preview-mb').on('click', function(ev) {
      window.open($(this).attr('href'), '_blank', 'resizable=yes,scrollbars=yes,width=350,height=600');
      ev.preventDefault();
    });
  }

  return Cms;

})();
