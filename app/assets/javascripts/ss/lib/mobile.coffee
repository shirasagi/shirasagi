class @SS_Mobile
  @render: ->
    if navigator.userAgent.match(/(Android|iPad|iPhone)/)
      if $.cookie("ss-mobile") == "pc"
        head = $("head")
        head.children("meta[name=viewport]").remove()
        head.append '<meta name="viewport" content="width=1024" />'
        vr = $("#ss-mb")
        vr.html('<a href="#" onclick="return SS_Mobile.unset()">' + vr.text() + '</a>').show()
      else
        vr = $("#ss-pc")
        vr.html('<a href="#" onclick="return SS_Mobile.setPc()">' + vr.text() + '</a>').show()

  @unset: ->
    $.removeCookie("ss-mobile", { expires: 7, path: '/' })
    location.reload()
    return false

  @setPc: ->
    $.cookie("ss-mobile", "pc", { expires: 7, path: '/' })
    location.reload()
    return false
