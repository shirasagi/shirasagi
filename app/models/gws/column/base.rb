class Gws::Column::Base
  include SS::Document
  include SS::Model::Column
  include Gws::Reference::Site

  store_in collection: 'gws_columns'
end
