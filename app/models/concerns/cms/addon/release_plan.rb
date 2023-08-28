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
      if release_date.present? && release_date_changed? && release_date <= Time.zone.now
        errors.add :release_date, :greater_than, count: I18n.l(Time.zone.now)
      end
      if close_date.present? && close_date_changed? && close_date <= Time.zone.now
        errors.add :close_date, :greater_than, count: I18n.l(Time.zone.now)
      end
    end

    def validate_release_state
      return if errors.present?

      if try(:state) == "public"
        now = Time.zone.now
        self.state = "ready" if release_date && release_date > now
        # 差し替えページのマージ処理は state == "public" の場合に動作する
        # 「公開終了日時(予約)」が過去日に設定された差し替えページを公開保存した場合、
        # 適切にマージ処理を実行させるため、差し替えページの場合 state を変更しないようにする。
        self.state = "closed" if close_date && close_date <= now && !try(:branch?)
      end
    end

    def default_release_plan_enabled?
      parent = self.try(:parent)
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
      return calc_beginning_of_day(now, parent.default_release_days_after) if parent.try(:default_release_plan_enabled?)
      return calc_beginning_of_day(now, parent.default_release_days_after) if parent.try(:default_release_plan_enabled?)

      site = self.try(:site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return calc_beginning_of_day(now, site.default_release_days_after) if site.try(:default_release_plan_enabled?)

      site = self.try(:cur_site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return calc_beginning_of_day(now, site.default_release_days_after) if site.try(:default_release_plan_enabled?)
    end

    def default_close_date(now = Time.zone.now)
      parent = self.try(:parent)
      return calc_beginning_of_day(now, parent.default_close_days_after) if parent.try(:default_release_plan_enabled?)

      site = self.try(:site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return calc_beginning_of_day(now, site.default_close_days_after) if site.try(:default_release_plan_enabled?)

      site = self.try(:cur_site)
      site = Cms::Site.find(site.id) if site.present? && !site.is_a?(Cms::Site)
      return calc_beginning_of_day(now, site.default_close_days_after) if site.try(:default_release_plan_enabled?)
    end

    def expired_close_date?
      close_date && close_date <= Time.zone.now
    end

    private

    def calc_beginning_of_day(now, days)
      ret = now + days.days
      ret = ret.beginning_of_day
      return ret
    end
  end
end
