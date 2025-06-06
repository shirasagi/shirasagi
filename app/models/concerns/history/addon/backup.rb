module History::Addon
  module Backup
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :skip_history_backup, :history_backup_action

      after_save :save_backup, if: -> { changes.present? || previous_changes.present? }
      after_destroy :transfer_backups_or_destroy
    end

    def backups
      # History::Backup.where(ref_coll: collection_name, "data._id" => id).sort(created: -1)
      # 作成日時の降順に並び替えたい。
      # 主キーがBSON::ObjectIDの場合、主キーの降順に並び替えるのとほぼ同義（厳密には異なるが）で、
      # そして、主キーの降順に並び替える方が効率が良い。
      History::Backup.where(ref_coll: collection_name, ref_id: id).reorder(id: -1)
    end

    def current_backup
      History::Backup.find_by(ref_coll: collection_name, ref_id: id, state: 'current') rescue nil
    end

    def before_backup
      History::Backup.find_by(ref_coll: collection_name, ref_id: id, state: 'before') rescue nil
    end

    private

    def save_backup
      return if @skip_history_backup

      max_age = History::Backup.max_age
      current = current_backup
      before = before_backup

      # add backup
      backup = History::Backup.new
      backup.user      = @cur_user
      backup.member    = @cur_member
      backup.ref_coll  = collection_name
      backup.ref_id    = id
      backup.ref_class = self.class.to_s
      backup.action = history_backup_action if history_backup_action.present?
      if self.class.relations.find { |k, relation| relation.instance_of?(Mongoid::Association::Embedded::EmbedsMany) }
        backup.data = self.class.find(id).attributes
      else
        backup.data = attributes
      end
      backup.host_info = {
        hostname: Rails.application.hostname,
        ip_address: Rails.application.ip_address,
        process_id: Process.pid
      }
      if Rails.application.current_request
        backup.request_info = {
          session_id: Rails.application.current_session_id,
          request_id: Rails.application.current_request_id,
          method: Rails.application.current_request.method,
          controller: (Rails.application.current_request.params[:controller] rescue nil),
          action: (Rails.application.current_request.params[:action] rescue nil),
        }
      end

      backup.state = 'current'
      current.state = 'before' if current
      before.state = nil if before

      backup.save
      if current
        # don't touch "updated"
        current.without_record_timestamps { current.save }
      end
      if before
        # don't touch "updated"
        before.without_record_timestamps { before.save }
      end

      # remove old backups
      backups.skip(max_age).destroy
    rescue => e
      # delete のタイミングで、別プロセス・別スレッドで保存を実行すると、履歴作成時にエラーになる場合がある。
      # タイミングが非常にシビアで再現性がないが、このケースに備えて発生したエラーをなかったことにする。
      Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    end

    def transfer_backups_or_destroy
      if @transfer_history_backup && (master = self.try(:master))
        backups.set(ref_id: master.id, ref_class: master.class.name)
      else
        backups.destroy_all
      end
    end
  end
end
