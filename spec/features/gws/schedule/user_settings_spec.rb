require 'spec_helper'

describe "gws_schedule_user_settings", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_user_setting_path site }

  context "with auth", js: true do
    let!(:item) { gws_user.groups.in_group(site).first }

    before { login_gws_user }

    it "#show" do
      visit path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit "#{path}/edit"
      within "form#item-form" do
        uncheck("tab-g-#{item.id}")
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
