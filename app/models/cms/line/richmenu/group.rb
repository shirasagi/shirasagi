module Cms::Line::Richmenu
  class Group
    include Cms::Model::Line::ServiceGroup
    include Cms::Addon::Line::Richmenu::Menu
    set_permission_name "cms_line_services", :use
  end
end
