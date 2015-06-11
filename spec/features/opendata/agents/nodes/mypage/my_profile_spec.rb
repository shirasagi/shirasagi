require 'spec_helper'

describe "opendata_agents_nodes_my_profile", dbscope: :example do
  let(:site) { cms_site }
  let(:node_mypage) { create :opendata_node_mypage, filename: "mypage", basename: "mypage" }
  let(:node_my_profile) { create :opendata_node_my_profile, filename: "#{node_mypage.filename}/myprofile" }
  let!(:node_login) { create :member_node_login, redirect_url: node_my_profile.url }
  let(:member) { opendata_member(site: site) }

  let(:index_url) { ::URI.parse "http://#{site.domain}#{node_my_profile.url}" }
  let(:login_url) { ::URI.parse "http://#{site.domain}#{node_login.url}login.html" }

  let(:item_name) { "name-#{unique_id}" }
  let(:item_email) { "#{unique_id}@example.jp" }

  before do
    login_opendata_member(site, node_login)
  end

  after do
    logout_opendata_member(site, node_login)
  end

  it "#index" do
    visit index_url
    expect(current_path).to eq index_url.path
    expect(status_code).to eq 200

    within "table.see" do
      expect(page).to have_content(member.name)
      expect(page).to have_content(member.email)
    end

    within "nav.menu" do
      click_link 'プロフィールの編集'
    end
    expect(status_code).to eq 200

    within "form#item-form" do
      fill_in "item[name]", with: item_name
      fill_in "item[email]", with: item_email
      click_button '保存'
    end
    expect(status_code).to eq 200

    within "table.see" do
      expect(page).to have_content(item_name)
      expect(page).to have_content(item_email)
    end

    within "nav.account" do
      click_link 'アカウントの削除'
    end
    expect(status_code).to eq 200

    within "form#item-form" do
      click_button 'アカウント削除'
    end
    expect(status_code).to eq 200
    expect(current_path).to eq login_url.path
  end
end
