this.Cms_Line_Message_Repeat_Plan = (function () {
  function Cms_Line_Message_Repeat_Plan() {
  }

  Cms_Line_Message_Repeat_Plan.renderForm = function () {
    this.changeRepeatForm();
    $('#item_repeat_type').on("change", function () {
      Cms_Line_Message_Repeat_Plan.changeRepeatForm();
    });
  };

  Cms_Line_Message_Repeat_Plan.changeRepeatForm = function () {
    var repeat_type;
    repeat_type = $('#item_repeat_type').val();
    if (repeat_type === '') {
      $('.cms-line-message-repeat').addClass("hide");
    } else {
      $('.cms-line-message-repeat').removeClass("hide");
      $(".repeat-daily, .repeat-weekly, .repeat-monthly").hide();
      $(".repeat-" + repeat_type).show();
    }
  };

  return Cms_Line_Message_Repeat_Plan;

})();

this.Cms_Line_Area_Cropper = (function () {
  function Cms_Line_Area_Cropper(el, opts) {
    if (!opts) {
      opts = {};
    }
    this.$el = $(el);
    this.$currentArea = this.$el.find(".areas .area1");
    this.$image = this.$el.find(".image-warp img");
    this.readonly = opts["readonly"];
    this.render();
  };

  Cms_Line_Area_Cropper.prototype.render = function () {
    var self = this;
    self.cropper = new Cropper(
      self.$image[0],
      {
        viewMode: 1,
        zoomOnWheel: false,
        background: true,
        autoCrop: false,
        ready: function(e) {
          $(".area-names .area-name:first").trigger("click");
          if (self.readonly) {
            self.cropper.disable();
          }
          window.cropper = self.cropper;
        },
        cropmove: function(e) {
          self.setCroppedArea();
        }
      }
    );

    self.$el.find(".area-name").on("click" , function(){
      self.$el.find(".area-name").removeClass("current")
      self.$el.find(".area-name").removeClass("btn-active");
      $(this).addClass("current");
      $(this).addClass("btn-active");

      var idx = $(this).data("area");
      self.$currentArea = $('[data-area="' + idx + '"]');

      self.$el.find(".areas .area").hide();
      self.$currentArea.show();
      self.cropCurrentArea();
      return false;
    });

    self.$el.find(".reset-area").on("click", function() {
      self.$currentArea.find('[name="item[in_areas][][x]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][y]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][width]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][height]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][text]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][uri]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][data]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][menu_id]"]').val("");
      self.$currentArea.find('[name="item[in_areas][][type]"]').val("message");
      self.cropper.clear();
      return false;
    });

    self.$el.find(".action").each(function() {
      var $action = $(this)
      var $select = $action.find('[name="item[in_areas][][type]"]');
      var toggleAction = function(){
        $action.find('[data-type]').hide();
        $action.find('[data-type="' + $select.val() + '"]').show();
      };
      $select.on("change", toggleAction);
      toggleAction();
    });
  };

  Cms_Line_Area_Cropper.prototype.cropCurrentArea = function () {
    var self = this;
    var x = self.$currentArea.find('input[name="item[in_areas][][x]"]').val();
    var y = self.$currentArea.find('input[name="item[in_areas][][y]"]').val();
    var width = self.$currentArea.find('input[name="item[in_areas][][width]"]').val();
    var height = self.$currentArea.find('input[name="item[in_areas][][height]"]').val();

    if (x && y && width && height) {
      var data = self.cropper.getData(true);
      Object.assign(data, { x: parseInt(x), y: parseInt(y), width: parseInt(width), height: parseInt(height) });
      self.cropper.enable();
      self.cropper.crop();
      self.cropper.setData(data);
    } else {
      self.cropper.enable();
      self.cropper.clear();
    }

    if (self.readonly) {
      self.cropper.disable();
    }
  };

  Cms_Line_Area_Cropper.prototype.setCroppedArea = function () {
    var self = this;
    var data = self.cropper.getData(true);
    self.$currentArea.find('input[name="item[in_areas][][x]"]').val(data.x);
    self.$currentArea.find('input[name="item[in_areas][][y]"]').val(data.y);
    self.$currentArea.find('input[name="item[in_areas][][width]"]').val(data.width);
    self.$currentArea.find('input[name="item[in_areas][][height]"]').val(data.height);
  };

  return Cms_Line_Area_Cropper;
})();
