module Opendata::Addon::MyIdeaList
  extend SS::Addon
  extend ActiveSupport::Concern
  include Cms::Addon::PageList

  public
  def template_variable_get(item, name)
    if name.start_with?('idea_')
      if name == 'idea_name'
        ERB::Util.html_escape item.name
      elsif name == 'idea_url'
        ERB::Util.html_escape "#{self.url}#{item.id}/"
      elsif name == 'idea_updated'
        I18n.l item.updated, format: I18n.t("opendata.labels.updated")
      elsif name =~ /^idea_updated\.(.+)$/
        I18n.l item.updated, format: $1
      elsif name == 'idea_state'
        ERB::Util.html_escape(item.label :state)
      elsif name == 'idea_point'
        ERB::Util.html_escape(item.point.to_i.to_s)
      elsif name == 'idea_datasets'
        if item.dataset_ids.length > 0
          ERB::Util.html_escape(item.datasets[0].name)
        else
          ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
        end
      elsif name == 'idea_apps'
        if item.app_ids.length > 0
          ERB::Util.html_escape(item.apps[0].name)
        else
          ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
        end
      elsif name == 'idea_ideas_count'
        ERB::Util.html_escape(item.ideas.size.to_s)
      else
        false
      end
    else
      super
    end
  end
end
