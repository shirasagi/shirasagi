module Cms::Addon
  module ContentQuota
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :content_quota, type: Integer, default: nil
      permit_params :content_quota
    end

    def content_quota_model
      quota_bytes = content_quota.to_i * 1024 * 1024
      # return nil if quota_bytes <= 0

      usage_bytes = Cms::Page.site(site).where(filename: /^#{::Regexp.escape(filename)}\//).sum(:size)
      SS::Quota.new({ quota_bytes: quota_bytes, usage_bytes: usage_bytes })
    end

    def content_quota_label
      quota = content_quota_model
      if content_quota.present?
        percentage = ((quota.usage_bytes.to_f / quota.quota_bytes.to_f) * 100).floor
        "#{quota.usage_bytes.to_s(:human_size)}/#{quota.quota_bytes.to_s(:human_size)}(#{percentage}%)"
      else
        quota.usage_bytes.to_s(:human_size)
      end
    end
  end
end
