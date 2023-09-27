function Riken_LdapTest(el) {
  this.$el = $(el);
  this.$ldapTestResult = null;

  this.render();
}

Riken_LdapTest.render = function() {
  $(".btn-ldap-test").each(function() {
    new Riken_LdapTest(this);
  });
};

Riken_LdapTest.prototype.render = function() {
  var self = this;

  self.$el.on("click", function() {
    var $form = self.$el.closest("form");
    var data = new FormData($form[0]);
    data.delete("_method");

    var additionalParams = self.$el.data("params");
    if (additionalParams) {
      $.each(additionalParams, function (key, value) {
        data.append(key, value);
      })
    }

    self.ldapTestResult().html(SS.loading);

    $.ajax({
      method: 'POST',
      url: self.$el.data("url"),
      data: data,
      contentType: false,
      processData: false,
      cache: false,
      success: function(data) {
        self.showResult(data);
      },
      error: function(xhr, status, error) {
        self.showError(xhr, status, error);
      }
    });
  });
};

Riken_LdapTest.prototype.ldapTestResult = function(data) {
  if (this.$ldapTestResult) {
    return this.$ldapTestResult;
  }

  var $ldapTestResult = $("<div />", { class: "ldap-test-result" });
  this.$el.after($ldapTestResult);

  this.$ldapTestResult = $ldapTestResult;
  return $ldapTestResult;
};

Riken_LdapTest.prototype.showResult = function(data) {
  var $list = $("<div />");
  if (data.status === "ok") {
    data.results.forEach(function(result) {
      $list.append($("<div>").html(result))
    });
  } else {
    data.errors.forEach(function(error) {
      $list.append($("<div>").html(error))
    });
  }

  this.ldapTestResult().html($list);
};

Riken_LdapTest.prototype.showError = function(xhr, status, error) {
  this.ldapTestResult().html(error);
};
