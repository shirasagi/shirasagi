require 'spec_helper'

describe 'members/agents/nodes/login', type: :feature, dbscope: :example, js: true do
  describe "ss-2724" do
    let(:root_site) { cms_site }
    let(:site1) { create(:cms_site_subdir, domains: root_site.domains, parent_id: root_site.id) }
    let(:site2) { create(:cms_site_subdir, domains: root_site.domains, parent_id: root_site.id) }

    let(:site1_layout) { create_cms_layout(cur_site: site1) }
    let(:site2_layout) { create_cms_layout(cur_site: site2) }

    let!(:site1_my_page) { create :member_node_mypage, cur_site: site1, layout_id: site1_layout.id }
    let!(:site2_my_page) { create :member_node_mypage, cur_site: site2, layout_id: site2_layout.id }
    let!(:site1_my_profile) do
      create :member_node_my_profile, cur_site: site1, cur_node: site1_my_page, layout_id: site1_layout.id
    end
    let!(:site2_my_profile) do
      create :member_node_my_profile, cur_site: site2, cur_node: site2_my_page, layout_id: site2_layout.id
    end
    let!(:site1_login) do
      create(
        :member_node_login, cur_site: site1, layout_id: site1_layout.id, redirect_url: site1_my_profile.url,
        form_auth: "enabled"
      )
    end
    let!(:site2_login) do
      create(
        :member_node_login, cur_site: site2, layout_id: site2_layout.id, redirect_url: site2_my_profile.url,
        form_auth: "enabled"
      )
    end

    let!(:site1_member) { create :cms_member, cur_site: site1 }

    it do
      visit site1_login.full_url

      within ".form-login" do
        fill_in "item[email]", with: site1_member.email
        fill_in "item[password]", with: site1_member.in_password

        click_on I18n.t("ss.login")
      end
      expect(page).to have_no_css(".form-login")

      visit site2_my_profile.full_url
      expect(page).to have_css(".form-login")

      site1_member.reload
      expect(site1_member.last_loggedin).to be_present
    end
  end

  describe "open redirect" do
    let(:site) { cms_site }
    let(:layout) { create_cms_layout(cur_site: site) }
    let(:index_page) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", html: "you've been logged in" }
    let!(:login_node) do
      create(
        :member_node_login, cur_site: site, layout: layout, redirect_url: index_page.url, form_auth: "enabled"
      )
    end
    let!(:member) { create :cms_member, cur_site: site }

    it do
      visit "#{login_node.full_url}login.html" + "?" + { ref: Addressable::URI.encode("https://www.ss-proj.org/") }.to_query

      within ".form-login" do
        fill_in "item[email]", with: member.email
        fill_in "item[password]", with: member.in_password

        click_on I18n.t("ss.login")
      end

      expect(page).to have_css(".body", text: "you've been logged in")

      expect(Member::ActivityLog.all.member(member).count).to eq 1
      Member::ActivityLog.all.member(member).first.tap do |activity_log|
        expect(activity_log.activity_type).to eq "login"
        expect(activity_log.remote_addr).to eq "127.0.0.1"
        expect(activity_log.user_agent).to be_present
      end

      member.reload
      expect(member.last_loggedin).to be_present
    end
  end

  describe "with line login" do
    let(:site) { cms_site }
    let(:layout) { create_cms_layout(cur_site: site) }
    let(:index_page) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", html: "you've been logged in" }
    let!(:login_node) do
      create(
        :member_node_login, cur_site: site, layout: layout, redirect_url: index_page.url, form_auth: "enabled",
        line_oauth: "enabled", line_client_id: "client-#{unique_id}", line_client_secret: "secret-#{unique_id}"
      )
    end
    let!(:member) { create :cms_member, cur_site: site, oauth_type: "line", oauth_id: "oauth-#{unique_id}" }

    before do
      @save_test_mode = OmniAuth.config.test_mode
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:line, { provider: member.oauth_type, uid: member.oauth_id })
    end

    after do
      OmniAuth.config.mock_auth.delete(:line)
      OmniAuth.config.test_mode = @save_test_mode
    end

    it do
      visit "#{login_node.full_url}login.html" + "?" + { ref: Addressable::URI.encode("https://www.ss-proj.org/") }.to_query

      within ".oauth-login" do
        click_on I18n.t("member.login_by.line")
      end

      expect(page).to have_css(".body", text: "you've been logged in")

      expect(Member::ActivityLog.all.member(member).count).to eq 1
      Member::ActivityLog.all.member(member).first.tap do |activity_log|
        expect(activity_log.activity_type).to eq "login"
        expect(activity_log.remote_addr).to eq "127.0.0.1"
        expect(activity_log.user_agent).to be_present
      end

      member.reload
      expect(member.last_loggedin).to be_present
    end
  end
end
