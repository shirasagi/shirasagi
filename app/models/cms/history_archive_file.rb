class Cms::HistoryArchiveFile
  include SS::Model::File
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::Lgwan::File
  extend ActiveSupport::Concern

  set_permission_name "cms_tools", :use

  attr_accessor :cur_site, :cur_node, :request

  default_scope ->{ where(model: 'sys/history_archive_file') }
  default_scope ->{ order_by filename: -1 }

  def previewable?(site: nil, user: nil, member: nil)
    return false if !user
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id

    Cms::HistoryArchiveFile.allowed?(:read, user, site: site)
  end
end
