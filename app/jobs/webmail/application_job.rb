class Webmail::ApplicationJob < SS::ApplicationJob
  after_perform :imap_disconnect

  private

  def imap_disconnect
    Webmail.imap_pool.disconnect_all
  end
end
