class Gws::StaffRecord::User
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Export
  include SS::Model::Reference::UserTitles

  seqid :id
  field :name, type: String
  field :code, type: String
  field :order, type: Integer, default: 0
  field :kana, type: String
  field :multi_section, type: String, default: 'regular'
  field :section_name, type: String
  field :section_order, type: Integer
  field :tel_ext, type: String
  field :charge_name, type: String
  field :charge_address, type: String
  field :charge_tel, type: String
  field :divide_duties, type: String
  field :remark, type: String
  field :staff_records_view, type: String, default: 'show'
  field :divide_duties_view, type: String, default: 'show'

  embeds_ids :titles, class_name: "Gws::StaffRecord::UserTitle"

  attr_accessor :in_title_id

  permit_params :name, :code, :order, :kana, :multi_section, :section_name,
                :tel_ext, :charge_name, :charge_address, :charge_tel,
                :divide_duties, :remark, :staff_records_view, :divide_duties_view,
                :in_title_id

  validates :name, presence: true
  validates :code, presence: true
  validates :multi_section, inclusion: { in: %w(regular plural) }
  validates :section_name, presence: true
  validates :charge_name, presence: true, unless: -> { %i[copy_situation].include?(validation_context) }
  validates :staff_records_view, inclusion: { in: %w(show hide) }
  validates :divide_duties_view, inclusion: { in: %w(show hide) }

  before_validation :set_section_order, if: -> { section_name.present? }
  before_validation :set_title_ids, if: -> { in_title_id }

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
      criteria = criteria.keyword_in(
        params[:keyword],
        :name,
        :code,
        :kana,
        :section_name,
        :charge_name,
        :charge_address,
        :charge_tel,
        :tel_ext,
        :divide_duties,
        :remark
      )
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

  def title_id_options
    Gws::StaffRecord::UserTitle.site(cur_site).where(year_id: year_id).active.map { |m| [m.name_with_code, m.id] }
  end

  def staff_records_view_options
    %w(show hide).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def divide_duties_view_options
    staff_records_view_options
  end

  def name_with_code
    if code.present?
      "[#{code}] #{name}"
    else
      name
    end
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

  def set_title_ids
    title_ids = titles.reject { |m| m.group_id == cur_site.id }.map(&:id)
    title_ids << in_title_id.to_i if in_title_id.present?
    self.title_ids = title_ids
  end

  def export_fields
    %w(
      id name code order kana multi_section section_name title_ids tel_ext
      charge_name charge_address charge_tel divide_duties remark staff_records_view divide_duties_view
      group_ids user_ids permission_level
    )
  end

  def export_convert_item(item, data)
    # multi_section
    data[5] = item.label(:multi_section)
    # staff_records_view
    data[14] = item.label(:staff_records_view)
    # divide_duties_views
    data[15] = item.label(:divide_duties_view)
    # group_ids
    data[16] = Gws::Group.site(@cur_site).in(id: data[16]).active.pluck(:name).join("\n")
    # user_ids
    data[17] = Gws::User.site(@cur_site).in(id: data[17]).active.pluck(:uid).join("\n")

    data
  end

  def import_convert_data(data)
    regular = I18n.t("gws/staff_record.options.multi_section.regular")
    data[:multi_section] = (data[:multi_section] == regular) ? 'regular' : 'plural'

    show = I18n.t("ss.options.state.show")
    data[:staff_records_view] = (data[:staff_records_view] == show) ? 'show' : 'hide'
    data[:divide_duties_view] = (data[:divide_duties_view] == show) ? 'show' : 'hide'

    data[:group_ids] = Gws::Group.site(@cur_site).active.in(name: data[:group_ids]).pluck(:id)
    data[:user_ids] = Gws::User.site(@cur_site).active.in(uid: data[:user_ids]).pluck(:id)

    data
  end

  def import_find_item(data)
    self.class.site(@cur_site).
      where(year_id: year_id, id: data[:id]).
      allow(:read, @cur_user, site: @cur_site).
      first
  end

  def import_new_item(data)
    self.class.new(data.merge(year_id: year_id))
  end
end
