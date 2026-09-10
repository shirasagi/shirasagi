this.Form_Alert = (function () {
  function Form_Alert() {};

  Cms_Form.alert = Form_Alert;

  Form_Alert.alerts = {};

  Form_Alert.asyncValidations = [];

  Form_Alert.beforeSaves = [];

  Form_Alert.render = function () {
    $("input:submit").on("click.form_alert", function (e) {
      var submitter = this;
      var $submitter = $(submitter);
      var $form = $submitter.closest("form");

      var resolved = function(html) {
        var promise = Form_Alert.asyncValidate($form, submitter, { html: html });
        promise.done(function() {
          if (!SS.isEmptyObject(Form_Alert.alerts)) {
            Form_Alert.showAlert($form, submitter);
            $submitter.trigger("ss:formAlertFinish");
            return;
          }

          $submitter.off(".form_alert");
          $submitter.trigger("ss:formAlertFinish");
          // To protected from bubbling events within a event wraps trigger "click" with setTimeout
          setTimeout(function() { $submitter.trigger("click"); }, 0);
        });
      };

      var rejected = function(xhr, status, error) {
        alert(error);
        $submitter.trigger("ss:formAlertFinish");
      };

      $submitter.trigger("ss:formAlertStart");
      Cms_Form.getHtml(resolved, rejected);

      e.preventDefault();
      return false;
    });
  };

  Form_Alert.asyncValidate = function ($form, submitter, opts) {
    Form_Alert.alerts = {};
    var promises = [];
    $.each(Form_Alert.asyncValidations, function () {
      var promise = this($form, submitter, opts);
      promises.push(promise);
    });

    return $.when.apply($, promises);
  };

  Form_Alert.addValidation = function (validate) {
    return Form_Alert.asyncValidations.push(Form_Alert.wrapDeferred(validate));
  };

  Form_Alert.addAsyncValidation = function (validate) {
    return Form_Alert.asyncValidations.push(validate);
  };

  Form_Alert.runBeforeSave = function (form, submit) {
    return $.each(Form_Alert.beforeSaves, function () {
      return this(form, submit);
    });
  };

  Form_Alert.showAlert = function ($form, submitter) {
    var $div = $('<div/>', { id: "alertExplanation", class: "errorExplanation" });
    $div.append($("<h2/>").text(i18next.t('cms.alert')));

    var appendAlerts = function (alerts) {
      for (var addon in alerts) {
        var fields = alerts[addon];
        $div.append($('<p />').text(addon));
        var $ul = $("<ul>").appendTo($div);
        var i, j, len;
        for (i = j = 0, len = fields.length; j < len; i = ++j) {
          var field = fields[i];
          if (field["msg"]) {
            $ul.append($('<li />').html(field["msg"]));
          }
        }
      }
    }
    appendAlerts(Form_Alert.alerts);

    // caution: below IE8, you must use document.createElement() method to create <footer>
    var $footer = $(document.createElement("footer")).addClass('send');
    var allowEdit = true;
    if (!SS.isEmptyObject(Form_Alert.alerts[i18next.t("cms.backlink_check")])) {
      allowEdit = false;
    } else if (!SS.isEmptyObject(Form_Alert.alerts[i18next.t("cms.syntax_check")])) {
      $.each(Form_Alert.alerts[i18next.t("cms.syntax_check")], function(id, alert) {
        if (alert["msg"] === i18next.t('cms.confirm.disallow_edit_ignore_syntax_check')) {
          if (submitter.name === "draft_save" || submitter.name === "branch_save") {
            allowEdit = true;
          } else {
            allowEdit = false;
          }
        }
      });
    }
    if (allowEdit) {
      $footer.append($('<button/>'), { name: "button", type: "button", class: "btn-primary save" }).text(i18next.t("ss.buttons.ignore_alert"));
    }
    $footer.append($('<button/>', { name: "button", type: "button", class: "btn-default cancel" }).text(i18next.t("ss.buttons.cancel")));
    $.colorbox({
      html: $div.get(0).outerHTML + $footer.get(0).outerHTML,
      maxHeight: "80%",
      fixed: true
    });
    $("#cboxLoadedContent").find(".save").on("click", function () {
      Form_Alert.runBeforeSave($form, submitter);
      $(submitter).off(".form_alert");
      return $(submitter).trigger("click");
    });
    $("#cboxLoadedContent").find(".cancel").on("click", function (_e) {
      $.colorbox.close();
      return false;
    });
  };

  Form_Alert.addBeforeSave = function (callback) {
    return Form_Alert.beforeSaves.push(callback);
  };

  Form_Alert.asyncValidateSyntaxCheck = function ($form, submitter, _opts) {
    var promise = Syntax_Checker.asyncCheck2($form, submitter);
    promise.done(function() {
      $.each(Syntax_Checker.errors, function(id, error) {
        Form_Alert.add(i18next.t('cms.syntax_check'), error["ele"], error["msg"]);
      });
    });
    return promise;
  };

  Form_Alert.wrapDeferred = function (validate) {
    return function ($form, submitter, opts) {
      var d = $.Deferred();
      try {
        validate($form, submitter, opts);
        d.resolve();
      } catch (ex) {
        d.reject(ex);
      }
      return d.promise($form, submitter, opts);
    };
  };

  Form_Alert.clonedName = function ($form, submitter, _opts) {
    var $name = $form.find("#addon-basic #item_name");
    if ($(submitter).hasClass("publish_save") && new RegExp(`^\\[${RegExp.escape(i18next.t('workflow.cloned_name_prefix'))}\\]`).test($name.val())) {
      var addonName = $name.closest(".addon-view").find("header").text();
      return Form_Alert.add(addonName, $name, i18next.t('errors.messages.cloned_name'));
    }
  };

  Form_Alert.closeConfirmation = function ($form, submitter, _opts) {
    var addonName, msg;
    if ($(submitter).attr("data-close-confirmation")) {
      addonName = i18next.t("cms.confirm.close");
      msg = null;
      if ($(submitter).attr("data-contain-links-path")) {
        msg = $("<a/>", { href: $(submitter).attr("data-contain-links-path"), target: "_blank", ref: "noopener" })
          .text(i18next.t("cms.confirm.check_contains_urls"))
          .prop("outerHTML");
      }
      return Form_Alert.add(addonName, null, msg);
    }
  };

  Form_Alert.snsPostConfirmation = function ($form, submitter) {
    var addonName, messages, f;
    f = $(submitter).data("sns-post-confirmation");

    messages = [];
    if (f) {
      messages = f();
    }

    addonName = i18next.t("cms.sns_post");
    $.each(messages, function() {
      Form_Alert.add(addonName, null, this);
    });
  }

  Form_Alert.add = function (addon, ele, msg) {
    var base;
    (base = Form_Alert.alerts)[addon] || (base[addon] = []);
    return Form_Alert.alerts[addon].push({
      "ele": ele,
      "msg": msg
    });
  };

  return Form_Alert;

})();
