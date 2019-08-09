class Rss::TempFile
  include SS::Model::File
  include SS::UserPermission

  store_in_repl_master
  default_scope ->{ where(model: 'rss/temp_file') }
end
