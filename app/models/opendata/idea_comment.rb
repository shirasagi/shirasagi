class Opendata::IdeaComment
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Opendata::Addon::Workflow::IdeaCommentApprover
  include Contact::Addon::Page
  include Opendata::Reference::Member
  include Opendata::AllowableAny
  include Workflow::MemberPermission

  field :idea_id, type: Integer
  field :name, type: String
  field :text, type: String
  field :comment_deleted, type: DateTime
  field :state, type: String

  belongs_to :idea, class_name: "Opendata::Idea"

  permit_params :name, :text, :comment_deleted, :state

  validates :site_id, presence: true
  validates :idea_id, presence: true
  validates :text, presence: true, length: { maximum: 400 }

  def get_member_name
    if member
      name = member.name
    elsif contact_group
      name = contact_group.name.sub(/.*\//, "")
    elsif user && user.groups && user.groups.present?
      name = user.groups.first.name
    else
      name = I18n.t("opendata.labels.guest_user")
    end

    return name
  end

  def owned?(user)
    idea.owned(user)
  end

  def allowed?(action, user, opts = {})
    if idea
      opts[:site] ||= idea.site
      idea.allowed?(action, user, opts)
    else
      Opendata::Idea.allowed?(action, user, opts)
    end
  end

  def state_options
    [
      [I18n.t('views.options.state.public'), 'public'],
      [I18n.t('views.options.state.closed'), 'closed'],
    ]
  end

  class << self
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.where(text: /#{params[:keyword]}/) if params[:keyword].present?
        criteria = search_poster(params, criteria)
      end

      def search_poster(params, criteria)
        if params[:poster].present?
          code = {}
          cond = { :workflow_member_id.exists => true } if params[:poster] == "member"
          cond = { :workflow_member_id => nil } if params[:poster] == "admin"
          criteria = criteria.where(cond)
        end
        criteria
      end

      def allow(action, user, opts = {})
        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
        ids = Opendata::Idea.where(site_id: site_id).allow(action, user, opts).map(&:id)
        self.in(idea_id: ids)
      end
  end
end
