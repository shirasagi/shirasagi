class Cms::Page::CheckLinks
  include Cms::Model::Page
  include Cms::Addon::GroupPermission
  include Cms::Addon::CheckLinks

  default_scope ->{ where(:check_links_errors.exists => true) }
end
