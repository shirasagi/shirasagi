this.SS_TreeUI = (function () {
  SS_TreeUI.render = function (tree, opts) {
    return new SS_TreeUI(tree, opts);
  };

  SS_TreeUI.toggle = function (el) {
    if (el.hasClass("opened")) {
      SS_TreeUI.close(el)
    } else if (el.hasClass("closed")) {
      SS_TreeUI.open(el)
    }
  };

  SS_TreeUI.open = function (el) {
    el.addClass("opened");
    el.removeClass("closed");

    $(el).each(function(){
      this.dispatchEvent(new Event("change"));
    });
  };

  SS_TreeUI.close = function (el) {
    el.removeClass("opened");
    el.addClass("closed");

    $(el).each(function(){
      this.dispatchEvent(new Event("change"));
    });
  };

  SS_TreeUI.openSelectedGroupsTree = function (current_tr) {
    current_tr.addClass("current");
    for (i = 0; i < parseInt(current_tr.attr("data-depth")); i++) {
      var tr = current_tr.prevAll('tr[data-depth=' + i.toString() + ']:first');
      var el = tr.find("a.toggle:first");
      tr.nextAll("tr").each(function () {
        var subordinated_depth = parseInt($(this).attr("data-depth"));
        if (i >= subordinated_depth) {
          return false;
        }
        if ((i + 1) === subordinated_depth) {
          $(this).show();
        }
      });
      SS_TreeUI.open(el);
    }
  }

  function SS_TreeUI(tree, opts) {
    if (opts == null) {
      opts = {}
    }

    var self = this;
    self.tree = $(tree);

    var root = [];
    var expand_all = opts["expand_all"];
    var collapse_all = opts["collapse_all"];
    var expand_group = opts["expand_group"];

    self.tree.find("tbody tr").each(function () {
      root.push(parseInt($(this).attr("data-depth")));
    });
    root = Math.min.apply(null, root);
    root = parseInt(root);
    if (isNaN(root) || root < 0) {
      return;
    }
    self.tree.find("tbody tr").each(function () {
      var d, depth, i, j, ref, ref1, td, name, $toggle;
      td = $(this).find(".expandable");
      depth = parseInt($(this).attr("data-depth"));
      name = $(this).attr("data-name");
      $toggle = $('<a class="toggle closed" href="#" data-controller="ss--set-aria-label"></a>')
      if (name) {
        $toggle.attr("data-name", name);
      }

      td.prepend($toggle);
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
    self.tree.find(".toggle").on("mousedown mouseup", function (e) {
      return false;
    });

    self.tree.find(".toggle").on("click", function (e) {
      var depth, el, tr;
      tr = $(this).closest("tr");
      el = tr.find("a.toggle:first");
      depth = parseInt(tr.attr("data-depth"));
      SS_TreeUI.toggle(el);
      tr.nextAll("tr").each(function () {
        var d, i;
        d = parseInt($(this).attr("data-depth"));
        i = $(this).find(".toggle:first");
        if (depth >= d) {
          return false;
        }
        if ((depth + 1) === d) {
          $(this).toggle();
          SS_TreeUI.close(i);
        } else {
          $(this).hide();
          SS_TreeUI.close(i);
        }
      });
      return false;
    });
    if (opts.descendants_check) {
      self.tree.on("click", "[type='checkbox']", function (_ev) {
        self.checkAllChildren(this, this.checked);
      });
    }
    if (expand_all) {
      SS_TreeUI.open(self.tree.find("tbody tr a.toggle"));
    } else if (collapse_all) {
      SS_TreeUI.close(self.tree.find("tbody tr a.toggle"));
    } else if (expand_group && $("tbody tr.current").attr("data-depth") !== "0") {
      SS_TreeUI.openSelectedGroupsTree(self.tree.find("tbody tr[data-id='" + expand_group + "']"));
    } else {
      self.tree.find("tr[data-depth='" + root + "'] a.toggle").trigger("click");
    }
  }

  SS_TreeUI.prototype.expandAll = function () {
    this.tree.find("tr a.toggle.closed").trigger("click");
  };

  SS_TreeUI.prototype.collapseAll = function () {
    $(this.tree.find("tr a.toggle.opened").get().reverse()).each(function () {
      $(this).trigger("click");
    });
  };

  SS_TreeUI.prototype.checkAllChildren = function (checkboxEl, checked) {
    var $checkboxEl = $(checkboxEl);
    var $tr = $checkboxEl.closest("[data-depth]");
    var depth = $tr.data("depth");
    if (!Number.isInteger(depth)) {
      return;
    }

    var breakLoop = false;
    $tr.nextAll("[data-depth]").each(function() {
      if (breakLoop) {
        return;
      }

      var $nextEl = $(this);
      if ($nextEl.data("depth") <= depth) {
        breakLoop = true;
        return;
      }

      $nextEl.find("[type='checkbox']").prop("checked", checked);
    });
  };

  return SS_TreeUI;

})();
