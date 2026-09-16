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
    $div.append($("<h2/>").text(Link_Checker.message.header()));

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
    $.each(links, function(link, msgHtml) {
      $ul.append($('<li/>').html(msgHtml));
    });

    this.$elBody.html("");
    this.$elBody.append($("<p/>").text(Link_Checker.message.checkLinks()));
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
    header: function() { return i18next.t('cms.link_check'); },
    noLinks: function() { return i18next.t('errors.template.no_links'); },
    checkLinks: function() { return i18next.t('errors.template.check_links'); },
    success: function() { return i18next.t('errors.messages.link_check_success'); },
    failure: function() { return i18next.t('errors.messages.link_check_failure'); },
    linkCheckerError: function() { return i18next.t('errors.messages.link_check_failed_to_connect'); }
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
        this.resultBox.showMessage("<p>" + Link_Checker.message.noLinks() + "</p>");
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
        var msg = Link_Checker.message.linkCheckerError() + ": " + Link_Checker.url;
        self.resultBox.showMessage($("<p/>").text(msg));
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

      this.resultBox.showMessage($("<p/>").text(msg));
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
          self.resultBox.showMessage($("<p/>").text(Link_Checker.message.noLinks()));
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
        var msg = Link_Checker.message.linkCheckerError() + ": " + self.form.form_link_check_path;
        self.resultBox.showMessage($("<p/>").text(msg));
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
      html += $('<span/>', { class: "success" }).text(Link_Checker.message.success()).prop("outerHTML") + ' ';
      html += $('<span/>', { class: "url" }).text(link).prop("outerHTML") + ' ';
    } else {
      html += $('<span/>', { class: "failure" }).text(Link_Checker.message.failure()).prop("outerHTML") + ' ';
      html += $('<span/>', { class: "url" }).text(link).prop("outerHTML") + ' ';
      this.linkErrorCount++;
    }

    if (message) {
      html += $('<div/>', { class: "message detail" }).text(message).prop("outerHTML");
    }

    this.links[link] = html;
  };

  return Link_Checker;

})();
