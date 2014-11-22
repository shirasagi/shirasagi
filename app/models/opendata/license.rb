class Opendata::License
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include SS::Relation::File
  include Cms::Addon::OwnerPermission

  set_permission_name :opendata_datasets

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :related_url, type: String
  field :order, type: Integer, default: 0

  belongs_to_file :file

  permit_params :state, :name, :related_url, :order, file_ids: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  def state_options
    [%w(公開 public), %w(非公開 closed)]
  end

  class << self
    public
      def public
        where(state: "public")
      end
  end
end
