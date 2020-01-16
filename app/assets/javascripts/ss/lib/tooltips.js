this.SS_Tooltips = (function () {
  function SS_Tooltips() {
  }

  SS_Tooltips.initialized = false;

  SS_Tooltips.initializeOnce = function () {
    if (SS_Tooltips.initialized) {
      return;
    }

    SS_Tooltips.initialized = true;

    // tippy default settings
    tippy.setDefaultProps({
      content: function(el) { return el.querySelector("ul"); },
      trigger: 'click',
      theme: 'light-border ss-tooltip'
    });
  };

  SS_Tooltips.render = function (selector) {
    SS_Tooltips.initializeOnce();

    $(document).on("click", selector, function (ev) {
      if (ev.target._tippy) {
        return;
      }

      // lazy tippinize
      var instance = tippy(ev.target);
      instance.show();
    });
  };

  return SS_Tooltips;
})();
