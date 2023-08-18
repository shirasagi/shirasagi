class Cms::InitColumn
  include SS::Document
  include SS::Model::InitColumn
  include SS::Reference::Site

  store_in collection: 'cms_init_columns'
end
