module Member::Addon
  module BookmarkList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def sort_hash
      { updated: -1 }
    end
  end
end
