# "Post" class for BBS. It represents "topic" and "comment" models.
class Gws::Board::Post
  include SS::Document
  include Gws::Addon::GroupPermission
  include Gws::Reference::User

  seqid :id
  field :name, type: String
  field :text, type: String
  field :mode, type: String, default: 'thread'
  field :permit_comment, type: String, default: 'allow'
  field :descendants_updated, type: DateTime

  permit_params :name, :text, :mode, :permit_comment

  belongs_to :topic, class_name: "Gws::Board::Post", inverse_of: :descendants
  belongs_to :parent, class_name: "Gws::Board::Post", inverse_of: :children

  has_many :descendants, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :topic
  has_many :children, class_name: "Gws::Board::Post", dependent: :destroy, inverse_of: :parent

  validates :name, presence: true
  validates :text, presence: true
  validates :mode, inclusion: {in: %w(thread tree)}, unless: :comment?
  validates :permit_comment, inclusion: {in: %w(allow deny)}, unless: :comment?

  # Can't create a comment if its topic "permit_comment?" returns false.
  validate -> do
    unless topic.permit_comment?
      errors.add :xxx, "Not allowed comment."
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
      [I18n.t('gws_board.options.mode.thread'), 'thread'],
      [I18n.t('gws_board.options.mode.tree'), 'tree']
    ]
  end

  def permit_comment_options
    [
      [I18n.t('gws_board.options.permit_comment.allow'), 'allow'],
      [I18n.t('gws_board.options.permit_comment.deny'), 'deny']
    ]
  end
end
