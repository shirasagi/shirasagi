module SS::Reference
  module UserOccupations
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Model::Reference::UserOccupations
  end
end
