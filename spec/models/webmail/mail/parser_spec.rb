require 'spec_helper'

describe Webmail::Mail::Parser do
  context "text mail" do
    subject(:item) { webmail_load_mail('text.yml') }

    it do
      expect(item.seen?).to be_truthy
      expect(item.unseen?).to be_falsey
      expect(item.star?).to be_truthy
      expect(item.draft?).to be_truthy
      expect(item.from).to eq ['"サイト管理者" <admin@example.jp>']
      expect(item.from).to eq item.to
      expect(item.from).to eq item.cc
      expect(item.from).to eq item.bcc
      expect(item.from).to eq item.reply_to
      expect(item.in_reply_to).to eq 'in_reply_to@localhost'
      expect(item.references).to eq ['reference@localhost']
      expect(item.display_size).to eq '1KB'
      expect(item.display_subject).to eq '件名'
      expect(item.display_sender).to eq 'admin@example.jp'
      expect(item.display_to).to eq ['サイト管理者']
      expect(item.display_to).to eq item.display_cc
      expect(item.display_to).to eq item.display_bcc
      expect(item.format).to eq 'text'
      expect(item.html?).to be_falsey
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_falsey
      expect(item.attachments?).to be_falsey
      expect(item.attachments.size).to eq 0
      expect(item.rfc822).to eq 'RFC822'
    end
  end

  context "html mail" do
    subject(:item) { webmail_load_mail('html.yml') }

    it do
      expect(item.seen?).to be_falsey
      expect(item.unseen?).to be_truthy
      expect(item.star?).to be_falsey
      expect(item.draft?).to be_falsey
      expect(item.from).to eq ['admin@example.jp']
      expect(item.from).to eq item.to
      expect(item.from).to eq item.cc
      expect(item.from).to eq item.bcc
      expect(item.display_subject).to eq '件名'
      expect(item.display_sender).to eq 'admin@example.jp'
      expect(item.display_to).to eq ['admin@example.jp']
      expect(item.display_to).to eq item.display_cc
      expect(item.display_to).to eq item.display_bcc
      expect(item.format).to eq 'html'
      expect(item.html?).to be_truthy
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_truthy
      expect(item.sanitize_html.present?).to be_truthy
      expect(item.sanitize_html.size).to be < item.html.size
    end
  end

  context "attachment mail" do
    subject(:item) { webmail_load_mail('attach.yml') }

    it do
      expect(item.format).to eq 'text'
      expect(item.html?).to be_falsey
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_falsey
      expect(item.attachments?).to be_truthy
      expect(item.attachments.size).to eq 1
    end
  end

  context "attachment part" do
    subject(:item) { webmail_load_mail('attach.yml').attachments[0] }

    it do
      expect(item.content_type).to eq 'image/png'
      expect(item.attachment?).to be_truthy
      expect(item.image?).to be_truthy
      expect(item.link_target).to eq '_blank'
      expect(item.filename).to eq '1px.png'
      expect(item.read.size).to be > 0
      expect(item.decoded.size).to be > 0
      expect(item.decoded.size).to be < item.read.size
    end
  end
end
