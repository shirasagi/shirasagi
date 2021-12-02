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

  def previewable?(site: nil, user: nil, member: nil)
    return false if !user

    self.allowed?(:read, user, site: site || @cur_site || self.site)
  end
end
