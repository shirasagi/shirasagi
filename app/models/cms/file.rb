class Cms::File
  include SS::Model::File
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  attr_accessor :cur_group

  before_validation :set_group, if: ->{ cur_group }

  default_scope ->{ where(model: "cms/file") }

  private

  def set_group
    return if group_ids.present?
    self.group_ids = [cur_group.id]
  end

  public

  def allowed?(action, user, opts = {})
    opts[:owned] = true if new_record?
    super(action, user, opts)
  end

  def previewable?(opts = {})
    cur_user = opts[:user]
    return false if !cur_user

    self.allowed?(:read, cur_user, site: @cur_site || self.site)
  end
end
