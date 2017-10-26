class Gws::Workflow::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Reminder
  include ::Workflow::Addon::Approver
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Workflow::CustomForm
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

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::WorkflowFileJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::WorkflowFileJob.callback

  default_scope -> {
    order_by updated: -1
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria = criteria.search_state(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_state(params)
      return all if params[:state].blank? || params[:cur_user].blank?

      cur_user = params[:cur_user]
      case params[:state]
      when 'approve'
        all.where(
          workflow_state: 'request',
          workflow_approvers: { '$elemMatch' => { 'user_id' => cur_user.id, 'state' => "request" } }
        )
      when 'request'
        all.where(workflow_user_id: cur_user.id)
      else
        all
      end
    end
  end

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

  def editable?(user, opts)
    editable = allowed?(:edit, user, opts) && !workflow_requested?
    return editable if editable

    if workflow_requested?
      workflow_approver_editable?(user)
    end
  end

  def destroyable?(user, opts)
    allowed?(:delete, user, opts) && !workflow_requested?
  end

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    ret = super
    options = ret.extract_options!
    options[:state] = 'all'
    [ *ret, options ]
  end
end
