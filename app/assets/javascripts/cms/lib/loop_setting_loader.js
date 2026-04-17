this.Cms_LoopSettingLoader = (function () {
  function Cms_LoopSettingLoader(opts) {
    opts = opts || {};

    this.$addon = opts.addonSelector ? $(opts.addonSelector) : $(document);
    this.$loopSettingSelect = opts.loopSettingSelect ? this.$addon.find(opts.loopSettingSelect) : $();
    this.$textarea = opts.textareaSelector ? this.$addon.find(opts.textareaSelector) : $();
    this.$snippetSelect = opts.snippetSelectSelector ? this.$addon.find(opts.snippetSelectSelector) : $();

    this.apiPathTemplate = opts.apiPathTemplate || "";
    this.acceptEmptyHtml = opts.acceptEmptyHtml !== false;

    this.onBeforeUpdate = opts.onBeforeUpdate || function() {};
    this.onBeforeRequest = opts.onBeforeRequest || function() {};
    this.onAfterSuccess = opts.onAfterSuccess || function() {};
    this.onAfterError = opts.onAfterError || function() {};
    this.onAfterComplete = opts.onAfterComplete || function() {};
    this.setTextareaSubmittable = opts.setTextareaSubmittable || function() {};
    this.setLoadingState = opts.setLoadingState || function() {};
    this.setValue = opts.setValue || function() {};

    this.lastXhr = null;
  }

  Cms_LoopSettingLoader.prototype.hasTarget = function() {
    return this.$loopSettingSelect.length > 0 && this.$textarea.length > 0;
  };

  Cms_LoopSettingLoader.prototype.buildPath = function(loopSettingId) {
    return this.apiPathTemplate.replace(":id", encodeURIComponent(loopSettingId));
  };

  Cms_LoopSettingLoader.prototype.abortPendingRequest = function() {
    if (!this.lastXhr) {
      return;
    }

    this.lastXhr.abort();
    this.lastXhr = null;
  };

  Cms_LoopSettingLoader.prototype.hasHtml = function(data) {
    if (!data) {
      return false;
    }

    if (this.acceptEmptyHtml) {
      return Object.prototype.hasOwnProperty.call(data, "html");
    }

    return !!data.html;
  };

  Cms_LoopSettingLoader.prototype.defaultSetValue = function(value) {
    var editor = this.$textarea.data("editor");
    if (editor) {
      editor.setValue(value);
      if (typeof editor.save === "function") {
        editor.save();
      }
      return;
    }

    this.$textarea.val(value);
  };

  Cms_LoopSettingLoader.prototype.defaultSetLoadingState = function(isLoading) {
    this.$textarea.prop("disabled", isLoading);

    var editor = this.$textarea.data("editor");
    if (editor) {
      editor.setOption("readOnly", isLoading ? "nocursor" : false);
    }
  };

  Cms_LoopSettingLoader.prototype.update = function() {
    var self = this;
    var loopSettingId = self.$loopSettingSelect.val();

    self.onBeforeUpdate(self.$textarea);
    self.abortPendingRequest();

    if (self.$snippetSelect.length) {
      self.$snippetSelect.prop("disabled", !!loopSettingId);
    }

    self.setTextareaSubmittable(self.$textarea, !loopSettingId);

    if (!loopSettingId || self.$textarea.length === 0) {
      if (self.setLoadingState) {
        self.setLoadingState(self.$textarea, false);
      } else {
        self.defaultSetLoadingState(false);
      }
      return;
    }

    if (self.$snippetSelect.length) {
      self.$snippetSelect.prop("disabled", true);
    }

    if (self.setLoadingState) {
      self.setLoadingState(self.$textarea, true);
    } else {
      self.defaultSetLoadingState(true);
    }

    self.onBeforeRequest(loopSettingId, self.$textarea);

    var xhr = $.ajax({
      url: self.buildPath(loopSettingId),
      method: "GET",
      dataType: "json",
      success: function(data) {
        if (xhr !== self.lastXhr) {
          return;
        }

        if (self.hasHtml(data)) {
          var html = data.html;
          if (html === null) {
            html = "";
          }

          if (self.setValue) {
            self.setValue(self.$textarea, html, data);
          } else {
            self.defaultSetValue(html);
          }
        }

        if (self.$snippetSelect.length) {
          self.$snippetSelect.prop("disabled", !!loopSettingId);
        }

        self.onAfterSuccess(data, loopSettingId, self.$textarea);
      },
      error: function(xhr2, status, error) {
        if (xhr !== self.lastXhr) {
          return;
        }
        if (status === "abort") {
          return;
        }

        self.onAfterError(xhr2, status, error, loopSettingId, self.$textarea);
      },
      complete: function() {
        if (xhr !== self.lastXhr) {
          return;
        }

        self.lastXhr = null;

        if (self.setLoadingState) {
          self.setLoadingState(self.$textarea, false);
        } else {
          self.defaultSetLoadingState(false);
        }

        self.onAfterComplete(loopSettingId, self.$textarea);
      }
    });

    self.lastXhr = xhr;
  };

  Cms_LoopSettingLoader.create = function(opts) {
    return new Cms_LoopSettingLoader(opts);
  };

  return Cms_LoopSettingLoader;
})();
