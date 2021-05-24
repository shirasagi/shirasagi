this.SS_AjaxFile = (function () {
  function SS_AjaxFile(el, options) {
    this.$el = $(el || "#ajax-box");
    this.options = options || {};

    this.render();
  }

  SS_AjaxFile.errors = {
    entityTooLarge: "request entity is too large"
  }

  SS_AjaxFile.defaultFileSelectHandler = function() {
    var promisses = [];
    var fileViews = [];

    for (var i = 0; i < arguments.length; i++) {
      var $argument = $(arguments[i]);
      var url = $argument.attr('href');
      if (!url) {
        continue;
      }

      var filename = $argument.data("humanized-name");

      promisses.push($.ajax({
        url: url,
        success: function(html) {
          fileViews.push({ name: filename, html: html });
        },
        error: function(xhr, status, data) {
          if (xhr.responseJSON && Array.isArray(xhr.responseJSON)) {
            alert(["== Error =="].concat(xhr.responseJSON).join("\n"));
          } else {
            alert(["== Error =="].concat(xhr.statusText).join("\n"));
          }
        }
      }));
    }

    $.when.apply($, promisses).done(function () {
      fileViews.sort(function(a,b) {
        if (a.name < b.name) return 1;
        if (a.name > b.name) return -1;
        return 0;
      });

      for (var i = 0; i < fileViews.length; i++) {
        $("#selected-files").prepend(fileViews[i].html);
      }

      $.colorbox.close();
    });
  };

  SS_AjaxFile.prototype.render = function() {
    var self = this;

    self.$el.on("submit", "form.user-file", function (ev) {
      var submitted = "attach";
      if (ev.originalEvent && ev.originalEvent.submitter) {
        submitted = ev.originalEvent.submitter.dataset.submitted;
      }
      var $form = $(this);

      var params = {
        url: $form.attr("action") + ".json",
        dataType: "json",
        success: function(data, textStatus, xhr) {
          self.submitSuccess(submitted, data);
        },
        error: function (xhr, status, error) {
          self.submitError(xhr);
        }
      };

      $form.ajaxSubmit(params);
      ev.preventDefault();
    });

    self.$el.on("click", ".user-files .select", function(ev) {
      self.selectFiles(this);

      ev.preventDefault();
      return false;
    });

    SS.ajaxDelete(self.$el, ".user-files .delete");

    var resizing = $('#file-resizing').val();
    if (resizing) {
      var label = $('#file-resizing').attr('data-label');
      var option = $('<option>').val(resizing).text(label).prop('selected', true);
      $('select.image-size').append(option);
    }
  };

  SS_AjaxFile.prototype.submitSuccess = function(submitted, data) {
    var self = this;

    $("<div />").load(self.options.indexPath, function () {
      var $userFiles = $(this).find(".user-files");
      if ($userFiles[0]) {
        // TODO: 差分だけをアニメーションつきで insert するとかっこよくなる
        self.$el.find(".user-files").html($userFiles.html());
        SS.renderInBox(self.$el);
      }

      self.$el.find("form.user-file [type='file']").val(null).trigger("change");
      self.$el.find("form.user-file .image-size").val(null).trigger("change");

      if (submitted === "attach") {
        self.attachFiles(data);
      }
    });
  };

  SS_AjaxFile.prototype.attachFiles = function(data) {
    var self = this;

    if (!Array.isArray(data) || data.length == 0) {
      return;
    }

    var elements = [];
    $.each(data, function(index, file) {
      var item = self.$el.find(".user-files .select[data-id='" + file._id + "']");
      elements.push(item);
    });

    self.selectFiles.apply(self, elements);
  };

  SS_AjaxFile.prototype.submitError = function(xhr) {
    if (xhr.status === 413) {
      alert(["== Error =="].concat(SS_AjaxFile.errors.entityTooLarge).join("\n"));
    } else {
      try {
        alert(["== Error =="].concat(xhr.responseJSON).join("\n"));
      } catch(_error) {
        alert(["== Error =="].concat(xhr.statusText).join("\n"));
      }
    }
  };

  SS_AjaxFile.prototype.selectFiles = function() {
    if (SS_SearchUI.anchorAjaxBox) {
      var handler = SS_SearchUI.anchorAjaxBox.data('on-select');
      if (handler) {
        $.each(arguments, function() {
          handler($(this));
        });

        return true;
      }
    }

    SS_AjaxFile.defaultFileSelectHandler.apply(SS_AjaxFile, arguments);
  };

  return SS_AjaxFile;

})();
