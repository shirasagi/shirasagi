module Gws::Reference::Notice::Folder
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    belongs_to :folder, class_name: "Gws::Notice::Folder"
    validates :folder_id, presence: true
    permit_params :folder_id
  end
end
