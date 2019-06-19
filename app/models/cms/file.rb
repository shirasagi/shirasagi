class Cms::File
  include SS::Model::File
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  default_scope ->{ where(model: "cms/file") }

  def previewable?(opts = {})
    cur_user = opts[:user]
    return false if !cur_user

    self.allowed?(:read, cur_user, site: @cur_site || self.site)
  end
end
