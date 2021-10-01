module History::Addon
  module Backup
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :skip_history_backup, :history_backup_action
      after_save :save_backup, if: -> { @db_changes.present? }
      before_destroy :destroy_backups
    end

    def backups
      History::Backup.where(ref_coll: collection_name, "data._id" => id).sort(created: -1)
    end

    def current_backup
      History::Backup.find_by(ref_coll: collection_name, "data._id" => id, state: 'current') rescue nil
    end

    def before_backup
      History::Backup.find_by(ref_coll: collection_name, "data._id" => id, state: 'before') rescue nil
    end

    private

    def save_backup
      return if @skip_history_backup

      max_age = History::Backup.max_age
      current = current_backup
      before = before_backup

      # add backup
      backup = History::Backup.new
      backup.user_id   = @cur_user.id if @cur_user
      backup.ref_coll  = collection_name
      backup.ref_class = self.class.to_s
      backup.action = history_backup_action if history_backup_action.present?
      if self.class.relations.find { |k, relation| relation.instance_of?(Mongoid::Association::Embedded::EmbedsMany) }
        backup.data = self.class.find(id).attributes
      else
        backup.data = attributes
      end

      backup.state     = 'current'
      current.state = 'before' if current
      before.state = nil if before

      backup.save
      current.update if current
      before.update if before

      # remove old backups
      backups.skip(max_age).destroy
    end

    def destroy_backups
      backups.destroy
    end
  end
end
