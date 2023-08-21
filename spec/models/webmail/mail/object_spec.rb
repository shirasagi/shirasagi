require 'spec_helper'

describe Webmail::Mail, type: :model, dbscope: :example do
  context "text_mail" do
    subject(:item) { webmail_load_mail('text.yml') }

    it do
      expect(item.format_options[0][0]).to eq 'TEXT'
      expect(item.replied_mail).to eq nil
      expect(item.forwarded_mail).to eq nil
      expect(item.rfc822_path).to include 'webmail_files/'

      def item.rfc822_path
        "#{Rails.root}/tmp/webmail_rfc822"
      end

      expect(item.save_rfc822).to be_truthy
      expect(item.read_rfc822).to eq item.rfc822
      expect(item.destroy_rfc822).to be_truthy

      msg = OpenStruct.new(to: [])
      expect(item.validate_message(msg)).to be_falsey
    end
  end

  context "html_mail" do
    subject(:item) { webmail_load_mail('html.yml') }

    it do
      item.html = %(<html><style></style><script></script><img src="cid:"><b>b</b></html>)
      sanitize_html = item.sanitize_html

      expect(sanitize_html).not_to include '<style'
      expect(sanitize_html).not_to include '<script'
      expect(sanitize_html).to include '<img data-url'
      expect(sanitize_html).to include '<b>'
    end
  end
end
