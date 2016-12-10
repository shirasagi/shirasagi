class @Webmail_Mail
  @render: ->
    @renderList()
    @renderDetail()
    @renderForm()

  @renderList: ->
    $(".list-head .search").on "click", ->
      $('.webmail-mail-search').animate( { height: 'toggle' }, 'fast' )
    $(".webmail-mail-search .reset").on "click", ->
      $(".webmail-mail-search input[type=text]").val("")
      $(".webmail-mail-search .search").click()

    $(".list-head .update-all").on "click", ->
      checked = $(".list-item input:checkbox:checked").map ->
        $(this).val()
      return false if checked.length == 0

      url = $(this).data('href')
      return Webmail_Mail.updateMail(url, ids: checked, redirect: location.href)

    $(".list-head .move-all, .list-head .copy-all").on "click", ->
      checked = $(".list-item input:checkbox:checked").map ->
        $(this).val()
      return false if checked.length == 0

      url = $(this).data('href')
      wrap = $(this).parent()
      if wrap.find('.dropdown-menu').length == 0
        navi = $('.main-navi').clone().addClass('dropdown-menu')
        navi.find('.mailbox-unseen-count').remove()
        navi.find('a').click ->
          return Webmail_Mail.updateMail(url, ids: checked, dst: $(this).data('name'))
        wrap.append(navi)

    $(".icon-star").on "click", ->
      star = $(this)
      if $(this).hasClass('icon-star--on')
        url = star.attr('href') + '/unset_star'
        chk = false
      else
        url = star.attr('href') + '/set_star'
        chk = true

      $.ajax
        url: url
        method: 'POST'
        data:
          _method: 'put'
        success: (data, a, b)->
          if chk
            star.removeClass('icon-star--off')
            star.addClass('icon-star--on')
          else
            star.removeClass('icon-star--on')
            star.addClass('icon-star--off')
      return false

  @renderDetail: ->
    $("img[data-src]").each ->
      $(this).attr('src', $(this).data('src'))
      $(this).data('src', '')

    $(".update-mail").on "click", ->
      url = $(this).attr('href')
      return Webmail_Mail.updateMail(url)
    $(".print-mail").on "click", ->
      $('body').addClass('webmail-print')
      window.print()
      return false

  @updateMail: (url, opts = {})->
    token = $('meta[name="csrf-token"]').attr('content')
    form = $("<form/>", action: url, method: "post")
    form.append($("<input/>", type: "hidden", name: "_method", value: "put" ))
    form.append($("<input/>", type: "hidden", name: "authenticity_token", value: token ))
    if opts['redirect']
      form.append($("<input/>", type: "hidden", name: "redirect", value: opts['redirect'] ))
    if opts['dst']
      form.append($("<input/>", type: "hidden", name: "dst", value: opts['dst'] ))
    if opts['ids']
      for id in opts['ids']
        form.append($("<input/>", name: "ids[]", value: id, type: "hidden"))
    form.appendTo(document.body).submit()
    return false

  @renderForm: ->
    $('#item_format').change ->
      Webmail_Mail.renderBodyForm($(this).val())
    Webmail_Mail.renderBodyForm($('#item_format').val())

    $('#item_signature').change ->
      return if $(this).val() == ""
      if $('#item_format').val() == "html"
        CKEDITOR.instances['item_html'].insertText($(this).val())
      else
        Webmail_Mail.insertText($("#item_text"), $(this).val())
      $(this).val("")

  @renderBodyForm: (format)->
    if format == 'html'
      $('.body-text').hide()
      $('.body-html').show()
    else
      $('.body-html').hide()
      $('.body-text').show()

  @insertText: (field, str)->
    field.focus()
    if (navigator.userAgent.match(/MSIE/))
      r = document.selection.createRange()
      r.text = str
      r.select()
    else
      s = field.val()
      p = field.get(0).selectionStart
      np = p + str.length
      field.val(s.substr(0, p) + str + s.substr(p))
      field.get(0).setSelectionRange(np, np)
