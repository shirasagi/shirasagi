require 'spec_helper'

describe "gws_user_locale_setting", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create :gws_user, group_ids: [gws_user.group_ids.first], lang: nil, timezone: nil }
  let(:lang) { %w(en ja).sample }
  let(:lang_label) { I18n.t("ss.options.lang.#{lang}") }
  let(:timezone) { ActiveSupport::TimeZone.all.sample }

  before { login_user item }

  context "basic crud" do
    it do
      visit gws_user_locale_setting_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select lang_label, from: "item[lang]"
        select timezone.to_s, from: "item[timezone]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.lang).to eq lang
      expect(item.timezone).to eq timezone.name
    end
  end
end
