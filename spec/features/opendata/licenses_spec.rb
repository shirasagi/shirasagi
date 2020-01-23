require 'spec_helper'

describe "opendata_licenses", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:index_path) { opendata_licenses_path site, node }
  let(:new_path) { new_opendata_license_path site, node }

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#new" do
      let!(:file) do
        tmp_ss_file(
          Cms::TempFile, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, site: site, node: node
        )
      end

      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          first(".btn-file-upload").click
        end
        wait_for_cbox do
          # click_on file.name
          expect(page).to have_css(".file-view", text: file.name)
          first("a[data-id='#{file.id}']").click
        end
        within "form#item-form" do
          expect(page).to have_css(".humanized-name", text: file.humanized_name)
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
    end

    describe "#show" do
      let(:item) { create(:opendata_license, cur_site: site) }
      let(:show_path) { opendata_license_path site, node, item }

      it do
        visit show_path
        expect(page).to have_css("#addon-basic", text: item.name)
      end
    end

    describe "#edit" do
      let(:item) { create(:opendata_license, cur_site: site) }
      let(:edit_path) { edit_opendata_license_path site, node, item }

      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
    end

    describe "#delete" do
      let(:item) { create(:opendata_license, cur_site: site) }
      let(:delete_path) { delete_opendata_license_path site, node, item }

      it do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_notice I18n.t("ss.notice.deleted")
      end
    end
  end
end
