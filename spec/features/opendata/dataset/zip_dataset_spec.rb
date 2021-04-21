require 'spec_helper'

describe "opendata_dataset_resources", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:index_path) { opendata_dataset_resources_path site, node, dataset.id }

  context "with auth" do
    let(:resource_file_path1) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    let(:resource_file_path2) { "#{Rails.root}/spec/fixtures/opendata/shift_jis-2.csv" }
    let(:resource_file_path3) { "#{Rails.root}/spec/fixtures/opendata/shift_jis-3.csv" }
    let(:new_path) { new_opendata_dataset_resource_path site, node, dataset.id }

    before { login_cms_user }

    def extract_filenames
      filenames = []
      Zip::File.open(dataset.zip_path) do |archive|
        archive.each do |entry|
          filenames << entry.name.force_encoding("utf-8").scrub
        end
      end
      filenames
    end

    def new_resource(path)
      visit new_path
      within "form#item-form" do
        attach_file "item[in_file]", path
        fill_in "item[name]", with: unique_id
        select license.name, from: "item_license_id"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    def delete_resource(filename)
      dataset.reload
      item = dataset.resources.where(filename: filename).first

      visit delete_opendata_dataset_resource_path(site, node, dataset, item)
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    describe "#new resource" do
      it do
        new_resource(resource_file_path1)
        expect(extract_filenames).to match_array %w(shift_jis-1.csv)

        new_resource(resource_file_path2)
        expect(extract_filenames).to match_array %w(shift_jis-1.csv shift_jis-2-2.csv)

        new_resource(resource_file_path3)
        expect(extract_filenames).to match_array %w(shift_jis-1.csv shift_jis-2-2.csv shift_jis-3-3.csv)

        delete_resource("shift_jis.csv")
        expect(extract_filenames).to match_array %w(shift_jis-2-2.csv shift_jis-3-3.csv)

        delete_resource("shift_jis-2.csv")
        expect(extract_filenames).to match_array %w(shift_jis-3-3.csv)

        delete_resource("shift_jis-3.csv")
        expect(::File.exists?(dataset.zip_path)).to be_falsey
      end
    end

    describe "#delete dataset" do
      it do
        new_resource(resource_file_path1)
        new_resource(resource_file_path2)
        new_resource(resource_file_path3)
        expect(extract_filenames).to match_array %w(shift_jis-1.csv shift_jis-2-2.csv shift_jis-3-3.csv)

        zip_path = dataset.zip_path
        visit delete_opendata_dataset_path(site, node, dataset)
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(::File.exists?(zip_path)).to be_falsey
      end
    end
  end
end
