module Gws::Reference::Notice::Folder
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    belongs_to :folder, class_name: "Gws::Notice::Folder"
    validates :folder_id, presence: true
    permit_params :folder_id
  end

  def folder_was
    return if folder_id_was.blank?
    Gws::Notice::Folder.site(site).find(folder_id_was) rescue nil
  end
end
