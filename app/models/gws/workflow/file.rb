class Gws::Workflow::File
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include ::Workflow::Addon::Approver
  include SS::Addon::Markdown
  include Gws::Addon::GroupPermission

  cattr_reader(:approver_user_class) { Gws::User }

  seqid :id
  field :state, type: String, default: "closed"
  field :name, type: String

  permit_params :state, :name

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  public
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
