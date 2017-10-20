# "Post" class for BBS. It represents "topic" models.
class Gws::Monitor::Topic
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Category
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Monitor::BrowsingState

  readable_setting_include_custom_groups

  field :article_state, type: String, default: 'open'
  field :deleted, type: DateTime

  validates :deleted, datetime: true
  validates :article_state, inclusion: { in: %w(open closed) }

  permit_params :deleted
  permit_params :article_state

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
    return true if self.admin_setting == "1" &&  (userid == self.user_id || self.user_ids.include?(userid))
    return true if self.admin_setting == "0" &&  (groupid == self.user_group_id || self.group_ids.include?(groupid))
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

  def closed?
    article_state == 'closed'
  end

  def unanswered?(groupid)
    if closed?
      case state_of_the_answers_hash["#{groupid}"]
      when "public", "preparation", nil
        I18n.t("gws/monitor.options.state.closed")
      end
    end
  end

  def article_state_name
    I18n.t("gws/monitor.options.article_state." + article_state)
  end

  def state_name(groupid)
    return I18n.t("gws/monitor.options.state.no_state") if state_of_the_answers_hash["#{groupid}"].blank?
    I18n.t("gws/monitor.options.state." + state_of_the_answers_hash["#{groupid}"])
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
    return Gws::Group.none if attend_group_ids.blank?

    conds = [{ id: { '$in' => attend_group_ids.flatten } }]

    Gws::Group.where('$and' => [ { '$or' => conds } ])
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  def answer_count
    answered = state_of_the_answers_hash.select{|k, v| v.match(/answered|question_not_applicable/)}.count
    return "(#{answered}/#{subscribed_groups.count})"
  end

  def to_csv
    CSV.generate do |data|
      data << I18n.t('gws/monitor.csv')

      subscribed_groups.each do |group|
        post = children.where(group_ids: group.id).first
        data << [
            id,
            name,
            unanswered?(group.id) ? unanswered?(group.id) : state_name(group.id),
            group.name,
            post.try(:contributor_name),
            post.try(:text),
            post.try(:updated) ? post.updated.strftime('%Y/%m/%d %H:%M') : ''
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

