this.SS_Tooltips = (function () {
  function SS_Tooltips() {
  }

  SS_Tooltips.render = function (ttips) {
    $(document).on("click", ttips, function (ev) {
      var css, cur, top, hgt, style, cbox;
      ev.preventDefault();
      ev.stopPropagation();
      ttips = $(ttips);
      ttips.find("ul").hide();
      cur = $(this);
      hgt = cur.find("ul").outerHeight();
      top = cur.offset().top;

      cbox = $(this).closest("#colorbox").offset();
      if (cbox) {
        top = top - cbox.top;
      }

      cur.find("ul").removeClass("tooltip-top");
      cur.find("ul").removeClass("tooltip-bottom");
      if (top - hgt < 0) {
        cur.find("ul").css("bottom", (hgt * (-1) - 15) + "px");
        cur.find("ul").addClass("tooltip-bottom");
        css = "ul:after {border: 8px solid transparent; border-bottom-color:#fff; bottom:" + (hgt - 5) + "px;}";
      } else {
        cur.find("ul").css("bottom", "18px");
        cur.find("ul").addClass("tooltip-top");
        css = "ul:after {border: 8px solid transparent; border-top-color:#fff; bottom:-13px;}";
      }
      style = $("<style>").append(document.createTextNode(css));
      $(".tooltip ul").hide();
      $(".tooltip ul style").remove();
      cur.find("ul").append(style);
      cur.find("ul").show();
    });
    $(document).click(function (ev) {
      ttips = $(ttips);
      if (!ttips.is($(ev.target).closest("div,span"))) {
        $(".tooltip ul").hide();
      }
    });
  };

  return SS_Tooltips;

})();

