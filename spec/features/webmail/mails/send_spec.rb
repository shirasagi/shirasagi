require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:item_subject) { "subject-#{unique_id}" }
  let(:item_texts) { Array.new(rand(1..10)) { "message-#{unique_id}" } }

  shared_examples "webmail/mails send flow" do
    before do
      ActionMailer::Base.deliveries.clear
      login_user(user)
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      # send
      visit index_path
      click_link I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in "to", with: user.email + "\n"
        fill_in "item[subject]", with: item_subject
        fill_in "item[text]", with: item_texts.join("\n")
      end
      click_button I18n.t('ss.buttons.send')
      sleep 1
      expect(current_path).to eq index_path

      expect(ActionMailer::Base.deliveries).to have(1).items
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq address
        expect(mail.to.first).to eq user.email
        expect(mail.subject).to eq item_subject
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mails_path(account: 0) }
    let(:address) { user.email }

    it_behaves_like 'webmail/mails send flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }
    let(:address) { group.contact_email }

    before { user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail/mails send flow'
  end
end
