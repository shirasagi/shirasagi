require 'spec_helper'

describe "uploader_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node) { create :uploader_node_file, cur_site: site }

  before { login_cms_user }

  context "with coffeescript" do
    it do
      visit uploader_files_path(site: site, cid: node)
      click_on I18n.t("ss.links.upload")

      within "form" do
        attach_file "item[files][]", "#{::Rails.root}/spec/fixtures/uploader/example.coffee"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(page).to have_css("a.file", text: "example.coffee")
      expect(page).to have_css("a.file", text: "example.js")

      expect(Fs.size("#{node.path}/example.coffee")).to be > 0
      expect(Fs.size("#{node.path}/example.js")).to be > 0
    end
  end
end
