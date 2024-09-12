function Gws_Schedule_Integration() {
}

Gws_Schedule_Integration.paths = {};

Gws_Schedule_Integration.render = function() {
  var $el = $(".gws-schedule-box");
  if (! $el[0]) {
    return;
  }

  $el.find(".send-message").each(function() {
    $(this).on("click", function(_ev) {
      var userId = $(this).closest("[data-user-id]").data("user-id");
      location.href = Gws_Schedule_Integration.paths.newMemoMessage + "?to%5B%5D=" + userId;
    });
  });

  $el.find(".send-email").each(function() {
    $(this).on("click", function(_ev) {
      var email = $(this).closest("[data-email]").data("email");
      location.href = Gws_Schedule_Integration.paths.newWebmail + "?item%5Bto%5D=" + encodeURIComponent(email);
    });
  });

  $el.find(".copy-email-address").each(function() {
    $(this).on("click", function(ev) {
      $(this).closest("[data-email]").find(".clipboard-copy-button").trigger("click");

      $(".dropdown, .dropdown-menu").removeClass('active');

      ev.preventDefault();
      return false;
    });
  });
};
