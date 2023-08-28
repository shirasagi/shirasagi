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

    page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
      within "form.index-search" do
        fill_in "keyword", with: "くらし"
        fill_in "replacement", with: "戸籍"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    page.execute_script("SS.clearNotice();")

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

    page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
      within "form.index-search" do
        fill_in "keyword", with: "/top/child/"
        fill_in "replacement", with: "/kurashi/koseki/"
        check "option-url"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    page.execute_script("SS.clearNotice();")

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

    page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
      within "form.index-search" do
        fill_in "keyword", with: '<p>.+?<\/p>'
        fill_in "replacement", with: "<s>正規表現</s>"
        check "option-regexp"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    page.execute_script("SS.clearNotice();")

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
    let!(:page5) do
      create(:revision_page, cur_site: site, group: group, contact_group_relation: 'unrelated')
    end
    let(:contact_tel) { unique_tel }
    let(:contact_fax) { unique_tel }
    let(:contact_email) { unique_email }
    let(:contact_link_url) { unique_url }
    let(:contact_link_name) { "contact_link_name-#{unique_id}" }

    context "with contact_tel" do
      it do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: page5.contact_tel
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)

        page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
          within "form.index-search" do
            fill_in "keyword", with: page5.contact_tel
            fill_in "replacement", with: contact_tel
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        page.execute_script("SS.clearNotice();")

        page5.reload
        expect(page5.contact_tel).to eq contact_tel

        within "form.index-search" do
          fill_in "keyword", with: contact_tel
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)
      end
    end

    context "with contact_fax" do
      it do
        visit html_index_path
        within "form.index-search" do
          fill_in "keyword", with: page5.contact_fax
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)

        page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
          within "form.index-search" do
            fill_in "keyword", with: page5.contact_fax
            fill_in "replacement", with: contact_fax
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        page.execute_script("SS.clearNotice();")

        page5.reload
        expect(page5.contact_fax).to eq contact_fax

        within "form.index-search" do
          fill_in "keyword", with: contact_fax
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)
      end
    end

    context "with contact_email" do
      it do
        visit html_index_path
        within "form.index-search" do
          fill_in "keyword", with: page5.contact_email
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)

        page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
          within "form.index-search" do
            fill_in "keyword", with: page5.contact_email
            fill_in "replacement", with: contact_email
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        page.execute_script("SS.clearNotice();")

        page5.reload
        expect(page5.contact_email).to eq contact_email

        within "form.index-search" do
          fill_in "keyword", with: contact_email
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)
      end
    end

    context "with contact_link_url" do
      it do
        visit html_index_path
        within "form.index-search" do
          fill_in "keyword", with: page5.contact_link_url
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)

        page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
          within "form.index-search" do
            fill_in "keyword", with: page5.contact_link_url
            fill_in "replacement", with: contact_link_url
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        page.execute_script("SS.clearNotice();")

        page5.reload
        expect(page5.contact_link_url).to eq contact_link_url

        within "form.index-search" do
          fill_in "keyword", with: contact_link_url
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)
      end
    end

    context "with contact_link_name" do
      it "replace_html with string" do
        visit html_index_path
        within "form.index-search" do
          fill_in "keyword", with: page5.contact_link_name
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)

        page.accept_confirm(I18n.t('cms.apis.contents.confirm_message')) do
          within "form.index-search" do
            fill_in "keyword", with: page5.contact_link_name
            fill_in "replacement", with: contact_link_name
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        page.execute_script("SS.clearNotice();")

        page5.reload
        expect(page5.contact_link_name).to eq contact_link_name

        within "form.index-search" do
          fill_in "keyword", with: contact_link_name
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
        expect(page).to have_css(".result table a", text: page5.name)
      end
    end
  end
end
