class Sns::Message::Thread
  include SS::Document
  include SS::Reference::User
  include Sns::Message::MemberPermission

  attr_accessor :text

  field :members_type, type: String # only, many

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

  before_create :set_members_type
  before_create :reset_unseen_member_ids
  before_update :update_unseen_member_ids, if: -> { member_ids_changed? }

  default_scope -> {
    order_by updated: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    #criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def editable_members?
    members_type == "many"
  end

  def name(user)
    if members_type == 'only'
      other_members(user).map(&:name).join(', ')
    elsif active_member_ids == [user.id]
      "(" + other_members(user).map(&:name).join(', ') + ")"
    else
      other_active_members(user).map(&:name).join(', ')
    end
  end

  def other_members(user = nil)
    user ||= self.user
    members.where(:_id.ne => user.id)
  end

  def other_active_members(user = nil)
    user ||= self.user
    active_members.where(:_id.ne => user.id)
  end

  def unseen?(user)
    unseen_member_ids.include?(user.id)
  end

  def seen?(user)
    !unseen?(user)
  end

  def set_seen(user)
    return unless unseen?(user)
    ids = unseen_member_ids
    ids.delete(user.id)
    self.set unseen_member_ids: ids
  end

  def post_created(user)
    ids = active_member_ids
    ids.delete(user.id)
    self.set unseen_member_ids: ids, updated: Time.zone.now
  end

  def activate_members
    self.set active_member_ids: member_ids
  end

  def recycle_create
    @recycle_create = true
    return false unless valid?
    thread = recycle_thread
    return false unless thread.save

    post = Sns::Message::Post.new(
      cur_user: @cur_user,
      thread_id: thread.id,
      text: text
    )
    return false unless post.save

    thread
  end

  def recycle_thread
    if member_ids.size == 2
      thread = self.class.all_in(member_ids: member_ids).where(members_type: 'only').first
    end
    thread || self.class.new(attributes)
  end

  def leave_member(user)
    return destroy if active_member_ids.size <= 1
    active_ids = active_member_ids
    active_ids.delete(user.id)
    unseen_ids = unseen_member_ids
    unseen_ids.delete(user.id)
    self.set active_member_ids: active_ids, unseen_member_ids: unseen_ids
    true
  end

  private
    def set_member_ids
      ids = member_ids.map(&:to_i)
      ids << user_id
      ids = ids.uniq.compact
      self.member_ids = ids
      self.active_member_ids = ids
    end

    def validate_member_ids
      errors.add :member_ids, :blank if member_ids.size < 2
    end

    def set_members_type
      self.members_type = (member_ids.size == 2) ? 'only' : 'many'
    end

    def reset_unseen_member_ids
      ids = active_member_ids
      ids.delete(user_id)
      self.unseen_member_ids = ids
    end

    def update_unseen_member_ids
      dec_ids = member_ids_was - member_ids
      return if dec_ids.blank?
      self.unseen_member_ids = unseen_member_ids.reject { |id| dec_ids.include?(id) }
    end
end
