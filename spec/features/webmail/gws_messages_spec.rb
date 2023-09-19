require 'spec_helper'

describe "webmail_gws_messages", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:site) { user.root_groups.first }
  let(:role) { create :gws_role_admin, cur_site: site, cur_user: user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:item_texts) { [ "message-#{unique_id}", "message-#{unique_id}" ] }
  let(:messages_path) { gws_memo_messages_path(site: site.id, folder: "INBOX.Sent") }

  shared_examples "webmail gws messages flow" do
    context "with auth" do
      before do
        ActionMailer::Base.deliveries.clear

        gws_user = user.gws_user
        gws_user.add_to_set(gws_role_ids: [ role.id ])

        login_user(user)
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it "#show" do
        # new/create
        visit index_path
        wait_for_js_ready
        new_window = window_opened_by { click_on I18n.t('ss.links.new') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within "form#item-form" do
            fill_in "to", with: user.email + "\n"
            fill_in "item[subject]", with: item_title
            fill_in "item[text]", with: item_texts.join("\n")
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.to.first).to eq user.email
          expect(mail.subject).to eq item_title
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item_texts.join("\r\n"))
        end
        webmail_import_mail(user, ActionMailer::Base.deliveries.first)

        # reload mails
        visit index_path
        wait_for_js_ready
        click_link item_title
        wait_for_js_ready

        # forward
        new_window = window_opened_by { click_link I18n.t('webmail.links.forward_gws_message') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          wait_cbox_open { first('.gws-addon-memo-member .ajax-box').click }
          wait_for_cbox do
            wait_cbox_close { click_on user.name }
          end
          page.accept_alert I18n.t("ss.confirm.send") do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        visit gws_memo_messages_path(site: site, folder: 'INBOX.Sent')
        wait_for_js_ready
        expect(has_link?(item_title)).to be_truthy
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mails_path(account: 0) }

    it_behaves_like 'webmail gws messages flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

    before { user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail gws messages flow'
  end
end
