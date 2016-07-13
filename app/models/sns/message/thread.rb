class Sns::Message::Thread
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  attr_accessor :text

  #field :name, type: String

  embeds_ids :members, class_name: "SS::User"
  embeds_ids :active_members, class_name: "SS::User"
  embeds_ids :unseen_members, class_name: "SS::User"
  has_many :posts, class_name: "Sns::Message::Post", dependent: :destroy

  permit_params :text, member_ids: []

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

  def name(user = nil)
    if active_member_ids == [user.id]
      mem = members
      mem = mem.where(:_id.ne => user.id) if user
      "(" + mem.map(&:name).join(', ') + ")"
    else
      mem = active_members
      mem = mem.where(:_id.ne => user.id) if user
      mem.map(&:name).join(', ')
    end
  end

  def unseen?(user)
    unseen_member_ids.include?(user.id)
  end

  def set_seen(user)
    if unseen?(user)
      ids = unseen_member_ids
      ids.delete(user.id)
      self.set unseen_member_ids: ids
    end
  end

  def reset_unseen(user)
    ids = active_member_ids
    ids.delete(user.id)
    self.set unseen_member_ids: ids, updated: Time.zone.now
  end

  def activate_members
    self.set active_member_ids: member_ids
  end

  def allowed?(action, user, opts = {})
    return true if super
    active_member_ids.include?(user.id) if action =~ /edit|delete/
  end

  def recycle_create
    @recycle_create = true
    return false unless valid?
    thread = recycle_thread
    return false unless thread.save

    post = Sns::Message::Post.new({
      cur_user: @cur_user,
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

  def leave_member(user)
    return destroy if active_member_ids.size <= 1
    ids = active_member_ids
    ids.delete(user.id)
    self.set active_member_ids: ids
    true
  end

  private
    def set_member_ids
      ids = self.member_ids.map(&:to_i)
      ids << user_id
      ids = ids.uniq.compact
      self.member_ids = ids
      self.active_member_ids = ids

      ids.delete(user_id)
      self.unseen_member_ids = ids
    end

    def validate_member_ids
      errors.add :member_ids, :blank if member_ids.size < 2
    end
end
