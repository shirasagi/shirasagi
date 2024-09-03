Gws_Workflow2_Approver = function () {
};

Gws_Workflow2_Approver.prototype.renderAgentForm = function(params) {
  this.superiorsUrl = params.url;
  this.errorHtml = $("<span/>", { class: "error" }).text(i18next.t("gws/workflow2.errors.messages.superior_is_not_found"));

  var _this = this;
  $('.agent-type-agent .ajax-selected').on('change', function() {
    _this.changeApprovers();
  });

  $('input[name="item[workflow_agent_type]"]').on('change', function() {
    var type = $(this).val();
    if (type === 'myself') {
      $('.myself-approvers').removeClass('hide');
      $('.agent-approvers').addClass('hide');
    } else {
      $('.myself-approvers').addClass('hide');
      $('.agent-approvers').removeClass('hide');
    }
    _this.renderSubmitButton();
  });
};

Gws_Workflow2_Approver.prototype.changeApprovers = function() {
  var _this = this;
  var userId = $('.change_agent_type table.index input').val();

  if (!userId) {
    var $message = $("<span />", { class: "info" }).text(i18next.t("gws/workflow2.errors.messages.plz_select_delegatee"));
    $('.gws-workflow-file-approver-item .agent-approvers').html($message);
    _this.renderSubmitButton();
    return;
  }

  $.ajax({
    url: this.superiorsUrl.replace('$id', userId),
    dataType: "json",
    beforeSend: function() {
      $('.gws-workflow-file-approver-item .agent-approvers').text('Loading..');
    },
    success: function(user) {
      $('.gws-workflow-file-approver-item .agent-approvers').text(user.long_name);
    },
    error: function() {
      $('.gws-workflow-file-approver-item .agent-approvers').html(_this.errorHtml);
    },
    complete: function() {
      _this.renderSubmitButton();
    }
  });
};

Gws_Workflow2_Approver.prototype.renderSubmitButton = function() {
  var disabled = $('.gws-workflow-file-approver-item').find('.user:not(.hide)').find('.error,.info').length > 0;
  $('form#workflow-request').find('.btn-primary').attr({ 'disabled': (disabled ? 'disabled': null) });
};
