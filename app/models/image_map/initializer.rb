module ImageMap
  class Initializer
    Cms::Node.plugin "image_map/page"
    Cms::Part.plugin "image_map/page"

    Cms::Role.permission :read_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :read_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :edit_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :edit_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :delete_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :delete_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :release_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :release_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :approve_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :approve_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :reroute_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :reroute_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :revoke_other_image_map_pages, module_name: "image_map"
    Cms::Role.permission :revoke_private_image_map_pages, module_name: "image_map"
    Cms::Role.permission :unlock_other_image_map_pages, module_name: "image_map"

    SS::File.model "image_map/page", SS::File
  end
end
