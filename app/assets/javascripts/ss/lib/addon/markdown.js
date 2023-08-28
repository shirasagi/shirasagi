this.SS_Addon_Markdown = (function () {
  function SS_Addon_Markdown(el, options) {
    this.$el = $(el);
    this.options = options;
    this.render();
  }

  SS_Addon_Markdown.container = 'ss-addon-markdown';

  SS_Addon_Markdown.content = 'ss-addon-markdown-content';

  SS_Addon_Markdown.textArea = 'ss-markdown-area';

  SS_Addon_Markdown.toolbar = 'ss-addon-markdown-toolbar';

  SS_Addon_Markdown.options = 'ss-addon-markdown-options';

  SS_Addon_Markdown.type = 'ss-addon-markdown-type';

  SS_Addon_Markdown.preview = 'ss-addon-markdown-preview';

  SS_Addon_Markdown.previewUrl = '/.u/addons/markdown';

  SS_Addon_Markdown.previewButton = 'ss-addon-markdown-preview-button';

  SS_Addon_Markdown.helpUrl = 'https://help.github.com/articles/basic-writing-and-formatting-syntax/';

  SS_Addon_Markdown.helpButton = 'ss-addon-markdown-help-button';

  SS_Addon_Markdown.customCkeConfig = '/.sys/apis/cke_config.js';

  SS_Addon_Markdown.render = function (el, options) {
    var $el = $(el || "." + SS_Addon_Markdown.container);
    $el.find("." + this.toolbar).append("<span class='" + this.options + "'></span>");
    $el.append("<div class='" + this.preview + " markdown-body'></div>");
    $el.find("." + this.options)
      .append($("<input />", { type: 'button', class: 'btn ' + this.previewButton, value: i18next.t("ss.links.preview") }))
      .append($("<a />", { href: this.helpUrl, class: this.helpButton, target: '_blank', rel: 'noopener' }).text(i18next.t("ss.links.markdown_help")));

    return new SS_Addon_Markdown("." + SS_Addon_Markdown.container, options);
  };

  SS_Addon_Markdown.prototype.render = function () {
    var self = this;

    var $typeSelect = self.$el.find("." + SS_Addon_Markdown.type);
    $typeSelect.on("change", function() {
      self.onTextTypeChanged($typeSelect);
    });

    self.$el.find("." + SS_Addon_Markdown.previewButton).on("click", function() {
      self.toggleMarkdownPreview();
    });

    self.onTextTypeChanged($typeSelect);
  };

  SS_Addon_Markdown.prototype.onTextTypeChanged = function ($this) {
    var self = this;
    var val = $this.val();

    var $typeSelect = this.$el.find("." + SS_Addon_Markdown.type);
    $typeSelect.prop("disabled", true);

    if (val === "markdown") {
      this.$el.find("." + SS_Addon_Markdown.options).removeClass("hide");
      this.$el.find("." + SS_Addon_Markdown.previewButton).removeClass("hide");
      this.$el.find("." + SS_Addon_Markdown.helpButton).removeClass("hide");
      self.disableCKEditor();
      $typeSelect.prop("disabled", false);
    } else {
      this.$el.find("." + SS_Addon_Markdown.options).addClass("hide");
      this.$el.find("." + SS_Addon_Markdown.previewButton).addClass("hide");
      this.$el.find("." + SS_Addon_Markdown.helpButton).addClass("hide");

      if (this.isPreviewButtonPressed()) {
        this.hideMarkdownPreview();
      }

      if (val === "cke") {
        self.enableCKEditor(function() { $typeSelect.prop("disabled", false); self.$el.trigger("ss:editorActivated"); });
      } else {
        self.disableCKEditor();
        $typeSelect.prop("disabled", false);
        self.$el.trigger("ss:editorDeactivated");
      }
    }
  };

  SS_Addon_Markdown.prototype.isPreviewButtonPressed = function() {
    return this.$el.find("." + SS_Addon_Markdown.previewButton).attr('aria-pressed') === 'true';
  }

  SS_Addon_Markdown.prototype.toggleMarkdownPreview = function() {
    if (this.isPreviewButtonPressed()) {
      this.hideMarkdownPreview();
    } else {
      this.previewMarkdown();
    }
  };

  SS_Addon_Markdown.prototype.previewMarkdown = function() {
    var self = this;
    var text = this.$el.find("." + SS_Addon_Markdown.textArea).val();

    this.$el.find("." + SS_Addon_Markdown.previewButton).attr('aria-pressed', 'true');
    this.$el.find("." + SS_Addon_Markdown.textArea).addClass("hide");
    this.$el.find("." + SS_Addon_Markdown.preview).html(SS.loading).removeClass("hide");

    $.ajax({
      url: SS_Addon_Markdown.previewUrl,
      method: "post",
      data: {
        text: text
      },
      success: function(data) {
        self.$el.find("." + SS_Addon_Markdown.preview).html(data);
      },
      error: function(xhr, _status, _error) {
        self.$el.find("." + SS_Addon_Markdown.preview).html("<p>Error!!</p><br/><p>" + xhr["statusText"] + "</p>");
      }
    });
  };

  SS_Addon_Markdown.prototype.hideMarkdownPreview = function() {
    this.$el.find("." + SS_Addon_Markdown.textArea).removeClass("hide").focus();
    this.$el.find("." + SS_Addon_Markdown.preview).addClass("hide").html('');
    this.$el.find("." + SS_Addon_Markdown.previewButton).attr('aria-pressed', 'false');
  };

  SS_Addon_Markdown.prototype.enableCKEditor = function(onReady) {
    var self = this;
    var $editor = self.$el.find("." + SS_Addon_Markdown.textArea);
    if ($editor.data("ss.ckeInstance")) {
      // already enabled
      return;
    }

    var customConfig;
    if (self.options && self.options.customCkeConfig) {
      customConfig = self.options.customCkeConfig;
    } else {
      customConfig = SS_Addon_Markdown.customCkeConfig;
    }
    var config = {
      customConfig: customConfig,
      on: {
        instanceReady: function() { $editor.data("ss.ckeInstance", this); onReady(); }
      }
    };

    $editor.ckeditor(config);
  };

  SS_Addon_Markdown.prototype.disableCKEditor = function() {
    var $editor = this.$el.find("." + SS_Addon_Markdown.textArea);
    var ckeInstance = $editor.data("ss.ckeInstance");
    $editor.data("ss.ckeInstance", null);

    if (! ckeInstance) {
      // not enabled
      return;
    }

    ckeInstance.destroy();
  };

  return SS_Addon_Markdown;

})();
