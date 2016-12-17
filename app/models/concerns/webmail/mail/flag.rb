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
    set_flags([:Seen])
  end

  def unset_seen
    unset_flags([:Seen])
  end

  def set_star
    set_flags([:Flagged])
  end

  def unset_star
    unset_flags([:Flagged])
  end

  def set_deleted
    set_flags([:Deleted])
  end

  def set_flags(values)
    self.flags ||= []
    self.flags = (self.flags + values.map(&:to_s)).uniq
    self.save if changed?
    imap.conn.uid_store(uid, '+FLAGS', values) # required symbole
  end

  def unset_flags(values)
    self.flags ||= []
    self.flags -= values.map(&:to_s)
    self.save if changed?
    imap.conn.uid_store(uid, '-FLAGS', values) # required symbole
  end
end
