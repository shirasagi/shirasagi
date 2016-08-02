class @Opendata_Point
  @render: (url)->
    $.ajax
      url: url
      success: (data)->
        $(".point").html data

  @renderButton: ->
    $(".point .update").click (event)->
      url = event.target.href
      data =
        authenticity_token: $(event.target).data('auth-token')
      $.ajax
        url: url
        data: data
        type: "POST"
        success: (data)->
          $(".point").html data
      event.preventDefault()
