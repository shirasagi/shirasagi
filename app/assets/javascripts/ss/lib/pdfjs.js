this.SS_Pdfjs = (function () {
  function SS_Pdfjs(el) {
    this.$pdfViewerWarp = $(el);
    this.viewerPath = "/assets/js/pdfjs-dist/web/ss-viewer.html";
  }

  SS_Pdfjs.prototype.render = function () {
    var self = this;
    $("a.ext-pdf").each(function() {
      var $a = $(this);
      var $icon = $('<i class="material-icons md-18 picture-as-pdf">picture_as_pdf</i>');
      $icon.on("click", function(){
        var $iframe = $("<iframe class='ss-pdf-inline'></iframe>");
        var title = $a.text();
        var file = $a.attr("href");
        if ($a.data("original-href")) {
          file = $a.data("original-href");
        }
        var src = self.viewerPath + "?file=" + file;
        $iframe.attr("src", src);
        $iframe.attr("title", title);
        $iframe.hide();

        self.$pdfViewerWarp.html("");
        self.$pdfViewerWarp.append($iframe);

        $iframe.on("load", function(){
          $iframe.contents().find("button#fullscreen").on("click", function(){
            location.href = $iframe.attr("src");
            return false;
          })
          $iframe.contents().find("button#close").on("click", function(){
            self.$pdfViewerWarp.html("");
            return false;
          })
        });

        $iframe.fadeIn();
        return false;
      });
      $(this).append($icon);
    });
  };

  return SS_Pdfjs;
})();
