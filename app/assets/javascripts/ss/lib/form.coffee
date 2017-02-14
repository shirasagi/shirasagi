class @SS_Form
  # Disable enter key[13]
  #
  # @example
  #   SS_Form.disableEnterKey();
  #   SS_Form.disableEnterKey('#item_subject');
  #
  # @param [String] selector
  # @return [Boolean]
  @disableEnterKey: (selector = null) ->
    if selector
      $(selector).on 'keypress', (ev) ->
        return ev.which != 13
    else
      $(document).on 'keypress', 'input:not(.allow-submit)', (ev) ->
        return ev.which != 13
