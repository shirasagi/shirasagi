require 'spec_helper'

describe "ads_banners_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :ads_node_banner, name: "ads" }
  let!(:bindings) { { user: cms_user, site: site, node: node } }
  let!(:file1) { tmp_ss_file Cms::TempFile, **bindings, contents: "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:file2) { tmp_ss_file Cms::TempFile, **bindings, contents: "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:file3) { tmp_ss_file Cms::TempFile, **bindings, contents: "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:index_path) { ads_banners_path site.id, node }

  before { login_cms_user }

  describe "ss_file_field" do
    it do
      file1.update(sanitizer_state: 'wait')
      file2.update(sanitizer_state: 'error')
      file3.update(sanitizer_state: nil)

      # index
      visit index_path
      expect(current_path).not_to eq sns_login_path

      # new
      click_on I18n.t("ss.links.new")
      within first(".ss-file-field") do
        expect(page).to have_css(".sanitizer-none", visible: false)
      end

      # set wait
      within first(".ss-file-field") do
        wait_cbox_open do
          first(".btn-file-upload").click
        end
      end
      within all(".file-view")[0] do
        wait_cbox_close do
          click_on file1.name
        end
      end
      within first(".ss-file-field") do
        expect(page).to have_css(".sanitizer-wait")
      end

      # set error
      within first(".ss-file-field") do
        wait_cbox_open do
          first(".btn-file-upload").click
        end
      end
      within all(".file-view")[1] do
        wait_cbox_close do
          click_on file2.name
        end
      end
      within first(".ss-file-field") do
        expect(page).to have_css(".sanitizer-error")
      end

      # set none
      within first(".ss-file-field") do
        wait_cbox_open do
          first(".btn-file-upload").click
        end
      end
      within all(".file-view")[2] do
        wait_cbox_close do
          click_on file3.name
        end
      end
      within first(".ss-file-field") do
        expect(page).to have_css(".sanitizer-none", visible: false)
      end
    end
  end
end
