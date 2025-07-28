class Gws::Elasticsearch::Setting::WorkflowForm
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Workflow::Form

  def menu_label
    workflow_label = cur_site.menu_workflow_label.presence || I18n.t('modules.gws/workflow')
    "#{workflow_label}/#{I18n.t('mongoid.models.gws/workflow/form')}"
  end

  def search_types
    search_types = []
    return search_types unless cur_site.menu_workflow_visible?
    return search_types unless Gws.module_usable?(:workflow, cur_site, cur_user)

    search_types << Gws::Workflow::Form.collection_name if allowed?(:read)

    search_types
  end

  def readable_filter
    {}
  end
end
