require 'spec_helper'

describe "opendata_agents_nodes_mypage", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :opendata_node_mypage, filename: "mypage", basename: "mypage" }
  let!(:member) { opendata_member }
  let!(:member_notice) { create(:opendata_member_notice, member: member) }

  context "with email and password" do
    let(:index_url) { ::URI.parse "http://#{site.domain}#{node.url}" }
    let(:dataset_url) { ::URI.parse "http://#{site.domain}#{node.url}dataset/" }
    let(:login_url) { ::URI.parse "http://#{site.domain}#{node.url}login/" }
    let(:logout_url) { ::URI.parse "http://#{site.domain}#{node.url}logout/" }
    let(:show_notice_url) { ::URI.parse "http://#{site.domain}#{node.url}notice/show.html" }
    let(:confirm_notice_url) { ::URI.parse "http://#{site.domain}#{node.url}notice/confirm.html" }

    before do
      @save_config = SS.config.opendata.use_member_form_login
      SS.config.replace_value_at :opendata, :use_member_form_login, true
    end

    after do
      SS.config.replace_value_at :opendata, :use_member_form_login, @save_config
    end

    it do
      visit index_url
      expect(status_code).to eq 200
      expect(current_path).to eq login_url.path

      within "form.member-login" do
        fill_in "item[email]", with: member.email
        fill_in "item[password]", with: member.in_password
        click_button "ログイン"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq dataset_url.path

      visit logout_url
      expect(status_code).to eq 200
      expect(current_path).to eq login_url.path
    end

    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_HOST", site.domain)
        visit index_url
        expect(status_code).to eq 200
        expect(current_path).to eq login_url.path

        within "form.member-login" do
          fill_in "item[email]", with: member.email
          fill_in "item[password]", with: member.in_password
          click_button "ログイン"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq dataset_url.path

        visit show_notice_url
        expect(status_code).to eq 200
        expect(page).to have_link(member_notice.commented_count)

        visit confirm_notice_url
        expect(status_code).to eq 200
        member_notice.reload
        expect(member_notice.commented_count).to eq 0
      end
    end
  end

  describe "#provide" do
    let(:dataset_url) { ::URI.parse "http://#{site.domain}#{node.url}dataset/" }
    let(:provide_url) { ::URI.parse "http://#{site.domain}#{node.url}twitter" }
    let(:oauth_user) { set_omniauth }

    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_HOST", site.domain)
        # session.env("REQUEST_PATH", provide_path)
        session.env("omniauth.auth", oauth_user)

        visit provide_url
        expect(current_path).to eq dataset_url.path
      end
    end
  end
end
