module Opendata::Addon::MyDatasetList
  extend SS::Addon
  extend ActiveSupport::Concern
  include Cms::Addon::PageList

  public
    def template_variable_get(item, name)
      if name.start_with?('dataset_')
        if name == 'dataset_name'
          ERB::Util.html_escape item.name
        elsif name == 'dataset_url'
          ERB::Util.html_escape "#{self.url}#{item.id}/"
        elsif name == 'dataset_updated'
          I18n.l item.updated, format: I18n.t("opendata.labels.updated")
        elsif name =~ /^dataset_updated\.(.+)$/
          I18n.l item.updated, format: $1
        elsif name == 'dataset_state'
          ERB::Util.html_escape(item.label :status)
        elsif name == 'dataset_point'
          ERB::Util.html_escape(item.point.to_i.to_s)
        elsif name == 'dataset_downloaded'
          ERB::Util.html_escape(item.downloaded.to_i.to_s)
        elsif name == 'dataset_apps_count'
          ERB::Util.html_escape(item.apps.size.to_s)
        elsif name == 'dataset_ideas_count'
          ERB::Util.html_escape(item.ideas.size.to_s)
        else
          false
        end
      else
        super
      end
    end
end
