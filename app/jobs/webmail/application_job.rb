class Webmail::ApplicationJob < SS::ApplicationJob
  after_perform :imap_disconnect

  private

  def imap_disconnect
    Webmail.disconnect_all_imap
  end
end
