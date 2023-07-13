class Gws::DailyReport::Form
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::DailyReport::ColumnSetting
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  readable_setting_include_custom_groups
  permission_include_custom_groups

  belongs_to :daily_report_group, class_name: 'Gws::Group'

  field :name, type: String
  field :year, type: Integer
  field :order, type: Integer
  field :memo, type: String

  permit_params :daily_report_group_id, :name, :year, :order, :memo

  validates :daily_report_group_id, presence: true, uniqueness: { scope: [:site_id, :year] }
  validates :name, presence: true, length: { maximum: 80 }
  validates :year, presence: true
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_year(params)
      criteria = criteria.search_group(params)
      criteria.search_keyword(params)
    end

    def search_year(params)
      return all if params[:year].blank?

      all.where(year: params[:year])
    end

    def search_group(params)
      return all if params[:group_id].blank?

      all.where(daily_report_group_id: params[:group_id])
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name)
    end
  end
end
