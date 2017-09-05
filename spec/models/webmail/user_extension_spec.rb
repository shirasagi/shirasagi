require 'spec_helper'

describe Webmail::UserExtension, type: :model, dbscope: :example do
  subject(:user) { create :webmail_user }

  context "blank settings" do
    it do
      expect(user.imap_default_settings.is_a?(Hash)).to be_truthy
      expect(user.imap_settings.is_a?(Hash)).to be_truthy
      expect(user.imap_auth_type_options.is_a?(Array)).to be_truthy
      expect(user.imap_sent_box).to eq 'INBOX.Sent'
      expect(user.imap_draft_box).to eq 'INBOX.Draft'
      expect(user.imap_trash_box).to eq 'INBOX.Trash'
      expect(user.imap_password).to eq SS::Crypt.encrypt(user.decrypt_imap_password)
    end
  end

  context "changed settings" do
    before do
      user.imap_sent_box = 'INBOX.Sent2'
      user.imap_draft_box = 'INBOX.Draft2'
      user.imap_trash_box = 'INBOX.Trash2'
    end

    it do
      expect(user.imap_sent_box).to eq 'INBOX.Sent2'
      expect(user.imap_draft_box).to eq 'INBOX.Draft2'
      expect(user.imap_trash_box).to eq 'INBOX.Trash2'
    end
  end
end
