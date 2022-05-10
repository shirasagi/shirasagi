require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_site_path site.id }
  let(:now) { Time.zone.now.beginning_of_minute }

  let(:png_file) do
    filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
    basename = ::File.basename(filename)
    SS::File.create_empty!(
      site_id: site.id, cur_user: cms_user, name: basename, filename: basename, content_type: "image/png", model: 'ss/file'
    ) do |file|
      ::FileUtils.cp(filename, file.path)
    end
  end
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_site: site, cur_node: node, file_ids: [ png_file.id ] }

  around do |example|
    travel_to(now) { example.run }
  end

  describe "site usage" do
    before { login_cms_user }

    it do
      visit index_path

      within "#addon-ss-agents-addons-site_usage" do
        expect(page).to have_css(".usage-node-count", text: "-")
        expect(page).to have_css(".usage-calculated-at", text: "-")

        click_on I18n.t("service.buttons.reload")
        expect(page).to have_css(".usage-node-count", text: "1")
        expect(page).to have_css(".usage-calculated-at", text: I18n.l(now))
      end

      site.reload
      expect(site.usage_node_count).to eq 1
      expect(site.usage_page_count).to eq 1
      expect(site.usage_file_count).to eq 1
      expect(site.usage_db_size).to be > 100
      expect(site.usage_group_count).to be > 0
      expect(site.usage_user_count).to be > 0
      expect(site.usage_calculated_at).to eq now
    end
  end
end
