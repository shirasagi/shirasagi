class Sys::HistoryArchiveFile
  include Sys::Permission
  include SS::Model::File
  include SS::Reference::Site
  extend ActiveSupport::Concern

  set_permission_name "sys_users", :edit

  #Cms::HistoryArchiveFile用
  # set_permission_name "cms_tools", :use

  attr_accessor :cur_site, :cur_node, :request

  default_scope ->{ where(model: 'sys/history_archive_file') }

  def previewable?(opts = {})
    cur_user = opts[:user]
    if cur_user
      Sys::HistoryArchiveFile.allowed?(:read, cur_user)
    end
  end
end
