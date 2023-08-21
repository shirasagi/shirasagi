module SS::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Model::Reference::UserTitles
  end
end
