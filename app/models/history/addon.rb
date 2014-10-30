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
        max_age = History::Backup.max_age

        # add backup
        backup = History::Backup.new
        backup.user_id   = @cur_user.id if @cur_user
        backup.ref_coll  = collection_name
        backup.ref_class = self.class.to_s
        backup.data      = attributes
        backup.save

        # remove old backups
        backups.skip(max_age).destroy
      end

      def destroy_backups
        backups.destroy
      end
  end
end
