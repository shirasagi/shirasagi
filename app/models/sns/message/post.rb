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

  after_save :set_thread_updated

  default_scope -> {
    order_by created: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    #criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  private
    def set_thread_updated
      thread.set updated: updated
    end
end
