class SS::UserFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/user_file") }
end
