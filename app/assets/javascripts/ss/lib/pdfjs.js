this.SS_Pdfjs = (function () {
  function SS_Pdfjs(el) {
    this.$pdfViewerWarp = $(el);
    this.viewerPath = "/assets/js/pdfjs-legacy-dist/web/ss-viewer.html";
    this.links = [];
    this.current = 0;
  }

  SS_Pdfjs.prototype.render = function () {
    var self = this;
    $("a.ext-pdf:visible").each(function(idx) {
      var $a = $(this);
      var file = $a.attr("href");

      $a.attr("data-index", idx);
      if ($a.data("original-href")) {
        file = $a.data("original-href");
      }

      var regexp = new RegExp('^' + location.origin);
      if (!file.match(/^\//) && !file.match(regexp)) {
        return false
      }

      var $openLink = $('<a class="open-pdf btn"></a>');
      $openLink.text(i18next.t("ss.links.open_in_new_tab"));
      $openLink.attr("target", "_blank");
      $openLink.attr("href", file);

      $a.on("click", function(){
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
        self.current = parseInt($(this).attr("data-index"));

        $iframe.on("load", function(){
          // title
          $iframe.contents().find("#pdf-title").text($iframe.attr("title"));

          // next pdf, prev pdf
          var $prevPdf = $iframe.contents().find("button#previous-pdf");
          var $nextPdf = $iframe.contents().find("button#next-pdf");
          if (self.links.length == 1) {
            $prevPdf.attr("disabled", "disabled");
            $nextPdf.attr("disabled", "disabled");
          } else {
            if (self.current == 0) {
              $prevPdf.attr("disabled", "disabled");
              $nextPdf.removeAttr("disabled");
            }
            if (self.current == (self.links.length - 1)) {
              $prevPdf.removeAttr("disabled");
              $nextPdf.attr("disabled", "disabled");
            }
          }
          $iframe.contents().find("button#previous-pdf").on("click", function(){
            self.current -= 1;
            self.links[self.current].trigger("click");
            return false;
          });
          $iframe.contents().find("button#next-pdf").on("click", function(){
            self.current += 1;
            self.links[self.current].trigger("click");
            return false;
          });

          // close
          $iframe.contents().find("button#close").on("click", function(){
            self.$pdfViewerWarp.html("");
            return false;
          });

          // fullscreen
          //$iframe.contents().find("button#fullscreen").on("click", function(){
          //  location.href = $iframe.attr("src");
          //  return false;
          //});
        });

        $iframe.fadeIn();
        return false;
      });

      $($a).after($openLink);
      self.links.push($a);
    });

    if (self.links.length) {
      self.links[self.current].trigger("click");
    }
  };

  return SS_Pdfjs;
})();
