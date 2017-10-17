# "Post" class for BBS. It represents "topic" models.
class Gws::Monitor::Topic
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Category
  include Gws::Addon::Monitor::Group
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Monitor::BrowsingState

  readable_setting_include_custom_groups

  field :deleted, type: DateTime
  validates :deleted, datetime: true
  permit_params :deleted

  #validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      where({}).order_by(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      where({}).order_by(descendants_updated: key.end_with?('_asc') ? 1 : -1)
    else
      where({})
    end
  }

  def topic_admin?(userid, groupid)
    return true if self.admin_setting == "1" &&  userid == self.user_id
    return true if self.admin_setting == "2" &&  groupid == self.user_group_id
    false
  end

  def active?
    return true unless deleted.present? && deleted < Time.zone.now
    false
  end

  def active
    update_attributes(deleted: nil)
  end

  def disable
    update_attributes(deleted: Time.zone.now) if deleted.blank? || deleted > Time.zone.now
  end

  def state_name
    I18n.t("gws/monitor.options.state.#{state_of_the_answer}")
  end

  def admin_setting_options
    [
        [I18n.t('gws/monitor.options.admin_setting.user'), '1'],
        [I18n.t('gws/monitor.options.admin_setting.section'), '0']
    ]
  end

  def spec_config_options
    [
        [I18n.t('gws/monitor.options.spec_config.my_group'), '0'],
        [I18n.t('gws/monitor.options.spec_config.other_groups'), '3'],
        [I18n.t('gws/monitor.options.spec_config.other_groups_and_contents'), '5']
    ]
  end

  def reminder_start_section_options
    [
        [I18n.t('gws/monitor.options.reminder_start_section.post'), '0'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_one_day_after'), '-1'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_two_days_after'), '-2'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_three_days_after'), '-3'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_four_days_after'), '-4'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_five_days_after'), '-5'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_one_day_ago'), '1'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_two_days_ago'), '2'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_three_days_ago'), '3'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_four_days_ago'), '4'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_five_days_ago'), '5'],
        [I18n.t('gws/monitor.options.reminder_start_section.hide'), '-999']
    ]
  end

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def subscribed_groups
    return Gws::Group.none if new_record?
    return Gws::Group.none if group_ids.blank? && user_ids.blank? && custom_group_ids.blank?

    conds = []
    # conds << { id: { '$in' => Gws::Monitor::Post.pluck(:user_ids).flatten } }
    # conds << { group_ids: { '$in' => Gws::Monitor::Post.pluck(:group_ids).flatten } }
    conds << { id: { '$in' => Gws::Monitor::Post.pluck(:group_ids).flatten } }

    if Gws::Monitor::Category.subscription_setting_included_custom_groups?
      custom_gropus = Gws::CustomGroup.in(id: Gws::Monitor::Post.pluck(:custom_group_ids))
      conds << { id: { '$in' => custom_gropus.pluck(:member_ids).flatten } }
    end

    Gws::Group.where('$and' => [ { '$or' => conds } ])
    # Gws::User.where('$and' => [ { '$or' => conds } ])
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  def to_csv
    CSV.generate do |data|
      data << I18n.t('gws/monitor.csv')

      children.each do |item|
        data << [
            self.id,
            self.name,
            I18n.t("gws/monitor.options.state.#{item.state_of_the_answer}"),
            item.user_name,
            item.text,
            item.updated.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end

  private

  def set_descendants_updated_with_released
    if descendants_updated.present?
      self.descendants_updated = released if descendants_updated < released
    else
      self.descendants_updated = released
    end
  end
end

