this.SS_Validation = (function () {
  function SS_Validation() {
  }

  SS_Validation.url = '';
  SS_Validation.model = '';
  SS_Validation.id = '';
  SS_Validation.labels = {};

  SS_Validation.render = function () {

    $.each(SS_Validation.labels, function(key, label) {
      var div = $('<div id="item_' + key + '_errors"></div>');
      var input = $("#item_" + key);
      input.after(div);
      input.blur(function() {
        SS_Validation.validation();
      });
      input.change(function() {
        SS_Validation.validation();
      });
    })
  };

  SS_Validation.validation = function () {
    var formData = new FormData();
    var serializeArray = $('form#item-form').serializeArray();
    $.each(serializeArray, function() {
      if (this.name === "_method") {
        return;
      }

      formData.append(this.name, this.value);
    });
    formData.append("model", SS_Validation.model);
    formData.append("id", SS_Validation.id);
    $.ajax({
      url: SS_Validation.url,
      method: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      success: function(data) {
        $.each(SS_Validation.labels, function(key, label) {
          var div = $("#item_" + key + "_errors");
          div.text("");
          if (data[key]) {
            $.each(data[key], function(index, value) {
              var span = $('<span></span>').text(label + value);
              div.append(span);
            })
          }
        });
      },
      error: function(xhr, status, error) {
        console.log(["== Error =="].concat(error).join("\n"));
      }
    });
  };

  return SS_Validation;

})();
