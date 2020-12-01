class Gws::Elasticsearch::Setting::Report
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Report::File

  def menu_label
    cur_site.menu_report_label.presence || I18n.t('modules.gws/report')
  end

  def search_types
    return [] unless cur_site.menu_report_visible?
    return [] unless Gws.module_usable?(:report, cur_site, cur_user)

    [ model.collection_name ]
  end
end
