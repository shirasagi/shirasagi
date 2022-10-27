require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_site_path site }
  let(:now) { Time.zone.now.beginning_of_minute }

  let(:png_file) do
    filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
    basename = ::File.basename(filename)
    SS::File.create_empty!(
      cur_user: gws_user, name: basename, filename: basename, content_type: "image/png", model: 'ss/file'
    ) do |file|
      ::FileUtils.cp(filename, file.path)
    end
  end
  let!(:item) { create :gws_schedule_plan, member_ids: [gws_user.id], file_ids: [png_file.id] }

  around do |example|
    travel_to(now) { example.run }
  end

  describe "site usage" do
    before { login_gws_user }

    it do
      visit index_path

      within "#addon-gws-agents-addons-site_usage" do
        first(".addon-head h2").click
        expect(page).to have_css(".usage-file-count", text: "-")
        expect(page).to have_css(".usage-calculated-at", text: "-")

        click_on I18n.t("ss.buttons.update")
        expect(page).to have_css(".usage-file-count", text: "1")
        expect(page).to have_css(".usage-calculated-at", text: I18n.l(now))
      end

      site.reload
      expect(site.usage_file_count).to eq 1
      expect(site.usage_db_size).to be > 100
      expect(site.usage_group_count).to be > 0
      expect(site.usage_user_count).to be > 0
      expect(site.usage_calculated_at).to eq now
    end
  end
end
