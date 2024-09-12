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
        success: function (res, _status) {
          var html;
          html = "<div>" + res + "</div>";
          $(".event-calendar").replaceWith($(html).find(".event-calendar"));
          $(".calendar-nav a.paginate").on('click', function () {
            paginate(this);
            return false;
          });
        },
        error: function (_xhr, _status, _error) {
        },
        complete: function (_xhr, _status) {
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
