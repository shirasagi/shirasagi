class SS::UserFile
  include SS::Model::File
  include SS::UserPermission
  include Cms::Lgwan::File

  default_scope ->{ where(model: "ss/user_file") }
end
