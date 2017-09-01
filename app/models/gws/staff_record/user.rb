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
  field :section_name, type: String
  field :section_order, type: Integer
  field :title_name, type: String
  field :tel_ext, type: String
  field :charge_name, type: String
  field :charge_address, type: String
  field :charge_tel, type: String
  field :divide_duties, type: String
  field :remark, type: String
  field :staff_records_view, type: String, default: 'show'
  field :divide_duties_view, type: String, default: 'show'

  permit_params :name, :code, :order, :kana, :multi_section, :section_name,
                :title_name, :tel_ext, :charge_name, :charge_address, :charge_tel,
                :divide_duties, :remark, :staff_records_view,  :divide_duties_view

  validates :name, presence: true
  validates :code, presence: true#, uniqueness: { scope: [:site_id, :year] }
  validates :multi_section, inclusion: { in: %w(regular plural) }
  validates :section_name, presence: true
  validates :staff_records_view, inclusion: { in: %w(show hide) }
  validates :divide_duties_view, inclusion: { in: %w(show hide) }

  before_validation :set_section_order, if: -> { section_name.present? }

  default_scope -> { order_by section_order: 1, section_name: 1, order: 1 }

  scope :show_staff_records, -> {
    where staff_records_view: 'show'
  }
  scope :show_divide_duties, -> {
    where divide_duties_view: 'show'
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.where(section_name: params[:section_name]) if params[:section_name].present?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :code, :kana,
        :section_name, :title_name, :charge_name, :charge_address, :charge_tel,
        :tel_ext, :divide_duties, :remark
    end
    criteria
  }

  def multi_section_options
    %w(regular plural).map { |v| [I18n.t("gws/staff_record.options.multi_section.#{v}"), v] }
  end

  def section_name_options
    Gws::StaffRecord::Group.site(@cur_site || site).where(year_id: year_id).
      map { |c| [c.name, c.name] }
  end

  def staff_records_view_options
    %w(show hide).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def divide_duties_view_options
    staff_records_view_options
  end

  def name_with_code
    "[#{code}] #{name}"
  end

  def editable_charge?(user)
    permissions = user.gws_role_permissions

    if permissions["edit_other_gws_staff_record_charges_#{site_id}"].to_i >= permission_level
      return true
    elsif permissions["edit_private_gws_staff_record_charges_#{site_id}"].to_i >= permission_level
      return true if owned?(user)
    end
    false
  end

  private

  def set_section_order
    item = Gws::StaffRecord::Group.where(site_id: site_id, year: year, name: section_name).first
    self.section_order = item ? item.order : nil
  end
end
