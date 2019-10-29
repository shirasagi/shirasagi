require 'spec_helper'

describe "sns_mypage", type: :feature, dbscope: :example do
  subject(:index_path) { sns_mypage_path }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  context "with auth" do
    before { login_ss_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end

  describe "use_cms, use_gws and use_webmail permissions" do
    let!(:gws_site) { create :gws_group }
    let!(:cms_site) { create :cms_site_unique, group_ids: [ gws_site.id ] }
    let!(:user) { create :gws_user, cur_group: gws_site }

    before do
      ss_user = SS::User.find(user.id)
      ss_user.sys_role_ids = [ role.id ]
      ss_user.save!

      user.reload

      login_user user
    end

    context "when user has only use_cms permission" do
      let!(:role) { create :sys_role_cms }

      it do
        visit sns_mypage_path

        within ".application-menu" do
          expect(page).to have_link(I18n.t("ss.links.cms"))
          expect(page).to have_no_link(I18n.t("ss.links.gws"))
          expect(page).to have_no_link(I18n.t('webmail.mail'))
        end

        expect(page).to have_css(".mypage-sites .list-items", text: cms_site.name)
        expect(page).to have_no_css(".mypage-groups .list-items", text: gws_site.name)
      end
    end

    context "when user has only use_gws permission" do
      let!(:role) { create :sys_role_gws }

      it do
        visit sns_mypage_path

        within ".application-menu" do
          expect(page).to have_no_link(I18n.t("ss.links.cms"))
          expect(page).to have_link(I18n.t("ss.links.gws"))
          expect(page).to have_no_link(I18n.t('webmail.mail'))
        end

        expect(page).to have_no_css(".mypage-sites .list-items", text: cms_site.name)
        expect(page).to have_css(".mypage-groups .list-items", text: gws_site.name)
      end
    end

    context "when user has only use_webmail permission" do
      let!(:role) { create :sys_role_webmail }

      it do
        visit sns_mypage_path

        within ".application-menu" do
          expect(page).to have_no_link(I18n.t("ss.links.cms"))
          expect(page).to have_no_link(I18n.t("ss.links.gws"))
          expect(page).to have_link(I18n.t('webmail.mail'))
        end

        expect(page).to have_no_css(".mypage-sites .list-items", text: cms_site.name)
        expect(page).to have_no_css(".mypage-groups .list-items", text: gws_site.name)
      end
    end
  end
end
