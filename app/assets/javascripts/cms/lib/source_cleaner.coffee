class @Cms_Source_Cleaner extends SS_Module
  @extend Cms_Editor_Module

  @config = {}

  @render: ->
    $(".source-cleaner").on "click", ->
      html = Cms_Source_Cleaner.getEditorHtml()
      html = Cms_Source_Cleaner.cleanUp(html)
      Cms_Source_Cleaner.setEditorHtml(html)

  @cleanUp: (html) ->
    actions = {
      "remove":
        "tag": @removeTag
        "attribute": @removeAttribute
        "string": @removeString
        "regexp": @removeRegex
      "replace":
        "tag": @replaceTag
        "attribute": @replaceAttribute
        "string": @replaceString
        "regexp": @replaceRegexp
    }

    for i, v of Cms_Source_Cleaner.config["source_cleaner"]
      action_type = v["action_type"]
      target_type = v["target_type"]
      target_value = v["target_value"]
      replaced_value = v["replaced_value"]

      try
        action = actions[action_type][target_type]
        html = action(html, "value": target_value, "replaced": replaced_value)
      catch e
        console.warn(action_type, target_type, e)

    html

  @removeTag: (html, opts) ->
    value = opts["value"]
    ret = $('<div>' + html + '</div>')
    $(ret).find(value).remove()
    ret.html()

  @removeAttribute: (html, opts) ->
    value = opts["value"]
    ret = $('<div>' + html + '</div>')
    $(ret).find("*").removeAttr(value)
    ret.html()

  @removeString: (html, opts) ->
    value = opts["value"]
    ret = html
    regxp = new RegExp(Cms_Source_Cleaner.regexpEscape(value), "g")
    html.replace(regxp, "")

  @removeRegexp: (html, opts) ->
    value = opts["value"]
    ret = html
    regxp = new RegExp(value, "g")
    html.replace(regxp, "")

  @replaceTag: (html, opts) ->
    value = opts["value"]
    replaced = opts["replaced"]
    ret = $('<div>' + html + '</div>')
    $(ret).find(value).sort(
      (a, b) ->
        $(b).parents().length - $(a).parents().length
    ).each ->
      ele = $(document.createElement(replaced))
      ele.html($(this).html())
      $.each this.attributes, ->
      	ele.attr(this.name, this.value)
      $(this).replaceWith(ele)
    ret.html()

  @replaceAttribute: (html, opts) ->
    value = opts["value"]
    replaced = opts["replaced"]
    ret = $('<div>' + html + '</div>')
    $(ret).find("*").attr(value, replaced)
    ret.html()

  @replaceString: (html, opts) ->
    value = opts["value"]
    replaced = opts["replaced"]
    ret = html
    regxp = new RegExp(Cms_Source_Cleaner.regexpEscape(value), "g")
    html.replace(regxp, replaced)

  @replaceRegexp: (html, opts) ->
    value = opts["value"]
    replaced = opts["replaced"]
    ret = html
    regxp = new RegExp(value, "g")
    html.replace(regxp, replaced)

  @regexpEscape: (s) ->
    s.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

