Gws_Workflow2_Approver = function () {
};

Gws_Workflow2_Approver.prototype.renderAgentForm = function(params) {
  this.superiorsUrl = params.url;
  this.errorHtml = params.error;

  var _this = this;
  var el = $('.change_agent_type')[0];
  var mo = new MutationObserver(function() {
    _this.changeApprovers();
  });
  mo.observe(el, { subtree: true, childList: true });

  $('input[name="item[workflow_agent_type]"]').on('change', function() {
    $('#item_workflow_approver_target').attr({ 'disabled': ($(this).val() == 'myself' ? 'disabled' : null) });
    $('.myself-approvers').css({ 'display': ($(this).val() == 'myself' ? 'block' : 'none') });
    $('.agent-approvers').css({ 'display': ($(this).val() == 'agent' ? 'block' : 'none') });
    _this.renderSubmitButton();
  });
};

Gws_Workflow2_Approver.prototype.changeApprovers = function() {
  var _this = this;
  var userId = $('.change_agent_type table.index input').val();

  if (!userId) {
    $('.gws-workflow-file-approver-item .agent-approvers input').val('');
    $('.gws-workflow-file-approver-item .agent-approvers .user').html('<br>');
    _this.renderSubmitButton();
    return;
  }

  $.ajax({
    url: this.superiorsUrl.replace('$id', userId),
    dataType: "json",
    beforeSend: function() {
      $('.gws-workflow-file-approver-item .agent-approvers input').val('');
      $('.gws-workflow-file-approver-item .agent-approvers .user').html('Loading..');
    },
    success: function(user) {
      $('.gws-workflow-file-approver-item .agent-approvers input').val(user._id);
      $('.gws-workflow-file-approver-item .agent-approvers .user').html(user.i18n_long_name);
    },
    error: function() {
      $('.gws-workflow-file-approver-item .agent-approvers input').val('');
      $('.gws-workflow-file-approver-item .agent-approvers .user').html(_this.errorHtml);
    },
    complete: function() {
      _this.renderSubmitButton();
    }
  });
};

Gws_Workflow2_Approver.prototype.renderSubmitButton = function() {
  var type = $('input[name="item[workflow_agent_type]"]:checked').val();

  if (type == 'myself') {
    $('form#workflow-request').find('.btn-primary').attr({ 'disabled': null });
  } else if (type == 'agent') {
    var disabled = $('input[name="item[workflow_approver_target]"]').val() == '';
    $('form#workflow-request').find('.btn-primary').attr({ 'disabled': (disabled ? 'disabled': null) });
  }
};
