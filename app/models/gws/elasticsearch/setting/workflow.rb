class Gws::Elasticsearch::Setting::Workflow
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Workflow::File

  def menu_label
    @cur_site.menu_workflow_label || I18n.t('modules.gws/workflow')
  end

  def search_types
    search_types = []
    return search_types unless cur_site.menu_workflow_visible?

    search_types << Gws::Workflow::File.collection_name if allowed?(:read)
    search_types
  end
end
