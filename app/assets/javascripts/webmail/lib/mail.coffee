class @Webmail_Mail
  @render: ->
    @renderList()
    @renderDetail()

  @renderList: ->
    $(".list-head .update-all").on "click", ->
      checked = $(".list-item input:checkbox:checked").map ->
        $(this).val()
      return false if checked.length == 0

      url = $(this).data('href')
      return Webmail_Mail.updateMail(url, ids: checked, redirect: location.href)

  @renderDetail: ->
    $(".update-mail").on "click", ->
      url = $(this).attr('href')
      return Webmail_Mail.updateMail(url)

  @updateMail: (url, opts = {})->
    token = $('meta[name="csrf-token"]').attr('content')
    form = $("<form/>", action: url, method: "post")
    form.append($("<input/>", type: "hidden", name: "_method", value: "put" ))
    form.append($("<input/>", type: "hidden", name: "authenticity_token", value: token ))
    if opts['redirect']
      form.append($("<input/>", type: "hidden", name: "redirect", value: opts['redirect'] ))
    if opts['ids']
      for id in opts['ids']
        form.append($("<input/>", name: "ids[]", value: id, type: "hidden"))
    form.appendTo(document.body).submit()
    return false
