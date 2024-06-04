require 'spec_helper'

describe "cms_search_contents_html", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:html_index_path) { cms_search_contents_html_path site.id }
  let(:user) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let!(:node) { create :article_node_page, st_form_ids: (1..7).map { |i| send("form#{i}").id } }

  let!(:form1) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form2) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form3) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form4) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form5) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form6) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:form7) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }

  let!(:column1) { create(:cms_column_text_field, cur_site: site, cur_form: form1, order: 1) }
  let!(:column2) { create(:cms_column_text_area, cur_site: site, cur_form: form2, order: 1) }
  let!(:column3) { create(:cms_column_headline, cur_site: site, cur_form: form3, order: 1) }
  let!(:column4) { create(:cms_column_url_field2, cur_site: site, cur_form: form4, order: 1) }
  let!(:column5) { create(:cms_column_list, cur_site: site, cur_form: form5, order: 1) }
  let!(:column6) { create(:cms_column_table, cur_site: site, cur_form: form6, order: 1) }
  let!(:column7) { create(:cms_column_free, cur_site: site, cur_form: form7, order: 1) }

  let!(:page1) do
    create(
      :article_page, cur_node: node, form: form1, name: "[TEST]page1",
      column_values: [ column1.value_type.new(column: column1, value: "一行入力") ]
    )
  end
  let!(:page2) do
    create(
      :article_page, cur_node: node, form: form2, name: "[TEST]page2",
      column_values: [ column2.value_type.new(column: column2, value: "複数行入力\r\n複数行入力\r\n複数行入力") ]
    )
  end
  let!(:page3) do
    create(
      :article_page, cur_node: node, form: form3, name: "[TEST]page3",
      column_values: [ column3.value_type.new(column: column3, head: "h1", text: "見出し") ]
    )
  end
  let!(:page4) do
    create(
      :article_page, cur_node: node, form: form4, name: "[TEST]page4",
      column_values: [ column4.value_type.new(column: column4, link_label: "リンクラベル", link_url: "/docs/page1.html") ]
    )
  end
  let!(:page5) do
    create(
      :article_page, cur_node: node, form: form5, name: "[TEST]page5",
      column_values: [ column5.value_type.new(column: column5, lists: ["リスト1", "リスト2", "リスト3", ""]) ]
    )
  end
  let!(:page6) do
    create(
      :article_page, cur_node: node, form: form6, name: "[TEST]page6",
      column_values: [ column6.value_type.new(column: column6, value: '<table><caption>キャプション</caption></table>') ]
    )
  end
  let!(:page7) do
    create(
      :article_page, cur_node: node, form: form7, name: "[TEST]page7",
      column_values: [ column7.value_type.new(column: column7, value: '<a href="/top/child/">anchor2</a><p>くらし\r\nガイド</p>') ]
    )
  end

  before { login_cms_user }

  it "replace column_text_field with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "一行入力"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "一行入力"
        fill_in "replacement", with: "置換"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page1.reload
    expect(page1.column_values[0].value).to eq "置換"
  end

  it "replace cms_column_text_area with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "複数行入力"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
    within "form.index-search" do
      fill_in "keyword", with: "複数行入力"
      fill_in "replacement", with: "置換"
      click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page2.reload
    expect(page2.column_values[0].value).to eq "置換\r\n置換\r\n置換"
  end

  it "replace cms_column_headline with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "見出し"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "見出し"
        fill_in "replacement", with: "置換"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page3.reload
    expect(page3.column_values[0].text).to eq "置換"
  end

  it "replace cms_column_url_field2 (link_label) with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "リンクラベル"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "リンクラベル"
        fill_in "replacement", with: "置換"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page4.reload
    expect(page4.column_values[0].link_label).to eq "置換"
  end

  it "replace cms_column_url_field2 (link_url) with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "/docs/page1.html"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "/docs/page1.html"
        fill_in "replacement", with: "/category/page2.html"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "/category/page2.html"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page4.reload
    expect(page4.column_values[0].link_url).to eq "/category/page2.html"
  end

  it "replace cms_column_list with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "リスト1"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "リスト1"
        fill_in "replacement", with: "置換1"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換1"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page5.reload
    expect(page5.column_values[0].lists).to eq ["置換1", "リスト2", "リスト3", ""]
  end

  it "replace cms_column_table with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "キャプション"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "キャプション"
        fill_in "replacement", with: "置換"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "置換"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_css(".result table a", text: "[TEST]page6")
    expect(page).to have_no_css(".result table a", text: "[TEST]page7")

    page6.reload
    expect(page6.column_values[0].value).to eq '<table><caption>置換</caption></table>'
  end

  it "replace cms_column_free with string" do
    visit html_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.index-search" do
      fill_in "keyword", with: "/top/child/"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_css(".result table a", text: "[TEST]page7")

    page.accept_confirm do
      within "form.index-search" do
        fill_in "keyword", with: "/top/child/"
        fill_in "replacement", with: "#"
        click_button I18n.t("ss.buttons.replace_all")
      end
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "form.index-search" do
      fill_in "keyword", with: "#"
      click_button I18n.t('ss.buttons.search')
    end
    wait_for_ajax
    expect(page).to have_no_css(".result table a", text: "[TEST]page1")
    expect(page).to have_no_css(".result table a", text: "[TEST]page2")
    expect(page).to have_no_css(".result table a", text: "[TEST]page3")
    expect(page).to have_no_css(".result table a", text: "[TEST]page4")
    expect(page).to have_no_css(".result table a", text: "[TEST]page5")
    expect(page).to have_no_css(".result table a", text: "[TEST]page6")
    expect(page).to have_css(".result table a", text: "[TEST]page7")

    page7.reload
    expect(page7.column_values[0].value).to eq '<a href="#">anchor2</a><p>くらし\r\nガイド</p>'
  end
end
