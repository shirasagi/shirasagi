class Sns::Message::Post
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  field :text, type: String

  belongs_to :thread, class_name: "Sns::Message::Thread"

  permit_params :text

  validates :user_id, presence: true
  validates :thread_id, presence: true
  validates :text, presence: true

  after_save :update_thread, if: -> { @cur_user.present? }

  default_scope -> {
    order_by created: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :text if params[:keyword].present?
    criteria
  }

  private
    def update_thread
      thread.activate_members if thread.active_member_ids.size == 1
      thread.post_created(@cur_user)
    end
end
