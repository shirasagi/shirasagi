SS_Workflow = function (el, options) {
  this.$el = $(el);
  this.options = options;

  var pThis = this;

  $(document).on("click", el + " .update-item", function (e) {
    pThis.updateItem($(this));
    e.preventDefault();
    return false;
  });

  $(document).on("click", ".mod-workflow-approve .update-item", function (e) {
    pThis.updateItem($(this));
    e.preventDefault();
    return false;
  });

  this.$el.find(".mod-workflow-approve").insertBefore("#addon-basic");

  this.$el.find(".toggle-label").on("click", function (e) {
    pThis.$el.find(".request-setting").slideToggle();
    e.preventDefault();
    return false;
  });

  this.$el.find(".workflow-partial-section").each(function() {
    pThis.loadRouteList();
  });

  $(document).on("click", el + " .workflow-route-start", function (e) {
    var routeId = $(this).siblings('#workflow_route:first').val();
    pThis.loadRoute(routeId);
    e.preventDefault();
    return false;
  });

  $(document).on("click", el + " .workflow-route-cacnel", function (e) {
    pThis.loadRouteList();
    e.preventDefault();
    return false;
  });
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
  composeWorkflowUrl: function(type) {
    var uri = location.pathname.split("/");
    uri[2] = this.options.workflow_node;
    uri[3] = type;
    if (uri.length > 5) {
      uri.splice(4, 1);
    }

    return uri.join("/");
  },
  updateItem: function($this) {
    var approvers = this.collectApprovers();
    if ($.isEmptyObject(approvers) && $this.attr("type") === "request") {
      alert(this.options.errors.not_select);
      return;
    }

    var required_counts = [];
    this.$el.find("input[name='workflow_required_counts']").each(function() {
      required_counts.push($(this).prop("value"));
    });

    var uri = this.composeWorkflowUrl('pages');
    var updatetype = $this.attr("updatetype");
    uri += "/" + updatetype + "_update";
    var workflow_comment = $("#workflow_comment").prop("value");
    var redirect_location = this.options.redirect_location;
    var remand_comment = $("#remand_comment").prop("value");
    var forced_update_option;
    if (updatetype == "request") {
      forced_update_option = $("#forced-request").prop("checked");
    } else {
      forced_update_option = $("#forced-update").prop("checked");
    }
    $.ajax({
      type: "POST",
      url: uri,
      async: false,
      data: {
        workflow_comment: workflow_comment,
        workflow_approvers: approvers,
        workflow_required_counts: required_counts,
        remand_comment: remand_comment,
        url: this.options.request_url,
        forced_update_option: forced_update_option
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
  loadRouteList: function() {
    var pThis = this;
    var uri = this.composeWorkflowUrl('wizard');
    $.ajax({
      type: "GET",
      url: uri,
      async: false,
      success: function(html, status) {
        pThis.$el.find(".workflow-partial-section").html(html);
      },
      error: function(xhr, status) {
        try {
          var errors = $.parseJSON(xhr.responseText);
          alert(["== Error =="].concat(errors).join("\n"));
        } catch(ex) {
          alert(["== Error =="].concat(xhr["statusText"]).join("\n"));
        }
      }
    });
  },
  loadRoute: function(routeId) {
    var pThis = this;
    var uri = this.composeWorkflowUrl('wizard');
    uri += "/approver_setting";
    var data = { route_id: routeId };
    $.ajax({
      type: "POST",
      url: uri,
      async: false,
      data: data,
      success: function(html, status) {
        pThis.$el.find(".workflow-partial-section").html(html);
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
};
