function Webmail_Address_Autocomplete() {}

Webmail_Address_Autocomplete.createSelectedElement = function(name, email, label) {
  var icon = $("<i class=\"material-icons md-18 md-inactive deselect\">close</i>");
  icon.on("click", function() {
    return $(this).closest("span").remove();
  });
  var input = $("<input type=\"hidden\" name=\"" + name + "\" value=\"" + label + "\">");
  var span = $("<span></span>").text(label);
  if (!Webmail_Address_Autocomplete.validateEmail(email)) {
    span.addClass("invalid-address");
  }
  span.append(icon);
  span.append(input);
  return span;
};

// ref: https://stackoverflow.com/questions/46155/how-to-validate-email-address-in-javascript
Webmail_Address_Autocomplete.validateEmail = function(email) {
  var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return re.test(email);
};

Webmail_Address_Autocomplete.render = function(selector, opts) {
  if (opts == null) {
    opts = {};
  }

  var autocomplete = $(selector).find(".autocomplete");
  var names = opts["names"] || [];
  var labels = opts["labels"] || names;
  var values = opts["values"];

  if (names.length > 0) {
    $(autocomplete).autocomplete({
      source: function(request, response) {
        var matcher, matches;
        matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
        matches = [];
        $.each(names, function(i, v) {
          v = v.label || v.value || v;
          if (matcher.test(v)) {
            return matches.push(labels[i]);
          }
        });
        return response(matches);
      }
    });
  }

  var commitAddress = function($input) {
    var label = $input.val();
    var value = (values && values[label]) ? values[label] : label;
    var selected = $input.closest(".webmail-mail-form-address").find(".selected-address");
    if (!label) {
      return false;
    }

    var span = Webmail_Address_Autocomplete.createSelectedElement($input.attr("data-name"), value, label);
    selected.append(span);
    $input.val("");
  };

  $(autocomplete).on('keypress', function(e) {
    if (e.which !== 13) {
      return true;
    }

    commitAddress($(this));
    return false;
  }).on('blur', function() {
    commitAddress($(this));
  });

  $(selector).find(".selected-address").sortable({
    connectWith: ".selected-address",
    placeholder: "placeholder",
    dropOnEmpty: true,
    cursor: "pointer",
    receive: function(e, ui) {
      var name, selected;
      selected = $(this).closest(".webmail-mail-form-address").find(".selected-address");
      name = $(ui.item).closest(".webmail-mail-form-address").find(".autocomplete").attr("data-name");
      return $(ui.item).find("input").attr("name", name);
    }
  });

  $(selector).find(".selected-address .deselect").each(function() {
    $(this).on("click", function() {
      $(this).closest("span").remove();
    });
  });
};
