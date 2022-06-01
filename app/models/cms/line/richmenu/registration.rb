class Cms::Line::Richmenu::Registration
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_line_services", :use

  field :line_richmenu_id, type: String
  field :line_richmenu_alias_id, type: String
  field :linked_user_ids, type: Array, default: []
  belongs_to :menu, class_name: "Cms::Line::Richmenu::Menu"

  validates :line_richmenu_id, presence: true
  validates :line_richmenu_alias_id, presence: true
  validates :menu_id, presence: true
end
