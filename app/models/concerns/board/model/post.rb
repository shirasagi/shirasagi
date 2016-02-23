module Board::Model::Post
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  included do
    store_in collection: "board_posts"

    seqid :id
    field :name, type: String
    field :text, type: String, default: ""
    field :descendants_updated, type: DateTime
    permit_params :name, :text

    belongs_to :topic, class_name: "Board::Post", inverse_of: :descendants
    belongs_to :parent, class_name: "Board::Post", inverse_of: :children

    has_many :children, class_name: "Board::Post", dependent: :destroy, inverse_of: :parent,
      order: { created: 1 }
    has_many :descendants, class_name: "Board::Post", dependent: :destroy, inverse_of: :topic,
      order: { created: 1 }

    validates :name, presence: true
    validates :text, presence: true

    validate :validate_children, if: -> { topic_id.present? }

    before_validation :set_topic_id, if: :comment?
    before_save :set_descendants_updated, if: -> { topic_id.blank? }
    after_save :update_topic_descendants_updated, if: -> { topic_id.present? }

    scope :topic, ->{ exists parent_id: false }
    scope :comment, ->{ exists parent_id: true }
  end

  def root_post
    parent.nil? ? self : parent.root_post
  end

  def comment?
    parent_id.present?
  end

  def permit_comment?
    permit_comment == 'allow'
  end

  private
    def set_topic_id
      self.topic_id = root_post.id
    end

    def set_descendants_updated
      return unless new_record?
      self.descendants_updated = updated
    end

    def update_topic_descendants_updated
      return unless topic
      return unless _id_changed?
      topic.set descendants_updated: updated
    end

    def validate_children
      if topic.children.size >= 1000
        errors.add :base, I18n.t('board.errors.too_many_comments')
      end
    end
end
