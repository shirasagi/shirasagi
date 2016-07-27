class Opendata::IdeaComment
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Contact::Addon::Page
  include Opendata::Reference::Member
  include Opendata::AllowableAny

  field :idea_id, type: Integer
  field :name, type: String
  field :text, type: String
  field :comment_deleted, type: DateTime

  belongs_to :idea, class_name: "Opendata::Idea"

  permit_params :name, :text, :comment_deleted

  validates :site_id, presence: true
  validates :idea_id, presence: true
  validates :text, presence: true, length: { maximum: 400 }

  public
    def get_member_name
      if member
        name = member.name
      elsif contact_group
        name = contact_group.name.sub(/.*\//, "")
      elsif user && user.groups && user.groups.size > 0
        name = user.groups.first.name
      else
        name = I18n.t("opendata.labels.guest_user")
      end

      return name
    end

  class << self
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.where(text: /#{params[:keyword]}/) if params[:keyword].present?
        criteria
      end

  end
end
