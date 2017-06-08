module Gws::Board::Postable
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission

  included do
    store_in collection: "gws_board_posts"
    set_permission_name "gws_board_posts"

    attr_accessor :cur_site

    seqid :id
    field :state, type: String, default: 'public'
    field :name, type: String
    field :mode, type: String, default: 'thread'
    field :permit_comment, type: String, default: 'allow'
    field :descendants_updated, type: DateTime

    validates :descendants_updated, datetime: true

    belongs_to :topic, class_name: "Gws::Board::Post", inverse_of: :descendants
    belongs_to :parent, class_name: "Gws::Board::Post", inverse_of: :children

    has_many :children, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: -1 }
    has_many :descendants, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: -1 }

    permit_params :name, :mode, :permit_comment

    before_validation :set_topic_id, if: :comment?

    validates :name, presence: true, length: { maximum: 80 }
    validates :mode, inclusion: {in: %w(thread tree)}, unless: :comment?
    validates :permit_comment, inclusion: {in: %w(allow deny)}, unless: :comment?

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
        category_ids = Gws::Board::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
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
    descendants_updated > Time.zone.now - site.board_new_days.day
  end

  def mode_options
    [
      [I18n.t('gws/board.options.mode.thread'), 'thread'],
      [I18n.t('gws/board.options.mode.tree'), 'tree']
    ]
  end

  def permit_comment_options
    [
      [I18n.t('gws/board.options.permit_comment.allow'), 'allow'],
      [I18n.t('gws/board.options.permit_comment.deny'), 'deny']
    ]
  end

  private

  # topic(root_post)を設定
  def set_topic_id
    self.topic_id = root_post.id
  end

  # コメントを許可しているか検証
  def validate_comment
    return if topic.permit_comment?
    errors.add :base, I18n.t("gws/board.errors.denied_comment")
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
end
