require 'spec_helper'

describe Webmail::Imap, type: :model, dbscope: :example do
  let(:user) { create :webmail_user }
  subject(:imap) { Webmail::Imap }

  it do
    expect(imap.set_user(user)).to eq imap
    expect(imap.special_mailboxes.is_a?(Array)).to be_truthy
    expect(imap.sent_box).to eq user.imap_sent_box
    expect(imap.draft_box).to eq user.imap_draft_box
    expect(imap.trash_box).to eq user.imap_trash_box
    expect(imap.sent_box?(imap.sent_box.to_s)).to be_truthy
    expect(imap.sent_box?("#{imap.sent_box}.a")).to be_truthy
    expect(imap.sent_box?("#{imap.sent_box}xx.a")).to be_falsey
    expect(imap.mails.class).to eq Webmail::Imap::Mail
    expect(imap.mailboxes.class).to eq Webmail::Imap::Mailboxes
    expect(imap.quota.class).to eq Webmail::Imap::Quota
  end
end
