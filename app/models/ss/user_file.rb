# coding: utf-8
class SS::UserFile
  include SS::File::Model
  
  default_scope ->{ where(model: "ss/user_file") }
end
