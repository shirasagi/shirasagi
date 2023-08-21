module SS::Addon
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Release
  end
end
