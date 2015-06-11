class SS::GroupFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/group_file") }
end
