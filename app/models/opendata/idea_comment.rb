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
