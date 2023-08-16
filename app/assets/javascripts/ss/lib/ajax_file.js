this.SS_AjaxFile = (function () {
  function SS_AjaxFile(el, options) {
    this.$el = $(el || "#ajax-file-box");
    this.options = options || {};

    this.render();
  }

  SS_AjaxFile.additionalFileResizings = [];
  SS_AjaxFile.firesEvents = false;

  SS_AjaxFile.errors = {
    entityTooLarge: "request entity is too large"
  }

  SS_AjaxFile.addFileResizing = function() {
    for (var i = 0; i < arguments.length; i++) {
      var argument = arguments[i];
      if (argument.default) {
        for (var j = 0; j < SS_AjaxFile.additionalFileResizings.length; j++) {
          if (SS_AjaxFile.additionalFileResizings[j].default) {
            SS_AjaxFile.additionalFileResizings[j].default = false;
          }
        }
      }

      SS_AjaxFile.additionalFileResizings.push(argument);
    }
  }

  SS_AjaxFile.defaultFileResizing = function () {
    for (var i = 0; i < SS_AjaxFile.additionalFileResizings.length; i++) {
      if (SS_AjaxFile.additionalFileResizings[i].default) {
        return SS_AjaxFile.additionalFileResizings[i].value;
      }
    }

    return null;
  };

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
            alert(["== Error(AjaxFile) =="].concat(xhr.responseJSON).join("\n"));
          } else {
            alert(["== Error(AjaxFile) =="].concat(xhr.statusText).join("\n"));
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
        },
        complete: function (xhr, status) {
          SS.enableFormElementsOnTimeoutSubmit();
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

    self.$el.on("click", ".user-files .delete", function(ev) {
      self.deleteFile(ev.target);

      ev.preventDefault();
      return false;
    });

    for (var i = 0; i < SS_AjaxFile.additionalFileResizings.length; i++) {
      var fileResizing = SS_AjaxFile.additionalFileResizings[i];
      var option = $('<option />').val(fileResizing.value).text(fileResizing.label);
      if (fileResizing.default) {
        option.prop('selected', true)
      }

      self.$el.find('form.user-file .image-size').append(option);
    }
  };

  SS_AjaxFile.prototype.submitSuccess = function(submitted, data) {
    var self = this;
    var loadUrl = (submitted === "attach") ? self.options.selectedFilesPath : self.options.indexPath;
    var indexOptions = self.options.pathOptions || {};

    if (submitted === "attach" && Array.isArray(data)) {
      var select_ids = $.map(data, function(v) { return v._id });
      indexOptions = Object.assign(indexOptions, { select_ids: select_ids });
    }

    if (Object.keys(indexOptions).length) {
      loadUrl += "?" + $.param(indexOptions);
    }

    $("<div />").load(loadUrl, function () {
      var $userFiles = $(this).find(".user-files");
      if ($userFiles[0]) {
        // TODO: 差分だけをアニメーションつきで insert するとかっこよくなる
        self.$el.find(".user-files").html($userFiles.html());
        SS.renderInBox(self.$el);
      }

      self.$el.find("form.user-file [type='file']").val(null).trigger("change");

      var defaultImageSize = null;
      for (var i = 0; i < SS_AjaxFile.additionalFileResizings.length; i++) {
        var fileResizing = SS_AjaxFile.additionalFileResizings[i];
        if (fileResizing.default) {
          defaultImageSize = fileResizing.value;
          break;
        }
      }
      self.$el.find("form.user-file .image-size").val(defaultImageSize).trigger("change");

      if (submitted === "attach") {
        self.attachFiles(data);
      } else {
        $.rails.enableFormElements(self.$el.find('form.user-file'));
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
      var item = self.$el.find(".user-files [data-id='" + file._id + "'] .select");
      elements.push(item);
    });

    self.selectFiles.apply(self, elements);
  };

  SS_AjaxFile.prototype.submitError = function(xhr) {
    var self = this;
    if (xhr.status === 413) {
      alert(["== Error(AjaxFile) =="].concat(SS_AjaxFile.errors.entityTooLarge).join("\n"));
    } else {
      try {
        alert(["== Error(AjaxFile) =="].concat(xhr.responseJSON).join("\n"));
      } catch(_error) {
        alert(["== Error(AjaxFile) =="].concat(xhr.statusText).join("\n"));
      }
    }

    $.rails.enableFormElements(self.$el.find('form.user-file'));
  };

  SS_AjaxFile.prototype.selectFiles = function() {
    if (SS_SearchUI.anchorAjaxBox) {
      if (SS_AjaxFile.firesEvents) {
        var event = $.Event("ss:ajaxFileSelected");
        SS_SearchUI.anchorAjaxBox.trigger(event, [ arguments ]);
        if (event.isDefaultPrevented()) {
          return;
        }
      }

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

  SS_AjaxFile.prototype.deleteFile = function(el) {
    if (!confirm(i18next.t('ss.confirm.delete'))) {
      return false;
    }

    var $el = $(el);
    $.ajax({
      type: "POST",
      data: "_method=delete",
      url: $el.attr("href") + ".json",
      dataType: "json",
      beforeSend: function () {
        $el.html(SS.loading);
      },
      success: function () {
        var $target;
        if ($el.data("remove")) {
          $target = $($el.data("remove"));
        } else {
          $target = $el.closest(".file-view")
        }

        $target.slideUp("fast", function() {
          $target.remove();
          if (SS_AjaxFile.firesEvents && SS_SearchUI.anchorAjaxBox) {
            SS_SearchUI.anchorAjaxBox.trigger("ss:ajaxRemoved");
          }
        });
      },
      error: function (data, status) {
        alert(["== Error(AjaxFile) =="].concat(data.responseJSON).join("\n"));
      }
    });
  };

  return SS_AjaxFile;

})();
