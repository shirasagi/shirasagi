function SS_Tooltips(selector) {
  this.selector = selector;
  this.render();
}

SS_Tooltips.prototype.findClosestPopup = function($el) {
  return $el.closest(this.selector).find(".ss-tooltip-body")[0];
};

SS_Tooltips.prototype.render = function() {
  var _this = this;

  $(this.selector).on('click', '.ss-tooltip-toggle', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var popup = _this.findClosestPopup($(this));
    if (! popup) {
      return;
    }

    SS_Tooltips.hideTooltip();
    SS_Tooltips.showTooltip(this, popup);
  });
};

SS_Tooltips.instances = [];
SS_Tooltips.initialized = null;
SS_Tooltips.popup = null;
SS_Tooltips.popper = null;
SS_Tooltips.offset = 12;

SS_Tooltips.findTooltip = function(selector) {
  var found;
  for(var i = 0; i < SS_Tooltips.instances.length; i++) {
    var instance = SS_Tooltips.instances[i];
    if (instance.selector === selector) {
      found = instance;
      break;
    }
  }
  return found;
};

SS_Tooltips.render = function(selector) {
  SS_Tooltips.initialize();

  if (SS_Tooltips.findTooltip(selector)) {
    return;
  }

  var instance = new SS_Tooltips(selector);
  SS_Tooltips.instances.push(instance);
};

SS_Tooltips.initialize = function() {
  if (SS_Tooltips.initialized) {
    return;
  }

  $(document).click(function () {
    SS_Tooltips.hideTooltip();
  });

  $(document).keyup(function (e) {
    if (e.keyCode == 27) {
      SS_Tooltips.hideTooltip();
    }
  });

  SS_Tooltips.initialized = true;
};

SS_Tooltips.showTooltip = function(ref, popup) {
  popup.style.display = 'block';

  SS_Tooltips.popper = new Popper(ref, popup, { placement: 'top', modifiers: { shift: { fn: SS_Tooltips.popupOffset } } });
  SS_Tooltips.popup = popup;
};

SS_Tooltips.hideTooltip = function() {
  if (SS_Tooltips.popup) {
    SS_Tooltips.popup.style.display = 'none';
  }
  if (SS_Tooltips.popper) {
    SS_Tooltips.popper.destroy();
  }

  SS_Tooltips.popup = null;
  SS_Tooltips.popper = null;
};

SS_Tooltips.popupOffset = function(data, options) {
  if (data.placement === 'top') {
    data.offsets.popper.top = data.offsets.reference.top - data.offsets.popper.height - SS_Tooltips.offset;
  } else if (data.placement === 'bottom') {
    data.offsets.popper.top = data.offsets.reference.bottom + SS_Tooltips.offset;
  } else if (data.placement === 'left') {
    data.offsets.popper.left = data.offsets.reference.left - data.offsets.popper.width - SS_Tooltips.offset;
  } else if (data.placement === 'right') {
    data.offsets.popper.left = data.offsets.reference.right + SS_Tooltips.offset;
  }

  return data;
};
