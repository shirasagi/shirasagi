// List - select
$('.js-list-select').each(function() {
  var $el = $(this);
  var $table = $el.closest('table');
  $el.on('click', function(ev) {
    $table.find('tbody th input').each(function() {
      $(this).prop('checked', $el.prop('checked'));
    });
  });
});

// List - delete
$('.js-list-destroy').on('click', function() {
  var $el = $(this);
  var $form = $el.closest('form');
  if ($form.find('tbody th input:checked').length === 0) {
    return false;
  }
});

// Row - link
$('.row-link').each(function() {
  var $el = $(this);
  $el.css('cursor', 'pointer');
  $el.on('click', function(ev) {
    var href = $el.attr('data-href'); // ?? $el.find('a').attr('href');
    if (!href) return;

    if (ev.target.tagName === 'A' || ev.target.closest('a,.row-link-disabled')) return;
    if (window.getSelection().isCollapsed) window.location = href;
  });
});
