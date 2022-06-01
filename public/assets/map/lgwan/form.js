this.Map_Lgwan_Form = (function () {
  function Map_Lgwan_Form() {
  }

  Map_Lgwan_Form.maxPointForm = 10;

  Map_Lgwan_Form.deleteMessage = "マーカーを削除してよろしいですか？";

  Map_Lgwan_Form.renderEvents = function () {
    $(".mod-map .add-marker").on('click', function (e) {
      Map_Lgwan_Form.clonePointForm();
      return false;
    });
    $(".mod-map .clear-marker").on('click', function (e) {
      Map_Lgwan_Form.clearPointForm($(this).closest("dd.marker"));
      return false;
    });
    $(".mod-map .set-marker").on('click', function (e) {
      Map_Lgwan_Form.createMarker($(this).closest("dd.marker"));
      return false;
    });
    $(".mod-map .marker-name").on('keypress', function (e) {
      if (e.which === SS.KEY_ENTER) {
        return false;
      }
    });
    $(".mod-map .marker-loc-input").on('keypress', function (e) {
      if (e.which === SS.KEY_ENTER) {
        $(this).closest("dd.marker").find(".set-marker").trigger("click");
        return false;
      }
    });
    Map_Lgwan_Form.toggleAddMarker();
  };

  Map_Lgwan_Form.clonePointForm = function () {
    var cln;
    if ($(".mod-map dd.marker").length < Map_Lgwan_Form.maxPointForm) {
      cln = $(".mod-map dd.marker:last").clone(false).insertAfter($(".mod-map dd.marker:last"));
      cln.removeClass("active");
      cln.find("input,textarea").val("");
      cln.find(".marker-name").val("");
      cln.find(".clear-marker").on('click', function () {
        Map_Lgwan_Form.clearPointForm(cln);
        return false;
      });
      cln.find(".clear-marker").on('click', function () {
        Map_Lgwan_Form.clearPointForm(cln);
        return false;
      });
      cln.find(".set-marker").on('click', function () {
        Map_Lgwan_Form.createMarker($(this).closest("dd.marker"));
        return false;
      });
      cln.find(".marker-name").on('keypress', function (e) {
        if (e.which === SS.KEY_ENTER) {
          return false;
        }
      });
      cln.find(".marker-loc-input").on('keypress', function (e) {
        if (e.which === SS.KEY_ENTER) {
          $(this).closest("dd.marker").find(".set-marker").trigger("click");
          return false;
        }
      });
    }
    Map_Lgwan_Form.toggleAddMarker();
  };

  Map_Lgwan_Form.clearPointForm = function (ele) {
    if (ele.find(".marker-loc-input").val()) {
      if (confirm(Map_Lgwan_Form.deleteMessage)) {
        ele.removeClass("active");
        ele.find("input,textarea").val("");
        if ($(".mod-map dd.marker").length > 1) {
          ele.remove();
        }
      }
    } else {
      ele.removeClass("active");
      ele.find("input,textarea").val("");
      if ($(".mod-map dd.marker").length > 1) {
        ele.remove();
      }
    }
    Map_Lgwan_Form.toggleAddMarker();
  };

  Map_Lgwan_Form.toggleAddMarker = function () {
    if ($(".mod-map dd.marker").length < Map_Lgwan_Form.maxPointForm) {
      $(".mod-map dd .add-marker").parent().show();
    } else {
      $(".mod-map dd .add-marker").parent().hide();
    }
  }

  Map_Lgwan_Form.createMarker = function (ele) {
    var loc = null;
    if (ele.find(".marker-loc-input").val()) {
      if (Map_Lgwan_Form.validateLoc(ele.find(".marker-loc-input").val())) {
        loc = ele.find(".marker-loc-input").val();
      } else {
        alert("正しい座標をカンマ(,)区切りで入力してください。\\n例）133.6806607,33.8957612");
      }
    }
    if (loc) {
      ele.find(".marker-loc").val(loc);
      ele.addClass("active");
    }
  };

  Map_Lgwan_Form.validateLoc = Openlayers_Map_Form.validateLoc;

  return Map_Lgwan_Form;
})();
