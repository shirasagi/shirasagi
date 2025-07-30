this.Event_Search = (function () {
  function Event_Search() {
  }

  Event_Search.render = function () {
    SS.justOnce(this, "event-search", function() {
      $("form.event-search .search_clear").on("click", function () {
        $(this).parents("form.event-search").each(function() {
          $(this).find("input.keyword").val("");
          $(this).find("input.prop").prop("checked", false);
          $(this).find("input.start").val("");
          $(this).find("input.close").val("");
          $(this).find("select.facility").val("");
          $(this).find("select.sort").val("");
        });
        return false;
      });
    });
  };

  return Event_Search;

})();
