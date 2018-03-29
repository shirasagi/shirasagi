class Gws::Schedule::Plan
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Priority
  include Gws::Schedule::Colorize
  include Gws::Schedule::Planable
  include Gws::Schedule::Cloneable
  include Gws::Schedule::CalendarFormat
  include Gws::Addon::Reminder
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Memo::NotifySetting
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Schedule::Reports
  include Gws::Addon::Schedule::Comments
  include Gws::Addon::Member
  include Gws::Addon::Schedule::Attendance
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::Schedule::FacilityColumnValues
  include Gws::Addon::Schedule::Approval
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include ActiveSupport::NumberHelper

  member_include_custom_groups
  permission_include_custom_groups
  readable_setting_include_custom_groups

  field :color, type: String

  # 種別
  belongs_to :category, class_name: 'Gws::Schedule::Category'

  permit_params :color

  validate :validate_color
  validate :validate_file_size

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def category_options
    @category_options ||= Gws::Schedule::Category.site(@cur_site || site).
      readable(@cur_user || user, site: @cur_site || site).
      to_options
  end

  def reminder_user_ids
    member_ids
  end

  def private_plan?(user)
    return false if readable_custom_group_ids.present?
    return false if readable_group_ids.present?
    readable_member_ids == [user.id] && member_ids == [user.id]
  end

  def attendance_check_plan?
    attendance_check_enabled?
  end

  def approval_check_plan?
    approval_state.present?
  end

  alias allowed_for_managers? allowed?

  def allowed?(action, user, opts = {})
    return true if allowed_for_managers?(action, user, opts)
    member?(user) || custom_group_member?(user) if action =~ /edit|delete/
    false
  end

  def subscribed_users
    return Gws::User.none if new_record?

    ids = member_ids
    ids += Gws::CustomGroup.in(id: member_custom_group_ids).pluck(:member_ids).flatten
    ids += try(:facility_approver_ids) || []
    ids.uniq!
    Gws::User.in(id: ids)
  end

  def readable?(user, opts = {})
    return true if allowed?(:read, user, opts)
    return true if member?(user)
    return true if approval_member?(user)
    super
  end

  private

  def validate_color
    self.color = nil if color =~ /^#ffffff$/i
  end

  def validate_file_size
    limit = cur_site.schedule_max_file_size || 0
    return if limit <= 0

    size = files.compact.map(&:size).max || 0
    if size > limit
      errors.add(
        :base,
        :file_size_exceeds_limit,
        size: number_to_human_size(size),
        limit: number_to_human_size(limit))
    end
  end
end
