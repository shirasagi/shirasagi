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
  include SS::Model::Reference::UserOccupations

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
  embeds_ids :occupations, class_name: "Gws::StaffRecord::UserOccupation"

  attr_accessor :in_title_id, :in_occupation_id

  permit_params :name, :code, :order, :kana, :multi_section, :section_name,
    :tel_ext, :charge_name, :charge_address, :charge_tel,
    :divide_duties, :remark, :staff_records_view, :divide_duties_view,
    :in_title_id, :in_occupation_id

  validates :name, presence: true
  validates :code, presence: true
  validates :multi_section, inclusion: { in: %w(regular plural) }
  validates :section_name, presence: true
  validates :charge_name, presence: true, unless: -> { %i[copy_situation].include?(validation_context) }
  validates :staff_records_view, inclusion: { in: %w(show hide) }
  validates :divide_duties_view, inclusion: { in: %w(show hide) }

  before_validation :set_section_order, if: -> { section_name.present? }
  before_validation :set_title_ids, if: -> { in_title_id }
  before_validation :set_occupation_ids, if: -> { in_occupation_id }

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

  def occupation_id_options
    Gws::StaffRecord::UserOccupation.site(cur_site).where(year_id: year_id).active.map { |m| [m.name_with_code, m.id] }
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

    if permissions["edit_other_gws_staff_record_charges_#{site_id}"]
      return true
    elsif permissions["edit_private_gws_staff_record_charges_#{site_id}"]
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

  def set_occupation_ids
    occupation_ids = occupations.reject { |m| m.group_id == cur_site.id }.map(&:id)
    occupation_ids << in_occupation_id.to_i if in_occupation_id.present?
    self.occupation_ids = occupation_ids
  end

  def export_fields
    %w(
      id name code order kana multi_section section_name title_ids occupation_ids tel_ext
      charge_name charge_address charge_tel divide_duties remark staff_records_view divide_duties_view
      readable_setting_range readable_group_ids readable_member_ids
      group_ids user_ids
    )
  end

  def export_convert_item(item, data)
    # multi_section
    data[5] = item.label(:multi_section)
    # title_ids
    data[7] = item.titles.pluck(:code).join("\n")
    # occupation_ids
    data[8] = item.occupations.pluck(:code).join("\n")
    # staff_records_view
    data[15] = item.label(:staff_records_view)
    # divide_duties_views
    data[16] = item.label(:divide_duties_view)

    # readable_setting_range
    data[17] = item.label(:readable_setting_range)
    # readable_group_ids
    data[18] = Gws::Group.site(@cur_site).in(id: data[18]).active.pluck(:name).join("\n")
    # readable_member_ids
    data[19] = Gws::User.site(@cur_site).in(id: data[19]).active.pluck(:uid).join("\n")

    # group_ids
    data[20] = Gws::Group.site(@cur_site).in(id: data[20]).active.pluck(:name).join("\n")
    # user_ids
    data[21] = Gws::User.site(@cur_site).in(id: data[21]).active.pluck(:uid).join("\n")

    data
  end

  def import_convert_data(data)
    # multi_section
    regular = I18n.t("gws/staff_record.options.multi_section.regular")
    data[:multi_section] = (data[:multi_section] == regular) ? 'regular' : 'plural'

    # title_ids
    if data[:title_ids].present?
      user_titles = Gws::StaffRecord::UserTitle.site(@cur_site)
      user_titles = user_titles.where(year_id: self.year_id)
      user_titles = user_titles.in(code: data[:title_ids].split(/\R/))
      data[:title_ids] = user_titles.pluck(:id)
    else
      data[:title_ids] = []
    end

    # occupation_ids
    if data[:occupation_ids].present?
      user_occupations = Gws::StaffRecord::UserOccupation.site(@cur_site)
      user_occupations = user_occupations.where(year_id: self.year_id)
      user_occupations = user_occupations.in(code: data[:occupation_ids].split(/\R/))
      data[:occupation_ids] = user_occupations.pluck(:id)
    else
      data[:occupation_ids] = []
    end

    # staff_records_view
    show = I18n.t("ss.options.state.show")
    data[:staff_records_view] = (data[:staff_records_view] == show) ? 'show' : 'hide'
    # divide_duties_views
    data[:divide_duties_view] = (data[:divide_duties_view] == show) ? 'show' : 'hide'

    # readable_group_ids
    case data[:readable_setting_range]
    when I18n.t("gws.options.readable_setting_range.public")
      readable_setting_range = "public"
    when I18n.t("gws.options.readable_setting_range.select")
      readable_setting_range = "select"
    else # I18n.t("gws.options.readable_setting_range.private")
      readable_setting_range = "private"
    end
    data[:readable_setting_range] = readable_setting_range
    # readable_group_ids
    group_ids = data[:readable_group_ids]
    if group_ids
      data[:readable_group_ids] = Gws::Group.site(@cur_site).active.in(name: group_ids.split(/\R/)).pluck(:id)
    else
      data[:readable_group_ids] = []
    end
    # readable_member_ids
    user_ids = data[:readable_member_ids]
    if user_ids
      data[:readable_member_ids] = Gws::User.site(@cur_site).active.in(uid: user_ids.split(/\R/)).pluck(:id)
    else
      data[:readable_member_ids] = []
    end

    # group_ids
    group_ids = data[:group_ids]
    if group_ids
      data[:group_ids] = Gws::Group.site(@cur_site).active.in(name: group_ids.split(/\R/)).pluck(:id)
    else
      data[:group_ids] = []
    end
    # user_ids
    user_ids = data[:user_ids]
    if user_ids
      data[:user_ids] = Gws::User.site(@cur_site).active.in(uid: user_ids.split(/\R/)).pluck(:id)
    else
      data[:user_ids] = []
    end

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
