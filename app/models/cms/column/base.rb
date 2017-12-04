class Cms::Column::Base
  include SS::Document
  include SS::Model::Column
  include SS::Reference::Site

  store_in collection: 'cms_columns'
end
