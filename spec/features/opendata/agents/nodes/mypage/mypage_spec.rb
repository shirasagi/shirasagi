require 'spec_helper'

describe "opendata_agents_nodes_mypage", dbscope: :example do
  let(:site) { cms_site }
  let!(:node_dataset) { create :opendata_node_dataset }
  let(:node_mypage) { create :opendata_node_mypage, filename: "mypage", basename: "mypage" }
  let!(:node_my_dataset) { create :opendata_node_my_dataset, filename: "#{node_mypage.filename}/dataset" }
  let!(:member) { opendata_member }
  let!(:member_notice) { create(:opendata_member_notice, member_id: member.id) }

  context "with email and password" do
    let!(:node_login) { create :member_node_login, redirect_url: node_mypage.url, form_auth: "enabled" }

    let(:index_url) { ::URI.parse "http://#{site.domain}#{node_mypage.url}" }
    let(:dataset_url) { ::URI.parse "http://#{site.domain}#{node_mypage.url}dataset/" }
    let(:show_notice_url) { ::URI.parse "http://#{site.domain}#{node_mypage.url}notice/show.html" }
    let(:confirm_notice_url) { ::URI.parse "http://#{site.domain}#{node_mypage.url}notice/confirm.html" }

    let(:login_url) { ::URI.parse "http://#{site.domain}#{node_login.url}login.html" }
    let(:logout_url) { ::URI.parse "http://#{site.domain}#{node_login.url}logout.html" }

    it do
      visit index_url
      expect(status_code).to eq 200
      expect(current_path).to eq login_url.path

      within "form.form-login" do
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
      visit index_url
      expect(status_code).to eq 200
      expect(current_path).to eq login_url.path

      within "form.form-login" do
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
