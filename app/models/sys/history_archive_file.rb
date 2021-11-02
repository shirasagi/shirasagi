class Sys::HistoryArchiveFile
  include Sys::Permission
  include SS::Model::File
  extend ActiveSupport::Concern

  set_permission_name "sys_users", :edit

  attr_accessor :cur_site, :cur_node, :request

  default_scope ->{ where(model: 'sys/history_archive_file') }
  default_scope ->{ order_by filename: -1 }

  def previewable?(opts = {})
    cur_user = opts[:user]
    if cur_user
      Sys::HistoryArchiveFile.allowed?(:read, cur_user)
    end
  end
end
