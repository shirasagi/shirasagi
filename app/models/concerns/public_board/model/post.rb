module PublicBoard::Model::Post
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site

  included do
    store_in collection: "public_board_posts"

    seqid :id
    field :name, type: String
    field :text, type: String, default: ""
    field :descendants_updated, type: DateTime
    permit_params :name, :text

    belongs_to :topic, foreign_key: :topic_id, class_name: "PublicBoard::Post", inverse_of: :descendants
    belongs_to :parent, foreign_key: :parent_id, class_name: "PublicBoard::Post", inverse_of: :children

    has_many :descendants, foreign_key: :topic_id, class_name: "PublicBoard::Post", dependent: :destroy, inverse_of: :topic
    has_many :children, foreign_key: :parent_id, class_name: "PublicBoard::Post", dependent: :destroy, inverse_of: :parent

    validates :name, presence: true
    validates :text, presence: true

    before_validation :set_topic_id, if: :comment?
    before_save :set_descendants_updated
    after_save :update_parent_descendants_updated

    scope :topic, ->{ exists parent_id: false }
    scope :comment, ->{ exists parent_id: true }
  end

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
end
