class Sys::HistoryArchiveFile
  include Sys::Permission
  include SS::Model::File
  include Cms::Lgwan::File
  extend ActiveSupport::Concern

  set_permission_name "sys_users", :edit

  attr_accessor :cur_site, :cur_node, :request

  default_scope ->{ where(model: 'sys/history_archive_file') }
  default_scope ->{ order_by filename: -1 }

  def previewable?(site: nil, user: nil, member: nil)
    if user
      Sys::HistoryArchiveFile.allowed?(:read, user)
    end
  end
end
