function Gws_Schedule_Csv(el) {
  this.$el = $(el);
  this.$importMode = this.$el.find('#import_mode');
  this.$importLog = this.$el.find('.import-log');
}

Gws_Schedule_Csv.render = function (el) {
  var instance = new Gws_Schedule_Csv(el);
  instance.render();
  return instance;
};

Gws_Schedule_Csv.prototype.render = function () {
  var self = this;
  this.$el.find('.import-confirm').on("click", function(){
    self.$importMode.val('confirm');
  });
  this.$el.find('.import-save').on("click", function(){
    self.$importMode.val('save');
  });
  this.$el.find('#import_form').ajaxForm({
    beforeSubmit: function() {
      self.$importLog.html($('<span />', { class: "import-loading" }).text(i18next.t("ss.notice.uploading")));
      SS_AddonTabs.show('#import-result');
    },
    success: function(data, status) {
      self.renderResult(data);
    },
    error: function(xhr, status, error) {
      self.renderError(xhr, status, error);
    }
  });
//  this.$el.find('.download-csv-template').on("click", function() {
//    setTimeout(function() { self.showCsvDescription(); }, 0);
//    return true;
//  });
  this.$el.find('.show-csv-description').on("click", function() {
    self.showCsvDescription();
  });
}

Gws_Schedule_Csv.prototype.renderResult = function(data) {
  var log = this.$importLog;
  log.html('')

  if (data.messages) {
    log.append('<div class="mb-1">' + data.messages.join('<br />') + '</div>');
  }
  if (data.items) {
    var count = { exist: 0, entry: 0, saved: 0, error: 0 };
    var template = '\
      <table class="index mt-1"><thead><tr> \
        <th style="width: 150px"><%= start_at %></th> \
        <th style="width: 150px"><%= end_at %></th> \
        <th style="width: 30%"><%= name %></th> \
        <th><%= result %></th> \
      </tr></thead><tbody>';
    var html = ejs.render(
      template,
      {
        start_at: i18next.t("mongoid.attributes.gws/schedule/planable.start_at"),
        end_at: i18next.t("mongoid.attributes.gws/schedule/planable.end_at"),
        name: i18next.t("mongoid.attributes.gws/schedule/planable.name"),
        result: i18next.t('gws/schedule.import.result')
      });

    $.each(data.items, function(i, item){
      if (item.result == 'exist') count.exist += 1;
      if (item.result == 'entry') count.entry += 1;
      if (item.result == 'saved') count.saved += 1;
      if (item.result == 'error') count.error += 1;

      html += '<tr class="import-' + item.result + '">' +
        '<td>' + SS.formatTime(item.start_at) + '</td>' +
        '<td>' + SS.formatTime(item.end_at) + '</td>' +
        '<td>' + item.name + '</td>' +
        '<td>' + item.messages.join('<br />') + '</td>' +
        '</tr>'
    });
    html += '</tbody></table>';

    var tabs = '<div class="mb-1">';
    if (count.exist) tabs += ejs.render('<span class="ml-2 import-exist"><%= text %>(<%= count.exist %>)</span>', { text: i18next.t('gws/schedule.import.exist'), count: count });
    if (count.entry) tabs += ejs.render('<span class="ml-2 import-entry"><%= text %>(<%= count.entry %>)</span>', { text: i18next.t('gws/schedule.import.entry'), count: count });
    if (count.saved) tabs += ejs.render('<span class="ml-2 import-saved"><%= text %>(<%= count.saved %>)</span>', { text: i18next.t('gws/schedule.import.saved'), count: count });
    if (count.error) tabs += ejs.render('<span class="ml-2 import-error"><%= text %>(<%= count.error %>)</span>', { text: i18next.t('gws/schedule.import.error'), count: count });
    tabs += '</div>'

    log.append(tabs + html);
  }
}

Gws_Schedule_Csv.prototype.renderError = function(xhr, status, error) {
  try {
    var errors = xhr.responseJSON;
    var msg = errors.join("\n");
    this.$importLog.html(msg);
  } catch (ex) {
    this.$importLog.html("Error: " + error);
  }
};

Gws_Schedule_Csv.prototype.showCsvDescription = function() {
  var href = this.$el.find('.show-csv-description').attr("href");
  $.colorbox({
    inline: true, href: href, width: "90%", height: "90%", fixed: true, open: true
  });
};
