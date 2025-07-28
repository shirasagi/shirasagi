import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.$el = $(this.element);
    this.columnId = this.element.dataset.columnId;
    this.render();
  }

  render() {
    var _this = this;
    var $el = this.$el;
    var ids = [];

    // prepare
    $el.find('input[data-section-id]').each(function () {
      var sectionId = $(this).attr('data-section-id');
      if (sectionId && !ids.includes(sectionId)) {
        ids.push(sectionId);
      }
    });

    // change
    $el.find("input[type='radio']").each(function () {
      var $this = $(this);
      var sectionId = $this.attr('data-section-id'); // target
      $this.on('change', function () {
        // reset
        ids.forEach(function (id) {
          $(`.section-${id}`).addClass("hide");
          $(`.section-${id} *`).prop('disabled', true);
        });

        if (sectionId) {
          // set
          $(`.section-${sectionId}`).removeClass("hide");
          $(`.section-${sectionId} *`).prop('disabled', false);

          if (sectionId === 'other') {
            $el.find("input[type='text']").prop('disabled', false);
          } else {
            $el.find("input[type='text']").prop('disabled', true);
          }
        }

        $this.trigger("column:sectionChanged");
      });
    });

    // clear
    $el.find('.btn').on('click', function () {
      _this.reset(ids);
    });

    // on validation error
    if ($el.find("input[type='radio']:checked").length > 0) {
      $el.find("input[type='radio']:checked").trigger('change');
    } else {
      _this.reset(ids);
    }
  }

  reset(ids) {
    var $el = this.$el;
    ids.forEach(function(id) {
      $(`.section-${id}`).addClass("hide");
      $(`.section-${id} *`).prop('disabled', true);
      $el.find("input[type='text']").prop('value', null);
      $el.find("input[type='text']").prop('disabled', true);
    });
  }
}
