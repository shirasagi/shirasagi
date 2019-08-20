require 'spec_helper'

describe "cms_node_import", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :cms_node_import_node, name: "import" }
  let(:index_path) { node_import_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(current_path).to eq index_path

      within "form#task-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
        click_button I18n.t('ss.buttons.import')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))
    end
  end
end
