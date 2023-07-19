this.Gws_Memo_Member = (function () {
  function Gws_Memo_Member(el) {
    this.$addon = $(el);
    this.$boxUsers = this.$addon.find(".box-users");
    this.$boxSharedAddresses = this.$addon.find(".box-shared-addresses");
    this.$boxPersonalAddresses = this.$addon.find(".box-personal-addresses");

    this.connect();
  }

  Gws_Memo_Member.prototype.connect = function() {
    if (this.$boxUsers[0]) {
      this.connectUsers();
    }
    if (this.$boxSharedAddresses[0]) {
      this.connectSharedAddresses();
    }
    if (this.$boxPersonalAddresses[0]) {
      this.connectPersonalAddresses();
    }
  };

  Gws_Memo_Member.prototype.connectUsers = function() {
    var self = this;

    self.$boxUsers.data("on-init", function($box) {
      self.initBox($box);
    });
    self.$boxUsers.data("on-select", function($item) {
      self.selectItem($item);
    });
  };

  Gws_Memo_Member.prototype.connectSharedAddresses = function() {
    var self = this;

    self.$boxSharedAddresses.data("on-init", function($box) {
      self.initBox($box);
    });
    self.$boxSharedAddresses.data("on-select", function($item) {
      self.selectItem($item);
    });
  };

  Gws_Memo_Member.prototype.connectPersonalAddresses = function() {
    var self = this;

    self.$boxPersonalAddresses.data("on-init", function($box) {
      self.initBox($box);
    });
    self.$boxPersonalAddresses.data("on-select", function($item) {
      self.selectItem($item);
    });
  };

  Gws_Memo_Member.prototype.initBox = function($box) {
    this.checkItem($box, "dl.to", "to_ids[]");
    this.checkItem($box, "dl.cc", "cc_ids[]");
    this.checkItem($box, "dl.bcc", "bcc_ids[]");
  };

  Gws_Memo_Member.prototype.checkItem = function($box, containerSelector, checkBoxName) {
    var self = this;

    var $container = self.$addon.find(containerSelector)
    $container.find("tr[data-id]").each(function () {
      var $this = $(this);
      var id = $this.data("id");

      $box.find(`[name="${checkBoxName}"][value="${id}"]`)
        .prop("checked", true)
        .prop("disabled", true);
    });
  };

  Gws_Memo_Member.prototype.selectItem = function($item) {
    var self = this;

    var $dataEl = $item.closest("[data-id]");
    if ($dataEl.find('[name="to_ids[]"]').prop('checked')) {
      self.insertItem($item, "dl.to");
    }
    if ($dataEl.find('[name="cc_ids[]"]').prop('checked')) {
      self.insertItem($item, "dl.cc");
    }
    if ($dataEl.find('[name="bcc_ids[]"]').prop('checked')) {
      self.insertItem($item, "dl.bcc");
    }
  };

  Gws_Memo_Member.prototype.insertItem = function($item, containerSelector) {
    var self = this;

    var $data = $item.closest("[data-id]");
    var data = $data[0].dataset;
    if (!data.name) {
      data.name = $data.find(".select-item").text() || $item.text() || $data.text();
    }

    var $container = self.$addon.find(containerSelector)
    var $ajaxSelected = $container.find(".ajax-selected");
    if ($ajaxSelected.find(`[data-id="${data.id}"]`)[0]) {
      return;
    }

    var template = SS_SearchUI.defaultTemplate;
    var $input = $container.find(".hidden-ids");
    var attr = { name: $input.attr("name"), type: $input.attr("type"), class: $input.attr("class").replace("hidden-ids", "") }
    var tr = ejs.render(template, { data: data, attr: attr, label: { delete: i18next.t("ss.buttons.delete") } });

    $ajaxSelected.find("tbody").prepend(tr);
    $ajaxSelected.trigger("change");
    $ajaxSelected.show();
  };

  return Gws_Memo_Member;
})();
