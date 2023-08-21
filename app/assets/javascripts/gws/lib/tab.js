// Tab
function Gws_Tab() {
}

Gws_Tab.renderTabs = function(selector) {
  var path = location.pathname + "/";
  $(selector).find('a').each(function() {
    var $menu = $(this);
    if (path.match(new RegExp('^' + $menu.attr('href') + '(\/|$)'))) {
      $menu.addClass("current")
    }
  });
};
