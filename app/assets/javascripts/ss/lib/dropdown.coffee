class @SS_Dropdown
  @render: ->
    $("button.dropdown").each ->
      target = $(this).parent().find(".dropdown-container")[0]
      dropdown = new SS_Dropdown(this, { target: target })
      SS_Dropdown.dropdown = dropdown unless SS_Dropdown.dropdown

  @openDropdown: ->
    SS_Dropdown.dropdown.openDropdown() if SS_Dropdown.dropdown

  @closeDropdown: ->
    SS_Dropdown.dropdown.closeDropdown() if SS_Dropdown.dropdown

  @toggleDropdown: ->
    SS_Dropdown.dropdown.toggleDropdown() if SS_Dropdown.dropdown

  constructor: (elem, options) ->
    @elem = $(elem)
    @options = options
    @target = $(@options.target)
    @bindEvents()

  bindEvents: ->
    @elem.on "click", (e) =>
      @toggleDropdown()
      @cancelEvent(e)

    # focusout
    $(document).on "click", (e) =>
      if e.target != @elem && e.target != @target
        @closeDropdown()

    @elem.on "keydown", (e) =>
      if e.keyCode == 27  # ESC
        @closeDropdown()
        @cancelEvent(e)

  openDropdown: ->
    @target.show()

  closeDropdown: ->
    @target.hide()

  toggleDropdown: ->
    @target.toggle()

  cancelEvent: (e) ->
    e.preventDefault()
    e.stopPropagation()
    false
