require 'spec_helper'

describe Webmail::Mail::Parser do
  let(:item) { Webmail::Mail.new }

  context "text mail" do
    before do
      item.size = 1024
      item.header = File.open(Rails.root / 'spec/fixtures/webmail/mail/text.txt').read
      item.parse_header
    end

    it do
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
      expect(item.attachments?).to eq false
      expect(item.html?).to eq false
    end
  end

  context "html mail" do
    before do
      item.header = File.open(Rails.root / 'spec/fixtures/webmail/mail/html.txt').read
      item.parse_header
    end

    it do
      expect(item.from).to eq ['admin@example.jp']
      expect(item.from).to eq item.to
      expect(item.from).to eq item.cc
      expect(item.from).to eq item.bcc
      expect(item.display_subject).to eq '件名'
      expect(item.display_sender).to eq 'admin@example.jp'
      expect(item.display_to).to eq ['admin@example.jp']
      expect(item.display_to).to eq item.display_cc
      expect(item.display_to).to eq item.display_bcc
      expect(item.attachments?).to eq false
      expect(item.html?).to eq false
    end
  end

  context "text mail with attachments" do
    before do
      item.header = File.open(Rails.root / 'spec/fixtures/webmail/mail/file.txt').read
      item.parse_header
    end

    it do
      expect(item.attachments?).to eq true
    end
  end
end
