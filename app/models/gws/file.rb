class Gws::File
  include SS::Model::File
  include Gws::Reference::Site
  include Cms::Lgwan::File

  default_scope ->{ where(model: 'gws/file') }
end
