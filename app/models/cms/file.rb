class Cms::File
  include SS::Model::File
  include SS::Reference::Site
  include Cms::Addon::GroupPermission
  include Cms::Lgwan::File

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
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id

    self.allowed?(:read, user, site: site)
  end
end
