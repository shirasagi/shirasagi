module Cms::Addon
  module ReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :release_date, type: DateTime
      field :close_date, type: DateTime

      permit_params :release_date, :close_date

      validates :release_date, datetime: true
      validates :close_date, datetime: true
      validate :validate_release_date
      validate :validate_release_state
    end

    def validate_release_date
      self.released ||= release_date if respond_to?(:released)

      if close_date.present? && release_date.present? && release_date >= close_date
        errors.add :close_date, :greater_than, count: t(:release_date)
      end
    end

    def validate_release_state
      return if errors.present?

      if try(:state) == "public"
        self.state = "ready" if release_date && release_date > Time.zone.now
        self.state = "closed" if close_date && close_date <= Time.zone.now
      end
    end

    def default_release_plan_enabled?
      parent = self.try(:parent)
      parent = parent.becomes_with_route if parent.present?
      return true if parent.try(:default_release_plan_enabled?)

      site = self.try(:site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return true if site.try(:default_release_plan_enabled?)

      site = self.try(:cur_site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return true if site.try(:default_release_plan_enabled?)

      false
    end

    def default_release_date(now = Time.zone.now)
      parent = self.try(:parent)
      parent = parent.becomes_with_route if parent.present?
      return (now.to_date + parent.default_release_date_delay.days).to_time if parent.try(:default_release_plan_enabled?)

      site = self.try(:site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return (now.to_date + site.default_release_date_delay.days).to_time if site.try(:default_release_plan_enabled?)

      site = self.try(:cur_site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return (now.to_date + site.default_release_date_delay.days).to_time if site.try(:default_release_plan_enabled?)
    end

    def default_close_date(now = Time.zone.now)
      parent = self.try(:parent)
      parent = parent.becomes_with_route if parent.present?
      return (now.to_date + parent.default_close_date_delay.days).to_time if parent.try(:default_release_plan_enabled?)

      site = self.try(:site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return (now.to_date + site.default_close_date_delay.days).to_time if site.try(:default_release_plan_enabled?)

      site = self.try(:cur_site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return (now.to_date + site.default_close_date_delay.days).to_time if site.try(:default_release_plan_enabled?)
    end
  end
end
