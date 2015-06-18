class @SS_Debug
  @doing = false

  @run: ->
    $("#log").val("")
    $("#err").val("")
    $("#queue").val("0")
    @doing = true
    @connect_url location.href

  @stop: ->
    @doing = false

  @connect_url: (url, ref = null)->
    return if @doing == false
    return if url == undefined
    return if url == ""
    return if url.match(/^#/)
    return if url.match(/^[^h]\w+:/)
    return if url.match(/\/logout$/)
    return if url.match(/^\/\..*?\/uploader/)
    return if url.match(/^\/\..*?\/db/)
    return if url.match(/^\/\..*?\/history/)
    url = url.replace(/#.*/, "")

    if url.match(/^https?:/)
      return unless url.match(new RegExp("^https?://" + location.host))
      url = url.replace(/^https?:\/\/.*?\//, "/")
    else if url.match(/^[^\/]/)
      url = ref.replace(/\/[^\/]*$/, "") + "/#{url}"
      #return

    view = $("#log")
    path = url
    path = path.replace(/\d+/g, "123")
    path = path.replace(/\?s(\[|\%123).*/g, "")
    patt = path.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    return true if view.val().match(new RegExp("^" + patt + "$", "m"))
    view.val view.val() + path + "\n"
    view.scrollTop view[0].scrollHeight - view.height()

    queue = $("#queue")
    queue.val parseInt(queue.val()) + 1

    $.ajax {
      type: "GET", url: url, dataType: "html", cache: false
      success: (data, status, xhr)->
        queue.val parseInt(queue.val()) - 1
        $($.parseHTML(data.replace(/<img[^>]*>/ig,""))).find("a").each ->
          return true unless $(this).is('[href]')
          SS_Debug.connect_url $(this).attr("href"), url
      error: (xhr, status, error)->
        queue.val parseInt(queue.val()) - 1
        view = $("#err")
        view.val view.val() + " [" + xhr.status + "] " + url + " - Referer: " + ref + "\n"
        view.scrollTop view[0].scrollHeight - view.height()
    }
