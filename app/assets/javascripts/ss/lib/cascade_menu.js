function SS_CascadeMenu() {
}

SS_CascadeMenu.render = function() {
  $('.cascade-menu').on('click', function(ev) {
    var $this = $(this);
    var ref = $this.data('ref');
    if (! ref) {
      return;
    }

    var $currDropdown = $this.closest('.dropdown-menu');
    var $nextDropdown = $(ref);

    // if ($currDropdown.height() > $nextDropdown.height()) {
    //   $nextDropdown.height($currDropdown.height());
    // }

    $nextDropdown.addClass('active');
    $currDropdown.removeClass('active');

    if ($nextDropdown.data('load')) {
      $nextDropdown.data('load')();
    }

    ev.preventDefault();
    ev.stopPropagation();
  });

  $('.cascade-back').on('click', function(ev) {
    var $this = $(this);
    var ref = $this.attr('href');

    var $currDropdown = $this.closest('.dropdown-menu');
    var $nextDropdown = $(ref);

    $nextDropdown.addClass('active');
    $currDropdown.removeClass('active');

    ev.preventDefault();
    ev.stopPropagation();
  });
};
