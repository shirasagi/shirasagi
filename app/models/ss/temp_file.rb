class SS::TempFile
  include SS::File::Model

  default_scope ->{ where(model: "ss/temp_file") }
end
