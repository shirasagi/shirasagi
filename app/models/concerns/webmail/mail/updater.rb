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
end
