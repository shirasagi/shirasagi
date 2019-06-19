this.SS_Tooltips = (function () {
  function SS_Tooltips() {
  }

  SS_Tooltips.render = function (ttips) {
    $(document).on("click", ttips, function (ev) {
      var css, cur, hgt, ofs, style;
      ev.preventDefault();
      ev.stopPropagation();
      ttips = $(ttips);
      ttips.find("ul").hide();
      cur = $(this);
      hgt = cur.find("ul").outerHeight();
      ofs = cur.offset();
      if (ofs.top - hgt < 0) {
        cur.find("ul").css("bottom", (hgt * (-1) - 15) + "px");
        css = "ul:after {border: 8px solid transparent; border-bottom-color:#fff; bottom:" + (hgt - 5) + "px;}";
      } else {
        cur.find("ul").css("bottom", "18px");
        css = "ul:after {border: 8px solid transparent; border-top-color:#fff; bottom:-13px;}";
      }
      style = $("<style>").append(document.createTextNode(css));
      ttips.find("ul style").remove();
      cur.find("ul").append(style);
      return cur.find("ul").show();
    });
    return $(document).click(function (ev) {
      ttips = $(ttips);
      if (!ttips.is($(ev.target).closest("div,span"))) {
        return ttips.find("ul").hide();
      }
    });
  };

  return SS_Tooltips;

})();

