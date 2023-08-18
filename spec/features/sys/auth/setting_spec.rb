require 'spec_helper'

describe "sys/auth/setting", type: :feature, dbscope: :example, js: true do
  let(:show_path) { sys_auth_setting_path }

  before { login_sys_user }

  it do
    visit show_path

    within "#addon-basic" do
      expect(page).to have_css("dd", text: I18n.t('ss.options.state.enabled'))
    end
    within "#menu" do
      click_on I18n.t('ss.links.edit')
    end
    within "#item-form" do
      select I18n.t('ss.options.state.disabled'), from: "item[form_auth]"
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t("ss.notice.saved")

    within "#addon-basic" do
      expect(page).to have_css("dd", text: I18n.t('ss.options.state.disabled'))
    end
  end
end
