module Guidance
  class Initializer
    Cms::Node.plugin "guidance/guide"

    Cms::Role.permission :read_other_guidance_results
    Cms::Role.permission :read_private_guidance_results
    Cms::Role.permission :edit_other_guidance_results
    Cms::Role.permission :edit_private_guidance_results
    Cms::Role.permission :delete_other_guidance_results
    Cms::Role.permission :delete_private_guidance_results
  end
end
