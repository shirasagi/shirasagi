this.Ads_Banner = (function () {
  function Ads_Banner() {
    //landomize banners
  }

  Ads_Banner.randomize = function (selector) {
    var list, wrap;
    wrap = $(selector);
    list = wrap.find("a").parent("span");
    list = list.sort(function () {
      return Math.random() - .5;
    });
    return list.each(function () {
      return wrap.append($(this));
    });
  };

  return Ads_Banner;

})();
