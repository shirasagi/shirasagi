require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:notice_folder) { create(:gws_notice_folder) }
  let!(:notice_post) { create(:gws_notice_post, folder_id: notice_folder) }

  before do
    login_gws_user
  end

  it do
    visit gws_portal_user_path(site: site, user: user)
    click_on I18n.t('gws/portal.links.manage_portlets')
    click_on I18n.t('ss.links.new')
    click_on I18n.t('gws/portal.portlets.notice.name')
    within 'form#item-form' do
      click_on I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    visit gws_portal_user_path(site: site, user: user)
    expect(page).to have_css('.portlets .gws-notices', text: notice_post.name)
  end
end
