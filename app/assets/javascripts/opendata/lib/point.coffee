class @Opendata_Point

  @getUrl: ->
    location.pathname.replace(/\.\w+$/, '/point.html')

  @render: ->
    $.ajax
      url: Opendata_Point.getUrl()
      success: (data)->
        $(".point").html data

  @renderButton: ->
    $(".point .update").click (event)->
      $.ajax
        url: Opendata_Point.getUrl()
        type: "POST"
        success: (data)->
          $(".point").html data
      event.preventDefault()
