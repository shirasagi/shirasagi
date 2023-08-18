this.SS_Debug = (function () {
  function SS_Debug() {
  }

  SS_Debug.doing = false;

  SS_Debug.run = function () {
    $("#log").val("");
    $("#err").val("");
    $("#queue").val("0");
    this.doing = true;
    return this.connect_url(location.href);
  };

  SS_Debug.stop = function () {
    return this.doing = false;
  };

  SS_Debug.connect_url = function (url, ref) {
    var path, patt, queue, view;
    if (ref == null) {
      ref = null;
    }
    if (this.doing === false) {
      return;
    }
    if (url === void 0) {
      return;
    }
    if (url === "") {
      return;
    }
    if (url.match(/^#/)) {
      return;
    }
    if (url.match(/^[^h]\w+:/)) {
      return;
    }
    if (url.match(/\/logout$/)) {
      return;
    }
    if (url.match(/^\/\..*?\/uploader/)) {
      return;
    }
    if (url.match(/^\/\..*?\/db/)) {
      return;
    }
    if (url.match(/^\/\..*?\/history/)) {
      return;
    }
    url = url.replace(/#.*/, "");
    if (url.match(/^https?:/)) {
      if (!url.match(new RegExp("^https?://" + location.host))) {
        return;
      }
      url = url.replace(/^https?:\/\/.*?\//, "/");
    } else if (url.match(/^[^\/]/)) {
      url = ref.replace(/\/[^\/]*$/, "") + ("/" + url);
    }
    view = $("#log");
    path = url;
    path = path.replace(/\d+/g, "123");
    path = path.replace(/\?s(\[|\%123).*/g, "");
    patt = path.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    if (view.val().match(new RegExp("^" + patt + "$", "m"))) {
      return true;
    }
    view.val(view.val() + path + "\n");
    view.scrollTop(view[0].scrollHeight - view.height());
    queue = $("#queue");
    queue.val(parseInt(queue.val()) + 1);
    return $.ajax({
      type: "GET",
      url: url,
      dataType: "html",
      cache: false,
      success: function (data, status, xhr) {
        queue.val(parseInt(queue.val()) - 1);
        return $($.parseHTML(data.replace(/<img[^>]*>/ig, ""))).find("a").each(function () {
          if (!$(this).is('[href]')) {
            return true;
          }
          return SS_Debug.connect_url($(this).attr("href"), url);
        });
      },
      error: function (xhr, status, error) {
        queue.val(parseInt(queue.val()) - 1);
        view = $("#err");
        view.val(view.val() + " [" + xhr.status + "] " + url + " - Referer: " + ref + "\n");
        return view.scrollTop(view[0].scrollHeight - view.height());
      }
    });
  };

  return SS_Debug;

})();
