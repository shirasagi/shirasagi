module Event::Addon
  module CalendarList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model
  end
end
