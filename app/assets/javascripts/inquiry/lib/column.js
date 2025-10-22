// できれば app/javascript/controllers/gws/column/radio_controller.js と統合
function Inquiry_Column_RadioButton(containerClass) {
  this.$el = $(containerClass);
  this.columnIds = {}

  this.prepare();
  this.hideSections();
  this.disableOthers();
  this.setEvents(); // after render
}

Inquiry_Column_RadioButton.prototype.prepare = function(debug = false) {
  var $el = this.$el;
  var columnIds = {};

  $el.find('[data-column-id]').each(function () {
    var $column = $(this);
    var columnId = $(this).attr('data-column-id');

    $column.find('input[data-section-id]').each(function () {
      var $radio = $(this);

      columnIds[columnId] ||= {};
      if ($radio.prop('disabled')) {
        columnIds[columnId][$radio.attr('data-section-id')] = false;
      } else {
        columnIds[columnId][$radio.attr('data-section-id')] = $radio.prop('checked');
      }
    });
  });
  this.columnIds = columnIds;

  if (debug) console.debug('columns:', columnIds);
};

Inquiry_Column_RadioButton.prototype.hideSections = function(debug = false) {
  var columnIds = this.columnIds;
  var results = {}

  for (let columnId in columnIds) {
    for (let targetId in columnIds[columnId]) {
      results[targetId] ||= [];
      results[targetId].push(columnIds[columnId][targetId]);
    }
  }
  if (debug) console.debug('results:', results);

  for (let targetId in results) {
    var state = results[targetId].includes(true);

    if (state) {
      $(`.section-${targetId}`).show();
      $(`.section-${targetId} *`).prop('disabled', false);
    } else {
      $(`.section-${targetId} input[type="radio"]:checked`).prop('checked', false);
      $(`.section-${targetId}`).hide();
      $(`.section-${targetId} *`).prop('disabled', true);
    }
  }
};

Inquiry_Column_RadioButton.prototype.setEvents = function() {
  var _this = this;
  var $container = this.$el;
  var columnIds = this.columnIds;

  $container.find("input[type='radio']").each(function() {
    $(this).on('change', function() {
      if (!$(this).attr('data-section-id')) return;

      for (var i = 0; i < Object.keys(columnIds).length; i++) {
        _this.prepare();
        _this.hideSections();
      }
      _this.prepare();
      _this.hideSections();
      _this.disableOthers();
    });

    $(this).on('change', function() {
      var $other = $(this).closest('dd').find('input[data-section-id="other"]');
      var $value = $(this).closest('dd').find(`input[name*="other_value"]`);

      if ($other.length === 0 || $value.length === 0) return;
      $value.prop('disabled', !$other.prop('checked'));
    });
  });

  $container.find("button[data-clear-radio]").on('click', function() {
    var $dd = $(this).closest('dd');
    $dd.find('input[type=radio]').prop('checked', false).trigger('change');
    $dd.find('input[type=text]').val('');
  });
};

// TODO: 一部２重
Inquiry_Column_RadioButton.prototype.disableOthers = function() {
  var $container = this.$el;

  $container.find(`input[name*="other_value"]`).each(function() {
    var $trigger = $(this).closest('label').find('input').first();
    if ($trigger.prop('disabled') || $trigger.prop('checked')) return;
    $(this).prop('disabled', true);
  });
};
