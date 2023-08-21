Gws_Affair_Menu = function (current, sessionKey) {
  this.current = current;
  this.sessionKey = sessionKey;
  this.render();
};

Gws_Affair_Menu.prototype.render = function() {
  var self = this;
  this.initNarrow();
  $(".toggle-narrow-page").on("click", function(){
    var $a = $(this);
    var $h3 = $a.closest("h3");
    var $narrow = $h3.next(".narrow-page");

    if ($narrow.hasClass("show")) {
      self.hideNarrow($narrow, "fast");
      $a.removeClass("down");
      self.updateSession();
    } else {
      self.showNarrow($narrow, "fast");
      $a.addClass("down");
      self.updateSession();
    }
    return false;
  });
};

Gws_Affair_Menu.prototype.showNarrow = function(ele, duration) {
  $(ele).removeClass("hide");
  $(ele).addClass("show");
  $(ele).show(duration);
};

Gws_Affair_Menu.prototype.hideNarrow = function(ele, duration) {
  $(ele).removeClass("show");
  $(ele).hide(duration, function(){
    $(this).addClass("hide");
  });
};

Gws_Affair_Menu.prototype.getSession = function() {
  var navi = sessionStorage.getItem(this.sessionKey);
  if (navi) {
    navi = navi.split(",")
  } else {
    navi = [];
  }
  return navi;
};

Gws_Affair_Menu.prototype.updateSession = function() {
  var navi = $(".narrow-page[data-navi].show").map(function() { return $(this).attr("data-navi") }).toArray();
  sessionStorage.setItem(this.sessionKey, navi.join(","));
};

Gws_Affair_Menu.prototype.initNarrow = function () {
  var self = this;
  $(".toggle-narrow-page").each(function(){
    var $a = $(this);
    var $h3 = $a.closest("h3");
    var $narrow = $h3.next(".narrow-page");

    var navi = self.getSession();
    var content = $narrow.attr("data-navi");

    if (navi.includes(content) || content == "<%= current_navi %>") {
      self.showNarrow($narrow);
      $a.addClass("down");
    } else {
      self.hideNarrow($narrow);
      $a.removeClass("down");
    }
  });
  self.updateSession();
};
