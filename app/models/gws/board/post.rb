# "Post" class for BBS. It represents "topic" and "comment" models.
class Gws::Board::Post
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown
  include Gws::Addon::GroupPermission

  seqid :id
  field :name, type: String
  field :mode, type: String, default: 'thread'
  field :permit_comment, type: String, default: 'allow'
  field :descendants_created, type: DateTime
  field :descendants_updated, type: DateTime

  permit_params :name, :mode, :permit_comment

  belongs_to :topic, class_name: "Gws::Board::Post", inverse_of: :descendants
  belongs_to :parent, class_name: "Gws::Board::Post", inverse_of: :children

  has_many :descendants, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :topic,
    order: { created: 1 }
  has_many :children, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :parent,
    order: { created: 1 }

  validates :name, presence: true
  validates :text, presence: true
  validates :mode, inclusion: {in: %w(thread tree)}, unless: :comment?
  validates :permit_comment, inclusion: {in: %w(allow deny)}, unless: :comment?

  # Can't create a comment if its topic "permit_comment?" returns false.
  validate -> do
    unless topic.permit_comment?
      errors.add :base, I18n.t("gws/board.errors.denied_comment")
      # FIXME 排他制御出来ないためにこんなコード書いてる
      # FIXME (例:コメント本文入力中にトピックがコメント許可しないに変更)
      # FIXME バリデーションエラーメッセージを何処に入れれば良いのだろう？
    end
  end, if: :comment?

  before_validation :set_topic_id, if: :comment?
  before_save :set_descendants_updated
  after_save :update_parent_descendants_updated

  scope :topic, ->{ exists parent_id: false }
  scope :comment, ->{ exists parent_id: true }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  def set_descendants_updated
    self.descendants_updated = updated
  end

  # Update parent's "descendants_updated" field recursively.
  def update_parent_descendants_updated(time = nil)
    if parent.present?
      time ||= descendants_updated
      # Call low level "set" API instead of "update" to skip callbacks.
      parent.set descendants_updated: time
      parent.update_parent_descendants_updated time
    end
  end

  def root_post
    parent.nil? ? self : parent.root_post
  end

  def comment?
    parent.present?
  end

  def set_topic_id
    self.topic_id = root_post.id
  end

  def permit_comment?
    permit_comment == 'allow'
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
end
