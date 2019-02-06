require 'spec_helper'

describe "opendata_datasets_release", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:item) { create(:opendata_dataset, cur_node: node) }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let(:index_path) { opendata_datasets_path site, node }
  let(:show_path) { opendata_dataset_path site, node, item }
  let(:edit_path) { edit_opendata_dataset_path site, node, item }

  let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
  let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
  let!(:license) { create(:opendata_license, cur_site: site, in_file: license_logo_file) }

  context "with auth" do
    before { login_cms_user }

    describe "#edit" do
      it do
        release_date = Time.zone.now.tomorrow

        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[text]", with: "sample"
          fill_in "item[release_date]", with: release_date
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(first('#addon-cms-agents-addons-release')).to have_text("公開待ち")
        expect(first('#addon-cms-agents-addons-release_plan')).to have_text(release_date.strftime("%Y/%m/%d %H:%M"))

        # add resources
        click_link "リソースを管理する"
        expect(status_code).to eq 200

        click_link "新規作成"
        expect(status_code).to eq 200

        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          fill_in "item[name]", with: "sample1"
          fill_in "item[format]", with: "png"
          select license.name, from: 'item_license_id'
          click_button "保存"
        end

        expect(status_code).to eq 200
        expect(first('#addon-basic')).to have_text("logo.png")

        click_link "一覧へ戻る"
        expect(status_code).to eq 200

        click_link "新規作成"
        expect(status_code).to eq 200

        within "form#item-form" do
          fill_in "item[source_url]", with: "https://github.com/shirasagi/shirasagi"
          fill_in "item[name]", with: "sample1"
          fill_in "item[format]", with: "html"
          select license.name, from: 'item_license_id'
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(first('#addon-basic')).to have_text("https://github.com/shirasagi/shirasagi")

        visit show_path
        expect(status_code).to eq 200
        expect(first('#addon-cms-agents-addons-release')).to have_text("公開待ち")
        expect(first('#addon-cms-agents-addons-release_plan')).to have_text(release_date.strftime("%Y/%m/%d %H:%M"))
      end
    end
  end
end
