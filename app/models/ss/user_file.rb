class SS::UserFile
  include SS::Model::File
  include SS::UserPermission

  default_scope ->{ where(model: "ss/user_file") }
end
