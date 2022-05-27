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


this.Cms_Line_Deliver_Condition =  (function () {
  function Cms_Line_Deliver_Condition() {
    this.render();
  };

  Cms_Line_Deliver_Condition.prototype.render = function () {
    $(".select-deliver-category").on("change", this.toggleDeliverCategory);
    $(".select-deliver-category").on("change", this.toggleDeliverCategoryRemark);
    $(".remarks-button").on("click", this.toggleRemarkText);
    this.toggleDeliverCategory();
    this.toggleDeliverCategoryRemark();
  };

  Cms_Line_Deliver_Condition.prototype.toggleDeliverCategory = function(){
    var selected = {};
    $(".deliver-category").each(function(){
      var category = this;

      // select
      var id = $(this).find("select").val();
      if (id) {
        selected[id] = $(category);
      }
      // checkbox
      $(this).find("input:checked").each(function(){
        var id = $(this).val();
        selected[id] = $(category);
      });
    });

    $(".deliver-category[data-required]").each(function() {
      var ids = $(this).attr("data-required").split(",");
      var required = false;
      $.each(ids, function() {
        var id = this;
        if (selected[id] && selected[id].is(':visible')) {
          required = true;
        }
      });
      if (required) {
        $(this).show();
        $(this).find("[name]").attr("name", "item[deliver_category_ids][]");
      } else {
        $(this).hide();
        $(this).find("[name]").attr("name", "");
      }
    });
  };

  Cms_Line_Deliver_Condition.prototype.toggleDeliverCategoryRemark = function () {
    $(".deliver-remarks").hide();
    $(".deliver-category").each(function () {
      // select
      var id = $(this).find("select").val();
      $(".remark-" + id).show();
      $(".remark-" + id).text("＋ 詳細を開く");
    });

    // checkbox
    $(this).find("input:checked").each(function(){
      var id = $(this).val();
      $(".remark-" + id).show();
      $(".remark-" + id).text("＋ 詳細を開く");
    });

  };

  Cms_Line_Deliver_Condition.prototype.toggleRemarkText = function () {
    className = $(this).attr("class").split(" ")[0];
    $( "." + className + "-text").toggle();
    if ($(this).text() == "＋ 詳細を開く") {
      $(this).text("− 詳細を閉じる");
    } else {
      $(this).text("＋ 詳細を開く");
    }
  };

  return Cms_Line_Deliver_Condition;
})();
