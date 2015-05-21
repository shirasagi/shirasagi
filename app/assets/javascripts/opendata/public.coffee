class @Opendata_Dataset

  @getPointUrl: ->
    location.pathname.replace(/\.\w+$/, '/point.html')

  @renderPoint: ->
    $.ajax
      url: Opendata_Dataset.getPointUrl()
      success: (data)->
        $(".point").html data

  @renderPointButton: ->
    $(".point .update").click (event)->
      $.ajax
        url: Opendata_Dataset.getPointUrl()
        type: "POST"
        success: (data)->
          $(".point").html data
      event.preventDefault()
