class Gws::Elasticsearch::Setting::Workflow2
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Workflow2::File

  def menu_label
    cur_site.menu_workflow2_label.presence || I18n.t('modules.gws/workflow2')
  end

  def search_types
    search_types = []
    return search_types unless cur_site.menu_workflow2_visible?
    return search_types unless Gws.module_usable?(:workflow2, cur_site, cur_user)

    # super
    search_types << model.collection_name
    search_types
  end
end
