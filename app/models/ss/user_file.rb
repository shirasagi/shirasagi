# frozen_string_literal: true

class SS::UserFile
  include SS::Model::File
  include SS::UserPermission
  include Cms::Lgwan::File

  FILE_MODEL = "ss/user_file"

  default_scope ->{ where(model: FILE_MODEL) }
end
