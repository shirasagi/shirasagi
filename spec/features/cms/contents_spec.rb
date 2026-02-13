require 'spec_helper'

describe "cms_contents", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:index_path) { cms_contents_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user to: index_path
    expect(page).to have_title(/403 Forbidden/)
  end

  context "with auth" do
    let!(:node1) { create :article_node_page, cur_site: site, shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ] }

    it "#index" do
      login_cms_user to: index_path
      expect(current_path).to eq index_path
      within ".system-recommends" do
        expect(page).to have_css("[data-id='#{node1.id}']", text: node1.name)
      end
      expect(page).to have_no_css(".recent-nodes")

      within ".system-recommends" do
        click_on node1.name
      end
      visit index_path
      within ".recent-nodes" do
        expect(page).to have_css("[data-id='#{node1.id}']", text: node1.name)
      end
      within ".system-recommends" do
        expect(page).to have_css("[data-id='#{node1.id}']", text: node1.name)
      end
    end
  end

  context "with notice" do
    let!(:normal_notice) { create(:cms_notice, notice_severity: Cms::Notice::NOTICE_SEVERITY_NORMAL) }
    let!(:high_notice) { create(:cms_notice, notice_severity: Cms::Notice::NOTICE_SEVERITY_HIGH) }
    # subject(:notice_path) { notice_cms_content_path site.id, item }

    it "#index and #notice" do
      login_cms_user to: index_path
      expect(current_path).not_to eq sns_login_path

      within "div.notices" do
        severity_high   = page.all(".notice-severity-high").map(&:text)
        severity_normal = page.all(".notice-severity-normal").map(&:text)

        expect(severity_high.index(high_notice.name)).to be_truthy
        expect(severity_high.index(normal_notice.name)).to be_falsey
        expect(severity_normal.index(normal_notice.name)).to be_truthy
        expect(severity_normal.index(high_notice.name)).to be_falsey
      end

      within "div.notices" do
        click_link high_notice.name
      end

      within ".main-box h2" do
        expect(page).to have_content(high_notice.name)
      end
    end
  end
end
