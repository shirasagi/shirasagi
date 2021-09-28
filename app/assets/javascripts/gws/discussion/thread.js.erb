this.Gws_Discussion_Thread = (function () {
  function Gws_Discussion_Thread() {
  }

  Gws_Discussion_Thread.render = function (user) {
    //temp file
    var appendSelectedFile = function (selected, fileId, humanizedName) {
      var span = $('<span></span>');
      var img = $('<img src="/assets/img/gws/ic-file.png" alt="" />');
      var a = $('<a target="_blank" rel="noopener"></a>');
      var input = $('<input type="hidden" name="item[file_ids][]" class="file-id" />');
      var icon = $("<i class=\"material-icons md-18 md-inactive deselect\">close</i>");

      span.attr("data-file-id", fileId);
      span.attr("id", "file-" + fileId);
      a.text(humanizedName);
      a.attr("href", "/.u" + user + "/apis/temp_files/" + fileId + "/view");
      input.attr("value", fileId);
      icon.on("click", function (e) {
        $(this).parent("span").remove();
        if ($(selected).find("[data-file-id]").length <= 0) {
          $(selected).hide();
        }
        return false;
      });

      span.append(img);
      span.append(a);
      span.append(icon);
      span.append(input);

      $(selected).show();
      $(selected).append(span);
    };

    $('a.ajax-box').data('on-select', function ($item) {
      var selected = $.colorbox.element().closest(".comment-files").find(".selected-files");
      var $data = $item.closest('[data-id]');
      var fileId = $data.data('id');
      var humanizedName = $data.data('humanized-name');
      appendSelectedFile(selected, fileId, humanizedName);
      return $.colorbox.close();
    });

    var options = {
      select: function (files, dropArea) {
        $(files).each(function (i, file) {
          var fileId, humanizedName, selected;
          selected = $(dropArea).closest(".comment-files").find(".selected-files");
          fileId = file["_id"];
          humanizedName = file["name"];
          return appendSelectedFile(selected, fileId, humanizedName);
        });
        return false;
      }
    };

    $(".comment-files .upload-drop-area").each(function() {
      new SS_Addon_TempFile(this, user, options);
    });

    // reply
    $(".open-reply").on('click', function () {
      $(this).closest(".addon-body").next(".reply").show();
      $(this).remove();
      return false;
    });

    //rely contriutor
    $(".reply[data-topic]").each(function () {
      var topic = $(this).attr("data-topic");
      var setContributor = function () {
        $('.discussion-contributor' + topic + ' input#item_contributor_model').val($(this).data('model'));
        $('.discussion-contributor' + topic + ' input#item_contributor_id').val($(this).data('id'));
        return $('.discussion-contributor' + topic + ' input#item_contributor_name').val($(this).data('name'));
      };
      $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]').on('change', setContributor);
      return $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]:checked').each(setContributor);
    });
  };

  return Gws_Discussion_Thread;

})();
