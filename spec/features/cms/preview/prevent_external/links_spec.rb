require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let!(:user) { cms_user }
  let!(:site) { cms_site }
  let!(:subsite1) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub1", group_ids: site.group_ids)
  end
  let!(:subsite2) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub2", group_ids: site.group_ids)
  end
  let!(:subsite1_role) { create :cms_role_admin, site: subsite1 }
  let!(:subsite2_role) { create :cms_role_admin, site: subsite2 }

  let(:layout) { create_cms_layout }
  let!(:docs1) { create :article_node_page, cur_site: site, filename: "docs", layout: layout }
  let!(:docs2) { create :article_node_page, cur_site: subsite1, filename: "docs", layout: layout }
  let!(:docs3) { create :article_node_page, cur_site: subsite2, filename: "docs", layout: layout }

  let!(:html) do
    h = Fs.read("#{Rails.root}/spec/fixtures/cms/preview/links.html")
    h.gsub!("http://sample.example.jp/", "http://#{site.domain}/")
    h
  end

  before do
    user.cms_role_ids = user.cms_role_ids.to_a + [subsite1_role.id, subsite2_role.id]
    user.update!

    Capybara.app_host = "http://#{site.domain}"
  end

  context "preview in root site" do
    before { login_cms_user }

    let!(:top_page1) { create :cms_page, cur_site: site, filename: "index.html", layout: layout, html: html }
    let!(:top_page2) { create :cms_page, cur_site: subsite1, filename: "index.html", layout: layout }
    let!(:top_page3) { create :cms_page, cur_site: subsite2, filename: "index.html", layout: layout }

    it "click site links" do
      visit cms_preview_path(site: site, path: top_page1.preview_path)
      first("a.top").click
      expect(current_path).to eq cms_preview_path(site: site) + site.url

      first("a.top-index").click
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      first("a.top-docs").click
      expect(current_path).to eq cms_preview_path(site: site, path: docs1.preview_path)
    end

    it "click subsite1 links" do
      visit cms_preview_path(site: site, path: top_page1.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub1").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub1-index").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub1-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)
    end

    it "click subsite2 links" do
      visit cms_preview_path(site: site, path: top_page1.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-index").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)
    end

    it "click full url links" do
      visit cms_preview_path(site: site, path: top_page1.preview_path)
      first("a.top-full").click
      expect(current_path).to eq cms_preview_path(site: site) + site.url

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub1-full").click
      end
      expect(current_path).to eq cms_preview_path(site: site) + site.url

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-full").click
      end
      expect(current_path).to eq cms_preview_path(site: site) + site.url
    end

    it "click full url docs links" do
      visit cms_preview_path(site: site, path: top_page1.preview_path)
      first("a.top-full-docs").click
      expect(current_path).to eq cms_preview_path(site: site, path: docs1.preview_path)

      visit cms_preview_path(site: site, path: top_page1.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub1-full-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-full-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: site, path: top_page1.preview_path)
    end
  end

  context "preview in subsite1" do
    before { login_cms_user }

    let!(:top_page1) { create :cms_page, cur_site: site, filename: "index.html", layout: layout }
    let!(:top_page2) { create :cms_page, cur_site: subsite1, filename: "index.html", layout: layout, html: html }
    let!(:top_page3) { create :cms_page, cur_site: subsite2, filename: "index.html", layout: layout }

    it "click site links" do
      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.top-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.top-index").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.top-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)
    end

    it "click subsite1 links" do
      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      first("a.sub1").click
      expect(current_path).to eq cms_preview_path(site: subsite1) + subsite1.url

      first("a.sub1-index").click
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      first("a.sub1-docs").click
      expect(current_path).to eq cms_preview_path(site: subsite1, path: docs2.preview_path)
    end

    it "click subsite2 links" do
      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-index").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)
    end

    it "click full url links" do
      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.top-full").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      first("a.sub1-full").click
      expect(current_path).to eq cms_preview_path(site: subsite1) + subsite1.url

      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-full").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1) + subsite1.url
    end

    it "click full url docs links" do
      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.top-full-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)

      first("a.sub1-full-docs").click
      expect(current_path).to eq cms_preview_path(site: subsite1, path: docs2.preview_path)

      visit cms_preview_path(site: subsite1, path: top_page2.preview_path)
      page.accept_alert(I18n.t("cms.notices.prevent_external_preview")) do
        first("a.sub2-full-docs").click
      end
      expect(current_path).to eq cms_preview_path(site: subsite1, path: top_page2.preview_path)
    end
  end
end
