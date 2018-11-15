Cms_TemplateForm = function(options) {
  this.options = options;
  this.$formChangeBtn = $('#addon-basic .btn-form-change');
  this.$formSelect = $('#addon-basic select[name="item[form_id]"]');
  this.$formPage = $('#addon-cms-agents-addons-form-page');
  this.$formPageBody = this.$formPage.find('.addon-body');
  this.selectedFormId = null;

  if (Cms_TemplateForm.targetEl) {
    this.bind(Cms_TemplateForm.targetEl);
  }
};

Cms_TemplateForm.instance = null;
Cms_TemplateForm.userId = null;
Cms_TemplateForm.targetEl = null;
Cms_TemplateForm.confirms = {};
Cms_TemplateForm.paths = {};

Cms_TemplateForm.render = function(options) {
  if (Cms_TemplateForm.instance) {
    return;
  }

  var instance = new Cms_TemplateForm(options);
  instance.render();
  Cms_TemplateForm.instance = instance;
};

Cms_TemplateForm.bind = function(el) {
  if (Cms_TemplateForm.instance) {
    Cms_TemplateForm.instance.bind(el)
  } else {
    Cms_TemplateForm.targetEl = el;
  }
};

Cms_TemplateForm.prototype.render = function() {
  // this.changeForm();

  var pThis = this;
  this.$formChangeBtn.on('click', function() {
    pThis.changeForm();
  });
};

Cms_TemplateForm.prototype.changeForm = function() {
  var formId = this.$formSelect.val();
  if (formId) {
    if (!this.selectedFormId || this.selectedFormId !== formId) {
      this.loadAndActivateForm(formId);
      this.selectedFormId = formId;
    } else {
      this.activateForm();
    }
  } else {
    this.deactivateForm();
  }
};

Cms_TemplateForm.prototype.loadAndActivateForm = function(formId) {
  var pThis = this;

  this.$formChangeBtn.attr('disabled', true);
  $.ajax({
    url: Cms_TemplateForm.paths.formUrlTemplate.replace(':id', formId),
    type: 'GET',
    success: function(html) {
      pThis.loadForm(html);
      pThis.activateForm();
    },
    error: function(xhr, status, error) {
      pThis.showError(error);
      pThis.activateForm();
    },
    complete: function() {
      pThis.$formChangeBtn.attr('disabled', false);
    }
  });
};

Cms_TemplateForm.prototype.loadForm = function(html) {
  this.$formPage.html($(html).html());
  // SS.render();
  SS.renderAjaxBox();
  SS.renderDateTimePicker();
};

Cms_TemplateForm.prototype.showError = function(msg) {
  this.$formPageBody.html('<p>' + msg + '</p>');
};

Cms_TemplateForm.prototype.activateForm = function() {
  this.$formPage.removeClass('hide');
  $('#addon-cms-agents-addons-body').addClass('hide');
  $('#addon-cms-agents-addons-file').addClass('hide');
  Cms_Form.addonSelector = "#addon-cms-agents-addons-form-page .addon-body";
};

Cms_TemplateForm.prototype.deactivateForm = function() {
  this.$formPageBody.html('');
  this.$formPage.addClass('hide');
  $('#addon-cms-agents-addons-body').removeClass('hide');
  $('#addon-cms-agents-addons-file').removeClass('hide');
  Cms_Form.addonSelector = ".mod-cms-body";
};

Cms_TemplateForm.prototype.bind = function(el) {
  var bindsOne = (!this.el || this.el !== el);

  if (bindsOne) {
    this.bindOne(el);
  }

  this.resetOrder();

  var self = this;
  this.$el.find('.btn-file-upload').each(function() {
    var $this = $(this);
    var $columnValue = $this.closest(".column-value");
    if (! $columnValue[0]) {
      return;
    }

    $this.data("on-select", function($item) { self.selectFile($columnValue, $item) });
  });
};

Cms_TemplateForm.prototype.bindOne = function(el) {
  this.el = el;
  this.$el = $(el);

  var self = this;
  this.$el.on("change", ".column-value-controller-move-position", function(ev) {
    self.movePosition($(this));
  });

  this.$el.on("click", ".column-value-controller-move-up", function(ev) {
    self.moveUp($(this));
  });

  this.$el.on("click", ".column-value-controller-move-down", function(ev) {
    self.moveDown($(this));
  });

  this.$el.on("click", ".column-value-controller-delete", function(ev) {
    self.remove($(this));
  });

  // initialize command palette
  this.$el.on("click", ".column-value-palette [data-form-id]", function() {
    var $this = $(this);
    var formId = $this.data("form-id");
    var columnId = $this.data("column-id");

    $this.closest("fieldset").attr("disabled", true);
    $this.css('cursor', "wait");
    $this.closest(".column-value-palette").find(".column-value-palette-error").addClass("hide").html("");
    $.ajax({
      url: Cms_TemplateForm.paths.formColumn.replace(/:formId/, formId).replace(/:columnId/, columnId),
      success: function(data, status, xhr) {
        var $palette = $this.closest(".column-value-palette");
        $palette.before(data);
        var $inserted = $palette.prev(".column-value");
        // SS.render();
        SS.renderAjaxBox();
        SS.renderDateTimePicker();
        $inserted.find(".btn-file-upload").data("on-select", function($item) { self.selectFile($inserted, $item) });
        self.resetOrder();
      },
      error: function(xhr, status, error) {
        $this.closest(".column-value-palette").find(".column-value-palette-error").html(error).removeClass("hide");
      },
      complete: function(xhr, status) {
        $this.css('cursor', "pointer");
        $this.closest("fieldset").attr("disabled", false);
      }
    });
  });

  this.$el.on("click", ".btn-file-delete", function(e) {
    var $this = $(this);
    var $fileView = $this.closest(".file-view");

    $fileView.fadeOut().queue(function() {
      $fileView.remove();
    });

    e.preventDefault();
    return false;
  });

  var options = {};
  options.uploadUrl = function() {
    return "/.s" + Cms_TemplateForm.userId + "/cms/apis/temp_files.json";
  };
  options.select = function(files, dropArea) {
    if (! files[0]) {
      return;
    }

    var $fileView = $(dropArea).closest(".column-value").find(".column-value-files");
    $fileView.addClass("hide");

    var fileId = files[0]["_id"];
    $.ajax({
      url: Cms_TemplateForm.paths.formTempFileSelect.replace(":fileId", fileId),
      type: 'GET',
      success: function(html) {
        $fileView.html(html);
      },
      error: function(xhr, status, error) {
        $fileView.html(error);
      },
      complete: function() {
        $fileView.removeClass("hide");
      }
    });
  };

  this.tempFile = new SS_Addon_TempFile($(".column-value-upload-drop-area"), Cms_TemplateForm.userId, options);

};

Cms_TemplateForm.prototype.resetOrder = function() {
  var count = this.$el.find(".column-value").length;

  var optionTemplate = "<option value=\":value\">:display</option>";
  var options = [];
  for (var i = 0; i < count; i++) {
    options.push(optionTemplate.replace(":value", i.toString()).replace(":display", (i + 1).toString()));
  };
  options.push(optionTemplate.replace(":value", count.toString()).replace(":display", "末尾"));

  this.$el.find(".column-value").each(function(index) {
    var $select = $(this).find(".column-value-controller-move-position");
    $select.html(options.join(""));
    $select.val(index);
  });
};

Cms_TemplateForm.prototype.movePosition = function($evTarget) {
  var val = $evTarget.val();
  if (! val) {
    return;
  }

  var $columnValue = $evTarget.closest(".column-value");

  var $columnValues = this.$el.find(".column-value");
  val = parseInt(val);
  if (val >= $columnValues.length) {
    var $moveTo = $($columnValues[$columnValues.length - 1]);
    $moveTo.after($columnValue);
  } else {
    var $moveTo = $($columnValues[val]);
    $moveTo.before($columnValue);
  }

  this.resetOrder();
};

Cms_TemplateForm.prototype.moveUp = function($evTarget) {
  var $columnValue = $evTarget.closest(".column-value");
  if (! $columnValue[0]) {
    return;
  }

  var $prev = $columnValue.prev(".column-value");
  if (! $prev[0]) {
    return;
  }

  $prev.before($columnValue);
  this.resetOrder();
};

Cms_TemplateForm.prototype.moveDown = function($evTarget) {
  var $columnValue = $evTarget.closest(".column-value");
  if (! $columnValue[0]) {
    return;
  }

  var $next = $columnValue.next(".column-value");
  if (! $next[0]) {
    return;
  }

  $next.after($columnValue);
  this.resetOrder();
};

Cms_TemplateForm.prototype.remove = function($evTarget) {
  var $columnValue = $evTarget.closest(".column-value");
  if (! $columnValue[0]) {
    return;
  }

  if (! confirm(Cms_TemplateForm.confirms.delete)) {
    return;
  }

  var self = this;
  $columnValue.addClass("column-value-deleting").fadeOut().queue(function() {
    $columnValue.remove();
    self.resetOrder();
  });
};

Cms_TemplateForm.prototype.selectFile = function($columnValue, $item) {
  var $fileView = $columnValue.find(".column-value-files");
  $fileView.addClass("hide");

  $.colorbox.close();

  var fileId = $item.data('id');
  // var humanizedName = $item.data('humanized-name');
  // if (! fileId || ! humanizedName) {
  //   return;
  // }
  //
  // var $element = $.colorbox.element();
  // $element.siblings('input.file-id').val(fileId);
  // $element.siblings('span.humanized-name').text(humanizedName);
  // $element.siblings('.btn-file-delete').show();

  if (! fileId) {
    return;
  }

  $.ajax({
    url: Cms_TemplateForm.paths.formTempFileSelect.replace(":fileId", fileId),
    type: 'GET',
    success: function(html) {
      $fileView.html(html);
    },
    error: function(xhr, status, error) {
      $fileView.html(error);
    },
    complete: function() {
      $fileView.removeClass("hide");
    }
  });
};
