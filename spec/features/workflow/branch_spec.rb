require 'spec_helper'

describe "workflow_branch", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:old_name) { "[TEST] br_page" }
  let(:new_name) { "[TEST] br_replace" }

  before { login_cms_user }

  def create_branch
    # create_branch
    visit show_path
    click_button I18n.t('workflow.create_branch')

    # show branch
    click_link old_name
    expect(page).to have_css('.see.branch', text: I18n.t('workflow.branch_message'))

    # draft save
    click_on I18n.t('ss.links.edit')
    within "#item-form" do
      fill_in "item[name]", with: new_name
      click_on I18n.t('ss.buttons.draft_save')
    end
    wait_for_ajax
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

    master = item.class.where(name: old_name).first
    branch = item.class.where(name: new_name).first

    expect(master.state).to eq "public"
    expect(branch.state).to eq "closed"
    expect(master.branches.first.id).to eq(branch.id)

    branch_url = show_path.sub(/\/\d+$/, "/#{branch.id}")
    publish_branch(branch_url)
  end

  def publish_branch(branch_url)
    visit branch_url
    expect(page).to have_css('.see.branch', text: I18n.t('workflow.branch_message'))

    # publish branch
    click_on I18n.t('ss.links.edit')
    within "#item-form" do
      click_on I18n.t('ss.buttons.publish_save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    # master was replaced
    item.class.all.each do |pub|
      expect(pub.name).to eq new_name
      expect(pub.state).to eq "public"
    end
    expect(item.class.all.size).to eq 1
  end

  context "cms page" do
    let(:item) { create_once :cms_page, filename: "page.html", name: old_name }
    let(:show_path) { cms_page_path site, item }
    it { create_branch }
  end

  context "article page" do
    let(:item) { create_once :article_page, filename: "docs/page.html", name: old_name }
    let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
    let(:show_path) { article_page_path site, node, item }
    it { create_branch }
  end

  context "faq page" do
    let(:item) { create_once :faq_page, filename: "faq/page.html", name: old_name }
    let(:node) { create_once :faq_node_page, filename: "faq", name: "faq" }
    let(:show_path) { faq_page_path site, node, item }
    it { create_branch }
  end

  context "event page" do
    let(:item) { create_once :event_page, filename: "event/page.html", name: old_name }
    let(:node) { create_once :event_node_page, filename: "event", name: "event" }
    let(:show_path) { event_page_path site, node, item }
    it { create_branch }
  end

  context "sitemap page" do
    let(:item) { create_once :sitemap_page, filename: "sitemap/page.html", name: old_name }
    let(:node) { create_once :sitemap_node_page, filename: "sitemap", name: "sitemap" }
    let(:show_path) { sitemap_page_path site, node, item }
    it { create_branch }
  end

  context "mail_page page" do
    let(:item) { create_once :mail_page_page, filename: "mail/page.html", name: old_name }
    let(:node) { create_once :mail_page_node_page, filename: "mail", name: "mail" }
    let(:show_path) { mail_page_page_path site, node, item }
    it { create_branch }
  end
end
