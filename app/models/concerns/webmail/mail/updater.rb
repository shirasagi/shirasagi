module Webmail::Mail::Updater
  extend ActiveSupport::Concern

  def seen?
    flags.to_a.include?(:Seen)
  end

  def unseen?
    !seen?
  end

  def star?
    flags.to_a.include?(:Flagged)
  end

  def draft?
    flags.to_a.include?(:Draft)
  end

  def answerd?
    flags.to_a.include?(:Answered)
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

  def set_answered
    imap.conn.uid_store uid, '+FLAGS', [:Answered]
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
      return nil if uids.blank?
      imap.conn.uid_store uids, '+FLAGS', [:Seen]
    end

    def unset_seen(uids)
      return nil if uids.blank?
      imap.conn.uid_store uids, '-FLAGS', [:Seen]
    end

    def set_star(uids)
      return nil if uids.blank?
      imap.conn.uid_store uids, '+FLAGS', [:Flagged]
    end

    def unset_star(uids)
      return nil if uids.blank?
      imap.conn.uid_store uids, '-FLAGS', [:Flagged]
    end

    # @return [Net::IMAP::ResponseCode]
    #   <ResponseCode data="453719372 63,62 70:71">
    def uids_copy(uids, dst_mailbox)
      return nil if uids.blank?

      resp = imap.conn.uid_copy uids_compress(uids), dst_mailbox
      @imap_last_response_size = response_code_to_size(resp.data.code)
      resp
    end

    # @return [Array<Net::IMAP::FetchData>]
    #   <FetchData seqno=3, attr={"UID"=>95, "FLAGS"=>[:Flagged, :Seen]}>
    def uids_delete(uids)
      return nil if uids.blank?

      imap.select
      resp = imap.conn.uid_store uids_compress(uids), '+FLAGS', [:Deleted]
      imap.conn.expunge
      @imap_last_response_size = resp ? resp.size : 0

      self.where(imap.account_attributes).where(mailbox: imap.mailbox, :uid.in => uids).delete_all
      resp
    end

    # @return [Net::IMAP::FetchData]
    def uids_move(uids, dst_mailbox)
      return nil if uids.blank?
      resp = uids_copy(uids, dst_mailbox)
      resp ? uids_delete(uids) : nil
    end

    # @return [Net::IMAP::FetchData]
    def uids_move_trash(uids)
      trash = imap.user.imap_trash_box
      if imap.mailbox == trash
        uids_delete(uids)
      else
        uids_move(uids, trash)
      end
    end

    def imap_last_response_size
      @imap_last_response_size
    end

    # @param [Net::IMAP::ResponseCode] code
    # @return [Integer] count
    def response_code_to_size(code)
      return 0 unless code
      uids_size code.data.split(/ /)[2]
    end
  end
end
