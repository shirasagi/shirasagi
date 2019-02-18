var extend = function (child, parent) {
    for (var key in parent) {
      if (hasProp.call(parent, key)) child[key] = parent[key];
    }

    function ctor() {
      this.constructor = child;
    }

    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
  },
  hasProp = {}.hasOwnProperty;

this.Cms_Source_Cleaner = (function (superClass) {
  extend(Cms_Source_Cleaner, superClass);

  function Cms_Source_Cleaner() {
    return Cms_Source_Cleaner.__super__.constructor.apply(this, arguments);
  }

  Cms_Source_Cleaner.extend(Cms_Editor_Module);

  Cms_Source_Cleaner.config = {};

  Cms_Source_Cleaner.render = function (el, options) {
    if (!el) {
      el = ".source-cleaner";
    }
    if (!options) {
      options = {};
    }

    $(el).on("click", function () {
      var html = Cms_Source_Cleaner.getEditorHtml(options.editor);
      html = Cms_Source_Cleaner.cleanUp(html);
      return Cms_Source_Cleaner.setEditorHtml(html, { id: options.editor });
    });
  };

  Cms_Source_Cleaner.cleanUp = function (html) {
    var action, action_type, actions, e, i, ref, replaced_value, target_type, target_value, v;
    actions = {
      "remove": {
        "tag": this.removeTag,
        "attribute": this.removeAttribute,
        "string": this.removeString,
        "regexp": this.removeRegex
      },
      "replace": {
        "tag": this.replaceTag,
        "attribute": this.replaceAttribute,
        "string": this.replaceString,
        "regexp": this.replaceRegexp
      }
    };
    ref = Cms_Source_Cleaner.config["source_cleaner"];
    for (i in ref) {
      v = ref[i];
      action_type = v["action_type"];
      target_type = v["target_type"];
      target_value = v["target_value"];
      replaced_value = v["replaced_value"];
      try {
        action = actions[action_type][target_type];
        html = action(html, {
          "value": target_value,
          "replaced": replaced_value
        });
      } catch (_error) {
        e = _error;
        console.warn(action_type, target_type, e);
      }
    }
    return html;
  };

  Cms_Source_Cleaner.removeTag = function (html, opts) {
    var ret, value;
    value = opts["value"];
    ret = $('<div>' + html + '</div>');
    $(ret).find(value).remove();
    return ret.html();
  };

  Cms_Source_Cleaner.removeAttribute = function (html, opts) {
    var ret, value;
    value = opts["value"];
    ret = $('<div>' + html + '</div>');
    $(ret).find("*").removeAttr(value);
    return ret.html();
  };

  Cms_Source_Cleaner.removeString = function (html, opts) {
    var regxp, ret, value;
    value = opts["value"];
    ret = html;
    regxp = new RegExp(Cms_Source_Cleaner.regexpEscape(value), "g");
    return html.replace(regxp, "");
  };

  Cms_Source_Cleaner.removeRegexp = function (html, opts) {
    var regxp, ret, value;
    value = opts["value"];
    ret = html;
    regxp = new RegExp(value, "g");
    return html.replace(regxp, "");
  };

  Cms_Source_Cleaner.replaceTag = function (html, opts) {
    var replaced, ret, value;
    value = opts["value"];
    replaced = opts["replaced"];
    ret = $('<div>' + html + '</div>');
    $(ret).find(value).sort(function (a, b) {
      return $(b).parents().length - $(a).parents().length;
    }).each(function () {
      var ele;
      ele = $(document.createElement(replaced));
      ele.html($(this).html());
      $.each(this.attributes, function () {
        return ele.attr(this.name, this.value);
      });
      return $(this).replaceWith(ele);
    });
    return ret.html();
  };

  Cms_Source_Cleaner.replaceAttribute = function (html, opts) {
    var replaced, ret, value;
    value = opts["value"];
    replaced = opts["replaced"];
    ret = $('<div>' + html + '</div>');
    $(ret).find("*").attr(value, replaced);
    return ret.html();
  };

  Cms_Source_Cleaner.replaceString = function (html, opts) {
    var regxp, replaced, ret, value;
    value = opts["value"];
    replaced = opts["replaced"];
    ret = html;
    regxp = new RegExp(Cms_Source_Cleaner.regexpEscape(value), "g");
    return html.replace(regxp, replaced);
  };

  Cms_Source_Cleaner.replaceRegexp = function (html, opts) {
    var regxp, replaced, ret, value;
    value = opts["value"];
    replaced = opts["replaced"];
    ret = html;
    regxp = new RegExp(value, "g");
    return html.replace(regxp, replaced);
  };

  Cms_Source_Cleaner.regexpEscape = function (s) {
    return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
  };

  return Cms_Source_Cleaner;

})(SS_Module);

