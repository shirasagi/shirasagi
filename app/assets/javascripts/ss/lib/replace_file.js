this.SS_ReplaceFile = (function () {
  function SS_ReplaceFile(el) {
    this.$el = $(el);
  }

  var _instance = null;

  SS_ReplaceFile.instance = function() {
    if (_instance) {
      return _instance;
    }

    _instance = new SS_ReplaceFile("#cboxContent");

    $(document).one("cbox_cleanup", function() { SS_ReplaceFile.destroy(); });

    return _instance;
  };

  SS_ReplaceFile.destroy = function() {
    _instance = null
  };

  SS_ReplaceFile.sendBeaconAndReload = function(data) {
    if (!data || data.length === 0) {
      location.reload();
      return;
    }

    var promises = [];
    $.each(data, function(k, v){
      var url = v["url"] + "?_update=" + v["updated_to_i"];
      var promise = $.get(url);
      promises.push(promise);
    });

    $.when.apply($, promises).always(function() {
      setTimeout(function() { location.reload(); }, 0);
    });
  };

  SS_ReplaceFile.showError = function(xhr, status, error) {
    var fullMessages = [ "== Error ==" ];
    if (xhr.responseText) {
      fullMessages.push(xhr.responseText);
    }
    alert(fullMessages.join("\n"));
  };

  SS_ReplaceFile.prototype.renderEdit = function(confirmUrl) {
    var $ajaxBox = this.$el.find("#ajax-box");
    var $ajaxForm = this.$el.find('#ajax-form')
    var $loading = $(SS.loading).hide();
    $ajaxBox.after($loading);

    $ajaxForm.ajaxForm({
      type: "post",
      dataType: 'json',
      beforeSend: function() {
        $ajaxBox.hide();
        $loading.show();
      },
      success: function(data) {
        // $("#cboxLoadedContent").load(confirmUrl);
        $("<div />").load(confirmUrl, function(data, status) {
          $.colorbox.prep($(this).contents());
        });
      },
      error: function(xhr, status, error) {
        $ajaxBox.show();
        $loading.hide();

        SS_ReplaceFile.showError(xhr, status, error);
      }
    });
  };

  SS_ReplaceFile.prototype.renderConfirm = function() {
    var $ajaxBox = this.$el.find("#ajax-box");
    var $ajaxForm = this.$el.find('#ajax-form')
    var $loading = $(SS.loading).hide();
    $ajaxBox.after($loading);

    $ajaxForm.ajaxForm({
      dataType: 'json',
      beforeSend: function() {
        $ajaxBox.hide();
        $loading.show();
      },
      success: function(data) {
        SS_ReplaceFile.sendBeaconAndReload(data);
      },
      error: function(xhr, status, error) {
        $ajaxBox.show();
        $loading.hide();

        SS_ReplaceFile.showError(xhr, status, error);
      }
    });
  };

  SS_ReplaceFile.prototype.renderHistory = function(restoreConfirmation, deleteConfirmation, historiesUrl) {
    var $ajaxBox = this.$el.find("#ajax-box");
    var $loading = $(SS.loading).hide();

    $ajaxBox.after($loading);

    $ajaxBox.find(".restore").on("click", function() {
      if (!confirm(restoreConfirmation)) {
        return false;
      }

      var url = $(this).attr("href");
      $.ajax({
        url: url,
        type: "post",
        dataType: 'json',
        beforeSend: function() {
          $ajaxBox.hide();
          $loading.show();
        },
        success: function(data) {
          SS_ReplaceFile.sendBeaconAndReload(data);
        },
        error: function(xhr, status, error) {
          $ajaxBox.show();
          $loading.hide();

          SS_ReplaceFile.showError(xhr, status, error)
        }
      });

      return false;
    });

    $ajaxBox.find(".destroy").on("click", function() {
      if (!confirm(deleteConfirmation)) {
        return false;
      }

      var url = $(this).attr("href");
      $.ajax({
        url: url,
        type: "post",
        dataType: 'json',
        beforeSend: function() {
          $ajaxBox.hide();
          $loading.show();
        },
        success: function(data) {
          // $("#cboxLoadedContent").load(historiesUrl);
          $("<div />").load(historiesUrl, function(data, status) {
            $.colorbox.prep($(this).contents());
            SS_SearchUI.anchorAjaxBox.trigger("ss:ajaxRemoved");
          });
        },
        error: function(xhr, status, error) {
          $ajaxBox.show();
          $loading.hide();

          SS_ReplaceFile.showError(xhr, status, error)
        }
      });

      return false;
    });
  };

  return SS_ReplaceFile;
})();
