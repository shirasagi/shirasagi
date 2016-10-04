require "net/imap"
class Webmail::Imap
  def imap
    @imap
  end

  def login(user)
    @imap = Net::IMAP.new(user.imap_host)

    begin
      @imap.authenticate('LOGIN', user.imap_account, user.imap_password)
      @logged_in = true
    rescue Net::IMAP::NoResponseError
      @logged_in = false
    end

    initialize_criteria
    @logged_in
  end

  def logged_in?
    @logged_in == true
  end

  def mailboxes
    return @mailboxes if @mailboxes

    list = @imap.list('INBOX', '*')
    return [] unless list
    @mailboxes = list.map { |box| Webmail::Mailbox.new(box) }.sort { |a, b| a.basename <=> b.basename }
  end

  def mailbox(mailbox)
    @mailbox = mailbox
    return self
  end

  def initialize_criteria
    # RECENT UNSEEN SEEN UNDELETED
    @criteria = ['UNDELETED']
    @sort = ['REVERSE', 'DATE']
    @page = 1
    @limit = 5
  end

  def where(condition)
    @criteria = condition
    return self
  end

  def sort(condition)
    @sort = condition
    return self
  end

  def page(count)
    @page = count.present? ? count.to_i : 1
    return self
  end

  def per(count)
    @limit = count.to_i
    return self
  end

  def list_fields
    %w(UID ENVELOPE FLAGS RFC822.SIZE)
  end

  def find_fields
    # ALL - FLAGS INTERNALDATE RFC822.SIZE ENVELOPE
    # RFC822 RFC822.TEXT BODY BODY.PEEK[TEXT])
    %w(ALL UID RFC822)
  end

  def mails
    @imap.examine(@mailbox)
    mids = imap.sort(@sort, @criteria, 'UTF-8')
    size = mids.size

    items = []
    mids = mids.slice((@page - 1) * @limit, @limit) || []
    mids.each do |mid|
      msg = @imap.fetch(mid, list_fields)[0]
      items << Webmail::Mail.new_message(msg, @imap)
    end
    items

    Kaminari.paginate_array(items, total_count: size).page(@page).per(@limit)
  end

  def find(uid)
    @imap.examine(@mailbox)

    msg = @imap.uid_fetch(uid.to_i, find_fields)[0]
    Webmail::Mail.new_message(msg, @imap)
  end
end