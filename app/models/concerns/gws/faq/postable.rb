module Gws::Faq::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::ReadableSetting
  include Gws::GroupPermission
  include Fs::FilePreviewable

  included do
    store_in collection: "gws_faq_posts"
    set_permission_name "gws_faq_posts"

    attr_accessor :cur_site

    seqid :id
    field :state, type: String, default: 'public'
    field :name, type: String
    field :mode, type: String, default: 'thread'
    field :permit_comment, type: String, default: 'allow'
    field :descendants_updated, type: DateTime
    field :severity, type: String

    validates :descendants_updated, datetime: true

    belongs_to :topic, class_name: "Gws::Faq::Topic", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Faq::Post", inverse_of: :children

    has_many :children, class_name: "Gws::Faq::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Faq::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }

    permit_params :name, :mode, :permit_comment, :severity

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
        category_ids = Gws::Faq::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
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
    (release_date.presence || created) > Time.zone.now - site.faq_new_days.day
  end

  def mode_options
    [
      [I18n.t('gws/faq.options.mode.thread'), 'thread'],
      [I18n.t('gws/faq.options.mode.tree'), 'tree']
    ]
  end

  def permit_comment_options
    [
      [I18n.t('gws/faq.options.permit_comment.allow'), 'allow'],
      [I18n.t('gws/faq.options.permit_comment.deny'), 'deny']
    ]
  end

  def severity_options
    %w(normal important).map { |v| [ I18n.t("gws/faq.options.severity.#{v}"), v ] }
  end

  def becomes_with_topic
    if topic_id.present?
      return self
    end

    becomes_with(Gws::Faq::Topic)
  end

  def readable?(user, opts = {})
    if topic.present? && topic.id != id
      return topic.readable?(user, opts)
    end

    super
  end

  def file_previewable?(file, user:, member:)
    return false if user.blank?
    return false if !file_ids.include?(file.id)

    if topic.present? && topic.id != id
      return true if topic.allowed?(:read, user, site: site)
    end

    false
  end

  private

  # topic(root_post)を設定
  def set_topic_id
    self.topic_id = root_post.id
  end

  # コメントを許可しているか検証
  def validate_comment
    return if topic.permit_comment?

    errors.add :base, I18n.t("gws/faq.errors.denied_comment")
  end

  # 最新レス投稿日時の初期値をトピックのみ設定
  # 明示的に age るケースが発生するかも
  def set_descendants_updated
    self.descendants_updated = updated
  end

  # 最新レス投稿日時、レス更新日時をトピックに設定
  # 明示的に age るケースが発生するかも
  def update_topic_descendants_updated
    return unless topic

    topic.set descendants_updated: updated
  end
end
