require 'spec_helper'

describe "opendata_agents_nodes_my_profile", type: :feature, dbscope: :example do
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
      click_button I18n.t('ss.buttons.save')
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

  it "#index" do
    expect(Opendata::MemberFile.count).to eq 0

    visit index_url
    expect(current_path).to eq index_url.path
    expect(status_code).to eq 200

    within "table.see" do
      expect(page).to have_content(member.name)
      expect(page).to have_content(member.email)
    end

    # upload icon
    within "nav.menu" do
      click_link 'プロフィールの編集'
    end
    expect(status_code).to eq 200

    within "form#item-form" do
      attach_file "item[in_icon]", "#{Rails.root}/spec/fixtures/ss/logo.png"
      click_button I18n.t('ss.buttons.save')
    end

    expect(Opendata::MemberFile.count).to eq 1
    file = Opendata::MemberFile.first
    within ".parent-row.icon" do
      expect(page).to have_css "img[src=\"#{file.url}\"]"
    end
    visit file.url
    expect(status_code).to eq 200

    # delete icon
    visit index_url
    within "nav.menu" do
      click_link 'プロフィールの編集'
    end
    expect(status_code).to eq 200
    within "form#item-form" do
      check "item[rm_icon]"
      click_button I18n.t('ss.buttons.save')
    end
    expect(Opendata::MemberFile.count).to eq 0
  end

  it "#index" do
    node_my_profile.edit_profile_state = "restrict_all"
    node_my_profile.update!

    visit index_url
    expect(current_path).to eq index_url.path
    expect(status_code).to eq 200

    within "table.see" do
      expect(page).to have_content(member.name)
    end
    expect(page).to have_no_css("nav.menu")
    expect(page).to have_css("nav.account", text: "アカウントの削除")
  end
end
