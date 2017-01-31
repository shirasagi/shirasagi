module Webmail::Mail::Flag
  extend ActiveSupport::Concern

  def seen?
    flags.to_a.include?('Seen')
  end

  def unseen?
    !seen?
  end

  def star?
    flags.to_a.include?('Flagged')
  end

  def draft?
    flags.to_a.include?('Draft')
  end

  def answerd?
    flags.to_a.include?('Answered')
  end

  def set_seen
    imap.conn.uid_store uid, '+FLAGS', [:Seen]
  end

  def unset_seen
    imap.conn.uid_store uid, '-FLAGS', [:Seen]
  end

  def set_star
    imap.conn.uid_store uid, '+FLAGS', [:Flagged]
  end

  def unset_star
    imap.conn.uid_store uid, '-FLAGS', [:Flagged]
  end

  def set_deleted
    imap.select
    imap.conn.uid_store uid, '+FLAGS', [:Deleted]
    imap.conn.expunge
  end

  def copy(mailbox)
    imap.conn.uid_copy(uid, mailbox)
  end

  def move(mailbox)
    imap.conn.uid_copy(uid, mailbox)
    sync.destroy
  end

  def move_trash
    trash = imap.user.imap_trash_box
    return move(trash) if mailbox != trash
    sync.destroy
  end

  class_methods do
    def set_seen(uids)
      return [] if uids.blank?
      imap.conn.uid_store uids, '+FLAGS', [:Seen] || []
    end

    def unset_seen(uids)
      return [] if uids.blank?
      imap.conn.uid_store uids, '-FLAGS', [:Seen] || []
    end

    def set_star(uids)
      return [] if uids.blank?
      imap.conn.uid_store uids, '+FLAGS', [:Flagged] || []
    end

    def unset_star(uids)
      return [] if uids.blank?
      imap.conn.uid_store uids, '-FLAGS', [:Flagged] || []
    end

    def uids_delete(uids)
      return [] if uids.blank?
      imap.select
      resp = imap.conn.uid_store uids, '+FLAGS', [:Deleted] || []
      uids = resp.map { |r| r.attr['UID'] }
      imap.conn.expunge

      self.where(imap.cache_key).where(mailbox: imap.mailbox, :uid.in => uids).destroy_all
      resp
    end

    def uids_copy(uids, dst_mailbox)
      return [] if uids.blank?
      resp = imap.conn.uid_copy(uids, dst_mailbox)
      code = resp.data.code #ex. <struct Net::IMAP::ResponseCode data="453719372 63,62 70:71">
      return [] unless code

      uids = code.data.split(/ /)[1].split(/,/).presence || []
      uids.map(&:to_i)
    end

    def uids_move(uids, dst_mailbox)
      return [] if uids.blank?
      resp = uids_copy(uids, dst_mailbox)
      uids_delete(resp)
    end

    def uids_move_trash(uids)
      trash = imap.user.imap_trash_box
      return uids_move(uids, trash) if imap.mailbox != trash
      uids_delete(uids)
    end

    private
      def uids_update(uids, &block)
        resp = uids.map do |uid|
          begin
            yield uid = uid.to_i
            uid
          rescue Net::IMAP::NoResponseError
            nil
          end
        end
        resp.compact
      end
    end
end
