class Gws::File
  include SS::Model::File
  include Gws::Reference::Site

  default_scope ->{ where(model: 'gws/file') }
end
