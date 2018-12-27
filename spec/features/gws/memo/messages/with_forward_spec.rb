require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  context 'when a message save as draft with a recipient enabled forward setting' do
    let(:site) { gws_site }
    let!(:recipient) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
    let(:subject) { "subject-#{unique_id}" }
    let(:texts) { Array.new(rand(1..10)) { "text-#{unique_id}" } }
    let(:text) { texts.join("\r\n") }
    let(:forward_email) { "#{unique_id}@example.jp" }
    let(:forward_subject) { "[#{I18n.t("gws/memo/message.message")}]#{I18n.t("gws/memo/forward.subject")}:#{gws_user.name}" }

    shared_examples "save as draft and send" do
      before do
        ActionMailer::Base.deliveries.clear

        Gws::Memo::Forward.create!(
          cur_site: site, cur_user: recipient,
          default: "enabled", email: forward_email
        )

        login_gws_user
      end

      after do
        ActionMailer::Base.deliveries.clear
      end

      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')

        within 'form#item-form' do
          click_on I18n.t("webmail.links.show_cc_bcc")

          within target do
            click_on I18n.t('gws.organization_addresses')
          end
        end

        within '#cboxLoadedContent' do
          expect(page).to have_content(recipient.name)
          click_on recipient.name
        end

        within 'form#item-form' do
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text

          click_on I18n.t('ss.buttons.draft_save')
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))

        # do not send forward mail
        expect(ActionMailer::Base.deliveries).to have(0).items

        # send message
        visit gws_memo_messages_path(site)
        within ".gws-memo-folder" do
          click_on I18n.t("gws/memo/folder.inbox_draft")
        end
        click_on subject
        click_on I18n.t("ss.links.edit")
        within 'form#item-form' do
          page.accept_confirm do
            click_on I18n.t("ss.buttons.send")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t("ss.notice.sent"))

        # send forward mail
        expect(ActionMailer::Base.deliveries).to have(1).items
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq site.sender_address
          expect(mail.bcc.first).to eq forward_email
          expect(mail.subject).to eq forward_subject
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(subject)
          expect(mail.body.raw_source).to include(text)
        end
      end
    end

    context "when to is given" do
      let(:target) { 'dl.see.to' }
      it_behaves_like "save as draft and send"
    end

    context "when cc is given" do
      let(:target) { 'dl.see.cc' }
      it_behaves_like "save as draft and send"
    end

    context "when bcc is given" do
      let(:target) { 'dl.see.bcc' }
      it_behaves_like "save as draft and send"
    end
  end
end
