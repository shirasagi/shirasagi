module History::Addon
  module Backup
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 650

    included do
      after_save :save_backup, if: -> { @db_changes.present? }
      before_destroy :destroy_backups
    end

    public
      def backups
        History::Backup.where(ref_coll: collection_name, "data._id" => id).sort(created: -1)
      end

    private
      def save_backup
        # add backup
        backup = History::Backup.new
        backup.ref_coll = collection_name
        backup.data = attributes
        backup.save

        # remove old backups
        backups.skip(History::Backup.max_age).destroy
      end

      def destroy_backups
        backups.destroy
      end
  end
end
