require "net/imap"
class Webmail::Mailbox
  attr_reader :name, :basename, :original_name, :depth

  def initialize(mailboxlist)
    original_names = mailboxlist.name.split(mailboxlist.delim)
    names = original_names.map { |n| Net::IMAP.decode_utf7(n) }

    @original_name = mailboxlist.name
    @name = names.join('.')
    @basename = names.last
    @depth = names.size - 2
  end
end