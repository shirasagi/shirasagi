









this.Cms_Form = (function () {
  function Cms_Form() {};

  Cms_Form.options = { check: { syntax: true } };
  Cms_Form.addonSelector = ".mod-cms-body";

  Cms_Form.render = function () {
    // handle Syntax_Checker
    if(Cms_Form.options.check.syntax) {
      Syntax_Checker.render(Cms_Form, { afterCheck: Cms_Form.afterSyntaxCheck });
    }

    // handle Link_Checker
    Link_Checker.render();

    // handle Mobile_Size_Checker
    Mobile_Size_Checker.render();

    // handle Form_Alert
    Form_Alert.addValidation(Form_Alert.clonedName);
    Form_Alert.addValidation(Form_Alert.closeConfirmation);
    Form_Alert.addValidation(Form_Alert.snsPostConfirmation);
    if(Cms_Form.options.check.syntax) {
      Form_Alert.addAsyncValidation(Form_Alert.asyncValidateSyntaxCheck);
    }
    Form_Alert.addAsyncValidation(Mobile_Size_Checker.asyncValidateHtml);
    Form_Alert.render();

    // handle Form_Preview
    Form_Preview.render();
  };

  // wiziwig editor
  Cms_Form.editorId = "item_html";
  Cms_Form.getEditorHtml = function (id) {
    var html;
    if (id == null) {
      id = null;
    }
    id || (id = Cms_Form.editorId);
    if (typeof tinymce !== 'undefined') {
      html = "<div>" + tinymce.get(id).getContent() + "</div>";
    } else if (typeof CKEDITOR !== 'undefined') {
      html = "<div>" + CKEDITOR.instances[id].getData() + "</div>";
    } else {
      html = "";
    }
    return html;
  };
  Cms_Form.setEditorHtml = function (html, opts) {
    opts = opts || {}
    id = opts["id"];

    if (id == null) {
      id = null;
    }
    id || (id = Cms_Form.editorId);
    if (typeof tinymce !== 'undefined') {
      return tinymce.get(id).setContent(html);
    } else if (typeof CKEDITOR !== 'undefined') {
      return CKEDITOR.instances[id].setData(html);
    }
  };

  // activate syntax checks
  Cms_Form.syntaxChecks = {};
  Cms_Form.addSyntaxCheck = function (id, check) {
    Cms_Form.syntaxChecks[id] = check;
  };
  Cms_Form.activateSyntaxChecks = function () {
    Syntax_Checker.resetChecks();
    $.each(Cms_Form.syntaxChecks, function(id, check) {
      var ele = $('#' + id)[0];
      if (ele && $(ele).is(':visible')) {
        Syntax_Checker.addCheck(id, check);
      }
    });
  };
  Cms_Form.afterSyntaxCheck = function () {
    // emptyAttributesCheck
    $("[data-check-presence]").each(function () {
      var attr = $(this).attr("data-check-presence");
      if(attr && !$(this).val()) {
        var id = null;

        id = $(this).closest(".column-value").attr("id");
        id = id || $(this).closest(".addon-view").attr("id");

        Syntax_Checker.errors.push(
          {
            id: id,
            idx: 0,
            code: attr,
            msg: (attr + 'を入力してください。'),
            ele: this
          }
        );
      }
    });

    var h = [], ids = [], code, id, errorIdx, ref, i, j;
    $("#addon-cms-agents-addons-form-page .column-value-cms-column-headline").each(function () {
      ids.push($(this).attr("id"));
      h.push($(this).find('[name="item[column_values][][in_wrap][head]"]').val());
    });

    // orderOfH
    errorIdx = [];
    if (h.length) {
      for (i = j = 0, ref = h.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        if (i === 0) {
          if (!/h[12]/i.test(h[i])) {
            errorIdx.push(i);
          }
        } else {
          if (/h3/i.test(h[i])) {
            if (!/h[234]/i.test(h[i - 1])) {
              errorIdx.push(i);
            }
          } else if (/h4/i.test(h[i])) {
            if (!/h[34]/i.test(h[i - 1])) {
              errorIdx.push(i);
            }
          }
        }
      }
    }

    for (i = 0; i < errorIdx.length; i++) {
      var idx = errorIdx[i];
      Syntax_Checker.errors.push(
        {
          id: ids[idx],
          idx: 0,
          code: h[idx],
          msg: Syntax_Checker.message["invalidOrderOfH"],
          detail: Syntax_Checker.detail["invalidOrderOfH"]
        }
      );
    }
  };

  // get page html (use in Mobile_Size_Checker at Form_Alert)
  Cms_Form.form_html_path = null;
  Cms_Form.form_link_check_path = null;
  Cms_Form.getHtml = function (resolve, reject) {
    if ([".mod-cms-body", ".mod-body-part-html"].includes(Cms_Form.addonSelector)) {
      resolve(Cms_Form.getEditorHtml());
      return;
    }

    if (! Cms_Form.form_html_path) {
      if (reject) {
        reject(null, null, "form html path is not configured");
      }
      return;
    }

    var formData = Cms_Form.getFormData($("#" + Form_Preview.form_id));
    formData.append("route", Form_Preview.page_route);

    $.ajax({
      type: "POST",
      url: Cms_Form.form_html_path,
      data: formData,
      processData: false,
      contentType: false,
      cache: false,
      success: function(html) { resolve("<div>" + html + "</div>") },
      error: function(xhr, status, error) {
        if (reject) {
          reject(xhr, status, error);
        }
      }
    });
  };
  Cms_Form.getFormData = function($form, options) {
    if (!options) {
      options = {};
    }

    var formData = new FormData();
    $.each($form.serializeArray(), function() {
      if (!options.preserveMethod && this.name === "_method") {
        return;
      }

      formData.append(this.name, this.value);
    });
    return formData;
  };

  return Cms_Form;
})();
this.Form_Alert = (function () {
  function Form_Alert() {};

  Cms_Form.alert = Form_Alert;

  Form_Alert.alerts = {};

  Form_Alert.asyncValidations = [];

  Form_Alert.beforeSaves = [];

  Form_Alert.render = function () {
    $("input:submit").on("click.form_alert", function (e) {
      var submit = this;
      var form = $(submit).closest("form");

      var resolved = function(html) {
        var promise = Form_Alert.asyncValidate(form, submit, { html: html });
        promise.done(function() {
          if (! SS.isEmptyObject(Form_Alert.alerts)) {
            Form_Alert.showAlert(form, submit);
            return;
          }

          $(submit).off(".form_alert");
          // To protected from bubbling events within a event wraps trigger "click" with setTimeout
          setTimeout(function() { $(submit).trigger("click"); }, 0);
        });
      };

      var rejected = function(xhr, status, error) {
        alert(error);
      };

      Cms_Form.getHtml(resolved, rejected);

      e.preventDefault();
      return false;
    });
  };

  Form_Alert.asyncValidate = function (form, submit, opts) {
    Form_Alert.alerts = {};
    var promises = [];
    $.each(Form_Alert.asyncValidations, function () {
      var promise = this(form, submit, opts);
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

  Form_Alert.showAlert = function (form, submit) {
    var div = $('<div id="alertExplanation" class="errorExplanation">');
    div.append("<h2>警告</h2>");
    var ref = Form_Alert.alerts;
    var alert_msg = $(submit).attr("data-alert-msg");
    for (var addon in ref) {
      var fields = ref[addon];
      div.append('<p>' + addon + '</p>');
      if　(alert_msg)　{
        div.append("<p>" + alert_msg + "</p>");
      }
      var ul = $("<ul>").appendTo(div);
      var i, j, len;
      for (i = j = 0, len = fields.length; j < len; i = ++j) {
        var field = fields[i];
        if (field["msg"]) {
          ul.append('<li>' + field["msg"] + '</li>');
        }
      }
    }
    // caution: below IE8, you must use document.createElement() method to create <footer>
    var footer = $(document.createElement("footer")).addClass('send');
    
    if (!alert_msg) {
      footer.append('<button name="button" type="button" class="btn-primary save">警告を無視する</button>');
    }
    footer.append('<button name="button" type="button" class="btn-default cancel">キャンセル</button>');
    $.colorbox({
      html: div.get(0).outerHTML + footer.get(0).outerHTML,
      maxHeight: "80%",
      fixed: true
    });
    $("#cboxLoadedContent").find(".save").on("click", function () {
      Form_Alert.runBeforeSave(form, submit);
      $(submit).off(".form_alert");
      return $(submit).trigger("click");
    });
    $("#cboxLoadedContent").find(".cancel").on("click", function (e) {
      $.colorbox.close();
      return false;
    });
  };

  Form_Alert.addBeforeSave = function (callback) {
    return Form_Alert.beforeSaves.push(callback);
  };

  Form_Alert.asyncValidateSyntaxCheck = function (form, submit, opts) {
    var promise = Syntax_Checker.asyncCheck();
    promise.done(function() {
      $.each(Syntax_Checker.errors, function(id, error) {
        Form_Alert.add("アクセシビリティチェック", error["ele"], error["msg"]);
      });
    });
    return promise;
  };

  Form_Alert.presence = function (form, submit) {
    return $(form).find("input.presence,textarea.presence").each(function () {
      var addonName, fieldName;
      if ($(this).val() === "") {
        $(this).closest("dl").show();
        addonName = $(this).closest(".addon-view").find("header").text();
        fieldName = Form_Alert.justText($(this).closest("dd").prev("dt"));
        return Form_Alert.add(addonName, this, fieldName + "を入力してください。");
      }
    });
  };

  Form_Alert.wrapDeferred = function (validate) {
    return function (form, submit) {
      var d = $.Deferred();
      try {
        validate(form, submit);
        d.resolve();
      } catch (ex) {
        d.reject(ex);
      }
      return d.promise(form, submit);
    };
  };

  Form_Alert.clonedName = function (form, submit) {
    var name = $(form).find("#addon-basic #item_name");
    if ($(submit).hasClass("publish_save") && /^\[複製\]/.test($(name).val())) {
      var addonName = $(name).closest(".addon-view").find("header").text();
      return Form_Alert.add(addonName, name, "タイトルに[複製]が含まれています。");
    }
  };

  Form_Alert.closeConfirmation = function (form, submit) {
    var addonName, msg;
    if ($(submit).attr("data-close-confirmation")) {
      addonName = '非公開状態で保存しようとしています';
      msg = null;
      if ($(submit).attr("data-contain-links-path")) {
        msg = '<a href="' + $(submit).attr("data-contain-links-path") + '" target="_blank" rel="noopener">' + 'このページへのリンクを確認する。' + '</a>';
      }
      return Form_Alert.add(addonName, null, msg);
    }
  };

  Form_Alert.snsPostConfirmation = function (form, submit) {
    var addonName, messages, f;
    f = $(submit).data("sns-post-confirmation");

    messages = [];
    if (f) {
      messages = f();
    }

    addonName = 'SNS投稿連携';
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

  Form_Alert.justText = function (ele) {
    return $(ele).clone().children().remove().end().text();
  };

  Form_Alert.validateReplaceWord = function (form, submit) {
    var addonIds, excludes, k, results, v, words;
    words = Syntax_Checker.config["replace_words"];
    if (!words) {
      return;
    }
    addonIds = ["#addon-basic", "#addon-cms-agents-addons-meta", "#addon-event-agents-addons-date", "#addon-map-agents-addons-page"];
    excludes = ['[name="item[basename]"]', "location-search.keyword"];
    results = [];
    for (k in words) {
      v = words[k];
      results.push($(form).find(addonIds.join(",")).find("input,textarea").not(excludes.join(",")).each(function () {
        var addonName, fieldName, val;
        val = $(this).val();
        if (val && !SS.isEmptyObject(val.match(RegExp("" + k.replace(/([.?*+$\[\]\/\\(){}|\-])/g, '\\$1'), "g")))) {
          $(this).closest("dl").show();
          addonName = $(this).closest(".addon-view").find(".addon-head").text();
          fieldName = Form_Alert.justText($(this).closest("dd").prev("dt"));
          return Form_Alert.add(addonName, this, fieldName + "に使用が好ましくない単語が含まれています。" + ("「" + k + "」→「" + v + "」"));
        }
      }));
    }
    return results;
  };

  return Form_Alert;

})();
this.Form_Preview = (function () {
  function Form_Preview() {
  }

  Form_Preview.form_preview_path;

  Form_Preview.form_id = "item-form";

  Form_Preview.page_route;

  Form_Preview.render = function () {
    $("button.preview").not(".form-preview-rendered").on("click", function (e) {
      var basename, errors, form, height, i, name, ref, token, v, width;
      name = $("#" + Form_Preview.form_id + " input[name='item[name]']").val();
      basename = $("#" + Form_Preview.form_id + " input[name='item[basename]']").val();
      errors = [];
      if (!name) {
        errors.push("タイトルを入力してください。");
      }
      if (basename) {
        if (!/^[\w\-]+(\.html)?$/.test(basename)) {
          errors.push("ファイル名は不正な値です。");
        }
      } else {
        errors.push("ファイル名を入力してください。");
      }
      if (!SS.isEmptyObject(errors)) {
        alert(errors.join("\n"));
        return false;
      }
      token = $('meta[name="csrf-token"]').attr('content');
      form = $("<form>");
      $(form).attr("method", "post");
      $(form).attr("action", Form_Preview.form_preview_path);
      $(form).attr("target", "FormPreview");
      ref = $("#" + Form_Preview.form_id).serializeArray();
      for (i in ref) {
        v = ref[i];
        if (!/^item\[/.test(v["name"])) {
          continue;
        }
        if ("item[html]" === v["name"]) {
          continue;
        }
        if ("item[body_parts][]" === v["name"]) {
          continue;
        }
        form.append($("<input/>", {
          name: v["name"].replace(/^item\[/, "preview_item["),
          value: v["value"],
          type: "hidden"
        }));
      }
      $("textarea[id^=item_html_part_]").each(function () {
        var id;
        id = $(this).attr("id");
        name = $(this).attr("name").replace(/^item\[/, "preview_item[");
        return form.append($("<input/>", {
          name: name,
          value: Cms_Form.getEditorHtml(id),
          type: "hidden"
        }));
      });
      form.append($("<input/>", {
        name: "preview_item[route]",
        value: Form_Preview.page_route,
        type: "hidden"
      }));
      form.append($("<input/>", {
        name: "preview_item[html]",
        value: Cms_Form.getEditorHtml("item_html"),
        type: "hidden"
      }));
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      width = $(window).width();
      height = $(window).height();
      window.open("about:blank", "FormPreview", "width=" + width + ",height=" + height + ",resizable=yes,scrollbars=yes");
      form.appendTo("body");
      form.submit();
      return false;
    });
    $("button.preview").addClass("form-preview-rendered");
  };

  return Form_Preview;

})();
this.Form_Save_Event = (function () {
  function Form_Save_Event() {
  }

  Form_Save_Event.render = function () {
    return document.onkeydown = function (e) {
      if (event.ctrlKey || event.metaKey) {
        if (event.keyCode === 83) {
          event.keyCode = 0;
          $("#" + Form_Preview.form_id).submit();
          return false;
        }
      }
    };
  };

  return Form_Save_Event;

})();
this.Cms_Inplace_Form = (function () {
  function Cms_Inplace_Form() {
  }

  Cms_Inplace_Form.addonSelector = ".inplace-checkers";
  Cms_Inplace_Form.resolveType = "text";

  Cms_Inplace_Form.getFormData = Cms_Form.getFormData;

  Cms_Inplace_Form.options = { check: { form: true, syntax: true, link: true } };
  Cms_Inplace_Form.linkChecker = null;
  Cms_Inplace_Form.formChecker = null;

  Cms_Inplace_Form.render = function () {
    if (Cms_Inplace_Form.options.check.syntax) {
      Syntax_Checker.render(Cms_Inplace_Form, { afterCheck: Cms_Inplace_Form.afterSyntaxCheck });
    }
    if (Cms_Inplace_Form.options.check.link) {
      Cms_Inplace_Form.linkChecker = Link_Checker.render(Cms_Inplace_Form);
    }
    if (Cms_Inplace_Form.options.check.form) {
      Cms_Inplace_Form.formChecker = Form_Checker.render(Cms_Inplace_Form);
    }
    Cms_Inplace_Form.renderSaveIfNoAlerts();
  };

  Cms_Inplace_Form.setEditorHtml = function (content, opts) {
    opts = opts || {}
    Cms_Inplace_Form.setContent(content, opts);
  };

  Cms_Inplace_Form.afterSyntaxCheck = function () {
    // emptyAttributesCheck
    $("[data-check-presence]").each(function () {
      var attr = $(this).attr("data-check-presence");
      if(attr && !$(this).val()) {
        var id = null;

        id = $(this).closest(".column-value").attr("id");

        Syntax_Checker.errors.push(
          {
            id: id,
            idx: 0,
            code: attr,
            msg: (attr + 'を入力してください。'),
            ele: this
          }
        );
      }
    });
  };

  Cms_Inplace_Form.renderSaveIfNoAlerts = function () {
    $('input:submit[name="save_if_no_alerts"]').on("click.form_alert", function (ev) {
      var $this = $(this);

      var promises = [];
      if (Cms_Inplace_Form.options.check.syntax) {
        promises.push(Syntax_Checker.asyncCheck());
      }
      if (Cms_Inplace_Form.options.check.link) {
        promises.push(Cms_Inplace_Form.linkChecker.asyncCheck());
      }
      if (Cms_Inplace_Form.options.check.form) {
        promises.push(Cms_Inplace_Form.formChecker.asyncCheck());
      }

      if (promises.length === 0) {
        return true;
      }

      $.when.apply($, promises).then(function() {
        var result = true;
        for (var i = 0; i < arguments.length; i++) {
          if (arguments[i].status !== "ok") {
            result = false;
            break;
          }
        }

        if (result) {
          $this.off(".form_alert");
          $this.trigger("click");
        }
      });

      ev.preventDefault();
      return false;
    });
  };

  return Cms_Inplace_Form;

})();
this.Syntax_Checker = (function () {
  function ResultBox(form) {
    this.$el = null;
    this.$elBody = null;
    this.form = form;
  }

  ResultBox.prototype.init = function() {
    if (this.$el) {
      return this;
    }

    var $div = $("#errorSyntaxChecker");
    if ($div[0]) {
      this.$el = $div;
      this.$elBody = $div.find(".errorExplanationBody");

      return this.moveLast();
    }

    $div = $("<div/>", { id: 'errorSyntaxChecker', class: 'errorExplanation' });
    $div.append("<h2>" + "アクセシビリティチェック" + "</h2>");

    var $body = $("<div/>", { class: 'errorExplanationBody' });
    $div.append($body);

    this.$el = $div;
    this.$elBody = $body;

    return this.moveLast();
  };

  ResultBox.prototype.moveLast = function() {
    $(this.form.addonSelector).append(this.$el);
    return this;
  };

  ResultBox.prototype.showMessage = function(message) {
    this.init();
    this.$elBody.html(message);
    this.moveLast();
    return this;
  }

  ResultBox.prototype.showChecking = function() {
    return this.showMessage(SS.loading);
  };

  ResultBox.prototype.showResult = function (checks, errors) {
    if (errors.length == 0) {
      this.showMessage("<p>" + "エラーは見つかりませんでした。" + "</p>");
      return;
    }

    this.init();

    var ul = $("<ul/>");

    this.appendMessage(ul, checks, errors);

    this.$elBody.html("")
    this.$elBody.append("<p>" + "次の項目を確認してください。" + "</p>");
    this.$elBody.append(ul);

    this.moveLast();

    $(window).trigger('resize');

    return this;
  };

  ResultBox.prototype.appendMessage = function (ul, checks, errors) {
    var self = this;
    var correct, li, message, code, column;

    var errorHash = {};

    $.each(errors, function(_, error) {
      var id = error["id"];
      errorHash[id] = errorHash[id] || [];
      (errorHash[id]).push(error);
    });

    $.each(checks, function(id, check) {
      errors = errorHash[id];

      if (errors) {
        // append column name
        if (check["name"]) {
          column = $('<li class="column-name">');
          column.text(check["name"]);
          ul.append(column);
        }

        $.each(errors, function(_, error) {
          // append code
          code = $('<code>')
          code.text(error["code"]);
          ul.append('<li class="code">');
          ul.find('li:last').append(code);

          // append message
          ul.append('<ul>');
          ul.find('> ul:last').append('<li>');
          li = ul.find('> ul:last li:last');
          message = $('<span class="message detail">' + error["msg"] + '</span>');
          if (error["detail"]) {
            var tooltip = $('<div class="tooltip">!</div>').appendTo(message);
            var detail = $('<ul class="tooltip-content">').appendTo(tooltip);
            $.each(error["detail"], function () {
              detail.append("<li>" + this + "<br></li>");
            });
          }
          li.append(message);

          // append correct
          if (error["correctContent"]) {
            correct = $('<a href="#" class="correct">' + "自動修正" + '</a>');
            correct.on("click", function (e) {
              var setContent, getContent, correctContent, resolve, type;

              correctContent = error["correctContent"];
              setContent = check["setContent"];
              getContent = check["getContent"];
              resolve = check["resolve"];
              type = check["type"];

              setContent(correctContent(id, { content: getContent(), resolve: resolve, type: type }, error));
              $(self.form.addonSelector).find("button.syntax-check").trigger("click");

              return false;
            });
            li.append(correct)
          }
        });
      }
    });

    return;
  };

  function Syntax_Checker() {};

  Syntax_Checker.checks = {};
  Syntax_Checker.errors = [];
  Syntax_Checker.errorCount = 0;

  Syntax_Checker.form = null;
  Syntax_Checker.resultBox = null;
  Syntax_Checker.afterCheck = null;

  Syntax_Checker.render = function (form, options) {
    form = form || Cms_Form
    options = options || {};

    Syntax_Checker.form = form;
    Syntax_Checker.options = options;
    Syntax_Checker.resultBox = new ResultBox(Syntax_Checker.form);
    Syntax_Checker.afterCheck = options["afterCheck"];

    $(document).on("click", "button.syntax-check", function () {
      var button = this;
      button.disabled = true;

      var complete = function () {
        button.disabled = false;
      };

      Syntax_Checker.resultBox.init();
      Syntax_Checker.resultBox.showChecking();
      Syntax_Checker.asyncCheck().done(complete).fail(complete);
    });
  };

  Syntax_Checker.config = {};

  Syntax_Checker.asyncCheck = function () {
    var defer = $.Deferred();

    var resolve = function() {

      try {
        Syntax_Checker.check();
        Syntax_Checker.resultBox.showResult(Syntax_Checker.checks, Syntax_Checker.errors);
        defer.resolve({ status: Syntax_Checker.errors.length == 0 ? "ok" : "failed" });
      } catch (e) {
        Syntax_Checker.resultBox.showMessage("<p>" + e + "</p>");
        defer.reject(null, null, e);
      }
    };

    resolve();

    return defer.promise();
  };

  Syntax_Checker.addCheck = function (id, options) {
    options = options || {};

    var name = options["name"] || null;
    var resolve = options["resolve"] || "text";
    var type = options["type"] || "string";
    var getContent = options["getContent"];
    var setContent = options["setContent"];
    var afterCheck = options["afterCheck"];

    Syntax_Checker.checks[id] = {
      name: name,
      resolve: resolve,
      type: type,
      getContent: getContent,
      setContent: setContent,
      afterCheck: afterCheck
    };
  };

  Syntax_Checker.resetChecks = function () {
    Syntax_Checker.checks = {};
    Syntax_Checker.errors = [];
    Syntax_Checker.errorCount = 0;
  };

  Syntax_Checker.getContents = function () {
    var contents = {};

    $.each(Syntax_Checker.checks, function(id, check) {
      contents[id] = { content: check["getContent"](), resolve: check["resolve"], type: check["type"], afterCheck: check["afterCheck"] };
    });

    return contents;
  };

  Syntax_Checker.check = function () {
    var contents, afterCheck;

    Syntax_Checker.reset();

    contents = Syntax_Checker.getContents();
    $.each(contents, function(id, content) {
      if (content["resolve"] == "html") {
        Syntax_Checker.checkHtml(id, content);
      }
      else {
        Syntax_Checker.checkText(id, content);
      }

      afterCheck = content["afterCheck"];
      if (afterCheck) {
        afterCheck(id, content);
      }
    });

    if (Syntax_Checker.afterCheck) {
      Syntax_Checker.afterCheck();
    };

    return Syntax_Checker.errors;
  };

  Syntax_Checker.reset = function () {
    this.errors = [];
  };

  Syntax_Checker.checkHtml =  function (id, content) {
    Syntax_Checker.checkDateFormat(id, content);
    Syntax_Checker.checkInterwordSpace(id, content);
    Syntax_Checker.checkKanaCharacter(id, content);
    Syntax_Checker.checkMultibyteCharacter(id, content);
    Syntax_Checker.checkReplaceWords(id, content);

    Syntax_Checker.checkAdjacentA(id, content);
    Syntax_Checker.checkAppletAlt(id, content);
    Syntax_Checker.checkAreaAlt(id, content);
    Syntax_Checker.checkEmbeddedMedia(id, content);
    Syntax_Checker.checkImgAlt(id, content);
    Syntax_Checker.checkImgDataUriScheme(id, content);
    Syntax_Checker.checkLinkText(id, content);
    Syntax_Checker.checkObjectText(id, content);
    Syntax_Checker.checkOrderOfH(id, content);
    Syntax_Checker.checkTable(id, content);
  }

  Syntax_Checker.checkText =  function (id, content) {
    Syntax_Checker.checkDateFormat(id, content);
    Syntax_Checker.checkInterwordSpace(id, content);
    Syntax_Checker.checkKanaCharacter(id, content);
    Syntax_Checker.checkMultibyteCharacter(id, content);
    Syntax_Checker.checkReplaceWords(id, content);
  }

  Syntax_Checker.isValidDate = function (date) {
    if (Object.prototype.toString.call(date) !== "[object Date]") {
      return false;
    }
    if (!isNaN(date.getTime()) && date.getYear() > 0) {
      return true;
    } else {
      return false;
    }
  };

  Syntax_Checker.justText = function (ele) {
    return $(ele).clone().children().remove().end().text();
  };

  Syntax_Checker.outerHtmlSummary = function (ele) {
    return $(ele).get(0).outerHTML.replace(/[\r\n]|&nbsp;/g, "");
  };

  // javascript syntax check

  Syntax_Checker.message = {
    notSetImgAlt: "画像の代替テキストを確認してください。",
    notSetAppletAlt: "アプレット要素の代替テキストを確認してください。",
    notSetAreaAlt: "エリア要素の代替テキストを確認してください。",
    invalidImgScheme: "画像のURIにバイナリー文字列が含まれています。",
    notSetTableCaption: "表にキャプションが設定されていません。",
    notSetThScope: "表のヘッダーにスコープ属性が設定されていません。",
    invalidOrderOfH: "見出し(H)の順番が不正です。",
    invalidMultibyteCharacter: "英数字は半角文字を入力してください。",
    invalidKanaCharacter: "半角カナ文字が含まれています。",
    invalidDateFormat: "日付の表記は○年○月○日としてください。",
    invalidAdjacentA: "隣接する同じリンクを一つのリンクにまとめてください。",
    checkInterwordSpace: "単語の文字間のスペースを確認してください。",
    checkLinkText: "リンクのテキストを確認してください。",
    checkObjectText: "オブジェクト要素のボディに適切な代替テキストを記述してください。",
    checkEmbeddedMedia: "動画や音声を含む場合、説明があるか確認してください。",
    replaceWord: "使用が好ましくない単語が含まれています。",
    altIsIncludedInFilename: "代替テキストがファイル名に含まれています。"
  };
  Syntax_Checker.detail = {
    notSetImgAlt: ["画像の内容を示す代替テキストを設定してください。"],
    notSetAppletAlt: ["アプレットの内容を示す代替テキストを設定してください。"],
    notSetAreaAlt: ["エリア要素の内容を示す代替テキストを設定してください。"],
    invalidImgScheme: ["画像のSRC属性にデータ形式のURIスキームが存在します。","他のURIスキームを使用してください。"],
    notSetTableCaption: ["表に見出し(CAPTION)が設定されていません","TABLEタグの中にCAPTIONタグを追記してください。"],
    notSetThScope: ["表のヘッダー(TH)に見出しの方向であるSCOPE属性が設定されていません。","行方向であればscope=\"colを設定してください。","列方向であればscope=\"row\"を設定してください。"],
    invalidOrderOfH: ["適切な順に配置してください。"],
    invalidMultibyteCharacter: ["本文に全角英数が含まれています。","半角英数に置き換えるか削除してください。"],
    invalidKanaCharacter: ["本文に半角カナ文字が含まれています。","全角文字に置き換えるか削除してください。"],
    invalidDateFormat: ["日付の形式を修正してください。"],
    invalidAdjacentA: ["隣り合うリンク(A)に同じリンク先が設定されています。","一つのリンク(A)にマークアップしてください。"],
    checkInterwordSpace: ["単語の文字間に不要なスペースが含まれている場合は削除してください。"],
    checkLinkText: ["リンク内のテキストは遷移先を表すものを設定してください。"],
    checkObjectText: ["オブジェクト要素が正しく読み込まれなかった場合の説明を要素内に記述してください。"],
    checkEmbeddedMedia: ["動画や音声を本文に埋め込む場合は説明を記述してください。"],
    altIsIncludedInFilename: ["代替テキストの一部もしくは全部がファイル名に含まれています。","一般的にファイル名をそのまま代替テキストに設定するのは好ましくないと考えられます。","設定している代替テキストが妥当かどうか確認してください。"]
  };
  Syntax_Checker.mediaExtensions = [
    "aac", "aif", "aiff", "au", "avi", "flac", "flv", "mid",
    "midi", "mp3", "m4a", "mp4", "mpg", "mpeg", "oga", "ogg",
    "tta", "vdo", "wav", "wma", "wmv"
  ];

  Syntax_Checker.formatContent = function (content) {
    var value = content["content"];
    var resolve = content["resolve"];
    var type = content["type"];
    var array = [];

    if (type == "array") {
      $.each(value, function(_, v) {
        v = v || "";
        if (resolve == "html") {
          array.push(v);
        }
        else {
          array.push("<div>" + v + "</div>");
        }
      });
    } else {
      value = value || "";
      if (resolve == "html") {
        array.push(value);
      }
      else {
        array.push("<div>" + value + "</div>");
      }
    }
    return array;
  }

  // MultibyteCharacter
  Syntax_Checker.checkMultibyteCharacter = function (id, content) {
    var array, chars;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      chars = [];
      $(html).find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType == 3;
      }).each(function () {
        var c;
        c = this.textContent.match(/[Ａ-Ｚａ-ｚ０-９]/g);
        if (c) {
          return chars.push(c);
        }
      });
      if (!SS.isEmptyObject(chars)) {
        Syntax_Checker.errors.push(
          {
            id: id,
            idx: idx,
            code: chars.join(","),
            ele: html,
            msg: Syntax_Checker.message["invalidMultibyteCharacter"],
            detail: Syntax_Checker.detail["invalidMultibyteCharacter"],
            correctContent: Syntax_Checker.correctMultibyteCharacter
          }
        );
      }
    });
  };
  Syntax_Checker.correctMultibyteCharacter = function (id, content, error) {
    var array, ret;

    ret = [];
    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);
      html.find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType == 3;
      }).each(function () {
        var text;
        text = this.textContent.replace(/[Ａ-Ｚａ-ｚ０-９]/g, function (c) {
          return String.fromCharCode(c.charCodeAt(0) - 0xFEE0);
        });
        return this.textContent = text;
      });
      ret.push(html.html());
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // KanaCharacter
  Syntax_Checker.checkKanaCharacter = function (id, content) {
    var array, chars;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      chars = html.match(/[｡-ﾟ]/g);
      if (!SS.isEmptyObject(chars)) {
        Syntax_Checker.errors.push(
          {
            id: id,
            idx: idx,
            code: chars.join(","),
            ele: html,
            msg: Syntax_Checker.message["invalidKanaCharacter"],
            detail: Syntax_Checker.detail["invalidKanaCharacter"],
            correctContent: Syntax_Checker.correctKanaCharacter
          }
        );
      }
    });
  };
  Syntax_Checker.correctKanaCharacter = function (id, content, error) {
    var array, ret, kanaMap, markedkanaMap;

    ret = [];
    array = Syntax_Checker.formatContent(content);

    kanaMap = {
      '｡': '。', '｢': '「', '｣': '」', '､': '、', '･': '・', 'ｦ': 'ヲ',
      'ｧ': 'ァ', 'ｨ': 'ィ', 'ｩ': 'ゥ', 'ｪ': 'ェ', 'ｫ': 'ォ', 'ｬ': 'ャ',
      'ｭ': 'ュ', 'ｮ': 'ョ', 'ｯ': 'ッ', 'ｰ': 'ー', 'ｱ': 'ア', 'ｲ': 'イ',
      'ｳ': 'ウ', 'ｴ': 'エ', 'ｵ': 'オ', 'ｶ': 'カ', 'ｷ': 'キ', 'ｸ': 'ク',
      'ｹ': 'ケ', 'ｺ': 'コ', 'ｻ': 'サ', 'ｼ': 'シ', 'ｽ': 'ス', 'ｾ': 'セ',
      'ｿ': 'ソ', 'ﾀ': 'タ', 'ﾁ': 'チ', 'ﾂ': 'ツ', 'ﾃ': 'テ', 'ﾄ': 'ト',
      'ﾅ': 'ナ', 'ﾆ': 'ニ', 'ﾇ': 'ヌ', 'ﾈ': 'ネ', 'ﾉ': 'ノ', 'ﾊ': 'ハ',
      'ﾋ': 'ヒ', 'ﾌ': 'フ', 'ﾍ': 'ヘ', 'ﾎ': 'ホ', 'ﾏ': 'マ', 'ﾐ': 'ミ',
      'ﾑ': 'ム', 'ﾒ': 'メ', 'ﾓ': 'モ', 'ﾔ': 'ヤ', 'ﾕ': 'ユ', 'ﾖ': 'ヨ',
      'ﾗ': 'ラ', 'ﾘ': 'リ', 'ﾙ': 'ル', 'ﾚ': 'レ', 'ﾛ': 'ロ', 'ﾜ': 'ワ',
      'ﾝ': 'ン', 'ﾞ': '゛', 'ﾟ': '゜'
    }

    markedkanaMap = {
      'ｶﾞ': 'ガ', 'ｷﾞ': 'ギ', 'ｸﾞ': 'グ', 'ｹﾞ': 'ゲ', 'ｺﾞ': 'ゴ',
      'ｻﾞ': 'ザ', 'ｼﾞ': 'ジ', 'ｽﾞ': 'ズ', 'ｾﾞ': 'ゼ', 'ｿﾞ': 'ゾ',
      'ﾀﾞ': 'ダ', 'ﾁﾞ': 'ヂ', 'ﾂﾞ': 'ヅ', 'ﾃﾞ': 'デ', 'ﾄﾞ': 'ド',
      'ﾊﾞ': 'バ', 'ﾋﾞ': 'ビ', 'ﾌﾞ': 'ブ', 'ﾍﾞ': 'ベ', 'ﾎﾞ': 'ボ',
      'ﾊﾟ': 'パ', 'ﾋﾟ': 'ピ', 'ﾌﾟ': 'プ', 'ﾍﾟ': 'ペ', 'ﾎﾟ': 'ポ',
      'ｳﾞ': 'ヴ', 'ﾜﾞ': 'ヷ', 'ｦﾞ': 'ヺ'
    }

    $.each(array, function(idx, html) {
      html = $(html);
      html.find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType === 3;
      }).each(function () {
        var text = this.textContent;

        $.each(markedkanaMap, function(k, v) {
          text = text.replace(new RegExp(k, 'g'), v);
        });

        text = text.replace(/[｡-ﾟ]/g, function (c) {
          return kanaMap[c];
        });

        this.textContent = text;
      });

      ret.push(html.html());
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // ReplaceWords
  Syntax_Checker.checkReplaceWords = function (id, content) {
    var array, words;

    array = Syntax_Checker.formatContent(content);
    words = Syntax_Checker.config["replace_words"];

    if (!words) {
      return;
    }

    $.each(array, function(idx, html) {
      var c, k, v;

      for (k in words) {
        v = words[k];
        c = html.match(RegExp("" + k.replace(/([.?*+$\[\]\/\\(){}|\-])/g, '\\$1'), "g"));
        if (!SS.isEmptyObject(c)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: c[0],
              ele: html,
              msg: Syntax_Checker.message["replaceWord"] + ("「" + k + "」→「" + v + "」"),
              correctContent: Syntax_Checker.correctReplaceWords,
              replaceKey: k,
              replaceValue: v,
            }
          );
        }
      }
    });
  };
  Syntax_Checker.correctReplaceWords = function (id, content, error) {
    var key, value, array, ret, regexp, alt;

    array = Syntax_Checker.formatContent(content);
    key = error["replaceKey"];
    value = error["replaceValue"];
    ret = [];
    regexp = RegExp("" + key.replace(/([.?*+$\[\]\/\\(){}|\-])/g, '\\$1', "g"));

    if (!(key || value)) {
      return;
    }

    $.each(array, function(idx, html) {
      html = $(html);
      html.find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType === 3;
      }).each(function () {
        var text;
        text = this.textContent.replace(regexp, value);
        this.textContent = text;
      });
      html.find("img[alt]").each(function () {
        alt = $(this).attr("alt").replace(regexp, value);
        $(this).attr("alt", alt);
      });
      ret.push(html.html());
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // DateFormat
  Syntax_Checker.checkDateFormat = function (id, content) {
    var array, dates;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      dates = [];

      $(html).find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType === 3;
      }).each(function () {
        var d;
        d = this.textContent.match(/\d{4}[\.\-\/]\d{1,2}[\.\-\/]\d{1,2}/g);
        if (d) {
          dates = $.merge(dates, d);
        }
      });
      if (SS.isEmptyObject(dates)) {
        return;
      }
      dates = $.grep(dates, function (date) {
        return Syntax_Checker.isValidDate(new Date(date));
      });
      if (!SS.isEmptyObject(dates)) {
        Syntax_Checker.errors.push(
          {
            id: id,
            idx: idx,
            code: dates.join(","),
            ele: html,
            msg: Syntax_Checker.message["invalidDateFormat"],
            detail: Syntax_Checker.detail["invalidDateFormat"],
            correctContent: Syntax_Checker.correctDateFormat
          }
        );
      }
    });
  };
  Syntax_Checker.correctDateFormat = function (id, content, error) {
    var ret, array;

    array = Syntax_Checker.formatContent(content);
    ret = [];

    $.each(array, function(idx, html) {
      html = $(html);
      html.find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType === 3;
      }).each(function () {
        var text;
        text = this.textContent.replace(/(\d{4})[\.\-\/](\d{1,2})[\.\-\/](\d{1,2})/g, function (date, y, m, d) {
          if (Syntax_Checker.isValidDate(new Date([y, m, d].join("/")))) {
            return y + "年" + m + "月" + d + "日";
          } else {
            return date;
          }
        });
        return this.textContent = text;
      });
      ret.push(html.html());
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // ImgAlt
  Syntax_Checker.checkImgAlt = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find('img').each(function () {
        var alt = this.alt;
        if (alt) {
          alt = $.trim(alt);
        }
        if (!alt) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: this,
              msg: Syntax_Checker.message["notSetImgAlt"],
              detail: Syntax_Checker.detail["notSetImgAlt"]
            }
          );
        }

        var src = this.src;
        if (src) {
          src = $.trim(src);
        }
        if (alt && src && src.toLowerCase().includes(alt.toLowerCase())) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: this,
              msg: Syntax_Checker.message["altIsIncludedInFilename"],
              detail: Syntax_Checker.detail["altIsIncludedInFilename"]
            }
          );
        }
      });
    });
  };

  // AppletAlt
  Syntax_Checker.checkAppletAlt = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find('applet').each(function () {
        var alt, errors;
        alt = $(this).attr('alt');
        if (!alt || $.trim(alt) === "" || /^[\w\s\.\-]*$/.test(alt)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: this,
              msg: Syntax_Checker.message["notSetAppletAlt"],
              detail: Syntax_Checker.detail["notSetAppletAlt"]
            }
          );
        }
      });
    });
  };

  // AreaAlt
  Syntax_Checker.checkAreaAlt = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find('area').each(function () {
        var alt, errors;
        alt = $(this).attr('alt');
        if (!alt || $.trim(alt) === "" || /^[\w\s\.\-]*$/.test(alt)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: this,
              msg: Syntax_Checker.message["notSetAreaAlt"],
              detail: Syntax_Checker.detail["notSetAreaAlt"]
            }
          );
        }
      });
    });
  };

  // ImgDataUriScheme
  Syntax_Checker.checkImgDataUriScheme = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find('img[src]').each(function () {
        var errors, src;
        src = $(this).attr('src');
        if (/^data:.*?,.*?$/.test(src)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: this,
              msg: Syntax_Checker.message["invalidImgScheme"],
              detail: Syntax_Checker.detail["invalidImgScheme"]
            }
          );
        }
      });
    });
  };

  // Table
  Syntax_Checker.checkTable = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find("table").each(function () {
        var caption, errors, table;
        table = this;
        caption = $(this).find('caption');
        errors = [];
        if (!caption || $.trim(caption.text()) === "") {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              ele: table,
              msg: Syntax_Checker.message["notSetTableCaption"],
              detail: Syntax_Checker.detail["notSetTableCaption"],
              correctContent: Syntax_Checker.correctTableCaption
            }
          );
        }
        $(table).find('th').each(function () {
          if (!$(this).attr("scope")) {
            Syntax_Checker.errors.push(
              {
                id: id,
                idx: idx,
                code: Syntax_Checker.outerHtmlSummary(this),
                ele: table,
                msg: Syntax_Checker.message["notSetThScope"],
                detail: Syntax_Checker.detail["notSetThScope"],
                correctContent:  Syntax_Checker.correctTableScope
              }
            );
            return false;
          }
        });
      });
    });
  };
  Syntax_Checker.correctTableCaption = function (id, content) {
    var ret, array;

    array = Syntax_Checker.formatContent(content);
    ret = [];

    $.each(array, function(idx, html) {
      html = $(html).find("table");
      $(html).find('caption').remove();
      $(html).prepend('<caption>' + "キャプション" + '</caption>');
      html = $(html).parents().last().html() || $(html).html();
      ret.push(html);
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };
  Syntax_Checker.correctTableScope = function (id, content, error) {
    var array, ret, scope;

    array = Syntax_Checker.formatContent(content);
    ret = [];

    $.each(array, function(idx, html) {
      html = $(html).find("table");
      if ($(html).find("tr:first th").length == 1) {
        scope = "row";
      } else {
        scope = "col";
      }
      $(html).find("tr:first th").each(function () {
        if (!$(this).attr("scope")) {
          return $(this).attr("scope", scope);
        }
      });
      $(html).find("tr:not(:first) th").each(function () {
        if (!$(this).attr("scope")) {
          return $(this).attr("scope", "row");
        }
      });
      html = $(html).parents().last().html() || $(html).html();
      ret.push(html);
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // OrderOfH
  Syntax_Checker.checkOrderOfH = function (id, content) {
    var array, code, h, i, j, ref;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);
      h = $(html).find("h1,h2,h3,h4,h5,h6");

      if (!h.length) {
        return false;
      }

      code = "";
      for (i = j = 0, ref = h.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        if (i === 0) {
          if (!/h[12]/i.test(h[i].tagName)) {
            code += h[i].tagName + " ";
          }
        } else {
          if (/h3/i.test(h[i].tagName)) {
            if (!/h[23456]/i.test(h[i - 1].tagName)) {
              code += h[i].tagName + " ";
            }
          } else if (/h4/i.test(h[i].tagName)) {
            if (!/h[3456]/i.test(h[i - 1].tagName)) {
              code += h[i].tagName + " ";
            }
          } else if (/h5/i.test(h[i].tagName)) {
            if (!/h[456]/i.test(h[i - 1].tagName)) {
              code += h[i].tagName + " ";
            }
          } else if (/h6/i.test(h[i].tagName)) {
            if (!/h[56]/i.test(h[i - 1].tagName)) {
              code += h[i].tagName + " ";
            }
          }
        }
      }
      if (code !== "") {
        Syntax_Checker.errors.push(
          {
            id: id,
            idx: idx,
            code: code,
            ele: html,
            msg: Syntax_Checker.message["invalidOrderOfH"],
            detail: Syntax_Checker.detail["invalidOrderOfH"],
            correctContent:  Syntax_Checker.correctOrderOfH
          }
        );
      }
    });
  };
  Syntax_Checker.correctOrderOfH = function (id, content) {
    var array, ret;
    var h, i, j, ref, replace;

    array = Syntax_Checker.formatContent(content);
    ret = [];

    $.each(array, function(idx, html) {
      html = $(html);
      h = $(html).find("h1,h2,h3,h4,h5,h6");
      if (h.length) {

        replace = html;
        for (i = j = 0, ref = h.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
          if (i === 0) {
            if (!/h[12]/i.test(h[i].tagName)) {
              replace = $('<h1>' + $(h[i]).html() + '</h1>');
              $(h[i]).after(replace).remove();
              h[i] = replace[0];
            }
          } else {
            if (/h3/i.test(h[i].tagName)) {
              if (!/h[23456]/i.test(h[i - 1].tagName)) {
                replace = $('<' + h[i - 1].tagName.replace("1", "2") + '>');
                replace.html($(h[i]).html());
                $(h[i]).after(replace).remove();
                h[i] = replace[0];
              }
            } else if (/h4/i.test(h[i].tagName)) {
              if (!/h[3456]/i.test(h[i - 1].tagName)) {
                replace = $('<' + h[i - 1].tagName.replace("1", "2") + '>');
                replace.html($(h[i]).html());
                $(h[i]).after(replace).remove();
                h[i] = replace[0];
              }
            } else if (/h5/i.test(h[i].tagName)) {
              if (!/h[456]/i.test(h[i - 1].tagName)) {
                replace = $('<' + h[i - 1].tagName.replace("1", "2") + '>');
                replace.html($(h[i]).html());
                $(h[i]).after(replace).remove();
                h[i] = replace[0];
              }
            } else if (/h6/i.test(h[i].tagName)) {
              if (!/h[56]/i.test(h[i - 1].tagName)) {
                replace = $('<' + h[i - 1].tagName.replace("1", "2") + '>');
                replace.html($(h[i]).html());
                $(h[i]).after(replace).remove();
                h[i] = replace[0];
              }
            }
          }
        }
        replace = $(replace).parents().last().html() || $(replace).html();
        ret.push(replace);
      }
      else {
        ret.push($(html).parents().last().html());
      }
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // AdjacentA
  Syntax_Checker.checkAdjacentA = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);
      $(html).find("a[href]").each(function () {
        var errors, next, href;

        href = $(this).attr("href");
        next = $(this).next("a[href]");

        if (next.length && href == next.attr("href")) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this) + Syntax_Checker.outerHtmlSummary(next),
              ele: this,
              msg: Syntax_Checker.message["invalidAdjacentA"],
              detail: Syntax_Checker.detail["invalidAdjacentA"],
              correctContent: Syntax_Checker.correctAdjacentA
            }
          );
        }
      });
    });
  };
  Syntax_Checker.correctAdjacentA = function (id, content, error) {
    var array, ret, next, href;

    array = Syntax_Checker.formatContent(content);
    ret = [];

    $.each(array, function(idx, html) {
      html = $(html);

      href = $(html).attr("href");
      next = $(html).next("a[href]");

      if (next.length && href == next.attr("href")) {
        if ($(html).html() !== $(next).html()) {
          $(html).html($(html).html() + $(next).html());
        }
        next.remove();
      }

      html = $(html).parents().last().html() || $(html).html();
      ret.push(html);
    });

    if (content["type"] == "array") {
      return ret;
    } else {
      return ret[0];
    }
  };

  // InterwordSpace
  Syntax_Checker.checkInterwordSpace = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);

      $(html).find(":not(iframe)").addBack().contents().filter(function () {
        return this.nodeType == 3;
      }).each(function () {
        var i, j, ref, text;
        text = $.trim(Syntax_Checker.justText(this));
        if (/[　]/.test(text)) {
          for (i = j = 0, ref = text.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
            if (text.charCodeAt(i) >= 256) {
              Syntax_Checker.errors.push(
                {
                  id: id,
                  idx: idx,
                  code: text,
                  msg: Syntax_Checker.message["checkInterwordSpace"],
                  detail: Syntax_Checker.detail["checkInterwordSpace"]
                }
              );
              break;
            }
          }
        }
      });
    });
  };

  // LinkText
  Syntax_Checker.checkLinkText = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      $(html).find("a[href]").each(function () {
        var $this = $(this);
        var text = $this.text();
        if (text.length <= 3) {
          var $imgWithAlt = $this.find("img[alt]");
          if ($imgWithAlt[0]) {
            text = $imgWithAlt.attr('alt');
          }
        }
        if (!text || text.length <= 3) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              msg: Syntax_Checker.message["checkLinkText"],
              detail: Syntax_Checker.detail["checkLinkText"]
            }
          );
        }
      });
    });
  };

  // ObjectText
  Syntax_Checker.checkObjectText = function (id, content) {
    var array;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);
      $(html).find("object").each(function () {
        var errors, text;
        text = $(this).text();
        if (!$.trim(text)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              msg: Syntax_Checker.message["checkObjectText"],
              detail: Syntax_Checker.detail["checkObjectText"]
            }
          );
        }
      });
    });
  };

  // EmbeddedMedia
  Syntax_Checker.checkEmbeddedMedia = function (id, content) {
    var array, regExt, regSite;

    array = Syntax_Checker.formatContent(content);

    $.each(array, function(idx, html) {
      html = $(html);

      $(html).find("embed,video").each(function () {
        Syntax_Checker.errors.push(
          {
            id: id,
            idx: idx,
            code: Syntax_Checker.outerHtmlSummary(this),
            msg: Syntax_Checker.message["checkEmbeddedMedia"],
            detail: Syntax_Checker.detail["checkEmbeddedMedia"]
          }
        );
      });

      regExt = new RegExp("(" + Syntax_Checker.mediaExtensions.join("|") + ")", "i");
      regSite = /https?:\/\/www\.youtube\.com\//;

      $(html).find("iframe[src]").each(function () {
        var errors, ext, src;
        src = $(this).attr("src");
        ext = src.replace(/\?.*$/, "").replace(/.*\//, '').split(".").pop();
        if (regExt.test(ext) || regSite.test(src)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              msg: Syntax_Checker.message["checkEmbeddedMedia"],
              detail: Syntax_Checker.detail["checkEmbeddedMedia"]
            }
          );
        }
      });

      $(html).find("a[href]").each(function () {
        var ext, href;
        href = $(this).attr("href");
        ext = href.replace(/\?.*$/, "").replace(/.*\//, '').split(".").pop();
        if (regExt.test(ext) || regSite.test(href)) {
          Syntax_Checker.errors.push(
            {
              id: id,
              idx: idx,
              code: Syntax_Checker.outerHtmlSummary(this),
              msg: Syntax_Checker.message["checkEmbeddedMedia"],
              detail: Syntax_Checker.detail["checkEmbeddedMedia"]
            }
          );
        }
      });
    });
  };

  return Syntax_Checker;
})();
this.Form_Checker = (function () {
  function ResultBox(form) {
    this.$el = null;
    this.$elBody = null;
    this.form = form;
  }

  ResultBox.prototype.init = function() {
    if (this.$el) {
      return this;
    }

    var $div = $("#errorFormChecker");
    if ($div[0]) {
      this.$el = $div;
      this.$elBody = $div.find(".errorExplanationBody");

      return this.moveLast();
    }

    $div = $("<div/>", { id: 'errorFormChecker', class: 'errorExplanation' });
    $div.append("<h2>" + Form_Checker.message.header + "</h2>");

    var $body = $("<div/>", { class: 'errorExplanationBody' });
    $div.append($body);

    this.$el = $div;
    this.$elBody = $body;

    return this.moveLast();
  };

  ResultBox.prototype.moveLast = function() {
    $(this.form.addonSelector).append(this.$el);
    return this;
  };

  ResultBox.prototype.showMessage = function(message) {
    this.init();
    this.$elBody.html(message);
    this.moveLast();

    return this;
  };

  ResultBox.prototype.showChecking = function() {
    return this.showMessage(SS.loading);
  };

  ResultBox.prototype.showResult = function (errors) {
    if (!errors || errors.length == 0) {
      this.$elBody.html("");
      this.$elBody.append("<p>" + Form_Checker.message.noErrors + "</p>");
      return;
    }

     var $ul = $("<ul/>");
     $.each(errors, function() {
       $ul.append('<li>' + this + '</li>');
     });

    this.$elBody.html("");
    this.$elBody.append("<p>" + Form_Checker.message["body"] + "</p>");
    this.$elBody.append($ul);

    return this.moveLast();
  };

  function Form_Checker(el, form) {
    this.$el = $(el);
    this.form = form;
    this.resultBox = new ResultBox(form);
  }

  Form_Checker.message = {
    header: "制約チェック",
    body: "次の項目を確認してください。",
    noErrors: "エラーは見つかりませんでした。",
    formCheckerError: "内容チェックに失敗しました。次のURLに接続できません。"
  };

  Form_Checker.render = function (form) {
    form = form || Cms_Form;
    var instance = new Form_Checker(document, form);
    instance.render();
    return instance;
  }

  Form_Checker.prototype.render = function () {
    var self = this;

    this.$el.on("click", "button.form-check", function () {
      var button = this;
      button.disabled = true;

      var complete = function() {
        button.disabled = false;
      }

      self.asyncCheck().done(complete).fail(complete);
    });
  }

  Form_Checker.prototype.asyncCheck = function () {
    var defer = $.Deferred();

    this.resultBox.showChecking();

    var formData = this.form.getFormData($("#" + Form_Preview.form_id));
    var self = this;

    $.ajax({
      type: "POST",
      url: this.form.form_check_path,
      data: formData,
      processData: false,
      contentType: false,
      cache: false,
      success: function (data) {
        self.resultBox.showResult(data);
        defer.resolve({ status: (data && data.length > 0) ? "error" : "ok" });
      },
      error: function (xhr, status, error) {
        var msg = Form_Checker.message.formCheckerError + ": " + form.form_check_path;
        Form_Checker.resultBox.showMessage("<p>" + msg + "</p>");
        defer.reject(xhr, status, error);
      }
    });

    return defer.promise();
  }

  return Form_Checker;

})();
this.Mobile_Size_Checker = (function () {
  function ResultBox() {
    this.$el = null;
    this.$elBody = null;
  }

  ResultBox.prototype.init = function() {
    if (this.$el) {
      return this;
    }

    var $div = $("#errorMobileChecker");
    if ($div[0]) {
      this.$el = $div;
      this.$elBody = $div.find(".errorExplanationBody");

      return this.moveLast();
    }

    $div = $("<div/>", { id: 'errorMobileChecker', class: 'errorExplanation' });
    $div.append("<h2>" + Mobile_Size_Checker.message["header"] + "</h2>");

    var $body = $("<div/>", { class: 'errorExplanationBody' });
    $div.append($body);

    this.$el = $div;
    this.$elBody = $body;

    return this.moveLast();
  };

  ResultBox.prototype.moveLast = function() {
    $(Cms_Form.addonSelector).append(this.$el);
    return this;
  };

  ResultBox.prototype.showMessage = function(message) {
    this.init();
    this.$elBody.html(message);
    this.moveLast();

    return this;
  }

  ResultBox.prototype.showChecking = function() {
    return this.showMessage(SS.loading);
  };

  ResultBox.prototype.showResult = function () {
    if (Mobile_Size_Checker.error.length === 0) {
      return this.showMessage("<p>" + Mobile_Size_Checker.message["mobile_check"] + "</p>");
    }

    var ref = Mobile_Size_Checker.error;
    this.$elBody.html('');
    for (var j = 0, len = ref.length; j < len; j++) {
      var err = ref[j];
      this.$elBody.append('<p class="error">' + err + '</p>');
    }

    return this.moveLast();
  };

  function Mobile_Size_Checker() {
  }

  Mobile_Size_Checker.message = {
    header: "携帯データサイズチェック",
    body: "",
    success: "成功",
    failure: "失敗",
    mobile_disable: "モバイルサイズが設定されていません。",
    mobile_check: "本文のデータサイズはOKです。",
    SizeCheckServerError: "本文データサイズのチェック中にサーバーエラーが発生しました。"
  };

  Mobile_Size_Checker.error = [];

  Mobile_Size_Checker.url = "/.cms/mobile_size_check/check.json";

  Mobile_Size_Checker.rootUrl = "";

  Mobile_Size_Checker.imgs = [];

  Mobile_Size_Checker.hostFullUrl = "";

  Mobile_Size_Checker.resultBox = new ResultBox();

  Mobile_Size_Checker.render = function () {
    return $(document).on("click", "button.mobile-size-check", function () {

      if (!Mobile_Size_Checker.enabled) {
        Mobile_Size_Checker.resultBox.showMessage("<p>" + Mobile_Size_Checker.message["mobile_disable"] + "</p>");
        return;
      }

      var button = this;
      button.disabled = true;

      Mobile_Size_Checker.resultBox.showChecking();
      Mobile_Size_Checker.reset();

      var resolved = function(html) {
        Mobile_Size_Checker.check(html, function () {
          Mobile_Size_Checker.resultBox.showResult();
          button.disabled = false;
        });
      };

      var rejected = function(xhr, status, error) {
        Mobile_Size_Checker.resultBox.showMessage("<p>" + Mobile_Size_Checker.message["SizeCheckServerError"] + "</p>");
        button.disabled = false;
      }

      Cms_Form.getHtml(resolved, rejected);
    });
  };

  Mobile_Size_Checker.reset = function () {
    this.message["body"] = "";
    this.imgs = {};
    this.error = "";
  };

  Mobile_Size_Checker.get_str_byte = function (str) {
    var ESCAPECHAR, ESCAPEDLEN_TABLE, char, i, size;
    ESCAPECHAR = ";,/?:@&=+$ ";
    ESCAPEDLEN_TABLE = [0, 1, 1, 1, 2, 3, 2, 3, 4, 3];
    size = 0;
    if (str === null || str === "") {
      return size;
    }
    for (i in str) {
      char = str[i];
      if (ESCAPECHAR.indexOf(char) >= 0) {
        size++;
      } else {
        try {
          size += ESCAPEDLEN_TABLE[encodeURI(char).length];
        } catch (e) {
          console.error("Mobile_Size_Checker.get_str_byte failed : " + e);
        }
      }
    }
    return size;
  };

  Mobile_Size_Checker.check = function (html, complete) {
    var err_str, imgs, isThumb, j, len, mobile_size, numOfImage, ref, size, src, str_id, str_src;
    mobile_size = Mobile_Size_Checker.mobile_size;
    size = Mobile_Size_Checker.get_str_byte(html);
    if (mobile_size < size) {
      err_str = "<p class=\"error\">";
      err_str += Mobile_Size_Checker.message["SizeCheckError"];
      err_str += "(本文サイズ：" + (parseInt(size / 1024)) + "KB)";
      err_str += "</p>";
      Mobile_Size_Checker.error = [err_str];
      complete();
      return;
    }
    imgs = [];
    isThumb = {};
    ref = $(html).find('img[src]');
    for (j = 0, len = ref.length; j < len; j++) {
      src = ref[j];
      str_src = $(src).attr('src');
      str_src = str_src.replace(Mobile_Size_Checker.hostFullUrl.replace(/\/$/, ""), "");
      str_id = str_src.match(/^\/fs\/(.+?)\/_\//);
      if (str_id) {
        isThumb[str_id[1].replace(/\//g, "")] = str_src.match(/_\/thumb\//);
        imgs.push(parseInt(str_id[1].replace(/\//g, "")));
      }
    }
    if (imgs.length == 0) {
      complete();
      return;
    }
    $.ajax({
      type: "POST",
      url: Mobile_Size_Checker.url,
      cache: false,
      data: JSON.stringify({
        img_ids: imgs,
        mobile_size: mobile_size,
        is_thumb: isThumb
      }),
      contentType: 'application/json',
      dataType: "json",
      crossDomain: true,
      success: function (res, status) {
        if (res["errors"].length > 0) {
          return Mobile_Size_Checker.error = res["errors"];
        }
      },
      error: function (xhr, status, error) {
        var str_err;
        str_err = "<p>";
        str_err += Mobile_Size_Checker.message["SizeCheckServerError"];
        str_err += "</p>";
        Mobile_Size_Checker.error = [str_err];
      },
      complete: function (xhr, status) {
        complete();
      }
    });
  };

  Mobile_Size_Checker.asyncCheckHtmlSize = function (html) {
    var defer = $.Deferred();

    Mobile_Size_Checker.reset();
    if (!Mobile_Size_Checker.enabled) {
      defer.resolve();
      return defer.promise();
    }

    Mobile_Size_Checker.resultBox.showChecking();
    Mobile_Size_Checker.check(html, function () {
      Mobile_Size_Checker.resultBox.showResult();
      defer.resolve();
    });

    return defer.promise();
  };

  Mobile_Size_Checker.asyncValidateHtml = function (form, submit, opts) {
    var promise = Mobile_Size_Checker.asyncCheckHtmlSize(opts.html);
    promise.done(function() {
      if (Mobile_Size_Checker.error.length === 0) {
        return;
      }

      for (var j = 0, len = Mobile_Size_Checker.error.length; j < len; j++) {
        var err = Mobile_Size_Checker.error[j];
        Form_Alert.add("携帯データサイズチェック", this, err);
      }
    });

    return promise;
  };

  return Mobile_Size_Checker;

})();
this.Link_Checker = (function () {
  function ResultBox(form) {
    this.$el = null;
    this.$elBody = null;
    this.form = form;
  }

  ResultBox.prototype.init = function() {
    if (this.$el) {
      return this;
    }

    var $div = $("#errorLinkChecker");
    if ($div[0]) {
      this.$el = $div;
      this.$elBody = $div.find(".errorExplanationBody");

      return this.moveLast();
    }

    $div = $("<div/>", { id: 'errorLinkChecker', class: 'errorExplanation' });
    $div.append("<h2>" + Link_Checker.message["header"] + "</h2>");

    var $body = $("<div/>", { class: 'errorExplanationBody' });
    $div.append($body);

    this.$el = $div;
    this.$elBody = $body;

    return this.moveLast();
  };

  ResultBox.prototype.moveLast = function() {
    $(this.form.addonSelector).append(this.$el);
    return this;
  };

  ResultBox.prototype.showMessage = function(message) {
    this.init();
    this.$elBody.html(message);
    this.moveLast();

    return this;
  }

  ResultBox.prototype.showChecking = function() {
    return this.showMessage(SS.loading);
  };

  ResultBox.prototype.showResult = function (links) {
    var $ul = $("<ul/>");
    $.each(links, function(link, msg) {
      $ul.append('<li>' + msg + '</li>');
    });

    this.$elBody.html("");
    this.$elBody.append("<p>" + Link_Checker.message["checkLinks"] + "</p>");
    this.$elBody.append($ul);

    return this.moveLast();
  };

  function Link_Checker(el, form) {
    this.$el = $(el);
    this.form = form;
    this.links = {};
    this.linkErrorCount = 0;
    this.resultBox = new ResultBox(form);
  }

  Link_Checker.message = {
    header: "リンクチェック",
    noLinks: "リンクは見つかりませんでした。",
    checkLinks: "次のリンクを確認しました。",
    success: "[成功]",
    failure: "[失敗]",
    linkCheckerError: "リンクチェックに失敗しました。次のURLに接続できません。"
  };

  Link_Checker.url = "/.cms/link_check/check.json";

  Link_Checker.rootUrl = "";

  Link_Checker.instance = null;

  Link_Checker.render = function (form) {
    form = form || Cms_Form;

    var instance = Link_Checker.instance = new Link_Checker(document, form);
    instance.render();
    return instance;
  };

  Link_Checker.reset = function () {
    if (! Link_Checker.instance) {
      return;
    }

    Link_Checker.instance.reset();
  };

  Link_Checker.prototype.render = function () {
    var self = this;
    return this.$el.on("click", "button.link-check", function () {
      var button = this;
      button.disabled = true;

      var complete = function() {
        button.disabled = false;
      };

      self.asyncCheck().done(complete).fail(complete);
    });
  };

  Link_Checker.prototype.asyncCheck = function () {
    if (this.form.addonSelector === ".mod-cms-body") {
      return this.asyncCheckInEditor();
    } else {
      return this.asyncCheckInForm();
    }
  };

  Link_Checker.prototype.asyncCheckInEditor = function () {
    var self = this;
    var defer = $.Deferred();

    this.beforeCheck();

    var $html = $(this.form.getEditorHtml());

    var links = [];
    $html.find('a[href]').each(function() {
      var link = $(this).attr('href');
      if (link === "#") {
        return;
      }

      if (link[0] === "#") {
        var code = ($html.find(link).length != 0) ? 200 : 0;
        self.addMessage(link, { code: code });
      } else {
        if (/^\//.test(link)) {
          link = Link_Checker.rootUrl + link.slice(1);
        }
        links.push(link);
      }
    });

    if (links.length === 0) {
      if (SS.isEmptyObject(this.links)) {
        this.resultBox.showMessage("<p>" + Link_Checker.message["noLinks"] + "</p>");
      } else {
        this.resultBox.showResult(this.links);
      }

      defer.resolve({ status: (this.linkErrorCount === 0 ? "ok" : "failed") });
      return defer.promise();
    }

    $.ajax({
      type: "POST",
      url: Link_Checker.url,
      cache: false,
      data: JSON.stringify({
        "url": links,
        "root_url": Link_Checker.rootUrl
      }),
      contentType: 'application/json',
      dataType: "json",
      crossDomain: true,
      success: function (res, status) {
        $.each(res, function(link, result) {
          self.addMessage(link, result);
        });

        self.resultBox.showResult(self.links);
        defer.resolve({ status: (self.linkErrorCount === 0 ? "ok" : "failed") });
      },
      error: function (xhr, status, error) {
        var msg = Link_Checker.message["linkCheckerError"] + ": " + Link_Checker.url;
        self.resultBox.showMessage("<p>" + msg + "</p>");
        defer.reject(xhr, status, error);
      }
    });

    return defer.promise();
  };

  Link_Checker.prototype.asyncCheckInForm = function () {
    var self = this;
    var defer = $.Deferred();

    this.beforeCheck();

    if (! this.form.form_link_check_path) {
      var msg = "form link check path is not configured";

      this.resultBox.showMessage("<p>" + msg + "</p>");
      defer.reject(null, null, msg);
      return;
    }

    var formData = this.form.getFormData($("#" + Form_Preview.form_id));
    formData.append("route", Form_Preview.page_route);

    var status = "ok";

    $.ajax({
      type: "POST",
      url: self.form.form_link_check_path,
      data: formData,
      processData: false,
      contentType: false,
      cache: false,
      success: function(data) {
        if (!data || data.length === 0) {
          self.resultBox.showMessage("<p>" + Link_Checker.message["noLinks"] + "</p>");
          defer.resolve({ status: status });
          return;
        }

        $.each(data, function(link, result) {
          self.addMessage(link, result);

          if (result["code"] != 200) {
            status = "failed";
          }
        })

        self.resultBox.showResult(self.links);
        defer.resolve({ status: status });
      },
      error: function(xhr, status, error) {
        var msg = Link_Checker.message["linkCheckerError"] + ": " + self.form.form_link_check_path;
        self.resultBox.showMessage("<p>" + msg + "</p>");
        defer.reject(xhr, status, error);
      }
    });

    return defer.promise();
  };

  Link_Checker.prototype.reset = function () {
    this.links = {};
    this.linkErrorCount = 0;
  };

  Link_Checker.prototype.beforeCheck = function () {
    this.reset();

    $.support.cors = true;
    this.resultBox.showChecking();
  };

  Link_Checker.prototype.addMessage = function (link, result) {
    var code = result["code"];
    var message = result["message"];
    var state = (code == 200);
    var html = "";

    if (state) {
      html += '<span class="success">' + Link_Checker.message["success"] + '</span> ';
      html += '<span class="url">' + link + '</span> ';
    } else {
      html += '<span class="failure">' + Link_Checker.message["failure"] + '</span> ';
      html += '<span class="url">' + link + '</span> ';
      this.linkErrorCount++;
    }

    if (message) {
      html += '<div class="message detail">'
      html += message;
      html += '</div>'
    }

    this.links[link] = html;
  };

  return Link_Checker;

})();
Cms_TemplateForm = function(options) {
  this.options = options;
  this.$formChangeBtn = $('#addon-basic .btn-form-change');
  this.$formSelect = $('#addon-basic .form-change');
  this.$formIdInput = $('#addon-basic [name="item[form_id]"]');
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

Cms_TemplateForm.createElementFromHTML = function(html) {
  var div = document.createElement('div');
  div.innerHTML = html.trim();

  return div.firstChild;
};

Cms_TemplateForm.prototype.render = function() {
  // this.changeForm();

  var pThis = this;
  this.$formChangeBtn.on('click', function() {
    pThis.changeForm();
  });
  this.$formSelect.on('change', function() {
    setTimeout(function() {
      if (confirm(Cms_TemplateForm.confirms.changeForm)) {
        pThis.changeForm();
      } else {
        pThis.$formSelect.val(pThis.$formIdInput.val());
      }
    }, 13);
  });
};

Cms_TemplateForm.prototype.changeForm = function() {
  if (Cms_Form.addonSelector === ".mod-body-part-html") {
    return false;
  }
  var formId = this.$formSelect.val();
  if (formId) {
    if (!this.selectedFormId || this.selectedFormId !== formId) {
      this.loadAndActivateForm(formId);
      this.selectedFormId = formId;
    } else {
      this.activateForm(formId);
    }
  } else {
    this.deactivateForm();
  }
};

Cms_TemplateForm.prototype.loadAndActivateForm = function(formId) {
  var pThis = this;

  this.$formChangeBtn.prop('disabled', true);
  $.ajax({
    url: Cms_TemplateForm.paths.formUrlTemplate.replace(':id', formId),
    type: 'GET',
    success: function(html) {
      pThis.loadForm(html);
      pThis.activateForm(formId);
    },
    error: function(xhr, status, error) {
      pThis.showError(error);
      pThis.activateForm(formId);
    },
    complete: function() {
      pThis.$formChangeBtn.prop('disabled', false);
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

Cms_TemplateForm.prototype.activateForm = function(formId) {
  this.$formPage.removeClass('hide');
  $('#addon-cms-agents-addons-body').addClass('hide');
  $("#addon-cms-agents-addons-body_part").addClass('hide');
  $('#addon-cms-agents-addons-file').addClass('hide');
  $("#addon-cms-agents-addons-form-page").removeClass('hide');
  $("#item_body_layout_id").parent('dd').prev('dt').addClass('hide');
  $("#item_body_layout_id").parent('dd').addClass('hide');
  Cms_Form.addonSelector = "#addon-cms-agents-addons-form-page .addon-body";
  Cms_Form.activateSyntaxChecks();

  this.$formIdInput.val(formId);
  this.$formChangeBtn.trigger("ss:formActivated");
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

  this.$formIdInput.val('');
  this.$formChangeBtn.trigger("ss:formDeactivated");
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

    $this.closest("fieldset").prop("disabled", true);
    $this.css('cursor', "wait");
    $this.closest(".column-value-palette").find(".column-value-palette-error").addClass("hide").html("");
    // $this.trigger("ss:columnAdding");
    $.ajax({
      url: Cms_TemplateForm.paths.formColumn.replace(/:formId/, formId).replace(/:columnId/, columnId),
      success: function(data, status, xhr) {
        var newColumnElement = Cms_TemplateForm.createElementFromHTML(data);
        var $palette = $this.closest(".column-value-palette");
        $palette.before(newColumnElement);
        self.resetOrder();

        // To wait completely rendered DOM and executed javascript,
        // use "setTimeout" to consume events in browser.
        setTimeout(function() {
          SS.renderAjaxBox();
          SS.renderDateTimePicker();
          Cms_Form.activateSyntaxChecks();

          setTimeout(function() {
            $this.trigger("ss:columnAdded", newColumnElement);
          }, 0);
        }, 0);
      },
      error: function(xhr, status, error) {
        $this.closest(".column-value-palette").find(".column-value-palette-error").html(error).removeClass("hide");
      },
      complete: function(xhr, status) {
        $this.css('cursor', "pointer");
        $this.closest("fieldset").prop("disabled", false);
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
    var id = $columnValue.find(".column-value-body .html").attr("id");
    if (id) {
      CKEDITOR.instances[id].destroy();
    }
    $columnValue.remove();
    self.resetOrder();
    Cms_Form.activateSyntaxChecks();
  });
};
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

  // complete initialization, so now update-item is clickable
  $(".update-item").each(function() {
    this.disabled = false;
  });
  SS_Workflow.updateDisabled = false;
};

// 初期化が完了するまで update を無効にしておきたいので、クラス変数として定義する。
SS_Workflow.updateDisabled = true;

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

    if (SS_Workflow.updateDisabled) {
      return false;
    }
    SS_Workflow.updateDisabled = true;
    $this.prop("disabled", true);

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
          $this.prop("disabled", false);
          SS_Workflow.updateDisabled = false;
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
        $this.prop("disabled", false);
        SS_Workflow.updateDisabled = false;
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
      url: this.fileSelectViewUrl($item.closest("[data-id]").data("id")),
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

SS_WorkflowApprover = function (options) {
  this.options = options;
  this.render();
};

SS_WorkflowApprover.prototype.render = function () {
  var self = this;

  $("#addon-workflow-agents-addons-approver").remove();

  var state = $("#item_state").parent();
  state.prev().remove();
  state.remove();

  if (self.options.close_confirmation) {
    $(".save").attr("data-close-confirmation", self.options.close_confirmation);
    if (self.options.contain_links_path) {
      $(".save").attr("data-contain-links-path", self.options.contain_links_path);
    }
  }

  if (self.options.publish_save) {
    $("<input />").attr("type", "submit")
      .val(self.options.publish_save)
      .attr("name", "publish_save")
      .attr("class", "publish_save")
      .attr("data-disable", "")
      .on("click", function (_ev) {
        self.onPublishSaveClicked();
        return true;
      })
      .insertAfter("#item-form input.save");
  }
  if (self.options.branch_save) {
    $("<input />").attr("type", "submit")
      .val(self.options.branch_save)
      .attr("name", "branch_save")
      .attr("class", "branch_save")
      .attr("data-disable", "")
      .on("click", function (_ev) {
        return true;
      })
      .insertAfter("#item-form input.save");
  }
  if (self.options.draft_save) {
    $(".save")
      .val(self.options.draft_save)
      .attr("data-disable-with", null)
      .attr("data-disable", "")
      .on("click", function (_ev) {
        self.onClickSave();
        return true;
      });
  } else {
    $(".save").remove();
  }

  if (self.options.workflow_state === "request") {
    $("<input />").attr("type", "hidden")
      .attr("name", "item[workflow_cancel_request]")
      .attr("value", true)
      .appendTo("#item-form");
  }

  Form_Save_Event.render();
};

SS_WorkflowApprover.prototype.onClickSave = function () {
  var self = this;

  self.addOrUpdateInput("item[state]", "closed");
  self.addOrUpdateInput("item[workflow_reset]", null);
};

SS_WorkflowApprover.prototype.onPublishSaveClicked = function () {
  var self = this;

  self.addOrUpdateInput("item[state]", "public");
  self.addOrUpdateInput("item[workflow_reset]", "1");
};

SS_WorkflowApprover.prototype.addOrUpdateInput = function (name, value) {
  var $input = $("#item-form").find("input[name='" + name + "']");
  if ($input.length > 0) {
    $input.val(value);
    return;
  }

  $("<input />").attr("type", "hidden")
    .attr("name", name)
    .attr("value", value)
    .appendTo("#item-form");
};
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
          alert(["== Error =="].concat("データのサイズが大きすぎます。").join("\n"));
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
this.SS_SearchUI = (function () {
  function SS_SearchUI() {
  }

  SS_SearchUI.anchorAjaxBox;

  SS_SearchUI.defaultSelector = function (item) {
    var a, data, id, input, name, self, tr;
    self = this;
    data = item.closest("[data-id]");
    id = data.data("id");
    name = data.data("name") || data.find(".select-item").text() || item.text() || data.text();
    tr = $("<tr />").attr("data-id", id);//attr
    input = self.anchorAjaxBox.closest("dl").find(".hidden-ids").clone(false);
    input = input.val(id).removeClass("hidden-ids");
    a = $('<a class="deselect btn" href="#">削除</a>');
    tr.append($('<td />').append(input).append(name));
    tr.append($('<td />').append(a));
    self.anchorAjaxBox.closest("dl").find(".ajax-selected tbody").prepend(tr);
    self.anchorAjaxBox.closest("dl").find(".ajax-selected").trigger("change");
  };

  SS_SearchUI.defaultDeselector = function (item) {
    var table = $(item).closest(".ajax-selected");
    var tr = $(item).closest("tr");

    tr.remove();
    if (table.find("tbody tr").size() === 0) {
      table.hide();
    }
    table.trigger("change");
  };

  SS_SearchUI.select = function (item) {
    var selector = this.anchorAjaxBox.data('on-select');
    if (selector) {
      return selector(item);
    } else {
      return this.defaultSelector(item);
    }
  };

  SS_SearchUI.selectItems = function ($el) {
    if (! $el) {
      $el = $("#ajax-box");
    }
    var self = this;
    $el.find(".items input:checkbox").filter(":checked").each(function () {
      self.select($(this));
    });
    self.anchorAjaxBox.closest("dl").find(".ajax-selected").show();
  };

  SS_SearchUI.deselect = function (e) {
    var $item = $(this);
    var selector = $item.closest(".ajax-selected").data('on-deselect');
    if (selector) {
      selector($item);
    } else {
      SS_SearchUI.defaultDeselector($item);
    }
    e.preventDefault();
  };

  SS_SearchUI.toggleSelectButton = function ($el) {
    if (! $el) {
      $el = $("#ajax-box");
    }

    if ($el.find(".items input:checkbox").filter(":checked").size() > 0) {
      return $el.find(".select-items").parent("div").show();
    } else {
      return $el.find(".select-items").parent("div").hide();
    }
  };

  SS_SearchUI.render = function () {
    var self = this;

    $(".ajax-selected").each(function () {
      $(this).on("click", ".deselect", self.deselect);
      if ($(this).find("a.deselect").size() === 0) {
        $(this).hide();
      }
    });

    $(document)
      .on("cbox_load", self.onColorBoxLoaded)
      .on("cbox_cleanup", self.onColorBoxCleanedUp);
  };

  SS_SearchUI.onColorBoxLoaded = function (ev) {
    if (!SS_SearchUI.anchorAjaxBox) {
      // ファイル選択ダイアログの「編集」ボタンのクリックなどで別のモーダルが表示される場合がある。
      // 別のモーダルからキャンセルなどで戻ってきた際に、元々の anchor を利用したい。
      // そこで、初回表示時の anchor を記憶しておく。
      SS_SearchUI.anchorAjaxBox = $.colorbox.element();
    }
  };

  SS_SearchUI.onColorBoxCleanedUp = function (ev) {
    SS_SearchUI.anchorAjaxBox = null;
  };

  SS_SearchUI.modal = function (options) {
    if (!options) {
      options = {};
    }

    var self = this;
    var colorbox = options.colorbox || $.colorbox;
    var $el = options.$el || $("#ajax-box");

    var isSameWindow = (window == $el[0].ownerDocument.defaultView)
    if (isSameWindow) {
      $el.find("form.search").on("submit", function (ev) {
        var $div = $("<span />", { class: "loading" }).html(SS.loading);
        $el.find("[type=submit]").after($div);

        $(this).ajaxSubmit({
          url: $(this).attr("action"),
          success: function (data) {
            $el.closest("#cboxLoadedContent").html(data);
          },
          error: function (data, status) {
            $div.html("== Error ==");
          }
        });
        ev.preventDefault();
        return false;
      });
    }
    $el.find(".pagination a").on("click", function (ev) {
      self.selectItems($el);

      if (isSameWindow) {
        $el.find(".pagination").html(SS.loading);

        $.ajax({
          url: $(this).attr("href"),
          type: "GET",
          success: function (data) {
            $el.closest("#cboxLoadedContent").html(data);
          },
          error: function (data, status) {
            $el.find(".pagination").html("== Error ==");
          }
        });

        ev.preventDefault();
        return false;
      } else {
        return true;
      }
    });
    $el.find("#s_group").on("change", function (ev) {
      self.selectItems($el);
      return $el.find("form.search").submit();
    });
    $el.find(".submit-on-change").on("change", function (ev) {
      self.selectItems($el);
      return $el.find("form.search").submit();
    });
    self.anchorAjaxBox.closest("dl").find(".ajax-selected tr[data-id]").each(function () {
      var id, item, tr;
      id = $(this).data("id");
      tr = $("#colorbox .items [data-id='" + id + "']");
      tr.find("input[type=checkbox]").remove();
      item = tr.find(".select-item,.select-single-item").html();
      return tr.find(".select-item,.select-single-item").replaceWith("<span class='select-item' style='color: #888'>" + item + "</span>");
    });
    $el.find("table.index").each(function() {
      SS_ListUI.render(this);
    });
    $el.find("a.select-item").on("click", function (ev) {
      if (!SS.disableClick($(this))) {
        return false;
      }
      // self.select() を呼び出した際にダイアログが閉じられ self.anchorAjaxBox が null となる可能性があるので、事前に退避しておく。
      var ajaxBox = self.anchorAjaxBox;
      //append newly selected item
      self.select($(this));
      ajaxBox.closest("dl").find(".ajax-selected").show();
      ev.preventDefault();
      colorbox.close();
      return false;
    });
    //remove old items
    $el.find(".select-single-item").on("click", function (ev) {
      if (!SS.disableClick($(this))) {
        return false;
      }
      // self.select() を呼び出した際にダイアログが閉じられ self.anchorAjaxBox が null となる可能性があるので、事前に退避しておく。
      var ajaxBox = self.anchorAjaxBox;
      ajaxBox.closest("dl").find(".ajax-selected tr[data-id]").each(function () {
        if ($(this).find("input[value]").length) {
          return $(this).remove();
        }
      });
      //append newly selected item
      self.select($(this));
      ajaxBox.closest("dl").find(".ajax-selected").show();
      ev.preventDefault();
      colorbox.close();
      return false;
    });
    $el.find(".select-items").on("click", function (ev) {
      if (!SS.disableClick($(this))) {
        return false;
      }
      self.selectItems($el);
      ev.preventDefault();
      colorbox.close();
      return false;
    });
    $el.find(".index").on("change", function (ev) {
      return self.toggleSelectButton($el);
    });
    return self.toggleSelectButton($el);
  };

  return SS_SearchUI;

})();

this.SS_ListUI = (function () {
  function SS_ListUI() { }

  SS_ListUI.render = function (el) {
    var $el;
    if (el) {
      $el = $(el);
    } else {
      $el = $(document);
    }

    $el.find(".list-head input:checkbox").on("change", function () {
      var chk;
      chk = $(this).prop('checked');
      return $el.find('.list-item').each(function () {
        $(this).toggleClass('checked', chk);
        return $(this).find('input:checkbox').prop('checked', chk);
      });
    });
    $el.find(".list-item").each(function () {
      var list;
      list = $(this);
      list.find("input:checkbox").on("change", function () {
        return list.toggleClass("checked", $(this).prop("checked"));
      });
      list.on("mouseup", function (e) {
        var menu, offset, relX, relY;
        if ($(e.target).is('a') || $(e.target).closest('a,label').length) {
          return;
        }
        menu = list.find(".tap-menu");
        if (menu.hasClass("tap-menu-relative")) {
          offset = $(this).offset();
          relX = e.pageX - offset.left;
          relY = e.pageY - offset.top;
        } else {
          relX = e.pageX;
          relY = e.pageY;
        }
        return menu.css("left", relX - menu.width() + 5).css("top", relY).show();
      });
      return list.on("mouseleave", function () {
        return $el.find(".tap-menu").hide();
      });
    });
    $el.find(".list-head .destroy-all").each(function() {
      if (this.classList.contains("btn-list-head-action")) {
        return;
      }
      // for backward compatibility
      this.dataset.ssButtonToAction = "";
      this.dataset.ssButtonToMethod = "delete";
      this.dataset.ssConfirmation = "削除してよろしいですか？";
      this.classList.add("btn-list-head-action");
    });
    $el.find(".list-head [data-ss-list-head-method]").each(function() {
      if (this.classList.contains("btn-list-head-action")) {
        return;
      }
      // for backward compatibility
      if (this.dataset.ssListHeadAction) {
        this.dataset.ssButtonToAction = this.dataset.ssListHeadAction;
        delete this.dataset.ssListHeadAction;
      }
      if (this.dataset.ssListHeadMethod) {
        this.dataset.ssButtonToMethod = this.dataset.ssListHeadMethod;
        delete this.dataset.ssListHeadMethod;
      }
      this.classList.add("btn-list-head-action");
    });
    $el.find(".list-head .btn-list-head-action").each(function () {
      $(this).on("ss:beforeSend", function(ev) {
        var checked = $el.find(".list-item input:checkbox:checked").map(function () {
          return $(this).val();
        });
        if (checked.length === 0) {
          ev.preventDefault();
          return false;
        }

        for (var i = 0, len = checked.length; i < len; i++) {
          var id = checked[i];
          ev.$form.append($("<input/>", { name: "ids[]", value: id, type: "hidden" }));
        }
      });
    });
  };

  return SS_ListUI;

})();
this.SS_TreeUI = (function () {
  SS_TreeUI.openImagePath = "/assets/img/tree-open.png";

  SS_TreeUI.closeImagePath = "/assets/img/tree-close.png";

  SS_TreeUI.render = function (tree, opts) {
    return new SS_TreeUI(tree, opts);
  };

  SS_TreeUI.toggleImage = function (img) {
    if (img.attr("src") === SS_TreeUI.openImagePath) {
      return SS_TreeUI.closeImage(img);
    } else if (img.attr("src") === SS_TreeUI.closeImagePath) {
      return SS_TreeUI.openImage(img);
    }
  };

  SS_TreeUI.openImage = function (img) {
    img.attr("src", SS_TreeUI.openImagePath);
    img.addClass("opened");
    return img.removeClass("closed");
  };

  SS_TreeUI.closeImage = function (img) {
    img.attr("src", SS_TreeUI.closeImagePath);
    img.removeClass("opened");
    return img.addClass("closed");
  };

  SS_TreeUI.openSelectedGroupsTree = function (current_tr) {
    for (i = 0; i < parseInt(current_tr.attr("data-depth")); i++) {
      var tr = current_tr.prevAll('tr[data-depth=' + i.toString() + ']:first');
      var img = tr.find(".toggle:first");
      tr.nextAll("tr").each(function () {
        var subordinated_depth = parseInt($(this).attr("data-depth"));
        if (i >= subordinated_depth) {
          return false;
        }
        if ((i + 1) === subordinated_depth) {
          $(this).show();
        }
      });
      SS_TreeUI.openImage(img);
    }
  }

  function SS_TreeUI(tree, opts) {
    if (opts == null) {
      opts = {}
    }

    this.tree = $(tree);

    var root = [];
    var expand_all = opts["expand_all"];
    var collapse_all = opts["collapse_all"];
    var expand_group = opts["expand_group"];

    this.tree.find("tbody tr").each(function () {
      return root.push(parseInt($(this).attr("data-depth")));
    });
    root = Math.min.apply(null, root);
    root = parseInt(root);
    if (isNaN(root) || root < 0) {
      return;
    }
    this.tree.find("tbody tr").each(function () {
      var d, depth, i, j, ref, ref1, td;
      td = $(this).find(".expandable");
      depth = parseInt($(this).attr("data-depth"));
      td.prepend('<img src="' + SS_TreeUI.closeImagePath + '" alt="toggle" class="toggle closed">');
      if (depth !== root) {
        if (!expand_all) {
          $(this).hide();
        }
      }
      for (i = j = ref = root, ref1 = depth; ref <= ref1 ? j < ref1 : j > ref1; i = ref <= ref1 ? ++j : --j) {
        td.prepend('<span class="padding">');
      }
      d = parseInt($(this).next("tr").attr("data-depth")) || 0;
      i = $(this).find(".toggle:first");
      if (d === 0 || depth >= d) {
        return i.replaceWith('<span class="padding">');
      }
    });
    this.tree.find(".toggle").on("mousedown mouseup", function (e) {
      e.stopPropagation();
      return false;
    });
    this.tree.find(".toggle").on("click", function (e) {
      var depth, img, tr;
      tr = $(this).closest("tr");
      img = tr.find(".toggle:first");
      depth = parseInt(tr.attr("data-depth"));
      SS_TreeUI.toggleImage(img);
      tr.nextAll("tr").each(function () {
        var d, i;
        d = parseInt($(this).attr("data-depth"));
        i = $(this).find(".toggle:first");
        if (depth >= d) {
          return false;
        }
        if ((depth + 1) === d) {
          $(this).toggle();
          return SS_TreeUI.closeImage(i);
        } else {
          $(this).hide();
          return SS_TreeUI.closeImage(i);
        }
      });
      e.stopPropagation();
      return false;
    });
    if (expand_all) {
      SS_TreeUI.openImage(this.tree.find("tbody tr img"));
    } else if (collapse_all) {
      SS_TreeUI.closeImage(this.tree.find("tbody tr img"));
    } else if (expand_group && $("tbody tr.current").attr("data-depth") !== "0") {
      SS_TreeUI.openSelectedGroupsTree(this.tree.find("tbody tr.current"));
    } else {
      this.tree.find("tr[data-depth='" + root + "'] img").trigger("click");
    }
  }

  SS_TreeUI.prototype.expandAll = function () {
    return this.tree.find("tr img.toggle.closed").trigger("click");
  };

  SS_TreeUI.prototype.collapseAll = function () {
    return $(this.tree.find("tr img.toggle.opened").get().reverse()).each(function () {
      return $(this).trigger("click");
    });
  };

  return SS_TreeUI;

})();

// ---
// generated by coffee-script 1.9.2
;
this.SS_Dropdown = (function () {
  SS_Dropdown.render = function () {
    return $("button.dropdown").each(function () {
      var dropdown, target;
      target = $(this).parent().find(".dropdown-container")[0];
      dropdown = new SS_Dropdown(this, {
        target: target
      });
      if (!SS_Dropdown.dropdown) {
        return SS_Dropdown.dropdown = dropdown;
      }
    });
  };

  SS_Dropdown.openDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.openDropdown();
    }
  };

  SS_Dropdown.closeDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.closeDropdown();
    }
  };

  SS_Dropdown.toggleDropdown = function () {
    if (SS_Dropdown.dropdown) {
      return SS_Dropdown.dropdown.toggleDropdown();
    }
  };

  function SS_Dropdown(elem, options) {
    this.elem = $(elem);
    this.options = options;
    this.target = $(this.options.target);
    this.bindEvents();
  }

  SS_Dropdown.prototype.bindEvents = function () {
    this.elem.on("click", (function (_this) {
      return function (e) {
        _this.toggleDropdown();
        return _this.cancelEvent(e);
      };
    })(this));
    //focusout
    $(document).on("click", (function (_this) {
      return function (e) {
        if (e.target !== _this.elem && e.target !== _this.target) {
          return _this.closeDropdown();
        }
      };
    })(this));
    return this.elem.on("keydown", (function (_this) {
      return function (e) {
        if (e.keyCode === 27) {  //ESC
          _this.closeDropdown();
          return _this.cancelEvent(e);
        }
      };
    })(this));
  };

  SS_Dropdown.prototype.openDropdown = function () {
    return this.target.show();
  };

  SS_Dropdown.prototype.closeDropdown = function () {
    return this.target.hide();
  };

  SS_Dropdown.prototype.toggleDropdown = function () {
    return this.target.toggle();
  };

  SS_Dropdown.prototype.cancelEvent = function (e) {
    e.preventDefault();
    e.stopPropagation();
    return false;
  };

  return SS_Dropdown;

})();
String.prototype.endsWith||(String.prototype.endsWith=function(t,n){return n<this.length?n|=0:n=this.length,this.substr(n-t.length,t.length)===t});
String.prototype.includes||(String.prototype.includes=function(t,n){return"number"!=typeof n&&(n=0),!(n+t.length>this.length)&&-1!==this.indexOf(t,n)});
String.prototype.padEnd||(String.prototype.padEnd=function(t,n){return t>>=0,n=String(n||" "),this.length>t?String(this):((t-=this.length)>n.length&&(n+=n.repeat(t/n.length)),String(this)+n.slice(0,t))});
String.prototype.padStart||(String.prototype.padStart=function(t,n){return t>>=0,n=String(n||" "),this.length>t?String(this):((t-=this.length)>n.length&&(n+=n.repeat(t/n.length)),n.slice(0,t)+String(this))});
String.prototype.repeat||(String.prototype.repeat=function(t){if(null==this)throw new TypeError("can't convert "+this+" to object");var r=""+this;if((t=+t)!=t&&(t=0),t<0)throw new RangeError("repeat count must be non-negative");if(t==1/0)throw new RangeError("repeat count must be less than infinity");if(t=Math.floor(t),0==r.length||0==t)return"";if(r.length*t>=1<<28)throw new RangeError("repeat count must not overflow maximum string size");for(var e="";1==(1&t)&&(e+=r),0!=(t>>>=1);)r+=r;return e});
String.prototype.startsWith||(String.prototype.startsWith=function(t,r){return r=r||0,this.substr(r,t.length)===t});
String.prototype.trim||(String.prototype.trim=function(){return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,"")});










// here are polyfills for IE11








SS_Preview = (function () {
  function SS_Preview(el) {
    this.el = el;
    this.inplaceMode = false;
    this.layouts = [];
    this.parts = [];
    this.editLock = new EditLock(this);
    this.updateDisabled = false;
  }

  SS_Preview.libs = {
    jquery: { isInstalled: function() { return !!window.jQuery; }, js: null, css: null },
    datetimePicker: { isInstalled: function() { return !!$.datetimepicker; }, js: null, css: null },
    colorbox: { isInstalled: function() { return !!$.colorbox; }, js: null, css: null },
    dialog: { isInstalled: function() { return $.ui && $.ui.dialog; }, js: null, css: null }
  };

  SS_Preview.confirms = { delete: null, publish: null };

  SS_Preview.notices = { deleted: null, published: null, moved: null };

  SS_Preview.item = {};

  SS_Preview.preview_path = "";

  SS_Preview.mobile_path = "/mobile";

  SS_Preview.request_path = null;

  SS_Preview.form_item = null;

  SS_Preview.overlayPadding = 0;
  SS_Preview.previewToolHeight = 70;

  SS_Preview.inplaceFormPath = { page: null, columnValue: {}, palette: null };

  SS_Preview.workflowPath = { wizard: null, pages: null, request: null };

  SS_Preview.redirectorPath = { newPage: null };

  SS_Preview.publishPath = null;

  SS_Preview.lockPath = null;

  SS_Preview.refreshLockInterval = 2 * 60 * 1000;

  SS_Preview.instance = null;

  SS_Preview.minFrameSize = { width: 320, height: 150 };
  SS_Preview.initialFrameSize = { width: 960, height: 240 };
  SS_Preview.initialApproverSize = { width: SS_Preview.initialFrameSize.width, height: 480 };

  SS_Preview.jqueryDialogMargin = { height: 60 };

  SS_Preview.pageTitle = "本文";

  SS_Preview.userInplaceEdit = true;

  SS_Preview.render = function (opts) {
    if (SS_Preview.instance) {
      return;
    }

    SS_Preview.instance = new SS_Preview("#ss-preview");

    SS_Preview.loadJQuery(function() {
      $.when(
        SS_Preview.lazyLoad(SS_Preview.libs.datetimePicker),
        SS_Preview.lazyLoad(SS_Preview.libs.colorbox),
        SS_Preview.lazyLoad(SS_Preview.libs.dialog)
      ).done(function () {
        SS_Preview.instance.initialize(opts);
      });
    });
  };

  SS_Preview.loadJQuery = function (callback) {
    if (window.jQuery) {
      callback();
      return;
    }

    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = SS_Preview.libs.jquery.css;

    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = SS_Preview.libs.jquery.js;

    if (script.readyState) {
      // IE
    } else {
      script.onload = function () {
        callback();
      }
    }

    document.getElementsByTagName("head")[0].appendChild(link);
    document.getElementsByTagName("head")[0].appendChild(script);
  };

  SS_Preview.lazyLoad = function (data) {
    var d = $.Deferred();

    if (data.isInstalled()) {
      d.resolve();
      return d.promise();
    }

    var link;
    if (data.css) {
      link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = data.css;
    }

    var script;
    if (data.js) {
      script = document.createElement("script");
      script.type = "text/javascript";
      script.src = data.js;
    }

    if (link) {
      document.getElementsByTagName("head")[0].appendChild(link);
    }

    if (script) {
      if (script.readyState) {
        // IE
        d.resolve();
      } else {
        script.onload = function () {
          d.resolve();
        }
      }

      document.getElementsByTagName("head")[0].appendChild(script);
    } else {
      d.resolve();
    }

    return d.promise();
  };

  SS_Preview.notice = function (message) {
    if (!SS_Preview.instance) {
      return;
    }
    if (!SS_Preview.instance.notice) {
      return;
    }

    SS_Preview.instance.notice.show(message);
  };

  SS_Preview.bindToWorkflowCommentForm = function (updateType) {
    if (!SS_Preview.instance) {
      return;
    }

    SS_Preview.instance.bindToWorkflowCommentForm(updateType);
  };

  SS_Preview.openNewWindow = function (path) {
    var a = document.createElement("a");
    a.href = path;
    a.target = "_blank";
    a.rel = "noopener";
    a.click();
  };

  SS_Preview.closeWindow = function ($frame) {
    if ($frame.closest("#cboxLoadedContent")[0]) {
      $.colorbox.close();
    }
    if ($frame.closest(".ui-dialog")[0]) {
      $frame.dialog("close");
    }
  }

  SS_Preview.prototype.initialize = function(opts) {
    this.$el = $(this.el);
    this.$datePicker = this.$el.find(".ss-preview-date");
    this.$datePicker.datetimepicker({
      lang: "ja",
      roundTime: "ceil",
      step: 30,
      closeOnDateSelect: true
    });

    var self = this;

    this.initializePart();
    this.initializeLayout();
    this.initializePage();
    this.initializeColumn();

    // initialize workflow
    this.$el.on("click", "#ss-preview-btn-workflow-start", function() {
      self.openWorkflowApprove();
    });

    this.$el.on("click", "#ss-preview-btn-workflow-approve", function() {
      self.openWorkflowComment("approve");
    });
    this.$el.on("click", "#ss-preview-btn-workflow-remand", function() {
      self.openWorkflowComment("remand");
    });
    this.$el.on("click", "#ss-preview-btn-workflow-pull-up", function() {
      self.openWorkflowComment("pull-up");
    });

    this.$el.on("click", "#ss-preview-btn-publish", function () {
      self.publish();
    });

    // initialize overlay
    this.overlay = new Overlay(this);
    this.overlay.on("part:edit", function(ev, data) {
      self.openPartEdit(data.id);
    });
    this.overlay.on("page:edit", function(ev, data) {
      self.openPageEdit(data.id);
    });
    this.overlay.on("column:edit", function(ev, data) {
      self.openColumnEdit(data.id);
    });
    this.overlay.on("column:delete", function(ev, data) {
      self.postColumnDelete(data.id);
    });
    this.overlay.on("column:moveUp", function(ev, data) {
      self.postColumnMoveUp(data.id);
    });
    this.overlay.on("column:moveDown", function(ev, data) {
      self.postColumnMoveDown(data.id);
    });
    this.overlay.on("column:movePosition", function(ev, data, order) {
      self.postColumnMovePosition(data.id, order);
    });

    var formEnd = $("#ss-preview-form-end");
    if (formEnd[0]) {
      this.formPalette = FormPalette.createBefore(this, formEnd[0]);
    }

    this.$el.on("click", ".ss-preview-btn-toggle-inplace", function () {
      var before = self.inplaceMode;
      self.toggleInplaceMode().always(function() {
        if (before === self.inplaceMode) {
          return;
        }
        if (!window.history.pushState) {
          return;
        }

        if (self.inplaceMode) {
          window.history.pushState(null, null, window.location.pathname + "#inplace");
        } else {
          window.history.pushState(null, null, window.location.pathname);
        }

        setTimeout(function() { self.$el.trigger("ss:inplaceModeChanged"); }, 0);
      });
    });

    this.$el.on("click", "#ss-preview-btn-workflow-start", function () {
      var before = self.inplaceMode;
      if (self.inplaceMode) {
        self.toggleInplaceMode().always(function () {
          if (before === self.inplaceMode) {
            return;
          }
          if (!window.history.pushState) {
            return;
          }
          window.history.pushState(null, null, window.location.pathname);
          setTimeout(function() { self.$el.trigger("ss:inplaceModeChanged"); }, 0);
        });
      }
    });

    $(document).on("click", ".ss-preview-btn-open-path", function () {
      var path = $(this).data("path");
      if (path) {
        // window.open(path, "_blank")
        SS_Preview.openNewWindow(path);
      }
    });

    var $selectNodeBtn = this.$el.find("#ss-preview-btn-select-node");
    $selectNodeBtn.colorbox({ iframe: true, fixed: true, width: "90%", height: "90%" })
      .data("on-select", function($item) {
        var $dataEl = $item.closest("[data-id]");
        var id = $dataEl.data("id");
        var name = $dataEl.find(".name").text();

        var $nodeDataEl = $selectNodeBtn.closest("[data-node-id]");
        SS_Preview.setData($nodeDataEl, "node-id", id);
        $nodeDataEl.find("label").html(name);
      });

    this.$el.find("#ss-preview-btn-create-new-page").on("click", function() {
      var $nodeDataEl = $selectNodeBtn.closest("[data-node-id]");
      var nodeId = $nodeDataEl.data("node-id");

      window.open(SS_Preview.redirectorPath.newPage.replace(":nodeId", nodeId));
    });

    this.$el.find("#ss-preview-btn-select-draft-page")
      .colorbox({ iframe: true, fixed: true, width: "90%", height: "90%" })
      .data("on-select", function($item) {
        var $dataEl = $item.closest("[data-id]");
        var filename = $dataEl.find(".filename").text();

        var url = SS_Preview.previewPath.replace(":path", filename);
        if (window.location.hash === "#inplace") {
          url += "#inplace";
        }
        window.location.href = url;
      });

    this.$el.on("click", ".ss-preview-btn-pc", function () {
      self.previewPc();
    });

    this.$el.on("click", ".ss-preview-btn-mobile", function () {
      self.previewMobile();
    });

    if (SS_Preview.request_path) {
      $('body a [href="#"]').val("onclick", "return false;");
    }

    if (window.history.pushState) {
      // history api is available
      window.addEventListener("popstate", function() {
        if (window.location.hash === "#inplace") {
          self.startInplaceMode();
        } else {
          self.stopInplaceMode();
        }
      });
    }

    if (window.location.hash === "#inplace") {
      this.startInplaceMode();
    }

    // initialize notice;
    this.notice = new Notice(this);
    if (opts.notice) {
      this.notice.show(opts.notice);
    }
  };

  SS_Preview.prototype.initializeLayout = function() {
    var $body = $("body");
    if ($body.data("layout-id")) {
      this.layouts = [{
        id: $body.data("layout-id"), name: $body.data("layout-name"),
        filename: $body.data("layout-filename"), path: $body.data("layout-path")
      }];
    }

    var button = this.$el.find(".ss-preview-btn-edit-layout");
    if (! this.layouts || this.layouts.length === 0) {
      button.closest(".ss-preview-btn-group").addClass("ss-preview-hide");
      return;
    }

    button.closest(".ss-preview-btn-group").removeClass("ss-preview-hide");

    var path = this.layouts[0].path;
    button.on('click', function() {
      // window.open(path, '_blank');
      SS_Preview.openNewWindow(path);
    });
  };

  SS_Preview.prototype.initializePage = function() {
    var self = this;
    $(document).on("mouseover", ".ss-preview-page", function() {
      if (self.inplaceMode) {
        self.overlay.showForPage($(this));
      }
    });
  };

  SS_Preview.prototype.adjustDialogSize = function(frame) {
    var width = frame.contentWindow.document.body.scrollWidth;
    var height = frame.contentWindow.document.body.scrollHeight;

    if ($(frame).closest(".ui-dialog")[0]) {
      height += SS_Preview.jqueryDialogMargin.height;
    }

    if (width < SS_Preview.initialFrameSize.width) {
      width = SS_Preview.initialFrameSize.width;
    }
    if (height < SS_Preview.initialFrameSize.height) {
      height = SS_Preview.initialFrameSize.height;
    }

    var maxWidth = Math.floor(window.innerWidth * 0.9);
    var maxHeight = Math.floor(window.innerHeight * 0.9);

    if (width > maxWidth) {
      width = maxWidth;
    }
    if (height > maxHeight) {
      height = maxHeight;
    }

    if ($(frame).closest("#cboxLoadedContent")[0]) {
      $.colorbox.resize({ width: width, height: height });
    }

    if ($(frame).closest(".ui-dialog")[0]) {
      $(frame).dialog("option", "width", width)
        .dialog("option", "height", height)
        .css("display", "")
        .css("width", "");
    }
  };

  SS_Preview.prototype.initializeFrame = function(frame) {
    var itemForm = frame.contentWindow.document.querySelector("#item-form");
    if (! itemForm) {
      // iframe is not loaded completely
      return;
    }

    this.adjustDialogSize(frame);

    var self = this;
    self.saveIfNoAlerts = false;
    self.ignoreAlertsAndSave = false;

    itemForm.addEventListener("click", function(ev) {
      var el = ev.target;

      if (el.tagName === "BUTTON" && el.classList.contains("btn-cancel")) {
        SS_Preview.closeWindow($(frame));
      }

      if (el.tagName === "INPUT" && el.name === "save_if_no_alerts") {
        self.saveIfNoAlerts = true;
      }

      if (el.tagName === "INPUT" && el.name === "ignore_alerts_and_save") {
        self.ignoreAlertsAndSave = true;
      }

      return true;
    });
    itemForm.onsubmit = function(ev) {
      var formData = frame.contentWindow.Cms_Form.getFormData(frame.contentWindow.$(itemForm), { preserveMethod: true });
      if (self.saveIfNoAlerts) {
        formData.append("save_if_no_alerts", "button");
      }
      if (self.ignoreAlertsAndSave) {
        formData.append("ignore_alerts_and_save", "button");
      }

      var action = itemForm.getAttribute("action");
      var method = itemForm.getAttribute("method") || "POST";
      $.ajax({
        url: action,
        type: method,
        data: formData,
        processData: false,
        contentType: false,
        cache: false,
        success: function(data, textStatus, xhr) {
          SS_Preview.closeWindow($(frame));
          if (typeof data === "string") {
            // data is html
            location.reload();
          } else {
            // data is json
            if (data && data.location) {
              location.href = data.location;
            } else {
              location.reload();
            }
          }
        },
        error: function(xhr, status, error) {
          var $html = $(xhr.responseText);
          var $itemForm = $html.find("#item-form");

          itemForm.innerHTML = $itemForm.html();
          self.adjustDialogSize(frame);
        }
      });

      self.saveIfNoAlerts = false;
      self.ignoreAlertsAndSave = false;

      ev.preventDefault();
      return false;
    };


    if (frame.contentWindow.CKEDITOR) {
      frame.contentWindow.CKEDITOR.on("instanceReady", function (ev) {
        self.adjustRichEditorHeight(ev.editor);
      });
    }

    self.$el.trigger("ss:inplaceEditFrameInitialized");
  };

  // SS_Preview.prototype.openDialogInFrame = function(url) {
  //   var self = this;
  //
  //   // open edit form in iframe
  //   $.colorbox({
  //     href: url,
  //     iframe: true,
  //     fixed: true,
  //     width: SS_Preview.initialFrameSize.width,
  //     height: SS_Preview.initialFrameSize.height,
  //     opacity: 0.15,
  //     overlayClose: false,
  //     escKey: false,
  //     arrowKey: false,
  //     closeButton: false,
  //     onComplete: function() {
  //       var frame = $("#cboxLoadedContent iframe")[0];
  //       frame.onload = function() {
  //         self.initializeFrame(frame);
  //       };
  //     }
  //   });
  // };
  SS_Preview.prototype.openDialogInFrame = function(url) {
    var self = this;

    var $frame = $("<iframe></iframe>", {
      id: "ss-preview-dialog-frame",
      frameborder: "0", allowfullscreen: true,
      src: url
    });

    $frame[0].onload = function() { self.initializeFrame($frame[0]); };

    $frame.dialog({
      autoOpen: true,
      width: SS_Preview.initialFrameSize.width,
      height: SS_Preview.initialFrameSize.height,
      minWidth: SS_Preview.minFrameSize.width,
      minHeight: SS_Preview.minFrameSize.height,
      closeOnEscape: false,
      dialogClass: "ss-preview-dialog ss-preview-dialog-column",
      draggable: true,
      modal: true,
      resizable: true,
      close: function(ev, ui) {
        // explicitly destroy dialog and remove elemtns because dialog elements is still remained
        $(this).dialog('destroy').remove();
      }
    });
  };

  SS_Preview.prototype.openDialog = function(url, options) {
    var self = this;

    if (! options) {
      options = {};
    }

    $.ajax({
      url: url,
      type: "GET",
      success: function(data, textStatus, xhr) {
        var $frame = $("div#ss-preview-dialog-frame");
        if (! $frame[0]) {
          $frame = $("<div></div>", { id: "ss-preview-dialog-frame" });
        }
        $frame.html(data);
        $frame.dialog({
          autoOpen: true,
          width: options.width || SS_Preview.initialFrameSize.width,
          height: options.height || SS_Preview.initialFrameSize.height,
          minWidth: options.minWidth || SS_Preview.minFrameSize.width,
          minHeight: options.minHeight || SS_Preview.minFrameSize.height,
          closeOnEscape: false,
          dialogClass: "ss-preview-dialog ss-preview-dialog-column",
          draggable: true,
          modal: true,
          resizable: true,
          close: function(ev, ui) {
            // explicitly destroy dialog and remove elemtns because dialog elements is still remained
            $(this).dialog('destroy').remove();
          }
        });
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
      }
    })
  };

  SS_Preview.prototype.adjustRichEditorHeight = function(editor) {
    if (editor.status !== "ready") {
      return;
    }

    var $el = $(editor.element.$);
    var $parent = $el.parent();
    var height = $parent.height();

    height = height - 40;
    if (height < 50) {
      height = 50;
    }

    editor.resize("100%", height.toString());
  };

  SS_Preview.prototype.openPageEdit = function(pageId) {
    // open page(body) edit form in iframe
    var url = SS_Preview.inplaceFormPath.page.replace(":id", pageId);
    this.openDialogInFrame(url);
  };

  SS_Preview.prototype.initializePart = function() {
    var self = this;
    this.parts = [];
    $(document).find(".ss-preview-part").each(function() {
      var $this = $(this);
      if (! $this.data("part-id")) {
        return;
      }
      self.parts.push({
        el: $this, id: $this.data("part-id"), name: $this.data("part-name"),
        filename: $this.data("part-filename"), path: $this.data("part-path")
      });
    });


    if (!this.parts || this.parts.length === 0) {
      this.$el.find(".ss-preview-part-group").addClass("ss-preview-hide");
      return;
    }

    var list = this.$el.find(".ss-preview-part-list");
    var options = list.html();
    $.each(this.parts, function(index, item) {
      options += "<option value=\"" + item.id + "\">" + item.name + "</option>"
    });

    list.html(options).on('change', function() {
      self.changePart($(this));
    });

    this.$el.on("click", ".ss-preview-btn-edit-part", function() {
      self.openPartEdit(list.val());
    });

    this.$el.find(".ss-preview-part-group").removeClass("ss-preview-hide");

    $(document).on("mouseover", ".ss-preview-part", function() {
      if (self.inplaceMode) {
        self.overlay.showForPart($(this));
      }
    });
  };

  SS_Preview.prototype.findPartById = function(partId) {
    if (! partId) {
      return null;
    }

    if ($.type(partId) === "string") {
      partId = parseInt(partId);
    }

    var founds = $.grep(this.parts, function(part, index) { return part.id === partId });
    if (! founds || founds.length === 0) {
      return null;
    }

    return founds[0];
  };

  SS_Preview.prototype.initializeColumn = function() {
    var self = this;
    $(document).on("mouseover", ".ss-preview-column", function() {
      if (self.inplaceMode) {
        self.overlay.showForColumn($(this));
      }
    });
  };

  SS_Preview.prototype.openColumnEdit = function(ids) {
    // open column edit form in iframe
    var url = SS_Preview.inplaceFormPath.columnValue.edit.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    this.openDialogInFrame(url);
  };

  SS_Preview.prototype.postColumnDelete = function(ids) {
    if (! confirm(SS_Preview.confirms.delete)) {
      return;
    }

    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.destroy.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { _method: "DELETE", authenticity_token: token },
      success: function(data, textStatus, xhr) {
        self.overlay.hide();

        if (data && data.location) {
          location.href = data.location;
        } else {
          var $column = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
          $column.fadeOut("fast", function () {
            $column.remove();
            self.notice.show(SS_Preview.notices.deleted);
          });
        }
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
      }
    });
  };

  SS_Preview.prototype.postColumnMoveUp = function(ids) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveUp.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token },
      success: function(data, textStatus, xhr) {
        self.overlay.hide();

        if (data.location) {
          location.href = data.location;
        } else {
          self.finishColumnMoveUp(ids, data);
          self.notice.show(SS_Preview.notices.moved);
        }
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
      }
    });
  };

  SS_Preview.camelize = function(str) {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function(letter, index) {
      return index == 0 ? letter.toLowerCase() : letter.toUpperCase();
    }).replace(/[\s-]+/g, '');
  };

  SS_Preview.setData = function($el, name, value) {
    $el.data(name, value);

    var camelizedName = SS_Preview.camelize(name);
    $el.each(function() {
      this.dataset[camelizedName] = value;
    });
  };

  SS_Preview.prototype.finishColumnMoveUp = function(ids, data) {
    var self = this;
    self.overlay.hide();

    var $target = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$target[0]) {
      return;
    }
    var $prev = $target.prev(".ss-preview-column[data-page-id='" + ids.pageId + "']");
    if (!$prev[0]) {
      return;
    }

    Cms_TemplateForm.swapElement($prev, $target, function() {
      SS_Preview.setData($prev, "column-order", data[$prev.data("column-id")]);
      SS_Preview.setData($target, "column-order", data[$target.data("column-id")]);
      $target.after($prev);

      $target.trigger("column:moved", "up");
    });
  };

  SS_Preview.prototype.postColumnMoveDown = function(ids) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveDown.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token },
      success: function(data) {
        self.overlay.hide();

        if (data.location) {
          location.href = data.location;
        } else {
          self.finishColumnMoveDown(ids, data);
          self.notice.show(SS_Preview.notices.moved);
        }
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
      }
    });
  };

  SS_Preview.prototype.finishColumnMoveDown = function(ids, data) {
    var self = this;
    self.overlay.hide();

    var $target = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$target[0]) {
      return;
    }

    var $next = $target.next(".ss-preview-column[data-page-id='" + ids.pageId + "']");
    if (!$next[0]) {
      return;
    }

    Cms_TemplateForm.swapElement($target, $next, function() {
      SS_Preview.setData($next, "column-order", data[$next.data("column-id")]);
      SS_Preview.setData($target, "column-order", data[$target.data("column-id")]);
      $target.before($next);

      $target.trigger("column:moved", "down");
    });
  };

  SS_Preview.prototype.postColumnMovePosition = function(ids, order) {
    var self = this;
    var url = SS_Preview.inplaceFormPath.columnValue.moveAt.replace(":pageId", ids.pageId).replace(":id", ids.columnId);
    var token = $('meta[name="csrf-token"]').attr('content');

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token, order: order },
      success: function(data) {
        if (data.location) {
          location.href = data.location;
        } else {
          self.finishColumnMovePosition(ids, order, data);
          self.notice.show(SS_Preview.notices.moved);
        }
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
      }
    });
  };

  SS_Preview.prototype.finishColumnMovePosition = function(ids, order, data) {
    var self = this;
    self.overlay.hide();

    var $source = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-id='" + ids.columnId + "']");
    if (!$source[0]) {
      return;
    }
    var sourceOrder = $source.data("column-order");

    var $destination = $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "'][data-column-order='" + order + "']");
    if (!$destination[0]) {
      return;
    }

    Cms_TemplateForm.insertElement($source, $destination, function() {
      $(document).find(".ss-preview-column[data-page-id='" + ids.pageId + "']").each(function() {
        var $this = $(this);
        SS_Preview.setData($this, "column-order", data[$this.data("column-id")]);
      });
      if (order < sourceOrder) {
        $destination.before($source);
      } else {
        $destination.after($source);
      }

      $source.trigger("column:moved", "position");
    });
  };

  SS_Preview.prototype.previewPc = function() {
    var date = this.dateForPreview();
    if (! date) {
      return;
    }

    var path = SS_Preview.request_path || location.pathname;
    path = path.replace(RegExp("\\/preview\\d*(" + SS_Preview.mobile_path + "|" + SS_Preview.preview_path + ")?"), "/preview" + date + SS_Preview.preview_path) + location.search;
    if (SS_Preview.request_path) {
      this.submitFormPreview(path, SS_Preview.form_item);
    } else {
      location.href = path;
    }
  };

  SS_Preview.prototype.previewMobile = function() {
    var date = this.dateForPreview();
    if (! date) {
      return;
    }

    var path = SS_Preview.request_path || location.pathname;
    path = path.replace(RegExp("\\/preview\\d*(" + SS_Preview.mobile_path + "|" + SS_Preview.preview_path + ")?"), "/preview" + date + SS_Preview.mobile_path) + location.search;
    if (SS_Preview.request_path) {
      this.submitFormPreview(path, SS_Preview.form_item);
    } else {
      location.href = path;
    }
  };

  SS_Preview.prototype.dateForPreview = function() {
    var date = this.$datePicker.val();
    if (!date) {
      return;
    }
    return date.replace(/[^\d]/g, "");
  };

  SS_Preview.prototype.submitFormPreview = function (path, form_item) {
    var token = $('meta[name="csrf-token"]').attr('content');
    var form = $("<form>").attr("method", "post").attr("action", path);

    SS_Preview.appendParams(form, "preview_item", form_item);
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden"}));
    form.appendTo("body");
    form.submit();
  };

  SS_Preview.prototype.changePart = function($el) {
    var part = this.findPartById($el.val());
    if (! part) {
      this.overlay.hide();
      return;
    }

    // this.showOverlayForPart(part.el);
    this.overlay.showForPart(part.el);
    this.scrollToPart(part.el);
  };

  SS_Preview.prototype.scrollToPart = function($part) {
    var offset = $part.offset();
    var scrollTop = offset.top - SS_Preview.previewToolHeight;
    if (scrollTop < 0) {
      scrollTop = 0;
    }

    window.scrollTo({ top: scrollTop, behavior: "smooth" });
  };

  SS_Preview.prototype.openPartEdit = function(partId) {
    var part = this.findPartById(partId);
    if (! part) {
      return;
    }

    // window.open(part.path, "_blank");
    SS_Preview.openNewWindow(part.path);
  };

  //
  // Workflow Approve
  //

  SS_Preview.prototype.openWorkflowApprove = function() {
    var url = SS_Preview.workflowPath.wizard.replace(":id", SS_Preview.item.pageId) + "/frame";
    this.openDialog(url, { width: SS_Preview.initialApproverSize.width, height: SS_Preview.initialApproverSize.height });
  };

  SS_Preview.prototype.openWorkflowComment = function(updateType) {
    var url = SS_Preview.workflowPath.wizard.replace(":id", SS_Preview.item.pageId) + "/comment?update_type=" + updateType;
    this.openDialog(url, { width: SS_Preview.initialApproverSize.width, height: SS_Preview.initialApproverSize.height });
  };

  SS_Preview.prototype.bindToWorkflowCommentForm = function(updateType) {
    var self = this;
    var $frame = $("#ss-preview-dialog-frame");
    $frame.on("click", "input[type=submit]", function() {
      var remandComment = $frame.find("textarea[name=comment]").prop("value");
      var action = updateType + "_update";
      var url = SS_Preview.workflowPath.pages.replace(":id", SS_Preview.item.pageId);
      url += "/" + action;
      var path = SS_Preview.request_path || location.pathname;

      if (self.updateDisabled) {
        return;
      }
      self.updateDisabled = true;

      $.ajax({
        type: "POST",
        url: url,
        data: {
          remand_comment: remandComment,
          url: path,
          forced_update_option: true
        },
        success: function (data) {
          if (data.workflow_alert) {
            self.updateDisabled = false;
            self.notice.show(data.workflow_alert);
            return;
          }

          if (data.redirect.reload) {
            location.reload();
            return;
          }

          if (data.redirect.url) {
            location.href = SS_Preview.previewPath.replace(":path", data.redirect.url.slice(1));
            return;
          }

          location.reload();
        },
        error: function(xhr, status, error) {
          try {
            var errors = xhr.responseJSON;
            var msg = errors.join("\n");
            self.notice.show(msg);
          } catch (ex) {
            self.notice.show("Error: " + error);
          }
          self.updateDisabled = false;
        },
        complete: function() {
          SS_Preview.closeWindow($frame);
        }
      });
    });
    $frame.on("click", "button[type=reset]", function() {
      SS_Preview.closeWindow($frame);
    });
  };

  //
  // Public
  //

  SS_Preview.prototype.publish = function() {
    if (! confirm(SS_Preview.confirms.publish)) {
      return;
    }

    var self = this;
    var url = SS_Preview.publishPath;
    var token = $('meta[name="csrf-token"]').attr('content');

    if (self.updateDisabled) {
      return;
    }
    self.updateDisabled = true;

    $.ajax({
      url: url,
      type: "POST",
      data: { authenticity_token: token },
      success: function(data, textStatus, xhr) {
        self.overlay.hide();

        if (data && data.location) {
          location.href = data.location;
        } else {
          self.notice.show(SS_Preview.notices.published);

          var $button = self.$el.find("#ss-preview-btn-publish")
          var $buttonContainer = $button.closest(".ss-preview-btn-group");
          $buttonContainer.remove();
          self.updateDisabled = false;
        }
      },
      error: function(xhr, status, error) {
        try {
          var errors = xhr.responseJSON;
          var msg = errors.join("\n");
          self.notice.show(msg);
        } catch (ex) {
          self.notice.show("Error: " + error);
        }
        self.updateDisabled = false;
      }
    });
  };

  //
  // Lock / Unlock
  //

  function EditLock(container) {
    this.container = container;
    this.timerId = null;
  }

  EditLock.prototype.acquire = function() {
    if (!SS_Preview.lockPath) {
      return $.Deferred().resolve().promise();
    }

    var self = this;
    var url = SS_Preview.lockPath;
    var token = $('meta[name="csrf-token"]').attr('content');

    return $.ajax({
      url: url,
      type: "POST",
      dataType: "json",
      cache: false,
      data: {authenticity_token: token}
    }).done(function(data, status, xhr) {
      self.bindBeforeUnloadOnce();
    }).fail(function(xhr, status, error) {
      if (self.container.notice) {
        if (xhr.responseJSON) {
          self.container.notice.show(xhr.responseJSON.join("\n"));
        } else {
          self.container.notice.show(error);
        }
      }
    });
  };

  EditLock.prototype.release = function() {
    if (!SS_Preview.lockPath) {
      return $.Deferred().resolve().promise();
    }

    var self = this;
    var url = SS_Preview.lockPath;
    var token = $('meta[name="csrf-token"]').attr('content');

    return $.ajax({
      url: url,
      type: "POST",
      dataType: "json",
      cache: false,
      data: { _method: "delete", authenticity_token: token }
    }).fail(function(xhr, status, error) {
      if (self.container.notice) {
        if (xhr.responseJSON) {
          self.container.notice.show(xhr.responseJSON.join("\n"));
        } else {
          self.container.notice.show(error);
        }
      }
    });
  };

  EditLock.prototype.startRefreshLoop = function(failed) {
    var self = this;

    if (self.timerId) {
      // loop was already started
      return;
    }

    self.timerId = setTimeout(function() { self.acquire().fail(failed); self.startRefreshLoop(); }, SS_Preview.refreshLockInterval);
  };

  EditLock.prototype.stopRefreshLoop = function() {
    if (this.timerId) {
      clearTimeout(this.timerId);
    }
    this.timerId = null;
  };

  EditLock.prototype.bindBeforeUnloadOnce = function() {
    var self = this;

    $(window).on("beforeunload", function () {
      self.release();
    });

    this.bindBeforeUnloadOnce = function() {};
  };

  //
  // Inplace Edit
  //

  SS_Preview.prototype.toggleInplaceMode = function() {
    if (this.inplaceMode) {
      return this.stopInplaceMode();
    } else {
      return this.startInplaceMode();
    }
  };

  SS_Preview.prototype.startInplaceMode = function() {
    if (!SS_Preview.userInplaceEdit) {
      return $.Deferred().resolve().promise();
    }
    if (this.inplaceMode) {
      // already in inplace mode
      return;
    }

    var self = this;
    return this.editLock.acquire().done(function() {
      self.inplaceMode = true;

      var button = self.$el.find(".ss-preview-btn-toggle-inplace");
      button.addClass("ss-preview-active");

      $("#ss-preview-notice").addClass("ss-preview-hide");
      if (self.formPalette) {
        self.formPalette.show();
      }

      $("a[href]").each(function() {
        var $a = $(this);
        var href = $a.attr("href");
        if (!href) {
          return;
        }
        if (!href.startsWith("/")) {
          return;
        }
        if (href.includes("#")) {
          return;
        }

        $a.attr("href", href + "#inplace");
      });

      self.editLock.startRefreshLoop(function() { self.stopInplaceMode(true); });
      window.location.hash = "#inplace";
    });
  };

  SS_Preview.prototype.stopInplaceMode = function(dontCareLock) {
    if (!this.inplaceMode) {
      // already exited from inplace mode
      return
    }

    var self = this;
    var afterReleased = function() {
      self.editLock.stopRefreshLoop();

      var button = self.$el.find(".ss-preview-btn-toggle-inplace");

      button.removeClass("ss-preview-active");
      self.overlay.hide();
      if (self.formPalette) {
        self.formPalette.hide();
      }

      $("a[href]").each(function () {
        var $a = $(this);
        var href = $a.attr("href");
        if (!href) {
          return;
        }
        if (!href.startsWith("/")) {
          return;
        }

        $a.attr("href", href.replace("#inplace", ""));
      });

      self.inplaceMode = false;
      window.location.hash = "";
    };

    if (dontCareLock) {
      afterReleased();
      return $.Deferred().resolve().promise();
    }

    return this.editLock.release().always(afterReleased);
  };

  //
  //
  //

  SS_Preview.prototype.showError = function(errorJson) {
    var messages = [];
    $.each(errorJson, function() {
      messages.push("<li>" + this + "</li>");
    });

    $("#ss-preview-error-explanation ul").html(messages.join());
    $("#ss-preview-error-explanation").removeClass("ss-preview-hide");
    $("#ss-preview-messages").removeClass("ss-preview-hide");
  };

  SS_Preview.prototype.clearError = function() {
    $("#ss-preview-error-explanation ul").html("");
    $("#ss-preview-error-explanation").addClass("ss-preview-hide");
    $("#ss-preview-messages").addClass("ss-preview-hide");
  };

  SS_Preview.appendParams = function (form, name, params) {
    var k, results, v;
    if (params.length <= 0) {
      form.append($("<input/>", {
        name: name + "[]",
        value: "",
        type: "hidden"
      }));
    }
    results = [];
    for (k in params) {
      v = params[k];
      if (k.match(/^\d+$/)) {
        k = "";
      }
      if (typeof v === 'object') {
        results.push(SS_Preview.appendParams(form, name + "[" + k + "]", v));
      } else {
        results.push(form.append($("<input/>", {
          name: name + "[" + k + "]",
          value: v,
          type: "hidden"
        })));
      }
    }
    return results;
  };

  //
  // Overlay
  //

  function Overlay(container) {
    this.container = container;
    this.$overlay = $("#ss-preview-overlay");

    this.initPosition();

    var self = this;
    this.$overlay.on("click", ".ss-preview-overlay-btn-edit", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":edit";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-delete", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":delete";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-move-up", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":moveUp";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("click", ".ss-preview-overlay-btn-move-down", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":moveDown";
      self.$overlay.trigger(eventType, self.$overlay.data());
    });
    this.$overlay.on("change", ".ss-preview-overlay-btn-move-position", function() {
      var mode = self.$overlay.data("mode");
      var eventType = mode + ":movePosition";
      var order = parseInt($(this).val(), 10);
      self.$overlay.trigger(eventType, [ self.$overlay.data(), order ]);
    });

    // delegates
    this.on = this.$overlay.on.bind(this.$overlay);
    this.off = this.$overlay.off.bind(this.$overlay);
  }

  Overlay.prototype.initPosition = function() {
    var select = this.$overlay.find(".ss-preview-overlay-btn-move-position");
    if (select[0]) {
      var html = [];
      $(document).find(".ss-preview-column[data-column-order]").each(function () {
        var order = parseInt(this.dataset.columnOrder, 10);
        html.push("<option value=\"" + order + "\">" + (order + 1) + "</option>");
      });

      select.html(html.join(""));
    }
  };

  Overlay.prototype.hide = function() {
    this.$overlay.addClass("ss-preview-hide");
  };

  Overlay.prototype.showForPage = function($page) {
    var rect = $page[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "page", id: $page.data("page-id"), name: SS_Preview.pageTitle });

    this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
    this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.showForColumn = function($column) {
    var rect = $column[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "column", id: { pageId: $column.data("page-id"), columnId: $column.data("column-id") }, name: $column.data("column-name") });

    if (SS_Preview.item.formSubType === "entry") {
      this.$overlay.find(".ss-preview-overlay-btn-group-move").removeClass("ss-preview-hide");
      this.$overlay.find(".ss-preview-overlay-btn-group-delete").removeClass("ss-preview-hide");

      var select = this.$overlay.find(".ss-preview-overlay-btn-move-position");
      select.val($column.data("column-order"));
    } else {
      this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
      this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");
    }

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.showForPart = function($part) {
    var part = this.container.findPartById($part.data("part-id"));
    if (! part) {
      return;
    }

    var rect = $part[0].getBoundingClientRect();
    if (! rect) {
      return;
    }

    this.moveTo(rect);
    this.setInfo({ mode: "part", id: part.id, name: part.name });

    this.$overlay.find(".ss-preview-overlay-btn-group-move").addClass("ss-preview-hide");
    this.$overlay.find(".ss-preview-overlay-btn-group-delete").addClass("ss-preview-hide");

    this.$overlay.removeClass("ss-preview-hide");
  };

  Overlay.prototype.moveTo = function(rect) {
    var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    var scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
    var top = Math.floor(rect.top + scrollTop) - SS_Preview.overlayPadding;
    var left = Math.floor(rect.left + scrollLeft) - SS_Preview.overlayPadding;
    var width = rect.width + SS_Preview.overlayPadding * 2;
    var height = rect.height + SS_Preview.overlayPadding * 2;

    this.$overlay[0].style.top = top + "px";
    this.$overlay[0].style.left = left + "px";
    this.$overlay[0].style.width = width + "px";
    this.$overlay[0].style.height = height + "px";
  };

  Overlay.prototype.setInfo = function(info) {
    SS_Preview.setData(this.$overlay, "mode", info.mode);
    SS_Preview.setData(this.$overlay, "id", info.id);

    if (info.name) {
      this.$overlay.find(".ss-preview-overlay-name").text(info.name).removeClass("ss-preview-hide");
    } else {
      this.$overlay.find(".ss-preview-overlay-name").text("").addClass("ss-preview-hide");
    }
  };

  //
  // FormPalette
  //

  function FormPalette(container, $el) {
    this.container = container;
    this.$el = $el;

    var self = this;
    this.$el.on("load", function() {
      self.initializeFrame();
    });
  }

  FormPalette.margin = { height: 20 };

  FormPalette.createBefore = function(container, elBefore) {
    var formId = elBefore.dataset.formId;
    if (! formId) {
      return null;
    }
    var subType = elBefore.dataset.formSubType;
    if (subType !== "entry") {
      return null;
    }

    var $frame = $("<iframe />", {
      id: "ss-preview-form-palette", class: "ss-preview-hide", frameborder: "0", scrolling: "no",
      src: SS_Preview.inplaceFormPath.palette.replace(":id", formId)
    });

    $(elBefore).before($frame);

    return new FormPalette(container, $frame);
  };

  FormPalette.prototype.initializeFrame = function() {
    this.adjustHeight();

    var frame = this.$el[0];
    var self = this;
    frame.contentWindow.addEventListener("resize", function () {
      self.delayAdjustHeight();
    });
    frame.contentWindow.document.addEventListener("click", function (ev) {
      var el = ev.target;
      if (el.tagName === "BUTTON" && el.dataset.formId && el.dataset.columnId) {
        self.clickPalette(el);
        return;
      }

      var button = $(el).closest("button[data-form-id]")[0];
      if (button && button.dataset.formId && button.dataset.columnId) {
        self.clickPalette(button);
        return;
      }
    });
  };

  FormPalette.prototype.delayAdjustHeight = function() {
    if (this.timer > 0) {
      clearTimeout(this.timer);
    }

    var self = this;
    this.timer = setTimeout(function () { self.adjustHeight(); self.timer = 0; }, 100);
  };

  FormPalette.prototype.adjustHeight = function() {
    var frame = this.$el[0];
    if (! frame) {
      return;
    }

    var window = frame.contentWindow;
    if (!window) {
      return;
    }

    var document = window.document;
    if (!document) {
      return;
    }

    var body = document.body;
    if (!body) {
      return;
    }

    var height = body.scrollHeight + FormPalette.margin;
    frame.style.height = height + "px";
  };

  FormPalette.prototype.show = function() {
    this.$el.removeClass("ss-preview-hide");
    this.delayAdjustHeight();
  };

  FormPalette.prototype.hide = function() {
    this.$el.addClass("ss-preview-hide");
  };

  FormPalette.prototype.clickPalette = function(el) {
    var formId = el.dataset.formId;
    var columnId = el.dataset.columnId;
    if (!formId || !columnId) {
      return;
    }

    var url = SS_Preview.inplaceFormPath.columnValue.new.replace(":pageId", SS_Preview.item.pageId).replace(":columnId", columnId);
    this.container.openDialogInFrame(url);
  };

  //
  // Notice
  //

  function Notice(container) {
    this.container = container;
    this.$el = this.container.$el.find(".ss-preview-notice-wrap");
    this.timerId = null;
  }

  Notice.speed = "normal";
  Notice.holdInMillis = 1800;

  Notice.prototype.show = function(message) {
    this.hide();

    var self = this;
    this.$el.html(message).slideDown(Notice.speed, function() {
      self.noticeShown();
    });
  };

  Notice.prototype.hide = function() {
    if (this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = null;
    }

    this.$el.hide();
    this.$el.html("");
  };

  Notice.prototype.noticeShown = function() {
    var self = this;
    this.timerId = setTimeout(function () {
      self.$el.slideUp(Notice.speed);
      self.timerId = null;
    }, Notice.holdInMillis);
  };

  return SS_Preview;

})();
