this.Backlink_Checker = (function () {
  function Backlink_Checker() {
  }

  Backlink_Checker.enabled = false;

  Backlink_Checker.url = null;

  Backlink_Checker.itemId = null;

  Backlink_Checker.asyncCheck = function(form, submit, opts) {
    var defer = $.Deferred();
    if (!Backlink_Checker.enabled || !Backlink_Checker.url || !Backlink_Checker.itemId) {
      defer.resolve();
      return defer.promise();
    }

    $.ajax({
      url: Backlink_Checker.url,
      method: "post",
      data: { item: { id: Backlink_Checker.itemId, submit: submit.name } },
      cache: false,
      success: function(data) {
        if (data["errors"] && data["errors"].length > 0) {
          Form_Alert.add(data["addon"], null, data["errors"]);
        }
      },
      error: function (_xhr, _status, _error) {
        Form_Alert.add("backlink_check", null, [ "Server Error" ]);
      },
      complete: function(_xhr, _status) {
        defer.resolve();
      }
    });

    return defer.promise();
  };

  return Backlink_Checker;
})();
