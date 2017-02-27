module Webmail::Imap::UidsCommand
  extend ActiveSupport::Concern

  module ClassMethods
    def uids_set_seen(uids)
      return nil if uids.blank?
      conn.uid_store uids, '+FLAGS', [:Seen]
    end

    def uids_unset_seen(uids)
      return nil if uids.blank?
      conn.uid_store uids, '-FLAGS', [:Seen]
    end

    def uids_set_star(uids)
      return nil if uids.blank?
      conn.uid_store uids, '+FLAGS', [:Flagged]
    end

    def uids_unset_star(uids)
      return nil if uids.blank?
      conn.uid_store uids, '-FLAGS', [:Flagged]
    end

    # @return [Net::IMAP::ResponseCode]
    #   <ResponseCode data="453719372 63,62 70:71">
    def uids_copy(uids, dst_mailbox)
      return nil if uids.blank?

      resp = conn.uid_copy uids_compress(uids), dst_mailbox
      @last_response_size = response_code_to_size(resp.data.code)
      resp
    end

    # @return [Array<Net::IMAP::FetchData>]
    #   <FetchData seqno=3, attr={"UID"=>95, "FLAGS"=>[:Flagged, :Seen]}>
    def uids_delete(uids)
      return nil if uids.blank?

      select
      resp = conn.uid_store uids_compress(uids), '+FLAGS', [:Deleted]
      conn.expunge
      @last_response_size = resp ? resp.size : 0

      Webmail::Mail.where(account_scope).where(mailbox: mailbox, :uid.in => uids).delete_all
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
      if mailbox == trash_box
        uids_delete(uids)
      else
        uids_move(uids, trash_box)
      end
    end

    def last_response_size
      @last_response_size
    end

    # @param [Net::IMAP::ResponseCode] code
    # @return [Integer] count
    def response_code_to_size(code)
      return 0 unless code
      uids_size code.data.split(/ /)[2]
    end

    # Compress uids for uid_xxx command
    #
    # @example
    #   '1,2,3,9' #=> [1..3, 9]
    #
    # @param [Array] uids
    # @return [Array] compressed uids
    def uids_compress(uids)
      prev = uids[0]
      uids = uids.slice_before do |e|
        prev2 = prev
        prev = e
        prev2 + 1 != e
      end
      uids.map do |b, *, c|
        c ? (b..c) : b
      end
    end

    # Counts the uids
    #
    # @example
    #   '1,2,5:7' #=> 5
    #
    # @param [String] uids Net::IMAP::ResponseCode#data
    # @return [Integer] uids size
    def uids_size(uids)
      size = 0
      uids.split(/,/).each do |uid|
        if uid =~ /:/
          arr = uid.split(/:/)
          size += arr[1].to_i - arr[0].to_i + 1
        else
          size += 1
        end
      end
      size
    end
  end
end
