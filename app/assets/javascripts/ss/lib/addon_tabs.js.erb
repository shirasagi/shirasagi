this.SS_AddonTabs = (function () {
  function SS_AddonTabs() {
  }

  SS_AddonTabs.render = function () {
    return $(document).on('click', '.toggle-head', function () {
      SS_AddonTabs.toggleWithAnimation(this);
    });
  };

  SS_AddonTabs.findAddonView = function (view) {
    var $view = $(view);
    var $addonView;
    if ($view.hasClass("addon-view")) {
      $addonView = $view;
    } else {
      $addonView = $view.closest('.addon-view');
      if (!$addonView[0]) {
        $addonView = $view.parent();
      }
    }

    return $addonView;
  };

//  SS_AddonTabs.head = function (content) {
//    var $addonView = SS_AddonTabs.findAddonView(content);
//    return $addonView.find('.addon-head');
//  };

  SS_AddonTabs.show = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    if (!$addonView[0]) {
      return;
    }

    $addonView.find('.toggle-body').show();
    $addonView.removeClass('body-closed');
    $addonView.trigger('ss:addonShown');
  };

  SS_AddonTabs.hide = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    if (!$addonView[0]) {
      return;
    }

    $addonView.find('.toggle-body').hide();
    $addonView.addClass('body-closed');
    $addonView.trigger('ss:addonHidden');
  };

  SS_AddonTabs.toggleWithAnimation = function (view) {
    var $addonView = SS_AddonTabs.findAddonView(view);
    if (!$addonView[0]) {
      return;
    }

    var $toggleBody = $addonView.find('.toggle-body');
    if (!$toggleBody[0]) {
      return;
    }

    $toggleBody.animate({ height: 'toggle' }, 'fast', function() {
      if ($addonView[0]) {
        var shown = SS_AddonTabs.isShown($toggleBody);
        if (shown) {
          $addonView.removeClass('body-closed');
          $addonView.trigger('ss:addonShown');
        } else {
          $addonView.addClass('body-closed');
          $addonView.trigger('ss:addonHidden');
        }
      }
    });
  };

  SS_AddonTabs.isShown = function ($el) {
    if ($el.css("display") === "none") {
      return false;
    }
    if ($el.css("visibility") === "hidden") {
      return false;
    }

    return true;
  };

//  SS_AddonTabs.toggleView = function (view) {
//    console.log("SS_AddonTabs.toggleView is deprecated");
//    SS_AddonTabs.hide(view);
//  };
  //TODO: depracated

  return SS_AddonTabs;

})();

