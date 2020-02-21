Cms_TemplateForm = function(options) {
  this.options = options;
  this.$formChangeBtn = $('#addon-basic .btn-form-change');
  this.$formSelect = $('#addon-basic select[name="item[form_id]"]');
  this.$formPage = $('#addon-cms-agents-addons-form-page');
  this.$formPageBody = this.$formPage.find('.addon-body');
  this.selectedFormId = null;

  if (Cms_TemplateForm.target) {
    this.bind(Cms_TemplateForm.target.el, Cms_TemplateForm.target.options);
  }
};

Cms_TemplateForm.instance = null;
Cms_TemplateForm.userId = null;
Cms_TemplateForm.target = null;
Cms_TemplateForm.confirms = {};
Cms_TemplateForm.paths = {};

// fast: 200
// normal: 400
// slow: 600
Cms_TemplateForm.duration = 400;

Cms_TemplateForm.render = function(options) {
  if (Cms_TemplateForm.instance) {
    return;
  }

  var instance = new Cms_TemplateForm(options);
  instance.render();
  Cms_TemplateForm.instance = instance;
};

Cms_TemplateForm.bind = function(el, options) {
  if (Cms_TemplateForm.instance) {
    Cms_TemplateForm.instance.bind(el, options)
  } else {
    Cms_TemplateForm.target.el = el;
    Cms_TemplateForm.target.options = options;
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
  if (Cms_Form.addonSelector == ".mod-body-part-html") {
    return false;
  }
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
  $("#addon-cms-agents-addons-body_part").addClass('hide');
  $('#addon-cms-agents-addons-file').addClass('hide');
  $("#addon-cms-agents-addons-form-page").removeClass('hide');
  $("#item_body_layout_id").parent('dd').prev('dt').addClass('hide');
  $("#item_body_layout_id").parent('dd').addClass('hide');
  Cms_Form.addonSelector = "#addon-cms-agents-addons-form-page .addon-body";
  Cms_Form.activateSyntaxChecks();
};

Cms_TemplateForm.prototype.deactivateForm = function() {
  this.$formPageBody.html('');
  this.$formPage.addClass('hide');
  $('#addon-cms-agents-addons-body').removeClass('hide');
  $("#addon-cms-agents-addons-body_part").addClass('hide');
  $('#addon-cms-agents-addons-file').removeClass('hide');
  $("#addon-cms-agents-addons-form-page").addClass('hide');
  $("#item_body_layout_id").parent('dd').prev('dt').removeClass('hide');
  $("#item_body_layout_id").parent('dd').removeClass('hide');
  Cms_Form.addonSelector = ".mod-cms-body";
  Cms_Form.activateSyntaxChecks();
};

Cms_TemplateForm.prototype.bind = function(el, options) {
  var bindsOne = (!this.el || this.el !== el);

  if (bindsOne) {
    this.bindOne(el, options);
  }

  this.resetOrder();
};

Cms_TemplateForm.prototype.bindOne = function(el, options) {
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
        Cms_Form.activateSyntaxChecks();
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

  if (options && options.type === "entry") {
    this.$el.find(".addon-body").sortable({
      axis: "y",
      handle: '.sortable-handle',
      items: "> .column-value",
      // start: function (ev, ui) {
      //   console.log("start");
      // },
      beforeStop: function(ev, ui) {
        ui.item.trigger("column:beforeMove");
      },
      stop: function (ev, ui) {
        ui.item.trigger("column:afterMove");
      },
      update: function (ev, ui) {
        self.resetOrder();
      }
    });
  }
};

Cms_TemplateForm.prototype.resetOrder = function() {
  var count = this.$el.find(".column-value").length;

  var optionTemplate = "<option value=\":value\">:display</option>";
  var options = [];
  for (var i = 0; i < count; i++) {
    options.push(optionTemplate.replace(":value", i.toString()).replace(":display", (i + 1).toString()));
  }

  this.$el.find(".column-value").each(function(index) {
    var $select = $(this).find(".column-value-controller-move-position");
    $select.html(options.join(""));
    $select.val(index);
  });
};

Cms_TemplateForm.prototype.movePosition = function($evSource) {
  var self = this;

  var moveToIndex = $evSource.val();
  if (! moveToIndex) {
    return;
  }
  moveToIndex = parseInt(moveToIndex);

  var $source = $evSource.closest(".column-value");
  var source = $source[0];

  var $columnValues = this.$el.find(".column-value");
  var sourceIndex = -1;
  $columnValues.each(function(index) {
    if (this === source) {
      sourceIndex = index;
      return false;
    }
  });
  if (sourceIndex < 0) {
    return;
  }

  if (moveToIndex === sourceIndex || moveToIndex >= $columnValues.length || moveToIndex < 0) {
    // are set some alert animations needed?
    return;
  }

  var $moveTo;
  var moveToMethod;
  if (moveToIndex < sourceIndex) {
    // move up
    $moveTo = $($columnValues[moveToIndex]);
    moveToMethod = $moveTo.before.bind($moveTo);
  } else {
    // move down
    $moveTo = $($columnValues[moveToIndex]);
    moveToMethod = $moveTo.after.bind($moveTo);
  }

  Cms_TemplateForm.insertElement($source, $moveTo, function() {
    $source.trigger("column:beforeMove");

    moveToMethod($source);
    self.resetOrder();

    $source.trigger("column:afterMove");
  });
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

  var self = this;
  Cms_TemplateForm.swapElement($prev, $columnValue, function() {
    $columnValue.trigger("column:beforeMove");

    $prev.before($columnValue);
    self.resetOrder();

    $columnValue.trigger("column:afterMove");
  });
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

  var self = this;
  Cms_TemplateForm.swapElement($columnValue, $next, function() {
    $columnValue.trigger("column:beforeMove");

    $next.after($columnValue);
    self.resetOrder();

    $columnValue.trigger("column:afterMove");
  });
};

Cms_TemplateForm.swapElement = function($upper, $lower, completion) {
  var upper = $upper[0];
  var lower = $lower[0];

  var diff = lower.offsetTop - upper.offsetTop;
  var spacing = lower.offsetTop - (upper.offsetTop + upper.offsetHeight);

  upper.style.transitionDuration = Cms_TemplateForm.duration + 'ms';
  lower.style.transitionDuration = Cms_TemplateForm.duration + 'ms';
  upper.style.transform = "translateY(" + (lower.offsetHeight + spacing) + "px)";
  lower.style.transform = "translateY(" + (-diff) + "px)";

  setTimeout(function() {
    upper.style.transitionDuration = "";
    lower.style.transitionDuration = "";
    upper.style.transform = "";
    lower.style.transform = "";

    completion();
  }, Cms_TemplateForm.duration);
};

Cms_TemplateForm.insertElement = function($source, $destination, completion) {
  var source = $source[0];
  var destination = $destination[0];

  if (source === destination) {
    completion();
    return;
  }

  var sourceDisplacement;
  var destinationDisplacement;
  var intermediateElements = [];
  if (destination.offsetTop < source.offsetTop) {
    // moveUp
    if (source === destination.nextElementSibling) {
      Cms_TemplateForm.swapElement($destination, $source, completion);
      return;
    }

    var sourceBottom = source.offsetTop + source.offsetHeight;
    var prev = source.previousElementSibling;
    var prevBottom = prev.offsetTop + prev.offsetHeight;

    sourceDisplacement = destination.offsetTop - source.offsetTop;
    destinationDisplacement = sourceBottom - prevBottom;

    var el = destination;
    while (el !== source) {
      intermediateElements.push(el);
      el = el.nextElementSibling;
    }
  } else if (destination.offsetTop > source.offsetTop) {
    // moveDown
    if (source === destination.previousElementSibling) {
      Cms_TemplateForm.swapElement($source, $destination, completion);
      return;
    }

    var destinationBottom = destination.offsetTop + destination.offsetHeight;
    var sourceBottom = source.offsetTop + source.offsetHeight;
    var next = source.nextElementSibling;

    sourceDisplacement = destinationBottom - sourceBottom;
    destinationDisplacement = source.offsetTop - next.offsetTop;

    var el = destination;
    while (el !== source) {
      intermediateElements.push(el);
      el = el.previousElementSibling;
    }
  }

  source.style.transitionDuration = Cms_TemplateForm.duration + "ms";
  source.style.transform = "translateY(" + sourceDisplacement + "px)";

  intermediateElements.forEach(function(el) {
    el.style.transitionDuration = Cms_TemplateForm.duration + "ms";
    el.style.transform = "translateY(" + destinationDisplacement + "px)";
  });

  setTimeout(function() {
    source.style.transitionDuration = "";
    source.style.transform = "";
    intermediateElements.forEach(function(el) {
      el.style.transitionDuration = "";
      el.style.transform = "";
    });

    completion();
  }, Cms_TemplateForm.duration);
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
  $columnValue.addClass("column-value-deleting").fadeOut(Cms_TemplateForm.duration).queue(function() {
    $columnValue.remove();
    self.resetOrder();
    Cms_Form.activateSyntaxChecks();
  });
};
