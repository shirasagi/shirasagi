class SS::Migration20190830000000
  include SS::Migration::Base

  depends_on "20190809000000"

  def change
    Member::Node::Registration.each do |node|
      next unless node.site

      attr = {}
      subject = node[:subject]
      if subject.present? && node.reply_subject.blank?
        attr[:reply_subject] = subject
      end

      signature = []
      signature << node[:reply_signature]
      signature << node[:reset_password_signature]
      signature = signature.select(&:present?).join("\n")
      if signature.present? && node.sender_signature.blank?
        attr[:sender_signature] = signature
      end

      next if attr.blank?
      node.attributes = attr
      node.without_record_timestamps { node.save }
    end
  end
end
