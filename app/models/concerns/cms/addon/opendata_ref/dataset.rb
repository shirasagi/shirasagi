module Cms::Addon::OpendataRef::Dataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :opendata_dataset_state, type: String, default: 'none'
    embeds_ids :opendata_datasets, class_name: "Opendata::Dataset", metadata: { on_copy: :clear }

    permit_params :opendata_dataset_state
    permit_params opendata_dataset_ids: []

    validates :opendata_dataset_state, inclusion: { in: %w(none public closed existance), allow_blank: true }

    after_generate_file { invoke_opendata_job(:create_or_update) }
    after_remove_file { invoke_opendata_job(:destroy) }
  end

  def opendata_dataset_state_options
    %w(none public closed existance).map do |v|
      [ I18n.t("cms.options.opendata_dataset.#{v}"), v ]
    end
  end

  def associate_with_opendata?
    opendata_dataset_state.present? && opendata_dataset_state != 'none'
  end

  private
    def invoke_opendata_job(action)
      return if opendata_dataset_state.blank?

      parent = self.parent
      return if parent.blank?

      parent = parent.becomes_with_route
      opendata_sites = parent.try(:opendata_sites)
      return if opendata_sites.blank?

      opendata_sites.each do |site|
        job = Opendata::CmsIntegration::AssocJob.bind(site_id: site)
        job.perform_later(self.site.id, parent.id, self.id, action.to_s)
      end
    end
end
