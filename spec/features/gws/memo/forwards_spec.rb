require 'spec_helper'

describe 'gws_memo_forwards', type: :feature, dbscope: :example, js: true do
  context "forward setting" do
    let!(:site) { gws_site }
    let!(:show_path) { gws_memo_forwards_path site }
    let(:email1) { "#{unique_id}@example.jp" }
    let(:email2) { "#{unique_id}@example.jp" }

    before { login_gws_user }

    it "#show" do
      visit show_path
      click_link I18n.t('ss.links.edit')

      # edit
      within "form#item-form" do
        fill_in "item[emails]", with: [ email1, email2 ].join(", ")
        select I18n.t("ss.options.state.enabled"), from: "item[default]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#notice", text: I18n.t('ss.notice.saved'))
      expect(first('#addon-basic')).to have_text(email1)

      expect(Gws::Memo::Forward.all.count).to eq 1
      Gws::Memo::Forward.all.first.tap do |forward|
        expect(forward.default).to eq "enabled"
        expect(forward.emails).to eq [ email1, email2 ]
      end
    end
  end
end
