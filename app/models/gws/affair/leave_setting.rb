class Gws::Affair::LeaveSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Affair::CapitalYearly
  include Gws::Addon::Affair::AnnualLeaveSetting
  include Gws::Addon::Affair::PaidLeaveSetting
  include Gws::Addon::Import::Affair::LeaveSetting
  include Gws::SitePermission

  set_permission_name 'gws_affair_capital_years', :edit

  seqid :id
  field :name, type: String
  belongs_to :target_user, class_name: 'Gws::User'

  permit_params :target_user_id
  permit_params :start_at
  permit_params :end_at

  validates :target_user_id, presence: true
  validate :validate_year

  before_save :set_name

  default_scope -> { order_by(start_at: -1) }

  def start_at
    year.start_date
  end

  def end_at
    year.close_date
  end

  def leave_files(opts = {})
    leave_start_at = start_at
    leave_end_at = end_at

    month = opts[:month]
    if month.present?
      leave_start_at = month.in_time_zone.change(day: 1, hour: 0, min: 0, sec: 0)
      leave_end_at = leave_start_at.end_of_month
    end
    leave_files = Gws::Affair::LeaveFile.and([
      { site_id: site_id },
      { target_user_id: target_user_id },
      { state: "approve" },
      { "end_at" => { "$gte" => leave_start_at } },
      { "start_at" => { "$lte" => leave_end_at } }
    ])

    types = opts[:types].presence || %w(annual_leave paidleave)
    if types.present?
      leave_files = leave_files.and([
        { leave_type: { "$in" => types } }
      ])
    end

    leave_files = leave_files.reorder(start_at: 1).to_a
    leave_files.each do |file|
      file.leave_dates_in_query = file.leave_dates.select do |leave_date|
        leave_date.date >= leave_start_at && leave_date.date <= leave_end_at
      end
      file.leave_minutes_in_query = file.leave_dates.map(&:minute).sum
    end
    leave_files
  end

  private

  def set_name
    self.name = "#{target_user.name}の休暇設定（#{year.name}）"
  end

  def validate_year
    return if year.blank?
    return if target_user.blank?

    item = self.class.where(
      :id.ne => id,
      target_user_id: target_user_id,
      year_id: year_id
    ).first

    if item
      errors.add :base, :exists_setting, name: target_user.name, term: item.year.name
    end
  end

  class << self
    def and_date(site, user, date)
      year = ::Gws::Affair::CapitalYear.and_date(site, date).first
      return self.none unless year
      self.site(site).where(year_id: year.id, target_user_id: user.id)
    end

    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end
end
