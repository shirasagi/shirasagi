require 'spec_helper'

describe "import_datasets", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let(:import_path) { opendata_import_datasets_path site, node }

  context "with auth" do
    before { login_cms_user }
    describe "#import_zip" do

      it do
        visit import_path

        within "form#item-form" do
          attach_file "item[file]", "#{Rails.root}/spec/fixtures/opendata/dataset_import.zip"
          page.accept_alert do
            click_on I18n.t("ss.links.import")
          end
        end

        expect(page).to have_content I18n.t("ss.notice.started_import")
      end
    end
  end
end
