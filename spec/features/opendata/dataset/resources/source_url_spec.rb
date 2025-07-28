require 'spec_helper'

describe "opendata_dataset_resources", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let!(:name) { unique_id }
  let!(:format) { "csv" }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:index_path) { opendata_dataset_resources_path site, node, dataset.id }

  context "with auth" do
    let(:new_path) { new_opendata_dataset_resource_path site, node, dataset.id }

    before { login_cms_user }

    describe "#new" do
      context "valid url" do
        let(:source_url) { "https://sample.example.jp/source.csv" }

        it do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
            select license.name, from: "item_license_id"
            fill_in "item[source_url]", with: source_url
            fill_in "item[format]", with: source_url
            click_button I18n.t('ss.buttons.publish_save')
          end
          wait_for_notice I18n.t("ss.notice.saved")

          within "#addon-basic" do
            expect(page).to have_text(name)
            expect(page).to have_link(source_url)
          end
        end
      end

      context "invalid url" do
        let(:source_url) { 'javascript:alert("hello");' }

        it do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
            select license.name, from: "item_license_id"
            fill_in "item[source_url]", with: source_url
            fill_in "item[format]", with: source_url
            click_button I18n.t('ss.buttons.publish_save')
          end
          within "#errorExplanation" do
            expect(page).to have_text(I18n.t("errors.messages.url"))
          end
        end
      end
    end
  end
end
