require 'spec_helper'

describe "gws_user_profiles", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
  let(:presence) do
    item = Gws::UserPresence.new(cur_user: user, cur_site: site)
    item.presence_state = 'available'
    item.presence_plan = unique_id
    item.presence_memo = unique_id
    item.save ? item : nil
  end

  before { login_user user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:kana) { unique_id }
    let(:email) { unique_email }
    let(:tel) { unique_tel }
    let(:tel_ext) { unique_tel }

    it do
      expect(presence.present?).to be_truthy

      visit gws_user_profile_path(site: site)
      within '#addon-basic' do
        expect(page).to have_content(user.name)
      end

      click_on I18n.t("ss.links.edit")
      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[kana]", with: kana
        fill_in "item[email]", with: email
        fill_in "item[tel]", with: tel
        fill_in "item[tel_ext]", with: tel_ext

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      user.reload
      expect(user.name).to eq name
      expect(user.kana).to eq kana
      expect(user.email).to eq email
      expect(user.tel).to eq tel
      expect(user.tel_ext).to eq tel_ext
    end
  end
end
