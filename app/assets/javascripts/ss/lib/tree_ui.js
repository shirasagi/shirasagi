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

    var self = this;
    self.tree = $(tree);

    var root = [];
    var expand_all = opts["expand_all"];
    var collapse_all = opts["collapse_all"];
    var expand_group = opts["expand_group"];

    self.tree.find("tbody tr").each(function () {
      return root.push(parseInt($(this).attr("data-depth")));
    });
    root = Math.min.apply(null, root);
    root = parseInt(root);
    if (isNaN(root) || root < 0) {
      return;
    }
    self.tree.find("tbody tr").each(function () {
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
    self.tree.find(".toggle").on("mousedown mouseup", function (e) {
      e.stopPropagation();
      return false;
    });
    self.tree.find(".toggle").on("click", function (e) {
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
    if (opts.descendants_check) {
      self.tree.on("click", "[type='checkbox']", function (ev) {
        self.checkAllChildren(this, this.checked);
      });
    }
    if (expand_all) {
      SS_TreeUI.openImage(self.tree.find("tbody tr img"));
    } else if (collapse_all) {
      SS_TreeUI.closeImage(self.tree.find("tbody tr img"));
    } else if (expand_group && $("tbody tr.current").attr("data-depth") !== "0") {
      SS_TreeUI.openSelectedGroupsTree(self.tree.find("tbody tr.current"));
    } else {
      self.tree.find("tr[data-depth='" + root + "'] img").trigger("click");
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

// ---
// generated by coffee-script 1.9.2