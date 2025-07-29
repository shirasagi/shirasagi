require 'spec_helper'

describe "cms_login", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:login_path) { cms_login_path(site: site) }
  let(:logout_path) { cms_logout_path(site: site) }
  let(:main_path) { cms_contents_path(site: site) }

  context "invalid login" do
    it "with uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: "wrong"
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq login_path
    end

    context 'with duplicated organization_uid' do
      let(:group) { create(:cms_group, name: unique_id) }
      let(:user2) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
               organization_uid: user.organization_uid, organization_id: group.id,
               group_ids: [group.id], cms_role_ids: [cms_role.id])
      end

      before do
        cms_site.set(group_ids: [cms_group.id, group.id])
      end

      it "with uid" do
        visit login_path
        within "form" do
          fill_in "item[email]", with: user2.organization_uid
          fill_in "item[password]", with: "pass"
          click_button I18n.t("ss.login")
        end
        expect(current_path).to eq login_path
      end
    end
  end

  context "valid login" do
    it "with email" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
    end

    it "with organization_uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.organization_uid
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
      within ".user-navigation" do
        wait_for_event_fired("turbo:frame-load") { click_on cms_user.name }
        expect(page).to have_link(I18n.t("ss.logout"), href: logout_path)
        click_on I18n.t("ss.logout")
      end

      expect(current_path).to eq login_path

      visit main_path
      expect(current_path).to eq login_path
    end
  end

  context "when internal path is given at `ref` parameter" do
    it do
      visit cms_login_path(site: site, ref: cms_layouts_path(site: site))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      wait_for_js_ready

      expect(current_path).to eq cms_layouts_path(site: site)
    end
  end

  context "when internal url is given at `ref` parameter" do
    let(:capybara_server) { Capybara.current_session.server }
    let(:ref) { cms_layouts_url(host: "#{capybara_server.host}:#{capybara_server.port}", site: site) }

    it do
      visit cms_login_path(site: site, ref: ref)
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      wait_for_js_ready

      expect(current_path).to eq cms_layouts_path(site: site)
    end
  end

  context "when external url is given at `ref` parameter" do
    before do
      @save_url_type = SS.config.sns.url_type
      SS.config.replace_value_at(:sns, :url_type, "restricted")
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    it do
      visit cms_login_path(site: site, ref: "https://www.google.com/")
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq main_path
    end
  end
end
