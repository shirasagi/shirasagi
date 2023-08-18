this.SS_Role = (function () {
  var modifyCheckBoxAll = function($permissions, state) {
    var $checkboxes = $permissions.find('input[type=checkbox]');
    $checkboxes.each(function() {
      $(this).prop('checked', state).trigger("change");
    });
  }

  var rendered = false;

  function SS_Role() {
    if (rendered) {
      return;
    }

    rendered = true;

    $(document).on('click', '.select-all', function() {
      var $permissions = $(this).closest('.module').find('.permissions');
      modifyCheckBoxAll($permissions, true);
    });

    $(document).on('click', '.deselect-all', function() {
      var $permissions = $(this).closest('.module').find('.permissions');
      modifyCheckBoxAll($permissions, false);
    });

    $(document).on('change', '.role-permissions input[type="checkbox"]', function() {
      var color = $(this).prop("checked") ? '#333' : '#aaa';
      $(this).closest('label').css('color', color);
    });
    $('.role-permissions input[type="checkbox"]').trigger("change");
  }

  return SS_Role;
})();
