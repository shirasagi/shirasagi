Gws_Column = function () {
  //
};

Gws_Column.renderRadioButton = function(columnId) {
  var ids = [];

  // prepare
  var $el = $(".radio-button-" + columnId);
  $el.find('input[data-section-id]').each(function() {
    ids.push($(this).attr('data-section-id'));
  });

  // change
  $el.find("input[type='radio']").each(function() {
    var $this = $(this);
    var sectionId = $this.attr('data-section-id');
    $this.on('change', function() {
      ids.forEach(function(id) {
        $(`.section-${id}`).addClass("hide");
        $(`.section-${id} *`).prop('disabled', true);
      });
      $(`.section-${sectionId}`).removeClass("hide");
      $(`.section-${sectionId} *`).prop('disabled', false);

      if (sectionId === 'other') {
        $el.find("input[type='text']").prop('disabled', false);
      } else {
        $el.find("input[type='text']").prop('disabled', true);
      }

      $this.trigger("column:sectionChanged");
    });
  });

  // clear
  $el.find('.btn').on('click', function() {
    Gws_Column.resetRadioButton($el, ids);
  });

  // on validation error
  if ($el.find("input[type='radio']:checked").length > 0) {
    $el.find("input[type='radio']:checked").trigger('change');
  } else {
    Gws_Column.resetRadioButton($el, ids);
  }
};

Gws_Column.resetRadioButton = function($el, ids) {
  ids.forEach(function(id) {
    $(`.section-${id}`).addClass("hide");
    $(`.section-${id} *`).prop('disabled', true);
    $el.find("input[type='text']").prop('value', null);
    $el.find("input[type='text']").prop('disabled', true);
  });
};
