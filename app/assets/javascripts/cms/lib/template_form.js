Cms_TemplateForm = function(options) {
  this.options = options;
  this.$formPage = $('#addon-cms-agents-addons-form-page');
  this.$formPageBody = this.$formPage.find('.addon-body');
};

Cms_TemplateForm.prototype = {
  render: function() {
    var $select = $('#addon-basic select[name="item[form_id]"]');
    var pThis = this;

    $('#addon-basic .btn-form-change').on('click', function() {
      pThis.changeForm($select.val());
    });

    if ($select.val()) {
      this.activateForm();
    } else {
      this.deactivateForm();
    }
  },
  changeForm: function(formId) {
    var param = this.options.params;
    if (!param) {
      param = {};
    }

    if (formId) {
      param.form_id = formId;
    } else {
      param.form_id = '';
    }

    location.href = this.options.url + '?' + $.param(param);
  },
  showError: function(msg) {
    this.$formPageBody.html('<p>' + msg + '</p>');
  },
  activateForm: function() {
    this.$formPage.show();
    $('#addon-cms-agents-addons-body').hide();
    $('#addon-cms-agents-addons-file').hide();
  },
  deactivateForm: function() {
    this.$formPageBody.html('');
    this.$formPage.hide();
    $('#addon-cms-agents-addons-body').show();
    $('#addon-cms-agents-addons-file').show();
  }
};
