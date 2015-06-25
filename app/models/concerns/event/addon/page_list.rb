module Event::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model
  end
end
