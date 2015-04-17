class @SS_Tooltips
  @render: (ttips)->
    $(document).on "click", ttips, (ev) ->
      ttips = $(ttips)
      ttips.find("ul").hide()
      cur = $(this)
      hgt = cur.find("ul").outerHeight()
      ofs = cur.offset()
      if ofs.top - hgt < 0
        cur.find("ul").css("bottom", (hgt * (-1) - 15) + "px")
        css = "ul:after {border: 8px solid transparent; border-bottom-color:#fff; bottom:" + (hgt - 5) + "px;}"
        style = $("<style>").append(document.createTextNode(css))
        ttips.find("ul style").remove()
        cur.find("ul").append(style)
      else
        cur.find("ul").css("bottom", "18px")
        css = "ul:after {border: 8px solid transparent; border-top-color:#fff; bottom:-13px;}"
        style = $("<style>").append(document.createTextNode(css))
        ttips.find("ul style").remove()
        cur.find("ul").append(style)
      cur.find("ul").show()

    $(document).click (ev) ->
      ttips = $(ttips)
      ttips.find("ul").hide() unless ttips.is($(ev.target).closest("div,span"))
