module SS::DownloadPolicy
  extend ActiveSupport::Concern

  class << self
    def download_policy
      default = SS.config.ss.download_policy
      return nil unless default
      return SS.current_site.download_policy || default if SS.current_site
      return SS.current_organization.download_policy || default if SS.current_organization
      return SS.current_user.organization.try(:download_policy) || default if SS.current_user
      return default
    end

    def download_policy_options
      default = SS.config.ss.download_policy
      values = [[I18n.t("ss.options.download_policy.default_#{default}"), nil]]
      values += %w(disallowed none).map { |v| [I18n.t("ss.options.download_policy.#{v}"), v] }
      values
    end

    def download_allowed?
      download_policy != 'disallowed'
    end

    def download_disallowed?
      download_policy == 'disallowed'
    end

    def html_class
      'download-disallowed' if download_disallowed?
    end
  end
end
