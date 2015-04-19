class @Ads_Banner
  # randomize banners
  @randomize: (selector) ->
    wrap = $(selector)
    list = wrap.find("a")
    list = list.sort ->
      return Math.random() - .5
    list.each ->
      wrap.append $(this)

#  ## puts access log
#  @countHandle: ->
#    $(".ads-banners a").click (e) ->
#      $.ajax
#        url: $(this).data("count")
