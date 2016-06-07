module KeyVisual
  class Initializer
    Cms::Node.plugin "key_visual/image"
    Cms::Part.plugin "key_visual/slide"

    Cms::Role.permission :read_other_key_visual_images, module_name: "key_visual"
    Cms::Role.permission :read_private_key_visual_images, module_name: "key_visual"
    Cms::Role.permission :edit_other_key_visual_images, module_name: "key_visual"
    Cms::Role.permission :edit_private_key_visual_images, module_name: "key_visual"
    Cms::Role.permission :delete_other_key_visual_images, module_name: "key_visual"
    Cms::Role.permission :delete_private_key_visual_images, module_name: "key_visual"
  end
end
