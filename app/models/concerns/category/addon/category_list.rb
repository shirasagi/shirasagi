module Category::Addon
  module CategoryList
    extend ActiveSupport::Concern
    extend SS::Addon
    include ::Category::Addon::Model::List
  end
end
