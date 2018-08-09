this.SS_Mobile = (function () {
  function SS_Mobile() {
  }

  SS_Mobile.render = function () {
    var head, vr;
    if (navigator.userAgent.match(/(Android|iPad|iPhone)/)) {
      if (Cookies.get("ss-mobile") === "pc") {
        head = $("head");
        head.children("meta[name=viewport]").remove();
        head.append('<meta name="viewport" content="width=1024" />');
        vr = $("#ss-mb");
        return vr.html('<a href="#" onclick="return SS_Mobile.unset()" class="btn btn-secondary">' + vr.text() + '</a>').show();
      } else {
        vr = $("#ss-pc");
        return vr.html('<a href="#" onclick="return SS_Mobile.setPc()" class="btn btn-secondary">' + vr.text() + '</a>').show();
      }
    }
  };

  SS_Mobile.unset = function () {
    Cookies.remove("ss-mobile", {
      path: '/'
    });
    location.reload();
    return false;
  };

  SS_Mobile.setPc = function () {
    Cookies.set("ss-mobile", "pc", {
      expires: 7,
      path: '/'
    });
    location.reload();
    return false;
  };

  return SS_Mobile;

})();

