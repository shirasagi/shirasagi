class Gws::Share::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  #include SS::UserPermission
  include Gws::Addon::File
  include Gws::Share::DescendantsFileInfo

  store_in collection: :gws_share_folders

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  has_many :files, class_name: "Gws::Share::File", order: { created: -1 }, dependent: :destroy

  permit_params :name, :order

  validates :name, presence: true, uniqueness: { scope: :site_id }

  default_scope ->{ order_by order: 1 }

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end
end
