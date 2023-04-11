# not used
class Gws::Elasticsearch::Setting::Workload
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Workload::Work

  def menu_label
    cur_site.menu_workload_label.presence || I18n.t('modules.gws/workload')
  end

  def search_types
    return [] unless cur_site.menu_workload_visible?
    return [] unless Gws.module_usable?(:worload, cur_site, cur_user)

    [ model.collection_name ]
  end

  def and_public(_date = nil)
    query0 = { term: { 'state' => 'public' } }
    [ query0 ]
  end
end
