class SS::GroupFile
  include SS::File::Model

  default_scope ->{ where(model: "ss/group_file") }
end
