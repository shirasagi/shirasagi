class @Event_Calendar
  @render: (url) ->
    paginate = (a)->
      year  = $(a).attr("data-year")
      month = $(a).attr("data-month")
      $.ajax {
        type: "GET",
        url: "#{url}?year=#{year}&month=#{month}",
        cache: false,
        success: (res, status) ->
          html = "<div>" + res + "</div>"
          $(".event-calendar").html($(html).find(".event-calendar"))
          $(".calendar-nav a.paginate").on 'click', ->
            paginate(this)
            return false
          return
        error: (xhr, status, error) ->
          return
        complete: (xhr, status) ->
          $(".event-calendar .calendar").hide().fadeIn('fast')
          return
      }

    $(".calendar-nav a.paginate").on 'click', ->
      paginate(this)
      return false
