class @Inquiry_Form
  @rendered = false

  @render: ->
    return if Inquiry_Form.rendered
    $('.inquiry-form input').on 'keypress', (ev) ->
      if (ev.which and ev.which is 13) or (ev.keyCode and ev.keyCode is 13)
        false
      else
        true
    Inquiry_Form.rendered = true
