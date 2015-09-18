require 'spec_helper'

describe "cms_contents", dbscope: :example, type: :feature do
  subject(:site) { cms_site }
  subject(:index_path) { cms_contents_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end

  context "with notice" do
    let!(:normal_notice) { create(:cms_notice, notice_severity: Cms::Notice::NOTICE_SEVERITY_NORMAL) }
    let!(:high_notice) { create(:cms_notice, notice_severity: Cms::Notice::NOTICE_SEVERITY_HIGH) }
    # subject(:notice_path) { notice_cms_content_path site.id, item }

    before do
      login_cms_user
    end

    it "#index and #notice" do
      visit index_path
      expect(status_code).to eq 200
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

      within "h2.notice-severity-high" do
        expect(page).to have_content(high_notice.name)
      end
    end
  end
end
