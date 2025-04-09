require 'spec_helper'

describe "opendata_agents_nodes_my_profile", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_mypage) { create :opendata_node_mypage, filename: "mypage", basename: "mypage" }
  let!(:node_my_profile) { create :opendata_node_my_profile, filename: "#{node_mypage.filename}/myprofile" }
  let!(:node_login) { create :member_node_login, redirect_url: node_my_profile.url }
  let!(:member) { opendata_member(site: site) }

  let(:error_message) do
    accepts = SS::File::IMAGE_FILE_EXTENSIONS
    I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: accepts.join(" / "))
  end

  before do
    Capybara.app_host = "http://#{site.domain}"
    login_opendata_member(site, node_login)
  end

  after do
    logout_opendata_member(site, node_login)
  end

  it "#index" do
    visit node_my_profile.url
    expect(status_code).to eq 200

    within "table.see" do
      expect(page).to have_content(member.name)
    end

    within "nav.menu" do
      click_link 'プロフィールの編集'
    end

    # attach invalid file
    within "form#item-form" do
      attach_file "item_in_icon", "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css("#errorExplanation", text: error_message)

    member.reload
    expect(member.icon).to be_nil

    # attach valid file
    within "form#item-form" do
      attach_file "item_in_icon", "#{Rails.root}/spec/fixtures/ss/logo.png"
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_no_css("#errorExplanation", text: error_message)

    member.reload
    expect(member.icon).to be_present
    within "table.see" do
      expect(page).to have_content(member.name)
      expect(first("img")["src"]).to eq member.icon.url
    end

    within "nav.menu" do
      click_link 'プロフィールの編集'
    end

    # attach invalid file again
    within "form#item-form" do
      attach_file "item_in_icon", "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css("#errorExplanation", text: error_message)

    member.reload
    expect(member.icon).to be_present

    # attach valid file again
    within "form#item-form" do
      attach_file "item_in_icon", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_no_css("#errorExplanation", text: error_message)

    member.reload
    expect(member.icon).to be_present
    within "table.see" do
      expect(page).to have_content(member.name)
      expect(first("img")["src"]).to eq member.icon.url
    end

    within "nav.menu" do
      click_link 'プロフィールの編集'
    end

    # remove attached file again
    within "form#item-form" do
      check "item_rm_icon"
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_no_css("#errorExplanation", text: error_message)

    member.reload
    expect(member.icon).to be_nil
  end
end
