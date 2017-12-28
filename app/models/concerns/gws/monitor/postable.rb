module Gws::Monitor::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission

  included do
    store_in collection: "gws_monitor_posts"
    set_permission_name "gws_monitor_posts"

    attr_accessor :cur_site

    seqid :id
    field :name, type: String
    field :mode, type: String, default: 'thread'
    field :permit_comment, type: String, default: 'allow'
    field :descendants_updated, type: DateTime
    field :severity, type: String
    field :due_date, type: DateTime
    field :spec_config, type: String, default: 'my_group'
    field :reminder_start_section, type: String, default: '3'

    validates :descendants_updated, datetime: true

    belongs_to :topic, class_name: "Gws::Monitor::Topic", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Monitor::Post", inverse_of: :children

    has_many :children, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }

    permit_params :name, :mode, :permit_comment, :severity, :due_date,
                  :spec_config, :reminder_start_section

    after_initialize :set_default

    before_validation :set_topic_id, if: :comment?

    validates :name, presence: true, length: { maximum: 80 }
    validates :mode, inclusion: {in: %w(thread tree)}, unless: :comment?
    validates :permit_comment, inclusion: {in: %w(allow deny)}, unless: :comment?
    validates :severity, inclusion: { in: %w(normal important), allow_blank: true }

    validate :validate_comment, if: :comment?

    before_save :set_descendants_updated, if: -> { topic_id.blank? }
    after_save :update_topic_descendants_updated, if: -> { topic_id.present? }

    scope :topic, ->{ exists parent_id: false }
    scope :topic_comments, ->(topic) { where topic_id: topic.id }
    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?

      if params[:category].present?
        category_ids = Gws::Monitor::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
      end
      if params[:question_state].present?
        criteria = criteria.where(question_state: params[:question_state].to_s)
      end
      criteria
    }
  end

  # Returns the topic.
  def root_post
    parent.nil? ? self : parent.root_post
  end

  # is comment?
  def comment?
    parent_id.present?
  end

  def permit_comment?
    permit_comment == 'allow'
  end

  def new_flag?
    descendants_updated > Time.zone.now - site.monitor_new_days.day
  end

  def spec_config_condition(cur_user, cur_group)
    unless topic.user_ids.include?(cur_user.id) || topic.group_ids.include?(cur_group.id) || topic.spec_config == 'other_groups_and_contents'
      admin_comment_check = topic.group_ids.include?(user_group_id) || topic.user_ids.include?(user_id)
      if parent.id == topic.id
        return false unless user_group_id == cur_group.id
      else
        return false unless user_group_id == cur_group.id || (admin_comment_check && parent.user_group_id == cur_group.id)
      end
    end
    return true
  end

  def mode_options
    [
      [I18n.t('gws/monitor.options.mode.thread'), 'thread'],
      [I18n.t('gws/monitor.options.mode.tree'), 'tree']
    ]
  end

  def permit_comment_options
    [
      [I18n.t('gws/monitor.options.permit_comment.allow'), 'allow'],
      [I18n.t('gws/monitor.options.permit_comment.deny'), 'deny']
    ]
  end

  def spec_config_options
    %w(my_group other_groups other_groups_and_contents).map do |v|
      [I18n.t("gws/monitor.options.spec_config.#{v}"), v]
    end
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

  def severity_options
    %w(normal important).map { |v| [ I18n.t("gws/monitor.options.severity.#{v}"), v ] }
  end

  def becomes_with_topic
    if topic_id.present?
      return self
    end

    becomes_with(Gws::Monitor::Topic)
  end

  private

  def set_default
    return if self.id > 0
    if @cur_site && @cur_site.default_reminder_start_section.present?
      self.reminder_start_section = @cur_site.default_reminder_start_section
    end
    self.due_date = Time.zone.today + 7
  end

  # topic(root_post)を設定
  def set_topic_id
    self.topic_id = root_post.id
  end

  # コメントを許可しているか検証
  def validate_comment
    return if topic.permit_comment?
    errors.add :base, I18n.t("gws/monitor.errors.denied_comment")
  end

  # 最新レス投稿日時の初期値をトピックのみ設定
  # 明示的に age るケースが発生するかも
  def set_descendants_updated
    #return unless new_record?
    self.descendants_updated = updated
  end

  # 最新レス投稿日時、レス更新日時をトピックに設定
  # 明示的に age るケースが発生するかも
  def update_topic_descendants_updated
    return unless topic
    #return unless _id_changed?
    topic.set descendants_updated: updated
  end

  module ClassMethods
    def readable_setting_included_custom_groups?
      class_variable_get(:@@_readable_setting_include_custom_groups)
    end

    private

    def readable_setting_include_custom_groups
      class_variable_set(:@@_readable_setting_include_custom_groups, true)
    end
  end
end
