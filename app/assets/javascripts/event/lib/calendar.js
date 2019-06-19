this.Event_Calendar = (function () {
  function Event_Calendar() {
  }

  Event_Calendar.render = function (url) {
    var paginate;
    paginate = function (a) {
      var month, year;
      year = $(a).attr("data-year");
      month = $(a).attr("data-month");
      return $.ajax({
        type: "GET",
        url: url + "?year=" + year + "&month=" + month,
        cache: false,
        success: function (res, status) {
          var html;
          html = "<div>" + res + "</div>";
          $(".event-calendar").replaceWith($(html).find(".event-calendar"));
          $(".calendar-nav a.paginate").on('click', function () {
            paginate(this);
            return false;
          });
        },
        error: function (xhr, status, error) {
        },
        complete: function (xhr, status) {
          $(".event-calendar .calendar").hide().fadeIn('fast');
        }
      });
    };
    return $(".calendar-nav a.paginate").on('click', function () {
      paginate(this);
      return false;
    });
  };

  return Event_Calendar;

})();
