require 'spec_helper'

describe "workflow_branch", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:old_name) { "[TEST] br_page" }
  let(:old_index_name) { "[TEST] br_page" }
  let(:new_name) { "[TEST] br_replace" }
  let(:new_index_name) { "" }

  before { login_cms_user }

  def create_branch
    # create_branch
    visit show_path
    within "#addon-workflow-agents-addons-branch" do
      click_button I18n.t('workflow.create_branch')

      # wait branch created
      expect(page).to have_css('.see.branch', text: old_name)
      click_link old_name
    end
    within "#addon-workflow-agents-addons-branch" do
      expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
    end
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

    # draft save
    click_on I18n.t('ss.links.edit')
    within "#item-form" do
      fill_in "item[name]", with: new_name
      fill_in "item[index_name]", with: new_index_name
      click_on I18n.t('ss.buttons.draft_save')
    end
    wait_for_notice I18n.t('ss.notice.saved')
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

    master = item.class.where(name: old_name).first
    branch = item.class.where(name: new_name).first

    expect(master.state).to eq "public"
    expect(branch.state).to eq "closed"
    expect(master.branches.first.id).to eq(branch.id)

    publish_branch(branch)
  end

  def publish_branch(branch)
    branch_url = show_path.sub(/\/\d+$/, "/#{branch.id}")
    visit branch_url
    expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

    # publish branch
    click_on I18n.t('ss.links.edit')
    within "#item-form" do
      if item.class.fields.key?("html")
        fill_in_ckeditor "item[html]", with: "<p>hello</p>"
      end
      click_on I18n.t('ss.buttons.publish_save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    if item.route == "cms/page"
      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: "refresh")
      end
    end

    # master was replaced
    item.class.all.each do |pub|
      expect(pub.name).to eq new_name
      expect(pub.index_name).to be_blank
      expect(pub.state).to eq "public"
    end
    expect(item.class.all.size).to eq 1
  end

  context "cms page" do
    let(:item) { create :cms_page, filename: "page.html", name: old_name, index_name: old_index_name }
    let(:show_path) { cms_page_path site, item }

    before { puts_log_stdout(true) }
    after { puts_log_stdout(false) }

    it { create_branch }
  end

  context "article page" do
    let(:item) { create :article_page, filename: "docs/page.html", name: old_name, index_name: old_index_name }
    let(:node) { create :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site, node, item }
    it { create_branch }
  end

  context "event page" do
    let(:item) { create :event_page, filename: "event/page.html", name: old_name, index_name: old_index_name }
    let(:node) { create :event_node_page, filename: "event", name: "event" }
    let(:show_path) { event_page_path site, node, item }
    it { create_branch }
  end

  context "faq page" do
    let(:item) { create :faq_page, filename: "faq/page.html", name: old_name, index_name: old_index_name }
    let(:node) { create :faq_node_page, filename: "faq", name: "faq" }
    let(:show_path) { faq_page_path site, node, item }
    it { create_branch }
  end

  context "mail_page page" do
    let(:item) { create :mail_page_page, filename: "mail/page.html", name: old_name, index_name: old_index_name }
    let(:node) { create :mail_page_node_page, filename: "mail", name: "mail" }
    let(:show_path) { mail_page_page_path site, node, item }
    it { create_branch }
  end

  context "sitemap page" do
    let(:item) { create :sitemap_page, filename: "sitemap/page.html", name: old_name, index_name: old_index_name }
    let(:node) { create :sitemap_node_page, filename: "sitemap", name: "sitemap" }
    let(:show_path) { sitemap_page_path site, node, item }
    it { create_branch }
  end
end
