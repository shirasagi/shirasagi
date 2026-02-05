class Gws::Share::RecoverFileService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include SS::PermitParams

  attr_accessor :cur_site, :cur_user, :item

  attribute :name, :string
  attribute :folder_id, :integer

  permit_params :name, :folder_id

  validates :name, presence: true
  validates :folder_id, presence: true
  validate :validate_folder

  def call
    return false if invalid?

    item.name = name
    item.folder_id = folder_id
    item.deleted = nil

    result = item.without_record_timestamps do
      item.save
    end

    unless result
      SS::Model.copy_errors(item, self)
    end

    result
  end

  private

  def validate_folder
    criteria = Gws::Share::Folder.site(cur_site).where(id: folder_id)
    if criteria.blank?
      errors.add :folder_id, :not_found
    end
  end
end
