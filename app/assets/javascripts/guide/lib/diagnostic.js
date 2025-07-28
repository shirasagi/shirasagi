this.Guide_Diagnostic = (function() {
  function Guide_Diagnostic(el) {
    this.$el = $(el);
    this.loadData();
    this.render();
  }

  Guide_Diagnostic.prototype.loadData = function() {
    var dataStr = this.$el.find(".guide-diagnostic-data").text();
    this.data = JSON.parse(dataStr);
  }

  Guide_Diagnostic.prototype.render = function() {
    var self = this;
    var $chart = this.$el.find(".guide-diagnostic-chart");

    $chart.on("click", ".node", function(ev) {
      var props = self.data[ev.currentTarget.id];
      if (props && props.url) {
        window.open(props.url, '_blank').focus();
      }
    });
    $chart.on("click", ".edgeLabel", function(ev) {
      var props = self.data[ev.currentTarget.id];
      if (props && props.url) {
        window.open(props.url, '_blank').focus();
      }
    });
  }

  return Guide_Diagnostic;
})();
