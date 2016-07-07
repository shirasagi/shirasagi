class Sns::Message::Thread
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  # first post message
  attr_accessor :text

  #field :descendants_created, type: DateTime, default: -> { created }
  #field :descendants_updated, type: DateTime, default: -> { created }

  field :name, type: String
  embeds_ids :members, class_name: "SS::User"
  has_many :posts, class_name: "Sns::Message::Post"

  permit_params :text, member_ids: []

  ## TODO: Delete
  field :member_ids, type: SS::Extensions::Words ##
  permit_params :member_ids
  ##

  before_validation :set_member_ids

  validates :user_id, presence: true
  validates :member_ids, presence: true
  validates :text, presence: true, if: -> { @recycle_create.present? }

  validate :validate_member_ids

  default_scope -> {
    order_by updated: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    #criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def name
    self[:name] || members.map(&:name).join(', ') || id
  end

  def recycle_create
    @recycle_create = true
    return false unless valid?

    thread = recycle_thread
    return false unless thread.save

    post = Sns::Message::Post.new({
      user_id: user_id,
      thread_id: thread.id,
      text: text,
      seen_member_ids: [user_id]
    })
    return false unless post.save

    thread
  end

  def recycle_thread
    thread = self.class.where(member_ids: member_ids).first if member_ids.size == 2
    thread || self.class.new(attributes)
  end

  private
    def set_member_ids
      member_ids = self.member_ids
      member_ids << user_id
      self.member_ids = member_ids.map(&:to_i).uniq.compact
    end

    def validate_member_ids
      errors.add :member_ids, :blank if member_ids.size < 2
    end
end
