## event form

$ ->
  if $("form .mod-event").length
    $(".mod-event button:button.add-date").click ->
      if $(".mod-event dd.dates").length < Event_Form.maxTermForm
        Event_Form.cloneTermForm()
      return

    $(".mod-event button:button.clear").click ->
      start = $(this).parent("dd").find(".start").val()
      close = $(this).parent("dd").find(".close").val()
      if start != "" ||  close != ""
        if confirm(Event_Form.deleteMessage)
          Event_Form.clearTermForm $(this).parent("dd")
      else
        Event_Form.clearTermForm $(this).parent("dd")
      return

    $("form").submit ->
      terms = $(".mod-event dd.dates")
      dates = []

      for term in terms
        add = Event_Form.termToDates($(term).find(".start").val(), $(term).find(".close").val())
        dates = dates.concat(add)

      $(".mod-event .event-dates").val Event_Form.datesToString(dates)
      return

#    $(".mod-event input.date").datepicker
#      dateFormat: "yy/mm/dd",
#      yearRange: "-10:+10"

    Event_Form.setStoredDates()
    return

class @Event_Form
  @maxTermForm = 10
  @deleteMessage = "イベント日を削除してよろしいですか？"

  @dateToString: (date)->
    yy = date.getYear()
    mm = date.getMonth() + 1
    dd = date.getDate()
    yy += 1900  if yy < 2000
    mm = "0" + mm  if mm < 10
    dd = "0" + dd  if dd < 10
    return yy + "/" + mm + "/" + dd

  @datesToString: (dates)->
    tmp = []
    for d in dates
      j = 0
      while j < tmp.length
        break if @dateToString(d) == @dateToString(tmp[j])
        j++
      tmp.push d if j == tmp.length
    dates = tmp

    dates.sort (a, b) ->
      a - b

    setstr = ""
    for d in dates
      setstr += @dateToString(d)
      setstr += "\r\n"

    return setstr

  @isValidDate: (date)->
    return false  if Object::toString.call(date) isnt "[object Date]"
    if not isNaN(date.getTime()) and date.getYear() > 0
      return true
    else
      return false

  @termToDates: (start, close)->
    startDate = new Date(start)
    closeDate = new Date(close)
    dates = []

    if @isValidDate(startDate) && @isValidDate(closeDate)
      d = new Date(startDate)
      while d <= closeDate
        dates.push new Date(d)
        d.setDate d.getDate() + 1
    else if @isValidDate(startDate)
      dates.push new Date(startDate)
    else if @isValidDate(closeDate)
      dates.push new Date(closeDate)

    return dates

  @datesToTerm: (dates)->
    terms = []
    term  = []

    for d, i in dates
      term.push d
      tommorow = new Date(d)
      tommorow.setDate tommorow.getDate() + 1
      if i + 1 < dates.length and @dateToString(dates[i + 1]) isnt @dateToString(tommorow)
        terms.push [ term[0], term[term.length - 1] ]
        term = []

    if term.length >= 1
      terms.push [ term[0], term[term.length - 1] ]

    return terms

  @setStoredDates: ()->
    stored = $(".mod-event .event-dates").val().split(/\r\n|\n/)
    dates  = []

    for d in stored
      date = new Date(d)
      dates.push(date) if @isValidDate(date)

    terms = @datesToTerm(dates)

    for term, i in terms
      @cloneTermForm() if i != 0
      $(".mod-event dd.dates:last").find(".start").val @dateToString(term[0])
      $(".mod-event dd.dates:last").find(".close").val @dateToString(term[1])

  @cloneTermForm: ()->
    cln = $(".mod-event dd.dates:last").clone(false).insertAfter($(".mod-event dd.dates:last"))
    cln.find(".start").val ""
    cln.find(".close").val ""

    cln.find(".clear").click ->
      start = $(this).parent("dd").find(".start").val()
      close = $(this).parent("dd").find(".close").val()
      if start != "" ||  close != ""
        if confirm(Event_Form.deleteMessage)
          Event_Form.clearTermForm $(this).parent("dd")
      else
        Event_Form.clearTermForm $(this).parent("dd")
      return

    $(".mod-event .date").attr("id", "").datetimepicker
      lang: "ja"
      timepicker: false
      format: "Y/m/d"
      #yearRange: "-10:+10"

    if $(".mod-event dd.dates").length >= @maxTermForm
      $(".mod-event button:button.add-date").attr "disabled", true

  @clearTermForm: (ele)->
    ele.find(".start").val ""
    ele.find(".close").val ""
    ele.remove() if $(".mod-event dd.dates").length > 1

    if $(".mod-event dd.dates").length < @maxTermForm
      $(".mod-event button:button.add-date").removeAttr "disabled"
