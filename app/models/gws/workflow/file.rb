class Gws::Workflow::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Reminder
  include ::Workflow::Addon::Approver
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  cattr_reader(:approver_user_class) { Gws::User }

  seqid :id
  field :state, type: String, default: "closed"
  field :name, type: String

  permit_params :state, :name

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> {
    order_by updated: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  def reminder_user_ids
    ids = [@cur_user.id, user_id]
    ids << workflow_user_id
    ids += workflow_approvers.map { |m| m[:user_id] }
    ids.uniq.compact
  end

  def status
    if state == "approve"
      state
    elsif workflow_state.present?
      workflow_state
    elsif state == "closed"
      'draft'
    else
      state
    end
  end
end
