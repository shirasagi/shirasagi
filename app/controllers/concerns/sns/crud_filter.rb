module Sns::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter

  included do
    menu_view "ss/crud/menu"
  end
end
