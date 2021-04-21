module History::Addon
  module Trash
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :skip_history_trash
      before_destroy :create_history_trash, if: ->{ !@skip_history_trash }
    end

    private

    def create_history_trash
      backup = History::Trash.new
      backup.ref_coll = collection_name
      backup.ref_class = self.class.to_s
      backup.data = attributes
      backup.site = self.site if respond_to?(:site)
      backup.user = @cur_user
      backup.save
    end
  end
end
