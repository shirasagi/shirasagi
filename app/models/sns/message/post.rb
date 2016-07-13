class Sns::Message::Post
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  field :text, type: String

  belongs_to :thread, class_name: "Sns::Message::Thread"
  embeds_ids :seen_members, class_name: "SS::User"

  permit_params :text

  validates :user_id, presence: true
  validates :thread_id, presence: true
  validates :text, presence: true

  after_save :set_thread_updated, if: -> { @cur_user.present? }

  default_scope -> {
    order_by created: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :text if params[:keyword].present?
    criteria
  }

  def set_seen(user)
    return if seen_member_ids.include?(user.id)
    #dump seen_member_ids.push(user.id)
    #self.set seen_member_ids: seen_member_ids.push(user.id)
    self.add_to_set seen_member_ids: user.id
  end

  private
    def set_thread_updated
      thread.activate_members if thread.active_member_ids.size == 1
      thread.reset_unseen(@cur_user)
    end
end
