class @SS_Font
  @size = null # %

  @render: ->
    @size = parseInt(Cookies.get("ss-font")) || 100
    @set(@size) if @size != 100

    vr = $("#ss-medium")
    vr.html '<a href="#" onclick="return SS_Font.set(100)">' + vr.text() + '</a>'
    vr = $("#ss-small")
    vr.html '<a href="#" onclick="return SS_Font.set(false)">' + vr.text() + '</a>'
    vr = $("#ss-large")
    vr.html '<a href="#" onclick="return SS_Font.set(true)">' + vr.text() + '</a>'

  @set: (size) ->
    if size == true
      size = @size + 20
      return false if size > 200
    else if size == false
      size = @size - 20
      return false if size < 60

    @size = size
    $("body").css "font-size", size + "%"
    Cookies.set("ss-font", size, { expires: 7, path: '/' })
    return false
