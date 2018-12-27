require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  context 'when a message save as draft with a recipient enabled forward setting' do
    let(:site) { gws_site }
    let!(:recipient) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
    let(:subject) { "subject-#{unique_id}" }
    let(:texts) { Array.new(rand(1..10)) { "text-#{unique_id}" } }
    let(:text) { texts.join("\r\n") }

    before do
      ActionMailer::Base.deliveries.clear

      Gws::Memo::Forward.create!(
        cur_site: site, cur_user: recipient,
        default: "enabled", email: "#{unique_id}@example.jp"
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
        within 'dl.see.to' do
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

      # do not send forward mail
      expect(ActionMailer::Base.deliveries).to have(0).items
    end
  end
end
