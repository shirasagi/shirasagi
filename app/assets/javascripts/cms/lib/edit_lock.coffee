class @Cms_EditLock
  constructor: (selector, lock_url, unlock_url) ->
    @selector = selector
    @lock_url = lock_url
    @unlock_url = unlock_url
    @unloading = false
    @interval = 2 * 60 * 1000
    $(window).bind('beforeunload', @releaseLock)
    @refreshLock()

  updateView: (lock_until) ->
    $("#{@selector} .lock_until").text('')
    return unless lock_until
    dateParts = []
    dateParts.push(lock_until.getFullYear())
    dateParts.push(('0' + (lock_until.getMonth() + 1)).slice(-2))
    dateParts.push(lock_until.getDate())

    timeParts = []
    timeParts.push(lock_until.getHours())
    timeParts.push(('0' + lock_until.getMinutes()).slice(-2))

    $("#{@selector} .lock_until").text(dateParts.join('/') + ' ' + timeParts.join(':'))

  refreshLock: =>
    return if @unloading
    $.ajax
      type: "GET"
      url: @lock_url
      dataType: "json"
      cache: false
      statusCode:
        200: (data, status, xhr) =>
          if (data.lock_until)
            @updateView(new Date(data.lock_until))
          else
            @updateView(null)
    setTimeout(@refreshLock, @interval)

  releaseLock: =>
    @unloading = true
    $.ajax
      type: "POST"
      url: @unlock_url
      dataType: "json"
      data:
        _method: "delete"
      async: false
    # must return void
    return
