require 'spec_helper'

describe "opendata_dataset_resources", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:index_path) { opendata_dataset_resources_path site, node, dataset.id }

  context "with auth" do
    let(:resource_file_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    let(:resource_tsv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    let(:new_path) { new_opendata_dataset_resource_path site, node, dataset.id }

    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          attach_file "item[in_file]", resource_file_path
          fill_in "item[name]", with: unique_id
          select license.name, from: "item_license_id"
          attach_file "item[in_tsv]", resource_tsv_path
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    context "with item" do
      let(:item) { dataset.resources.new(attributes_for(:opendata_resource)) }
      let(:show_path) { opendata_dataset_resource_path site, node, dataset, item }
      let(:edit_path) { edit_opendata_dataset_resource_path site, node, dataset, item }
      let(:delete_path) { delete_opendata_dataset_resource_path site, node, dataset, item }
      let(:download_path) { opendata_dataset_resource_file_path site, node, dataset, item }
      let(:download_tsv_path) { opendata_dataset_resource_tsv_path site, node, dataset, item }
      let(:content_path) { opendata_dataset_resource_content_path site, node, dataset, item }

      before do
        Fs::UploadedFile.create_from_file(resource_file_path, basename: "spec") do |f1|
          Fs::UploadedFile.create_from_file(resource_tsv_path, basename: "spec") do |f2|
            item.in_file = f1
            item.license_id = license.id
            item.in_tsv = f2
            item.save!
          end
        end
        item.reload
      end

      describe "#show" do
        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
        end
      end

      describe "#edit" do
        it do
          visit edit_path
          within "form#item-form" do
            fill_in "item[name]", with: "#{item.name}-modify"
            fill_in "item[text]", with: "sample-#{unique_id}"
            click_button I18n.t('ss.buttons.save')
          end
          expect(current_path).to eq show_path
          expect(page).to have_no_css("form#item-form")
        end
      end

      describe "#delete" do
        it do
          visit delete_path
          within "form" do
            click_button I18n.t('ss.buttons.delete')
          end
          expect(current_path).to eq index_path
        end
      end

      describe "#download" do
        it do
          visit download_path
          expect(status_code).to eq 200
          expect(current_path).to eq download_path
        end
      end

      describe "#download_tsv" do
        it do
          visit download_tsv_path
          expect(status_code).to eq 404
        end
      end

      describe "#content" do
        it do
          visit content_path
          expect(status_code).to eq 200
          expect(current_path).to eq content_path
        end
      end
    end

    context "with item having tsv" do
      let(:resource_file_path) { "#{Rails.root}/spec/fixtures/opendata/test.json" }
      let(:item) { dataset.resources.new(attributes_for(:opendata_resource)) }
      let(:download_tsv_path) { opendata_dataset_resource_tsv_path site, node, dataset, item }

      before do
        Fs::UploadedFile.create_from_file(resource_file_path, basename: "spec") do |f1|
          Fs::UploadedFile.create_from_file(resource_tsv_path, basename: "spec") do |f2|
            item.in_file = f1
            item.license_id = license.id
            item.in_tsv = f2
            item.save!
          end
        end
        item.reload
      end

      describe "#download_tsv" do
        it do
          visit download_tsv_path
          expect(status_code).to eq 200
          expect(current_path).to eq download_tsv_path
        end
      end
    end

    context "when non-tsv file is given for tsv-file" do
      let(:resource_file_path) { "#{Rails.root}/spec/fixtures/opendata/test.json" }
      let(:resource_tsv_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s }

      describe "new and show" do
        it do
          visit new_path
          within "form#item-form" do
            attach_file "item[in_file]", resource_file_path
            fill_in "item[name]", with: unique_id
            select license.name, from: "item_license_id"
            attach_file "item[in_tsv]", resource_tsv_path
            click_button I18n.t('ss.buttons.save')
          end
          expect(status_code).to eq 200
          expect(current_path).to eq index_path
          within "div#errorExplanation" do
            expect(page).to have_content("登録内容を確認してください。")
            expect(page).to have_content("プレビュー用データは不正な値です。")
          end
        end
      end
    end

    context "when preview file is given even if upload file is csv/tsv" do
      let(:resource_file_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
      let(:resource_tsv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis-2.csv" }

      describe "new and show" do
        it do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: unique_id
            select license.name, from: "item_license_id"
            attach_file "item[in_tsv]", resource_tsv_path
            attach_file "item[in_file]", resource_file_path
            click_button I18n.t('ss.buttons.save')
          end
          expect(status_code).to eq 200

          dataset.reload
          item = dataset.resources.first
          show_path = opendata_dataset_resource_path site, node, dataset, item
          expect(current_path).to eq show_path
          # acquire that tsv file is not saved.
          expect(item.tsv).to be_nil
        end
      end
    end
  end
end
