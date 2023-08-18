require 'spec_helper'

describe "cms_search_contents_html", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:html_index_path) { cms_search_contents_html_path site.id }

  before do
    create(:article_page, name: "[TEST]top",     html: '<a href="/top/" class="top">anchor</a>')
    create(:article_page, name: "[TEST]child",   html: '<a href="/top/child/">anchor2</a><p>くらし\r\nガイド</p>')
    create(:article_page, name: "[TEST]1.html",  html: '<a href="/top/child/1.html">anchor3</a>')
    create(:article_page, name: "[TEST]nothing", html: '')

    login_cms_user
  end

  it "replace_html with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "くらし"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "くらし"
        fill_in "replacement", with: "戸籍"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    within "form.index-search" do
      fill_in "keyword", with: "戸籍"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
  end

  it "replace_html with url" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "/top/child/"
      check "option-url"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_css(".result table a", text: "[TEST]1")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "/top/child/"
        fill_in "replacement", with: "/kurashi/koseki/"
        check "option-url"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    within "form.index-search" do
      fill_in "keyword", with: "/kurashi/koseki/"
      check "option-url"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_css(".result table a", text: "[TEST]1")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
  end

  it "replace_html with regexp" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: '<p>.+?<\/p>'
      check "option-regexp"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_no_css(".result table a", text: "[TEST]1")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: '<p>.+?<\/p>'
        fill_in "replacement", with: "<s>正規表現</s>"
        check "option-regexp"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    within "form.index-search" do
      fill_in "keyword", with: '<s>.+?<\/s>'
      check "option-regexp"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]top")
    expect(page).to have_css(".result table a", text: "[TEST]child")
    expect(page).to have_no_css(".result table a", text: "[TEST]1")
    expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
  end

  context "with contact_group_id" do
    let(:root_group) { create(:revision_root_group) }
    let(:group) { create(:revision_new_group) }

    before(:each) do
      create(:revision_page, cur_site: site, group: group)
    end

    it "replace_html with string" do
      visit html_index_path
      expect(current_path).not_to eq sns_login_path
      within "form.index-search" do
        fill_in "keyword", with: group.contact_tel
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: group.contact_tel
          fill_in "replacement", with: "contact_tel"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "form.index-search" do
        fill_in "keyword", with: "contact_tel"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      within "form.index-search" do
        fill_in "keyword", with: group.contact_fax
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: group.contact_fax
          fill_in "replacement", with: "contact_fax"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "form.index-search" do
        fill_in "keyword", with: "contact_fax"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      within "form.index-search" do
        fill_in "keyword", with: group.contact_email
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: group.contact_email
          fill_in "replacement", with: "contact_email"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "form.index-search" do
        fill_in "keyword", with: "contact_email"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      within "form.index-search" do
        fill_in "keyword", with: group.contact_link_url
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: group.contact_link_url
          fill_in "replacement", with: "contact_link_url"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "form.index-search" do
        fill_in "keyword", with: "contact_link_url"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      within "form.index-search" do
        fill_in "keyword", with: group.contact_link_name
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: group.contact_link_name
          fill_in "replacement", with: "contact_link_name"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "form.index-search" do
        fill_in "keyword", with: "contact_link_name"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_ajax
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]child")
      expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
      expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")
    end
  end
end
