class Cms::HistoryArchiveFile
  include SS::Model::File
  include SS::Reference::Site
  include Cms::SitePermission
  extend ActiveSupport::Concern

  set_permission_name "cms_tools", :use

  attr_accessor :cur_site, :cur_node, :request

  default_scope ->{ where(model: 'sys/history_archive_file') }

  def previewable?(opts = {})
    cur_user = opts[:user]
    if cur_user
      Cms::HistoryArchiveFile.allowed?(:read, cur_user)
    end
  end
end
