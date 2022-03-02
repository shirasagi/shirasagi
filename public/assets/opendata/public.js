

this.Opendata_Point = (function () {
  function Opendata_Point() {
  }

  Opendata_Point.render = function (url) {
    return $.ajax({
      url: url,
      success: function (data) {
        return $(".point").html(data);
      }
    });
  };

  Opendata_Point.renderButton = function () {
    return $(".point .update").on("click", function (event) {
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
          return $(".point").html(data);
        }
      });
      return event.preventDefault();
    });
  };

  return Opendata_Point;

})();
