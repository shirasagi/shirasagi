require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_notices_path(site) }
  let(:name) { unique_id }
  let(:text) { unique_id }

  before { login_gws_user }

  context 'with notification' do
    it do
      visit index_path
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[text]', with: text

        select I18n.t('gws.options.notification.enabled'), from: 'item[message_notification]'
        select I18n.t('gws.options.notification.enabled'), from: 'item[email_notification]'

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Notice.all.count).to eq 1
      Gws::Notice.all.first.tap do |item|
        expect(item.name).to eq name
        expect(item.text).to eq text
        expect(item.message_notification).to eq 'enabled'
        expect(item.email_notification).to eq 'enabled'
      end
    end
  end
end
