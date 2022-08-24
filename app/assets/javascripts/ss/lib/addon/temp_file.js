this.SS_Addon_TempFile = (function () {
  function SS_Addon_TempFile(selector, userId, options) {
    this.$selector = $(selector.selector || selector);
    this.userId = userId;
    this.dropEventTriggered = null;

    if (options && options.select) {
      this.select = options.select;
    }

    if (options && options.selectUrl) {
      this.selectUrl = options.selectUrl;
    }

    if (options && options.uploadUrl) {
      this.uploadUrl = options.uploadUrl;
    }

    this.render();
  }

  SS_Addon_TempFile.renderDrop = function (selector, userId) {
    return new SS_Addon_TempFile(selector, userId, {});
  };

  SS_Addon_TempFile.prototype.select = function (files) {
    var sorted_name_and_datas = [];
    var file_views = [];
    for (var j = 0; j < files.length; j++) {
      var file = files[j];
      var id = file["_id"];
      var url = this.selectUrl(id);
      var params = {};
      if ($('#show-file-size').val()) {
        params['file_size'] = $('#show-file-size').val();
      }
      file_views.push($.ajax({
        url: url,
        data: params,
        success: function (data) {
          var file_name = $(data).find(".name").text().trim();
          sorted_name_and_datas.push({name: file_name, data: data});
        }
      }));
    }
    $.when.apply($,file_views).done(function () {
      sorted_name_and_datas.sort(function(a,b) {
        if(a.name < b.name) return 1;
        if(a.name > b.name) return -1;
        return 0;
      });
      for (var i = 0; i < sorted_name_and_datas.length; i++) {
        $("#selected-files").prepend(sorted_name_and_datas[i].data);
      }
    });
  }

  SS_Addon_TempFile.prototype.selectUrl = function (id) {
    return "/.u" + this.userId + "/apis/temp_files/" + id + "/select";
  };

  SS_Addon_TempFile.prototype.uploadUrl = function () {
    return "/.u" + this.userId + "/apis/temp_files.json";
  };

  SS_Addon_TempFile.prototype.render = function() {
    var _this = this;

    $(document).on("dragenter", _this.$selector, function(ev) {
      if (ev.target === _this.$selector[0]) {
        _this.onDragEnter(ev);
        return false;
      }
    });

    $(document).on("dragleave", _this.$selector, function(ev) {
      if (ev.target === _this.$selector[0]) {
        _this.onDragLeave(ev);
        return false;
      }
    });

    $(document).on("dragover", _this.$selector, function(ev) {
      if (ev.target === _this.$selector[0] || $.contains(_this.$selector[0], ev.target)) {
        _this.onDragOver(ev);
        return false;
      }
    });

    $(document).on("drop", _this.$selector, function(ev) {
      if (ev.target === _this.$selector[0] || $.contains(_this.$selector[0], ev.target)) {
        return _this.onDrop(ev);
      }
    });
  };

  SS_Addon_TempFile.prototype.onDragEnter = function(ev) {
    this.$selector.addClass('file-dragenter');
  };

  SS_Addon_TempFile.prototype.onDragLeave = function(ev) {
    this.$selector.removeClass('file-dragenter');
  };

  SS_Addon_TempFile.prototype.onDragOver = function(ev) {
    if (!this.$selector.hasClass('file-dragenter')) {
      this.$selector.addClass('file-dragenter');
    }
  };

  SS_Addon_TempFile.prototype.onDrop = function(ev) {
    var _this = this;
    var token = $('meta[name="csrf-token"]').attr('content');
    var formData = new FormData();
    formData.append('authenticity_token', token);
    var defaultFileResizing = SS_AjaxFile.defaultFileResizing();
    if (defaultFileResizing) {
      formData.append('item[resizing]', defaultFileResizing);
    }
    var files = ev.originalEvent.dataTransfer.files;
    if (files.length === 0) {
      return false;
    }
    if (_this.dropEventTriggered) {
      return false;
    }
    _this.dropEventTriggered = true;
    for (var j = 0, len = files.length; j < len; j++) {
      formData.append('item[in_files][]', files[j]);
    }
    var request = new XMLHttpRequest();
    request.onload = function (e) {
      if (request.readyState === XMLHttpRequest.DONE) {
        _this.$selector.removeClass('file-dragenter');
        if (request.status === 200 || request.status === 201) {
          var files = JSON.parse(request.response);
          _this.select(files, _this.$selector);
        } else if (request.status === 413) {
          alert(["== Error =="].concat(i18next.t('errors.messages.request_entity_too_large')).join("\n"));
        } else {
          try {
            var json = $.parseJSON(request.response);
            alert(["== Error =="].concat(json).join("\n"));
          } catch (_error) {
            alert(["== Error =="].concat(request.statusText).join("\n"));
          }
        }
        _this.dropEventTriggered = false;
      }
    };
    request.open("POST", _this.uploadUrl());
    request.send(formData);
    return false;
  };

  return SS_Addon_TempFile;

})();
