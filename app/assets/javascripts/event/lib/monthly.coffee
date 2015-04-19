class @Event_Monthly
  @render: ->
    $(".event-pages-filter a[data-id!=all]").on 'click', ->
      $(".event-pages-filter a[data-id=all]").removeClass("clicked")

      if $(this).hasClass("clicked")
         $(this).removeClass("clicked")
      else
        $(this).addClass("clicked")

      dataIds = []
      $(".event-pages-filter a.clicked").each ->
        dataId = parseInt($(this).attr("data-id"))
        dataIds.push(dataId) unless isNaN(dataId)

      $("#event-list .page").each ->
        pageDataIds = []
        $.each $(this).attr("data-id").split(" "), ->
          pageDataIds.push(parseInt(this))

        visible = false
        $.each dataIds, ->
          if $.inArray(parseInt(this), pageDataIds) >= 0
            visible = true
            return false

        if visible
          $(this).show()
        else
          $(this).hide()
      return false

    $(".event-pages-filter a[data-id=all]").on 'click', ->
      unless $(this).hasClass("clicked")
        $(this).addClass("clicked")
        $(".event-pages-filter a[data-id!=all]").removeClass("clicked")
        $("#event-list .page").show()
      return false
