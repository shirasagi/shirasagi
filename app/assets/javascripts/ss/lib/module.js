globalThis.SS_Module = (function () {
  var moduleKeywords = ['extended', 'included'];

  function SS_Module() {
  }

  SS_Module.extend = function (obj) {
    var key, ref, value;
    for (key in obj) {
      value = obj[key];
      if (moduleKeywords.indexOf(key) < 0) {
        this[key] = value;
      }
    }
    if ((ref = obj.extended) != null) {
      ref.apply(this);
    }
    return this;
  };

  SS_Module.include = function (obj) {
    var key, ref, value;
    for (key in obj) {
      value = obj[key];
      if (moduleKeywords.indexOf(key) < 0) {
        this.prototype[key] = value;
      }
    }
    if ((ref = obj.included) != null) {
      ref.apply(this);
    }
    return this;
  };

  return SS_Module;

})();
