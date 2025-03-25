require 'spec_helper'

describe "ads_banners_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :ads_node_banner, name: "ads" }
  let!(:bindings) { { user: cms_user, site: site, node: node } }
  let(:content_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:file1) { tmp_ss_file Cms::TempFile, contents: content_path, basename: "logo-#{unique_id}.png", **bindings }
  let!(:file2) { tmp_ss_file Cms::TempFile, contents: content_path, basename: "logo-#{unique_id}.png", **bindings }
  let!(:file3) { tmp_ss_file Cms::TempFile, contents: content_path, basename: "logo-#{unique_id}.png", **bindings }
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
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "form#item-form" do
        within "#item_file_id" do
          expect(page).to have_css(".sanitizer-none", visible: false)
        end

        # set wait
        attach_to_ss_file_field "item_file_id", file1
        within "#item_file_id" do
          expect(page).to have_css(".sanitizer-wait")
        end

        # set error
        attach_to_ss_file_field "item_file_id", file2
        within "#item_file_id" do
          expect(page).to have_css(".sanitizer-error")
        end

        # set none
        attach_to_ss_file_field "item_file_id", file3
        within "#item_file_id" do
          expect(page).to have_css(".sanitizer-none", visible: false)
        end
      end
    end
  end
end
