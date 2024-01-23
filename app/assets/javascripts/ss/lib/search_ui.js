this.SS_SearchUI = (function () {
  function SS_SearchUI() {
  }

  var selectTable = null;
  let toSelected = [], ccSelected = [], bcSelected = [];

  SS_SearchUI.anchorAjaxBox;

  SS_SearchUI.defaultTemplate = " \
    <tr data-id=\"<%= data.id %>\"> \
      <td> \
        <input type=\"<%= attr.type %>\" name=\"<%= attr.name %>\" value=\"<%= data.id %>\" class=\"<%= attr.class %>\"> \
        <%= data.name %> \
      </td> \
      <td><a class=\"deselect btn\" href=\"#\"><%= label.delete %></a></td> \
    </tr>";

  SS_SearchUI.defaultSelector = function ($item, $prevSelected) {
    var self = this;

    var templateId = self.anchorAjaxBox.data("template");
    var templateEl = templateId ? document.getElementById(templateId) : null;
    var template, attr;
    if (templateEl) {
      template = templateEl.innerHTML;
      attr = {};
    } else {
      template = SS_SearchUI.defaultTemplate;

      var $input = self.anchorAjaxBox.closest("dl").find(".hidden-ids");
      if (selectTable === "to") {
        attr = {
          name: "item[in_to_members][]",
          type: $input.attr("type"),
          class: $input.attr("class").replace("hidden-ids", "")
        }
      } else if (selectTable === "cc") {
        attr = {
          name: "item[in_cc_members][]",
          type: $input.attr("type"),
          class: $input.attr("class").replace("hidden-ids", "")
        }
      } else if (selectTable === "bcc") {
        attr = {
          name: "item[in_bcc_members][]",
          type: $input.attr("type"),
          class: $input.attr("class").replace("hidden-ids", "")
        }
      } else {
        attr = {
          name: $input.attr("name"),
          type: $input.attr("type"),
          class: $input.attr("class").replace("hidden-ids", "")
        }
      }
    }

    var $data = $item.closest("[data-id]");
    var data = $data[0].dataset;
    if (!data.name) {
      data.name = $data.find(".select-item").text() || $item.text() || $data.text();
    }

    var tr = ejs.render(template, {data: data, attr: attr, label: {delete: i18next.t("ss.buttons.delete")}});
    var $tr = $(tr);
    var $ajaxSelected;
    if (selectTable === "to") {
      $ajaxSelected = self.anchorAjaxBox.closest("body").find(".see.to .ajax-selected");
    } else if (selectTable === "cc") {
      $ajaxSelected = self.anchorAjaxBox.closest("body").find(".see.cc-bcc.cc .ajax-selected");
    } else if (selectTable === "bcc") {
      $ajaxSelected = self.anchorAjaxBox.closest("body").find(".see.cc-bcc.bcc .ajax-selected");
    } else {
      $ajaxSelected = self.anchorAjaxBox.closest("dl").find(".ajax-selected");
    }

    if ($prevSelected) {
      $prevSelected.after($tr);
    } else {
      $ajaxSelected.find("tbody").prepend($tr);
    }
    $ajaxSelected.trigger("change");
    return $tr;
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

  SS_SearchUI.select = function (item, prevSelected) {
    var self = this;
    var selector = self.anchorAjaxBox.data('on-select');
    if (selector) {
      return selector(item);
    } else {
      if (!selectTable) {
        if (item.closest("[data-id]").find(".to-checkbox")[0]) {
          selectTable = "to";
        }
      }
      var result = this.defaultSelector(item, prevSelected);
      if (selectTable === "to") {
        self.anchorAjaxBox.closest("body").find(".see.to .ajax-selected").show();
      }
      return result;
    }
  };

  SS_SearchUI.selectItems = function ($el) {
    if (!$el) {
      $el = $("#ajax-box");
    }
    var self = this;
    var $prevSelected = undefined;
    $el.find(".items .to-checkbox input:checkbox").filter(":checked").each(function () {
      selectTable = "to";
      // 複数項目が選択された場合、最初の項目を先頭に挿入し、2個目以降の選択をその次に挿入する。
      $prevSelected = self.select($(this), $prevSelected);
    });
    if (selectTable === "to") {
      self.anchorAjaxBox.closest("body").find(".see.to .ajax-selected").show();
    }

    $prevSelected = undefined;
    $el.find(".items .cc-checkbox input:checkbox").filter(":checked").each(function () {
      selectTable = "cc";
      // 複数項目が選択された場合、最初の項目を先頭に挿入し、2個目以降の選択をその次に挿入する。
      $prevSelected = self.select($(this), $prevSelected);
    });
    if (selectTable === "cc") {
      self.anchorAjaxBox.closest("body").find(".see.cc-bcc.cc .ajax-selected").show();
    }

    $prevSelected = undefined;
    $el.find(".items .bcc-checkbox input:checkbox").filter(":checked").each(function () {
      selectTable = "bcc";
      // 複数項目が選択された場合、最初の項目を先頭に挿入し、2個目以降の選択をその次に挿入する。
      $prevSelected = self.select($(this), $prevSelected);
    });
    if (selectTable === "bcc") {
      self.anchorAjaxBox.closest("body").find(".see.cc-bcc.bcc .ajax-selected").show();
    }
    if (selectTable === null) {
      $prevSelected = undefined;
      $el.find(".items input:checkbox").filter(":checked").each(function () {
        // 複数項目が選択された場合、最初の項目を先頭に挿入し、2個目以降の選択をその次に挿入する。
        $prevSelected = self.select($(this), $prevSelected);
      });
      self.anchorAjaxBox.closest("dl").find(".ajax-selected").show();
    }
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
    if (!$el) {
      $el = $("#ajax-box");
    }

    if ($el.find(".items input:checkbox").filter(":checked").size() > 0) {
      return $el.find(".select-items").parent("div").show();
    } else {
      return $el.find(".select-items").parent("div").hide();
    }
  };

  SS_SearchUI.onceRendered = false;

  SS_SearchUI.renderOnce = function() {
    if (SS_SearchUI.onceRendered) {
      return;
    }

    $(document)
      .on("cbox_load", SS_SearchUI.onColorBoxLoaded)
      .on("cbox_cleanup", SS_SearchUI.onColorBoxCleanedUp);
    SS_SearchUI.onceRendered = true;
  };

  SS_SearchUI.render = function (box) {
    SS_SearchUI.renderOnce();

    $(box || document).find(".ajax-selected").each(function () {
      var $this = $(this);
      SS.justOnce(this, "searchUI", function() {
        $this.on("click", "a.deselect", SS_SearchUI.deselect);
        if ($this.find("a.deselect").size() === 0) {
          $this.hide();
        }
      });
    });
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
    selectTable = null;
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
        var $div = $("<span />", {class: "loading"}).html(SS.loading);
        $el.find("[type=submit]").after($div);

        $(this).ajaxSubmit({
          url: $(this).attr("action"),
          success: function (data) {
            var $data = $("<div />").html(data);
            $.colorbox.prep($data.contents());
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

    var $ajaxSelected = self.anchorAjaxBox.closest("dl").find(".ajax-selected");
    var $toAjaxSelected = self.anchorAjaxBox.closest("body").find(".see.to .ajax-selected");
    var $ccAjaxSelected = self.anchorAjaxBox.closest("body").find(".see.cc-bcc.cc .ajax-selected");
    var $bcAjaxSelected = self.anchorAjaxBox.closest("body").find(".see.cc-bcc.bcc .ajax-selected");
    if (!$ajaxSelected.length) {
      $ajaxSelected = self.anchorAjaxBox.parent().find(".ajax-selected");
    }
    if (!$toAjaxSelected.length) {
      $toAjaxSelected = self.anchorAjaxBox.parent().find(".ajax-selected");
    }
    if (!$ccAjaxSelected.length) {
      $ccAjaxSelected = self.anchorAjaxBox.parent().find(".ajax-selected");
    }
    if (!$bcAjaxSelected.length) {
      $bcAjaxSelected = self.anchorAjaxBox.parent().find("see.cc-bcc.bcc .ajax-selected");
    }
    $toAjaxSelected.find("tr[data-id]").each(function () {
      var id = $(this).data("id");
      toSelected.push($("#colorbox .items [data-id='" + id + "']"));
    });
    $ccAjaxSelected.find("tr[data-id]").each(function () {
      var id = $(this).data("id");
      ccSelected.push($("#colorbox .items [data-id='" + id + "']"));
    });
    $bcAjaxSelected.find("tr[data-id]").each(function () {
      var id = $(this).data("id");
      bcSelected.push($("#colorbox .items [data-id='" + id + "']"));
    });
    $ajaxSelected.find("tr[data-id]").each(function () {
      var id = $(this).data("id");
      var tr = $("#colorbox .items [data-id='" + id + "']");
      var i;
      for (i = 0; i < toSelected.length; i++) {
        toSelected[i].find(".to-checkbox input[type=checkbox]").remove();
      }
      for (i = 0; i < ccSelected.length; i++) {
        ccSelected[i].find(".cc-checkbox input[type=checkbox]").remove();
      }
      for (i = 0; i < bcSelected.length; i++) {
        bcSelected[i].find(".bcc-checkbox input[type=checkbox]").remove();
      }
      tr.find(".checkbox input[type=checkbox]").remove();
      tr.find(".select-item,.select-single-item").each(function () {
        var $this = $(this);
        var html = $this.html();

        var disabledHtml = $("<span />", {class: $this.prop("class"), style: 'color: #888'}).html(html);
        $this.replaceWith(disabledHtml);
      });
    });
    self.anchorAjaxBox.closest("body").find("tr[data-id]").each(function () {
      var i;
      for (i = 0; i < toSelected.length; i++) {
        toSelected[i].find(".to-checkbox input[type=checkbox]").remove();
      }
      for (i = 0; i < ccSelected.length; i++) {
        ccSelected[i].find(".cc-checkbox input[type=checkbox]").remove();
      }
      for (i = 0; i < bcSelected.length; i++) {
        bcSelected[i].find(".bcc-checkbox input[type=checkbox]").remove();
      }
    });
    $el.find("table.index").each(function () {
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
