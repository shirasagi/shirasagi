require 'spec_helper'

describe "opendata_licenses", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:index_path) { opendata_licenses_path site.host, node }
  let(:new_path) { new_opendata_license_path site.host, node }

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

    describe "#index" do
      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
      let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
      let(:item) { create(:opendata_license, site: site, file: license_logo_file) }
      let(:show_path) { opendata_license_path site.host, node, item }

      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#edit" do
      let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
      let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
      let(:item) { create(:opendata_license, site: site, file: license_logo_file) }
      let(:edit_path) { edit_opendata_license_path site.host, node, item }

      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button "保存"
        end
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#delete" do
      let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
      let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
      let(:item) { create(:opendata_license, site: site, file: license_logo_file) }
      let(:delete_path) { delete_opendata_license_path site.host, node, item }

      it do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(current_path).to eq index_path
      end
    end
  end
end
