this.Gws_Presence_User = (function () {
  function Gws_Presence_User() {}

  Gws_Presence_User.render = function () {
    // selector
    $(document).on("click", function() {
      $(".presence-state-selector").hide();
        return true;
    });
    $(".presence-state-selector").on("click", function() {
      return false;
    });
    $(".presence-state-selector [data-value]").on("click", function() {
      var $this = $(this);
      var $presenceState = $this.closest(".presence-state-selector");
      var id = $presenceState.attr("data-id");
      var url = $presenceState.attr("data-url");
      var value = $this.attr("data-value");
      $.ajax({
        url: url,
        type: "POST",
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          presence_state: value,
        },
        success: function(data) {
          Gws_Presence_User.changedState(id, data);
          $(".presence-state-selector").hide();
        },
        error: function (xhr, status, error) {
          alert(xhr.responseJSON.join("\n"));
        },
      });
      return false;
    });
    $(".editable .select-presence-state,.editable .presence-state").on("click", function(){
      $(".presence-state-selector").closest("li.portlet-item").css("z-index", 0);
      $(".presence-state-selector").hide();
      $(this).closest("li.portlet-item").css("z-index", 1000);
      $(this).closest("td").find(".presence-state-selector").show();
      return false;
    });
    // ajax-text-field
    $(".ajax-text-field").on("click", function(){
      Gws_Presence_User.toggleForm(this);
      return false;
    });
    $(".ajax-text-field").next(".editicon").on("click", function(){
      $(this).prev(".ajax-text-field").trigger('click');
      return false;
    })
  };

  Gws_Presence_User.changedState = function (id, data) {
    var presence_state = data["presence_state"] || "";
    var presence_state_label = data["presence_state_label"];
    var presence_state_style = data["presence_state_style"];
    var state = $("tr[data-id=" + id + "] .presence-state");
    var selector = $("tr[data-id=" + id + "] .presence-state-selector");

    state.removeClass();
    state.addClass('presence-state');
    state.addClass(presence_state_style);
    state.text(presence_state_label);

    selector.find('[data-value="' + presence_state + '"] .selected-icon').css('visibility', 'visible');
    selector.find('[data-value!="' + presence_state + '"] .selected-icon').css('visibility', 'hidden');
  }

  Gws_Presence_User.toggleForm = function (ele) {
    var state = $(ele).attr("data-tag-state");
    var original = $(ele).attr("data-original-tag");
    var form = $(ele).attr("data-form-tag");
    var value = $(ele).text() || $(ele).val();
    var name = $(form).attr("name");
    var id = $(form).attr("data-id");
    var url = $(form).attr("data-url");
    var errorOccurred = false;

    if (state == "original") {
      form = $(form);
      form.attr("data-original-tag", $(ele).attr("data-original-tag"));
      form.attr("data-form-tag", $(ele).attr("data-form-tag"));
      form.val(value);
      form.focusout(function (e) {
        if (errorOccurred) {
          return true;
        }
        var data = {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
        };
        data[name] = $(form).val();
        $.ajax({
          url: url,
          type: "POST",
          data: data,
          success: function(data) {
            $(form).val(data[name]);
            Gws_Presence_User.toggleForm(form);
          },
          error: function (xhr, status, error) {
            alert(xhr.responseJSON.join("\n"));
            errorOccurred = true;
          },
        });
        return false;
      });
      form.keypress(function (e) {
        if (e.which == SS.KEY_ENTER) {
          var data = {
            _method: 'put',
            authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          };
          data[name] = $(form).val();
          $.ajax({
            url: url,
            type: "POST",
            data: data,
            success: function(data) {
              $(form).val(data[name]);
              Gws_Presence_User.toggleForm(form);
            },
            error: function (xhr, status, error) {
              alert(xhr.responseJSON.join("\n"));
              errorOccurred = true;
            },
          });
          return false;
        }
      });
      var replaced = form.uniqueId();
      $(ele).replaceWith(form);
      $(replaced).focus();
    }
    else {
      original = $(original).text(value);
      original.attr("data-original-tag", $(ele).attr("data-original-tag"));
      original.attr("data-form-tag", $(ele).attr("data-form-tag"));
      original.on("click", function(){
        Gws_Presence_User.toggleForm(this);
        return false;
      });
      original.uniqueId();
      $(ele).replaceWith(original);

      // support same name's ajax-text-field
      $(".ajax-text-field[data-id='" + original.attr("data-id") + "'][data-name='" + original.attr("data-name") + "']").text(value);
    }
  };

  return Gws_Presence_User;
})();

this.Gws_Presence_User_Reload = (function () {
  function Gws_Presence_User_Reload() {}

  Gws_Presence_User_Reload.render = function (opts) {
    if (opts == null) {
      opts = {};
    }

    var table_url = opts["url"];
    var paginate_params = opts["paginate_params"];
    var page = opts["page"];

    $(".group-users .reload").on("click", function () {
      var param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
        "page": page
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time).show();
          time.show();
        }
      });
    });
    $(".group-users .list-head .search").on("submit", function () {
      var param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time);
          time.show();
        },
        error: function (xhr, status, error) {
          $(".group-users .data-table-wrap").html("");
        }
      });
      return false;
    });
  }

  return Gws_Presence_User_Reload;
})();
