require 'spec_helper'

describe Webmail::UserExtension, type: :model, dbscope: :example do
  let(:user) { create :webmail_user }
  let(:setting) { user.imap_settings.first }

  context "blank settings" do
    it do
      expect(user.imap_default_settings.is_a?(Hash)).to be_truthy
      expect(user.imap_auth_type_options.is_a?(Array)).to be_truthy
      expect(setting.imap_settings.is_a?(Hash)).to be_truthy
      expect(setting.imap_sent_box).to eq 'INBOX.Sent'
      expect(setting.imap_draft_box).to eq 'INBOX.Draft'
      expect(setting.imap_trash_box).to eq 'INBOX.Trash'
      expect(setting.imap_password).to eq SS::Crypt.encrypt(setting.decrypt_imap_password)
    end
  end

  context "changed settings" do
    before do
      setting[:imap_sent_box] = 'INBOX.Sent2'
      setting[:imap_draft_box] = 'INBOX.Draft2'
      setting[:imap_trash_box] = 'INBOX.Trash2'
    end

    it do
      expect(setting.imap_sent_box).to eq 'INBOX.Sent2'
      expect(setting.imap_draft_box).to eq 'INBOX.Draft2'
      expect(setting.imap_trash_box).to eq 'INBOX.Trash2'
    end
  end

  describe "#initialize_imap" do
    context "with account 0" do
      subject { user.initialize_imap(0) }

      it do
        expect(subject).to be_present
        expect(subject.address).to eq user.imap_default_settings[:address]
        expect(subject.email_address).to eq "#{user.name} <#{user.imap_default_settings[:address]}>"
        expect(subject.sent_box).to eq "INBOX.Sent"
        expect(subject.draft_box).to eq "INBOX.Draft"
        expect(subject.trash_box).to eq "INBOX.Trash"

        subject.email_address = %(#{user.name}'" <#{user.imap_default_settings[:address]}>)
        expect(subject.quote_email_address).to eq %("#{user.name}" <#{user.imap_default_settings[:address]}>)
      end
    end

    context "with account 1" do
      subject { user.initialize_imap(user.imap_settings.length) }

      it do
        expect(subject).to be_blank
      end
    end
  end
end
