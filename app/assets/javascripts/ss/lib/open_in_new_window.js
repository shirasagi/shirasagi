function SS_OpenInNewWindow() {
}

SS_OpenInNewWindow.rendered = false;
SS_OpenInNewWindow.defaultTarget = '_blank';
SS_OpenInNewWindow.minWidth = 800;
SS_OpenInNewWindow.defaultWidth = function() {
  var width = window.innerWidth / 2;
  if (width < SS_OpenInNewWindow.minWidth) {
    width = SS_OpenInNewWindow.minWidth;
  }
  return width;
};

SS_OpenInNewWindow.defaultHeight = function() {
  return window.innerHeight;
};

SS_OpenInNewWindow.render = function() {
  if (SS_OpenInNewWindow.rendered) {
    return;
  }

  $(document).on("click", ".ss-open-in-new-window", function(ev) {
    if (SS_OpenInNewWindow.openInNewWindow(ev.target)) {
      SS_OpenInNewWindow.closeDropdown(ev.target);
      ev.preventDefault();
      return false;
    }
  });

  window.addEventListener("message", function (ev) {
    SS_OpenInNewWindow.processMessages(ev.data, ev.source);
  }, false);

  SS_OpenInNewWindow.rendered = true;
};

SS_OpenInNewWindow.openInNewWindow = function(el) {
  var href = el.dataset["href"] || el.getAttribute("href");
  if (!href) {
    return false;
  }

  var target = el.dataset["target"] || el.getAttribute("target") || SS_OpenInNewWindow.defaultTarget;
  // var width = el.dataset["width"] || SS_OpenInNewWindow.defaultWidth();
  var width;
  if ("width" in el.dataset) {
    try {
      width = JSON.parse(el.dataset["width"]);
      if (typeof width === "object") {
        if ("pixel" in width) {
          width = width.pixel;
        } else if ("ratio" in width) {
          width = Math.floor(window.innerWidth * width.ratio);
        } else if ("screenRatio" in width) {
          width = Math.floor(window.screen.availWidth * width.screenRatio);
        } else {
          width = undefined;
        }
      }
    } catch (_error) {
      width = undefined;
    }
    console.log(width);
  }
  if (!width) {
    width = SS_OpenInNewWindow.defaultWidth();
  }
  var height = el.dataset["height"] || SS_OpenInNewWindow.defaultHeight();

  window.open(href, target, 'resizable=yes,scrollbars=yes,width=' + width + ',height=' + height);
  return true;
};

SS_OpenInNewWindow.closeDropdown = function(el) {
  var $el = $(el);
  $el.closest(".dropdown-menu.active").removeClass('active');
  $el.closest(".dropdown.active").removeClass('active');
};

SS_OpenInNewWindow.processMessages = function(messages, sourceWindow) {
  if (!$.isArray(messages)) {
    return;
  }

  for (var i = 0; i < messages.length; i++) {
    var message = messages[i];

    if (!message) {
      return;
    }
    if (!('type' in message)) {
      return;
    }

    var type = message.type;
    if (type === "ss.notice") {
      var notice = message.payload.body;
      var noticeOptions = message.payload.options;

      SS.notice(notice, noticeOptions);
    }
    if (type === "ss.close") {
      if (sourceWindow) {
        sourceWindow.close();
      }
    }
  }
};
