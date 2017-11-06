module Gws::Monitor::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission
  include Gws::Addon::Monitor::Group

  included do
    store_in collection: "gws_monitor_posts"
    set_permission_name "gws_monitor_posts"

    attr_accessor :cur_site

    seqid :id
    field :state, type: String, default: 'public'
    field :name, type: String
    field :mode, type: String, default: 'thread'
    field :permit_comment, type: String, default: 'allow'
    field :descendants_updated, type: DateTime
    field :severity, type: String
    field :due_date, type: DateTime
    field :spec_config, type: String, default: '0'
    field :reminder_start_section, type: String, default: '0'
    field :state_of_the_answers_hash, type: Hash, default: {}

    validates :descendants_updated, datetime: true

    belongs_to :topic, class_name: "Gws::Monitor::Post", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Monitor::Post", inverse_of: :children

    has_many :children, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Monitor::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }

    permit_params :name, :mode, :permit_comment, :severity, :due_date,
                  :spec_config, :reminder_start_section, :state_of_the_answers_hash

    before_validation :set_topic_id, if: :comment?
    before_validation :set_state_of_the_answers_hash

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
    scope :and_topics, ->(userid, groupid, custom_group_ids, key) {
      if key.start_with?('answerble')
        where("$and" => [ {"state_of_the_answers_hash.#{groupid}".to_sym.in => ["public","preparation"]},
                          {article_state: 'open'}
                        ]
             )
      elsif key.start_with?('readable')
        where("$and" =>
                [ "$or" =>
                  [
                    { :readable_group_ids.in => [groupid] },
                    { readable_member_ids: userid },
                    { :readable_custom_group_ids.in => custom_group_ids },
                    { "attend_group_ids.0" => { "$exists" => false } },
                    {"state_of_the_answers_hash.#{groupid}".to_sym.in => ["public","preparation"]}
                  ]
                ]
              )
      end
    }

    scope :and_answers, ->(groupid, key) {
      if key.start_with?('answerble')
        where("$and" => [
                          {"state_of_the_answers_hash.#{groupid}".to_sym.in => ["question_not_applicable","answered"]},
                          {article_state: 'open'}
                        ]
              )
      elsif key.start_with?('readable')
        where("$and" => [
                          {"state_of_the_answers_hash.#{groupid}".to_sym.in => ["question_not_applicable","answered"]}
                        ]
             )
      end
    }
    # Allow readable settings and readable permissions.
    scope :and_readable, ->(user, site, opts = {}) {
      cond = [
          { "readable_group_ids.0" => { "$exists" => false },
            "readable_member_ids.0" => { "$exists" => false },
            "readable_custom_group_ids.0" => { "$exists" => false },
            "group_ids.0" => { "$exists" => false },
            "user_ids.0" => { "$exists" => false },
            "attend_group_ids.0" => { "$exists" => false } },
          { :readable_group_ids.in => user.group_ids },
          { readable_member_ids: user.id },
          { :attend_group_ids.in => user.group_ids },
      ]
      if readable_setting_included_custom_groups?
        cond << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      cond << allow_condition(:read, user, site: site) if opts[:include_role]
      where("$and" => [{ "$or" => cond }])
    }
    scope :owner, ->(user, site, opts = {}) {
      cond = [
          { "group_ids.0" => { "$exists" => false },
            "user_ids.0" => { "$exists" => false } },
          { "$and" => [ { :group_ids.in => user.group_ids }] },
          { "$and" => [ { user_ids: user.id }] },
      ]
      where("$and" => [{ "$or" => cond }])
    }
    scope :attend, ->(user, site, opts = {}) {
      cond = [
          { "attend_group_ids.0" => { "$exists" => false } },
          { :attend_group_ids.in => user.group_ids },
      ]
      where("$and" => [{ "$or" => cond }])
    }
    scope :remind, ->() {
      where("$where" => "function() {
       var sect = parseInt(this.reminder_start_section);
       if (sect == -999) return false;
       if (sect > 0) {
         dd = this.due_date;
       } else {
         dd = this.created;
       }
       dt = new Date(dd.getFullYear(), dd.getMonth(), dd.getDate() - sect);
       return (dt <= ISODate('#{Time.zone.today}'));
     }")
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

  def answerable_article_options
    [
        [I18n.t('gws/monitor.options.answerable_article.answerable'), 'answerble'],
        [I18n.t('gws/monitor.options.answerable_article.readable'), 'readable']
    ]
  end

  def severity_options
    %w(normal important).map { |v| [ I18n.t("gws/monitor.options.severity.#{v}"), v ] }
  end

  private

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

  def set_state_of_the_answers_hash
    attend_group_ids_string = []
    @attributes["attend_group_ids"].each {|s| attend_group_ids_string << "#{s}"}
    self.state_of_the_answers_hash = attend_group_ids_string.map do |g|
      if @attributes["state_of_the_answers_hash"][g]
        [g, @attributes["state_of_the_answers_hash"][g]]
      else
        [g, "preparation"]
      end
    end.to_h
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
