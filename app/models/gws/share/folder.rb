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
  field :share_max_file_size, type: Integer, default: 0
  attr_accessor :in_share_max_file_size_mb

  has_many :files, class_name: "Gws::Share::File", order: { created: -1 }, dependent: :destroy

  permit_params :name, :order, :share_max_file_size, :in_share_max_file_size_mb

  before_validation :set_share_max_file_size

  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :share_max_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

  default_scope ->{ order_by order: 1 }

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end

  private

  def set_share_max_file_size
    return if in_share_max_file_size_mb.blank?
    self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
  end
end
