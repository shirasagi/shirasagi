this.SS_ImageViewer = (function () {
  function SS_ImageViewer() {}

  SS_ImageViewer.render = function (options) {
    var default_options = { prefixUrl: "/assets/js/openseadragon/images/" };
    var options = $.extend(default_options, options)
    var viewer = OpenSeadragon(options);
    return viewer;
  };

  return SS_ImageViewer;
})();
