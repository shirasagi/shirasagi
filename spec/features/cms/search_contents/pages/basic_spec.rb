require 'spec_helper'

describe "cms_search_contents_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:pages_index_path) { cms_search_contents_pages_path site.id }
  let(:user) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let(:node_name) { unique_id }
  let(:node_filename) { 'base' }
  let(:cate_name1) { unique_id }
  let(:opendata_cate_name1) { unique_id }

  def all_pages
    criteria = Cms::Page.site(site)
    criteria = yield(criteria) if block_given?
    criteria.pluck(:name)
  end

  before do
    node = create(:cms_node_page, name: node_name, filename: node_filename)
    cate1 = create(:category_node_page, name: cate_name1)
    cate2 = create(:category_node_page)
    cate3 = create(:category_node_page)
    cate4 = create(:category_node_page)
    html1 = "<div>html1</div>"
    html2 = "<div>[TEST]A</div>"
    html3 = "<div>html3</div>"
    html4 = "<div>html4</div>"
    create(
      :cms_page, cur_site: site, user: user, name: "[TEST]A", filename: "A.html", state: "public",
      category_ids: [ cate1.id ], group_ids: [ cms_group.id ], html: html1)
    create(
      :article_page, cur_site: site, cur_node: node, name: "[TEST]B", filename: "B.html", state: "public",
      category_ids: [ cate2.id ], group_ids: [ cms_group.id ], html: html2)
    create(
      :event_page, cur_site: site, cur_node: node, name: "[TEST]C", filename: "C.html", state: "closed",
      category_ids: [ cate3.id ], group_ids: [ cms_group.id ], html: html3)
    create(
      :faq_page, cur_site: site, cur_node: node, name: "[TEST]D", filename: "D.html", state: "closed",
      category_ids: [ cate4.id ], group_ids: [ cms_group.id ], html: html4)

    opendata_node = create(:opendata_node_dataset)
    opendata_cate = create(:opendata_node_category, name: opendata_cate_name1)
    create(
      :opendata_dataset, cur_node: opendata_node, name: "[TEST]E", state: "closed",
      category_ids: [ opendata_cate.id ], group_ids: [ cms_group.id ])

    login_cms_user
  end

  it "search with empty conditions" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
    expect(page).to have_css("div.info a.title", text: "[TEST]E")
  end

  it "search with name" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      fill_in "item[search_name]", with: "A"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
  end

  it "search with filename" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      fill_in "item[search_filename]", with: "#{node_filename}/"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "3 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
  end

  it "search with keyword" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      fill_in "item[search_keyword]", with: "[TEST]A"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "2 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
  end

  it "search with state" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      select I18n.t("ss.options.state.public"), from: "item[search_state]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "2 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    within "form.search-pages" do
      select I18n.t("ss.options.state.closed"), from: "item[search_state]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "3 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
    expect(page).to have_css("div.info a.title", text: "[TEST]E")
  end

  it "search with publishable" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      select I18n.t("ss.options.first_released.published"), from: "item[search_first_released]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "2 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    within "form.search-pages" do
      select I18n.t("ss.options.first_released.draft"), from: "item[search_first_released]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "3 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
    expect(page).to have_css("div.info a.title", text: "[TEST]E")
  end

  it "search with ready state" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      select I18n.t("ss.options.state.ready"), from: "item[search_state]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "0 件の検索結果")

    Article::Page.first.tap do |item|
      item.state = "ready"
      item.save!
    end

    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
  end

  it "search with released_or_updated" do
    Timecop.travel(3.days.from_now) do
      login_cms_user
      visit pages_index_path
      expect(current_path).not_to eq sns_login_path
      page = Cms::Page.where(name: "[TEST]D").first
      page.state = "public"
      page.save
    end

    Timecop.travel(6.days.from_now) do
      login_cms_user
      visit pages_index_path
      expect(current_path).not_to eq sns_login_path
      page = Cms::Page.where(name: "[TEST]A").first
      page.html = "update"
      page.save
    end

    Timecop.travel(1.day.from_now) do
      login_cms_user
      visit pages_index_path
      expect(current_path).not_to eq sns_login_path
      start = Time.zone.now
      close = start.advance(days: 6)

      within "form.search-pages" do
        fill_in_datetime "item[search_released_start]", with: start
        fill_in_datetime "item[search_released_close]", with: close
        fill_in_datetime "item[search_updated_start]", with: ""
        fill_in_datetime "item[search_updated_close]", with: ""
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
      expect(page).to have_css("div.info a.title", text: "[TEST]D")

      within "form.search-pages" do
        fill_in_datetime "item[search_released_start]", with: ""
        fill_in_datetime "item[search_released_close]", with: ""
        fill_in_datetime "item[search_updated_start]", with: start
        fill_in_datetime "item[search_updated_close]", with: close
        click_button I18n.t('ss.buttons.search')
      end
      expect(page).to have_css(".search-count", text: "2 件の検索結果")
      expect(page).to have_css("div.info a.title", text: "[TEST]A")
      expect(page).to have_css("div.info a.title", text: "[TEST]D")
    end
  end

  it "search with request approver_state" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      select I18n.t("workflow.page.request"), from: "item[search_approver_state]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "0 件の検索結果")

    Article::Page.first.tap do |item|
      item.cur_site = site
      item.cur_user = cms_user
      item.workflow_state = "request"
      item.workflow_user_id = cms_user.id
      item.workflow_approvers = [{ level: 1, user_id: user.id, state: "request" }]
      item.workflow_required_counts = [ false ]
      item.save!
    end

    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
  end

  it "search with approve approver_state" do
    visit pages_index_path
    expect(current_path).not_to eq sns_login_path
    within "form.search-pages" do
      select I18n.t("workflow.page.approve"), from: "item[search_approver_state]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: "0 件の検索結果")

    Article::Page.first.tap do |item|
      item.cur_site = site
      item.cur_user = user
      item.workflow_state = "request"
      item.workflow_user_id = user.id
      item.workflow_approvers = [{ level: 1, user_id: cms_user.id, state: "request" }]
      item.workflow_required_counts = [ false ]
      item.save!
    end

    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
  end

  it "search with categories" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("cms.apis.categories.index") }
    within_cbox do
      wait_for_cbox_closed { click_on cate_name1 }
    end
    expect(page).to have_css(".mod-cms-page-search", text: cate_name1)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
  end

  it "search with opendata categories" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("cms.apis.categories.index") }
    within_cbox do
      wait_for_cbox_closed { click_on opendata_cate_name1 }
    end
    expect(page).to have_css(".mod-cms-page-search", text: opendata_cate_name1)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]E")
  end

  it "search with groups" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
    within_cbox do
      wait_for_cbox_closed { click_on cms_group.name }
    end
    expect(page).to have_css(".mod-cms-page-search", text: cms_group.name)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
    expect(page).to have_css("div.info a.title", text: "[TEST]E")
  end

  it "search with user" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("cms.apis.users.index") }
    within_cbox do
      wait_for_cbox_closed { click_on user.name }
    end
    expect(page).to have_css(".mod-cms-page-search", text: user.name)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]A")
  end

  it "search with nodes" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("cms.apis.nodes.index") }
    within_cbox do
      wait_for_cbox_closed { click_on node_name }
    end
    expect(page).to have_css(".mod-cms-page-search", text: node_name)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: "3 件の検索結果")
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
    expect(page).to have_css("div.info a.title", text: "[TEST]C")
    expect(page).to have_css("div.info a.title", text: "[TEST]D")
  end

  it "search with routes" do
    visit pages_index_path
    wait_for_cbox_opened { click_on I18n.t("cms.apis.pages_routes.index") }
    page_route = I18n.t("modules.article") + "/" + I18n.t("mongoid.models.article/page")
    within_cbox do
      wait_for_cbox_closed { click_on page_route }
    end
    expect(page).to have_css(".mod-cms-page-search", text: page_route)
    click_button I18n.t('ss.buttons.search')
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
    expect(page).to have_css("div.info a.title", text: "[TEST]B")
  end

  it "search with sort options" do
    visit pages_index_path

    # sort by name
    within "form.search-pages" do
      select I18n.t("cms.sort_options.name.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(name: 1) }

    # sort by filename
    within "form.search-pages" do
      select I18n.t("cms.sort_options.filename.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(filename: 1) }

    # sort by creared
    within "form.search-pages" do
      select I18n.t("cms.sort_options.created.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(created: 1) }

    # sort by updated
    within "form.search-pages" do
      select I18n.t("cms.sort_options.updated_desc.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(updated: -1) }

    # sort by released
    within "form.search-pages" do
      select I18n.t("cms.sort_options.released_desc.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(released: -1) }

    # sort by approved
    within "form.search-pages" do
      select I18n.t("cms.sort_options.approved_desc.title"), from: "item[search_sort]"
      click_button I18n.t('ss.buttons.search')
    end
    expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))

    names = all("div.info a.title").map(&:text)
    expect(names).to eq all_pages { |criteria| criteria.reorder(approved: -1) }
  end
end
