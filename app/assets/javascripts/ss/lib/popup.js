this.SS_Popup = (function () {
  function SS_Popup(el, options) {
    this.el = el;
    this.options = options || {};
    this.render();
  }

  SS_Popup.initialized = false;

  SS_Popup.initializeOnce = function () {
    if (SS_Popup.initialized) {
      return;
    }

    SS_Popup.initialized = true;

    // tippy default settings
    tippy.setDefaultProps({
      theme: 'light-border ss-popup',
      trigger: 'click'
    });
  };

  SS_Popup.render = function (selector, options) {
    SS_Popup.initializeOnce();

    if (! selector) {
      selector = ".ss-popup";
    }

    $(document).on("click", selector, function (ev) {
      if (ev.target._ss && ev.target._ss.popup) {
        return;
      }

      var popup = new SS_Popup(ev.target, options);
      popup.show();
      return false;
    });
  };

  SS_Popup.prototype.render = function() {
    if (this.el._ss && this.el._ss.popup) {
      return;
    }
    if (this.el._tippy) {
      this.el._ss = this.el._ss || {};
      this.el._ss.popup = this;
      return;
    }

    var inline = ("ssPopupInline" in this.el.dataset) || this.options["ss-popup-inline"];
    var result;
    if (inline) {
      result = this.renderInlinePopup();
    } else {
      result = this.renderAjaxPopup();
    }
    if (! result) {
      return;
    }

    this.el._ss = this.el._ss || {};
    this.el._ss.popup = this;
  };

  SS_Popup.prototype.renderInlinePopup = function() {
    var self = this;
    var createAndShow = function(content, overflow) {
      var tippyOptions = { content: content };
      if (self.options["tippy-theme"]) {
        tippyOptions["theme"] = self.options["tippy-theme"]
      }
      if (overflow) {
        tippyOptions["popperOptions"] = { modifiers: { preventOverflow: { escapeWithReference: true } } };
      }
      tippy(self.el, tippyOptions);
    };

    var overflow = this.el.dataset["ssPopupOverflow"] || this.options["ss-popup-overflow"];
    var content = this.el.dataset["ssPopupHtml"] || this.options["ss-popup-html"];
    if (content) {
      createAndShow(content, overflow);
      return true;
    }

    var href = this.el.dataset["ssPopupHref"] || this.options["ss-popup-href"];
    if (href) {
      content = this.el.querySelector(href) || document.querySelector(href);
      if (content) {
        createAndShow(content, overflow);
        return true;
      }
    }

    return false;
  };

  SS_Popup.prototype.renderAjaxPopup = function() {
    var href = this.el.dataset["ssPopupHref"] || this.options["ss-popup-href"];
    if (! href) {
      return false;
    }

    var tippyOptions = { content: SS.loading, trigger: 'click', theme: 'light-border ss-popup' };

    if (this.options["tippy-theme"]) {
      tippyOptions["theme"] = this.options["tippy-theme"]
    }

    var overflow = this.el.dataset["ssPopupOverflow"] || this.options["ss-popup-overflow"];
    if (overflow) {
      tippyOptions["popperOptions"] = { modifiers: { preventOverflow: { escapeWithReference: true } } };
    }

    tippy(this.el, tippyOptions);

    var self = this;
    $.ajax({
      url: href,
      cache: false,
      success: function(html) {
        self.el._tippy.setContent(html);
      },
      error: function(xhr, status, error) {
        self.showError(xhr, status, error);
      }
    });
  };

  SS_Popup.prototype.showError = function(xhr, status, error) {
    this.el._tippy.setContent("[==Error==]");
  };

  SS_Popup.prototype.show = function() {
    if (!this.el._tippy) {
      return;
    }

    this.el._tippy.show();
  }

  return SS_Popup;
})();
