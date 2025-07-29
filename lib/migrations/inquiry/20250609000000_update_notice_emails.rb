class SS::Migration20250609000000
  include SS::Migration::Base

  def change
    ids = Inquiry::Node::Form.pluck(:id)
    ids.each do |id|
      node = Inquiry::Node::Form.find(id) rescue nil
      next unless node

      notice_email = node[:notice_email]
      if node.notice_emails.blank? && notice_email.present?
        node.set(notice_emails: [notice_email])
      end
    end
  end
end
