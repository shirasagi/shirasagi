SS_Workflow = function (el, options) {
  this.$el = $(el);
  this.options = options;

  var pThis = this;

  this.$el.on("click", ".update-item", function (e) {
    pThis.updateItem($(this));
    e.preventDefault();
    return false;
  });

  $(document).on("click", ".mod-workflow-approve .update-item", function (e) {
    pThis.updateItem($(this));
    e.preventDefault();
    return false;
  });

  $(document).on("click", ".mod-workflow-view .request-cancel", function (e) {
    pThis.cancelRequest($(this));
    e.preventDefault();
    return false;
  });

  this.$el.find(".mod-workflow-approve").insertBefore("#addon-basic");

  this.$el.find(".toggle-label").on("click", function (e) {
    pThis.$el.find(".request-setting").slideToggle();
    e.preventDefault();
    return false;
  });

  if (this.$el.find(".workflow-partial-section")[0]) {
    pThis.loadRouteList();
  }

  this.$el.on("click", ".workflow-route-start", function (e) {
    var routeId = $(this).siblings('#workflow_route:first').val();
    pThis.loadRoute(routeId);
    e.preventDefault();
    return false;
  });

  this.$el.on("click", ".workflow-route-cancel", function (e) {
    pThis.loadRouteList();
    e.preventDefault();
    return false;
  });

  this.$el.on("click", ".workflow-reroute", function (e) {
    var $this = $(this);
    var level = $this.data('level');
    var userId = $this.data('user-id');

    pThis.reroute(level, userId);
    e.preventDefault();
    return false;
  });

  $('.mod-workflow-approve .btn-file-upload').data('on-select', function($item) {
    $.colorbox.close();
    pThis.onUploadFileSelected($item);
  });

  this.tempFile = new SS_Addon_TempFile(
    ".mod-workflow-approve .upload-drop-area", this.options.user_id,
    { select: function(files, dropArea) { pThis.onDropFile(files, dropArea); } }
  );
};

SS_Workflow.prototype = {
  collectApprovers: function() {
    var approvers = [];

    this.$el.find(".workflow-multi-select").each(function () {
      approvers = approvers.concat($(this).val());
    });
    this.$el.find("input[name='workflow_approvers']").each(function() {
      approvers.push($(this).prop("value"));
    });

    return approvers;
  },
  collectApproverAttachmentUses: function() {
    var uses = [];

    this.$el.find("input[name='workflow_approver_attachment_uses']").each(function() {
      uses.push($(this).prop("value"));
    });

    return uses;
  },
  collectCirculations: function() {
    var circulations = [];

    this.$el.find("input[name='workflow_circulations']").each(function() {
      circulations.push($(this).prop("value"));
    });

    return circulations;
  },
  agentType: function() {
    return this.$el.find('input[name=agent_type]:checked').val();
  },
  collectDelegatees: function() {
    var delegatees = [];

    if (this.agentType() !== "agent") {
      return delegatees;
    }

    this.$el.find("input[name='workflow_delegatees']").each(function() {
      delegatees.push($(this).prop("value"));
    });

    return delegatees;
  },
  collectCirculationAttachmentUses: function() {
    var uses = [];

    this.$el.find("input[name='workflow_circulation_attachment_uses']").each(function() {
      uses.push($(this).prop("value"));
    });

    return uses;
  },
  collectFileIds: function() {
    var fileIds = [];

    $("input[name='workflow_file_ids[]']").each(function() {
      fileIds.push($(this).prop("value"));
    });

    return fileIds;
  },
  composeWorkflowUrl: function(controller) {
    if (this.options && this.options.paths && this.options.paths[controller]) {
      return this.options.paths[controller];
    }

    var uri = location.pathname.split("/");
    uri[2] = this.options.workflow_node;
    uri[3] = controller;
    if (uri.length > 5) {
      uri.splice(4, 1);
    }

    return uri.join("/");
  },
  updateItem: function($this) {
    var pThis = this;
    var updatetype = $this.attr("updatetype");
    var approvers = this.collectApprovers();
    if (SS.isEmptyObject(approvers) && updatetype === "request") {
      alert(this.options.errors.not_select);
      return;
    }

    var required_counts = [];
    this.$el.find("input[name='workflow_required_counts']").each(function() {
      required_counts.push($(this).prop("value"));
    });

    var uri = this.composeWorkflowUrl('pages');
    uri += "/" + updatetype + "_update";
    var workflow_comment = $("#workflow_comment").prop("value");
    var workflow_pull_up = $("#workflow_pull_up").prop("value");
    var workflow_on_remand = $("#workflow_on_remand").prop("value");
    var remand_comment = $("#remand_comment").prop("value");
    var forced_update_option;
    if (updatetype == "request") {
      forced_update_option = $("#forced-request").prop("checked");
    } else {
      forced_update_option = $("#forced-update").prop("checked");
    }
    var circulations = this.collectCirculations();
    var workflow_file_ids = this.collectFileIds();
    $.ajax({
      type: "POST",
      url: uri,
      data: {
        workflow_comment: workflow_comment,
        workflow_pull_up: workflow_pull_up,
        workflow_on_remand: workflow_on_remand,
        workflow_approvers: approvers,
        workflow_required_counts: required_counts,
        workflow_approver_attachment_uses: this.collectApproverAttachmentUses(),
        remand_comment: remand_comment,
        url: this.options.request_url,
        forced_update_option: forced_update_option,
        workflow_circulations: circulations,
        workflow_circulation_attachment_uses: this.collectCirculationAttachmentUses(),
        workflow_file_ids: workflow_file_ids,
        workflow_agent_type: this.agentType(),
        workflow_users: this.collectDelegatees()
      },
      success: function (data) {
        if (data.workflow_alert) {
          alert(data.workflow_alert);
          return;
        }

        if (data.redirect && data.redirect.reload) {
          location.reload();
          return;
        }

        if (data.redirect && data.redirect.show) {
          location.href = data.redirect.show;
          return;
        }

        if (data["workflow_state"] === "approve" && pThis.options.redirect_location) {
          location.href = pThis.options.redirect_location;
          return;
        }

        location.reload();
      },
      error: function(xhr, status) {
        try {
          var errors = $.parseJSON(xhr.responseText);
          alert(["== Error =="].concat(errors).join("\n"));
        }
        catch (ex) {
          alert(["== Error =="].concat(xhr["statusText"]).join("\n"));
        }
      }
    });
  },
  cancelRequest: function($this) {
    var confirmation = $this.data('ss-confirmation');
    if (confirmation) {
      if (!confirm(confirmation)) {
        return false;
      }
    }

    var method = $this.data('ss-method') || 'post';
    var action = $this.attr('href');
    var csrfToken = $('meta[name="csrf-token"]').attr('content');

    var saveHtml = $this.html();

    $this.prop("disabled", true);
    $this.html(SS.loading);

    $.ajax({
      type: method,
      url: action,
      data: {
        authenticity_token: csrfToken
      },
      success: function (data) {
        if (data["workflow_alert"]) {
          alert(data["workflow_alert"]);
          return;
        }
        if (data["workflow_state"] === "approve" && redirect_location !== "") {
          location.href = redirect_location;
        } else {
          location.reload();
        }
      },
      error: function(xhr, status) {
        var msg;
        try {
          var errors = $.parseJSON(xhr.responseText);
          msg = ["== Error =="].concat(errors).join("\n");
        } catch (ex) {
          msg = ["== Error =="].concat(xhr["statusText"]).join("\n");
        }
        alert(msg);
      },
      complete: function() {
        $this.html(saveHtml);
        $this.prop("disabled", false);
      }
    });
  },
  loadRouteList: function() {
    var pThis = this;
    var uri = this.composeWorkflowUrl('wizard');
    pThis.$el.find(".workflow-partial-section").html(SS.loading);
    $.ajax({
      type: "GET",
      url: uri,
      success: function(html, status) {
        pThis.$el.find(".workflow-partial-section").html(html);
      },
      error: function(xhr, status) {
        var msg;
        try {
          var errors = $.parseJSON(xhr.responseText);
          msg = ["== Error =="].concat(errors).join("\n");
        } catch(ex) {
          msg = ["== Error =="].concat(xhr["statusText"]).join("\n");
        }
        pThis.$el.find(".workflow-partial-section").html('<div class="error">' + msg + '</div>');
        alert(msg);
      }
    });
  },
  loadRoute: function(routeId) {
    var pThis = this;
    var uri = this.composeWorkflowUrl('wizard');
    uri += "/approver_setting";
    var data = { route_id: routeId };
    pThis.$el.find(".workflow-partial-section").html(SS.loading);
    $.ajax({
      type: "POST",
      url: uri,
      data: data,
      success: function(html, status) {
        pThis.$el.find(".workflow-partial-section").html(html);
      },
      error: function(xhr, status) {
        var msg;
        try {
          var errors = $.parseJSON(xhr.responseText);
          msg = errors.join("\n");
        } catch (ex) {
          msg = ["== Error =="].concat(xhr["statusText"]).join("\n");
        }
        pThis.$el.find(".workflow-partial-section").html(msg);
        alert(msg);
      }
    });
  },
  reroute: function(level, userId) {
    var uri = this.composeWorkflowUrl('wizard');
    uri += "/reroute";
    var param = $.param({ level: level, user_id: userId });
    uri += "?" + param;

    var pThis = this;
    $('<a/>').attr('href', uri).colorbox({
      fixed: true,
      width: "90%",
      height: "90%",
      open: true,
      onCleanup: function() {
        var selectedUserId = $('#cboxLoadedContent input[name=selected_user_id]').val();
        if (! selectedUserId) {
          return;
        }

        var uri = pThis.composeWorkflowUrl('wizard');
        uri += "/reroute";
        var data = {
          level: level, user_id: userId, new_user_id: selectedUserId, url: pThis.options.request_url
        };

        $.ajax({
          type: 'POST',
          url: uri,
          data: data,
          success: function(html, status) {
            location.reload();
          },
          error: function(xhr, status) {
            try {
              var errors = $.parseJSON(xhr.responseText);
              alert(errors.join("\n"));
            } catch (ex) {
              alert(["== Error =="].concat(xhr["statusText"]).join("\n"));
            }
          }
        });
      }
    });
  },
  fileSelectViewUrl: function(id) {
    var template = "/.u:user/apis/temp_files/:id/select.html";
    return template.replace(/:user/g, this.options.user_id).replace(/:id/g, id);
  },
  onUploadFileSelected: function($item) {
    var pThis = this;
    $.ajax({
      url: this.fileSelectViewUrl($item.data("id")),
      success: function(data, status, xhr) {
        pThis.renderFileHtml(data);
      },
      error: function (xhr, status, error) {
        alert("== Error ==");
      }
    });
  },
  renderFileHtml: function(data) {
    var pThis = this;
    var $html = $(data);
    $html.find("input[name='item[file_ids][]']").attr("name", "workflow_file_ids[]");
    $html.find(".action .action-delete").removeAttr("onclick", "").on("click", function(e) {
      e.preventDefault();
      pThis.deleteUploadedFile($(this));
      return false;
    });
    $html.find(".action .action-attach").remove();
    $html.find(".action .action-paste").remove();
    $html.find(".action .action-thumb").remove();
    $("#selected-files").append($html);
  },
  deleteUploadedFile: function($a) {
    $a.closest("div[data-file-id]").remove();
  },
  onDropFile: function(files, dropArea) {
    var pThis = this;
    for (var j = 0, len = files.length; j < len; j++) {
      var file = files[j];
      var id = file["_id"];
      var url = pThis.fileSelectViewUrl(id);
      $.ajax({
        url: url,
        success: function(data, status, xhr) {
          pThis.renderFileHtml(data);
        },
        error: function (xhr, status, error) {
          alert("== Error ==");
        }
      });
    }
  }
};

SS_WorkflowRerouteBox = function (el, options) {
  this.$el = $(el);
  this.options = options;

  var pThis = this;

  this.$el.find('form.search').on("submit", function(e) {
    $(this).ajaxSubmit({
      url: $(this).attr("action"),
      success: function (data) {
        pThis.$el.closest("#cboxLoadedContent").html(data);
      },
      error: function (data, status) {
        alert("== Error ==");
      }
    });

    e.preventDefault();
  });

  this.$el.find('.pagination a').on("click", function(e) {
    var url = $(this).attr("href");
    pThis.$el.closest("#cboxLoadedContent").load(url, function(response, status, xhr) {
      if (status === 'error') {
        alert("== Error ==");
      }
    });

    e.preventDefault();
    return false;
  });

  this.$el.find('.select-single-item').on("click", function(e) {
    var $this = $(this);
    if (! SS.disableClick($this)) {
      return false;
    }

    pThis.selectItem($this);

    e.preventDefault();
    $.colorbox.close();
  });
};

SS_WorkflowRerouteBox.prototype = {
  selectItem: function($this) {
    var listItem = $this.closest('.list-item');
    var id = listItem.data('id');
    var name = listItem.data('name');
    var email = listItem.data('email');

    var source_name = this.$el.data('name');
    var source_email = this.$el.data('email');

    if (source_name) {
      if (source_email) {
        source_name += '(' + source_email + ')'
      }
    }

    var message = '';
    if (source_name) {
      message += source_name;
      message += 'を';
    }
    message += name + '(' + email + ')' + 'に変更します。よろしいですか？';
    if(! confirm(message)) {
      return;
    }

    this.$el.find('input[name=selected_user_id]').val(id);
  }
};
