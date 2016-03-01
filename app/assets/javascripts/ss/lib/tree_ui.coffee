class @SS_TreeUI
  @openImagePath  = "/assets/img/tree-open.png"
  @closeImagePath = "/assets/img/tree-close.png"

  @render: (tree)->
    root = []
    $(tree).find("tbody tr").each ->
      root.push(parseInt($(this).attr("data-depth")))
    root = Math.min.apply(null, root)
    return unless Number.isInteger(root) && root > 0

    parent = null
    $(tree).find("tbody tr").each ->
      td = $(this).find(".expandable")
      depth = parseInt($(this).attr("data-depth"))

      td.prepend('<img src="' + SS_TreeUI.closeImagePath + '" alt="toggle" class="toggle">')
      if (parent && depth > parent)
        $(this).hide()
        for i in [root...depth]
          td.prepend('<span class="padding">')

      parent = depth unless parent
      parent = depth if parent > depth

      d = parseInt($(this).next("tr").attr("data-depth")) || 0
      i = $(this).find(".toggle:first")
      i.replaceWith('<span class="padding">') if (d == 0 || depth >= d)

    $(tree).find(".toggle").on "mousedown mouseup", (e) ->
      e.stopPropagation()
      return false

    $(tree).find(".toggle").on "click", (e) ->
      tr    = $(this).closest("tr")
      img   = tr.find(".toggle:first")
      depth = parseInt(tr.attr("data-depth"))
      SS_TreeUI.toggleImage(img)
      tr.nextAll("tr").each ->
        d = parseInt($(this).attr("data-depth"))
        i = $(this).find(".toggle:first")
        if (depth >= d)
          return false
        if ((depth + 1) == d)
          $(this).toggle()
          SS_TreeUI.closeImage(i)
        else
          $(this).hide()
          SS_TreeUI.closeImage(i)
      e.stopPropagation()
      return false

  @toggleImage = (img) ->
    if img.attr("src") == SS_TreeUI.openImagePath
      SS_TreeUI.closeImage(img)
    else if img.attr("src") == SS_TreeUI.closeImagePath
      SS_TreeUI.openImage(img)

  @openImage = (img) ->
    img.attr("src", SS_TreeUI.openImagePath)

  @closeImage = (img) ->
    img.attr("src", SS_TreeUI.closeImagePath)
