module Cms::Addon::Opendata
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :opendata_state, type: String
    permit_params :opendata_state
    validates :opendata_state, inclusion: { in: %w(public closed), allow_blank: true }

    after_generate_file { invoke_opendata_job(:create_or_update) }
    before_destroy { invoke_opendata_job(:destroy) }
  end

  def opendata_state_options
    %w(public closed).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def opendata_state_public?
    self.opendata_state == 'public'
  end

  private
    def invoke_opendata_job(action)
      parent = self.parent
      return if parent.blank?

      parent = parent.becomes_with_route if parent.route != parent.class.name.sub('Node::', '').underscore
      opendata_sites = parent.try(:opendata_sites)
      return if opendata_sites.blank?

      opendata_sites.each do |site|
        Opendata::Cms::AssocJob.bind(site_id: site).perform_later(self.site.id, parent.id, self.id, action.to_s)
      end
    end
end
