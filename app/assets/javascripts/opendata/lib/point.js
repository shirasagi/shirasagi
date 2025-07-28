this.Opendata_Point = (function () {
  function Opendata_Point() {
  }

  Opendata_Point.dispatchEvent = function (el, name) {
    el.dispatchEvent(new CustomEvent(name, { bubbles: true, cancelable: true, composed: true }));
  };

  Opendata_Point.render = function (url) {
    $.ajax({
      url: url,
      success: function (data) {
        var $point = $(".point");
        $point.html(data);
        Opendata_Point.pointLoaded = true;
        $point[0].dispatchEvent(new CustomEvent("opendata:pointLoaded", { bubbles: true, cancelable: true, composed: true }));
      }
    });
  };

  Opendata_Point.renderButton = function () {
    $(".point .update").on("click", function (event) {
      var data, url;
      url = event.target.href;
      data = {
        authenticity_token: $(event.target).data('auth-token')
      };
      $.ajax({
        url: url,
        data: data,
        type: "POST",
        success: function (data) {
          var $point = $(".point");
          $point.html(data);
          Opendata_Point.pointLoaded = true;
          $point[0].dispatchEvent(new CustomEvent("opendata:pointLoaded", { bubbles: true, cancelable: true, composed: true }));
        }
      });
      event.preventDefault();
    });
  };

  return Opendata_Point;

})();
