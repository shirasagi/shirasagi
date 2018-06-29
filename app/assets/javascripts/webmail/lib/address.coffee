class @Webmail_Address_Autocomplete
  @createSelectedElement: (name, email, label) ->
    icon = $("<i class=\"material-icons md-18 md-inactive deselect\">close</i>")
    icon.on "click", ->
      $(this).closest("span").remove()
    input = $("<input type=\"hidden\" name=\"#{name}\" value=\"#{label}\">")
    span = $("<span></span>").text(label)
    unless Webmail_Address_Autocomplete.validateEmail(email)
      span.addClass("invalid-address")
    span.append(icon)
    span.append(input)
    span

  # ref: https://stackoverflow.com/questions/46155/how-to-validate-email-address-in-javascript
  @validateEmail: (email) ->
    re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test(email)

  @render:(selector, opts = {}) ->
    autocomplete = $(selector).find(".autocomplete")
    names = opts["names"] || []
    labels = opts["labels"] || names
    values = opts["values"]

    if names.length > 0
      $(autocomplete).autocomplete(
        source: (request, response) ->
          matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i")
          matches = []
          $.each(names, (i, v) ->
            v = v.label || v.value || v
            if matcher.test(v)
              matches.push(labels[i])
          )
          response(matches)
      )

    $(autocomplete).on 'keypress', (e) ->
      return true if e.which != 13

      label = $(this).val()
      value = `(values && values[label]) ? values[label] : label`
      selected = $(this).closest(".webmail-mail-form-address").find(".selected-address")
      return false unless label

      span = Webmail_Address_Autocomplete.createSelectedElement($(this).attr("data-name"), value, label)
      selected.append(span)
      $(this).val("")
      return false

    $(selector).find(".selected-address").sortable(
      connectWith: ".selected-address"
      placeholder: "placeholder"
      dropOnEmpty: true
      cursor: "pointer"
      receive: (e, ui)->
        selected = $(this).closest(".webmail-mail-form-address").find(".selected-address")
        name = $(ui.item).closest(".webmail-mail-form-address").find(".autocomplete").attr("data-name")
        $(ui.item).find("input").attr("name", name)
    )

    $(selector).find(".selected-address .deselect").each ->
      $(this).on "click", ->
        $(this).closest("span").remove()
