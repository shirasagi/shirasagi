module Webmail::Mail::Uids
  extend ActiveSupport::Concern

  module ClassMethods
    # Compress uids for uid_xxx command
    # @example
    #   '1,2,3,9' #=> [1..3, 9]
    # @param uids [Array] uid List
    # @return [Array] compressed uids
    def uids_compress(uids)
      prev = uids[0]
      uids.slice_before { |e|
        prev, prev2 = e, prev
        prev2 + 1 != e
      }.map { |b, *, c|
        c ? (b..c) : b
      }
    end

    # Counts the uids for Net::IMAP::ResponseCode#data
    # @example
    #   '1,2,5:7' #=> 5
    # @param uids [String] response code
    # @return [Integer] uids size
    def uids_size(uids)
      size = 0;
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
