SS_DropdownToggle = (function () {
  function SS_DropdownToggle() {}

  function renderOnce() {
    $(document).on("click", function (e) {
      if ($(e.target).closest('.dropdown-menu').length === 0) {
        $(".dropdown").removeClass('active');
        $(".dropdown-menu").removeClass('active');
      }
    });
  }

  //dropdown
  SS_DropdownToggle.render = function() {
    SS.justOnce(document, "ss-dropdownToggle", function() {
      renderOnce();
    });
    $(".dropdown-toggle").each(function() {
      var $dropdownToggle = $(this);
      SS.justOnce(this, "ss-dropdownToggle", function() {
        $dropdownToggle.on("click", function (e) {
          var $target = $(e.target);
          var ref = $dropdownToggle.data('ref');
          var $dropdown = $target.closest('.dropdown');
          var $menu = ref ? $dropdownToggle.find(ref) : $dropdown.find('.dropdown-menu').first();

          // close other dropdown
          $(".dropdown").not($dropdown.get(0)).each(function () {
            return $(this).find('.dropdown-menu').removeClass('active');
          });

          // popup_notice
          SS_PopupNotice.closePopup();

          // open dropdown
          if ($target.parents('.dropdown-menu').length === 0) {
            $menu.toggleClass('active');
            e.stopPropagation();
            $dropdownToggle.trigger("ss:dropdownOpened");
          }
        });
      });
    });
  };

  return SS_DropdownToggle;
})();
