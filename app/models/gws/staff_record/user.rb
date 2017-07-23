class Gws::StaffRecord::User
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :code, type: String
  field :order, type: Integer, default: 0
  field :kana, type: String
  field :multi_section, type: String, default: 'regular'
  field :section_code, type: String
  field :section_name, type: String
  field :title_name, type: String
  field :tel_ext, type: String
  field :charge_name, type: String
  field :charge_tel, type: String
  field :charge_address, type: String
  field :divide_duties, type: String
  field :remark, type: String
  field :staff_records_view, type: String, default: 'show'
  field :divide_duties_view, type: String, default: 'show'

  permit_params :name, :code, :order, :kana, :multi_section, :section_code,
                :title_name, :tel_ext, :charge_name, :charge_tel, :charge_address,
                :divide_duties, :remark, :staff_records_view,  :divide_duties_view

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: [:site_id, :year] }
  validates :multi_section, inclusion: { in: %w(regular plural) }
  validates :staff_records_view, inclusion: { in: %w(show hide) }
  validates :divide_duties_view, inclusion: { in: %w(show hide) }

  before_validation :set_section_name, if: -> { section_code.present? }

  default_scope -> { order_by year: -1, order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :code, :year, :year_name if params[:keyword].present?
    criteria
  }

  def multi_section_options
    %w(regular plural).map { |v| [I18n.t("gws/staff_record.options.multi_section.#{v}"), v] }
  end

  def section_code_options
    Gws::StaffRecord::Group.site(@cur_site || site).
      map { |c| [c.name, c.code] }
  end

  def staff_records_view_options
    %w(show hide).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def divide_duties_view_options
    staff_records_view_options
  end

  private

  def set_section_name
    item = Gws::StaffRecord::Group.where(site_id: site_id, year: year, code: section_code).first
    self.section_name = item ? item.name : nil
  end
end
