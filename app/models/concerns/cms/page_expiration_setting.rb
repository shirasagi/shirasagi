module Cms::PageExpirationSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :expiration_setting_type, type: String, default: "site"

    validates :expiration_setting_type, inclusion: { in: %w(site never), allow_blank: true }
  end

  module ClassMethods
    def search_expiration_setting_type(params)
      return all if params.blank? || params[:expiration_setting_type].blank?

      case params[:expiration_setting_type]
      when "site"
        conditions = [
          { expiration_setting_type: "site" },
          { expiration_setting_type: nil }
        ]
        all.where("$and" => [{ "$or" => conditions }])
      else # never
        all.where(expiration_setting_type: "never")
      end
    end

    def search_updated_before(params)
      return all if params.blank? || params[:updated_before].blank?

      updated_before = SS::Duration.parse(params[:updated_before])
      all.where(updated: { "$lte" => Time.zone.now - updated_before })
    end
  end

  def expiration_setting_type_options
    %w(site never).map do |v|
      [ I18n.t("cms.options.expiration_setting_type.#{v}"), v ]
    end
  end

  def page_expiration_site?
    !page_expiration_never?
  end

  def page_expiration_never?
    expiration_setting_type == "never"
  end
end
