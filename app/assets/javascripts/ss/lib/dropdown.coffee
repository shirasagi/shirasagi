class @SS_DropDown
  @render: ->
    $("button.dropdown").each ->
      dropdown = new SS_DropDown(this, { target: $(this).siblings(".dropdown-target")[0] })
      SS_DropDown.dropdown = dropdown unless SS_DropDown.dropdown

  @openDropdown: ->
    SS_DropDown.dropdown.openDropdown() if SS_DropDown.dropdown

  @closeDropdown: ->
    SS_DropDown.dropdown.closeDropdown() if SS_DropDown.dropdown

  @toggleDropdown: ->
    SS_DropDown.dropdown.toggleDropdown() if SS_DropDown.dropdown

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
