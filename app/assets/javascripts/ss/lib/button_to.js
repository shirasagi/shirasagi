function SS_ButtonTo() {
}

SS_ButtonTo.rendered = false;

SS_ButtonTo.render = function() {
  if (SS_ButtonTo.rendered) {
    return;
  }

  $(document).on("click", "[data-ss-button-to-action],[data-ss-button-to-method]", function(ev) {
    SS_ButtonTo.invokeAction(ev);
  });
  SS_ButtonTo.rendered = true;
};

SS_ButtonTo.invokeAction = function(ev) {
  var $button = $(ev.target);
  var action = $button.data('ss-button-to-action');
  var method = $button.data('ss-button-to-method') || 'post';
  method = method.toString().toLowerCase();

  var $form = $("<form/>", { action: action, method: method === "get" ? "get" : "post" });
  if (method !== "get") {
    $form.append($("<input/>", {
      name: "authenticity_token", value: $('meta[name="csrf-token"]').attr('content'), type: "hidden"
    }));
  }
  if (method !== 'get' && method !== 'post') {
    $form.append($("<input/>", { name: "_method", value: method, type: "hidden" }));
  }

  var params = $button.data('ss-button-to-params');
  if (params) {
    for (var key in params) {
      var value = params[key];
      $form.append($("<input/>", { name: key, value: value, type: "hidden" }));
    }
  }

  var beforeSendEvent = jQuery.Event("ss:beforeSend");
  beforeSendEvent.$form = $form;
  $button.trigger(beforeSendEvent);
  if (beforeSendEvent.isDefaultPrevented()) {
    ev.preventDefault();
    return;
  }

  var confirmation = $button.data('ss-confirmation');
  if (confirmation) {
    if (!confirm(confirmation)) {
      ev.preventDefault();
      return;
    }
  }

  ev.preventDefault();
  $form.appendTo(document.body).submit();
};
