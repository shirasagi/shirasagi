require 'spec_helper'

describe "cms_node_import", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :cms_node_import_node, name: "import" }
  let(:index_path) { node_import_path site.id, node }
  let(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }

  context "with auth" do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(current_path).to eq index_path

      within "form#task-form" do
        attach_file "item[in_file]", file
        page.accept_alert do
          click_button I18n.t('ss.buttons.import')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))
    end

    context "with max file size" do
      let!(:max) { create :ss_max_file_size, in_size_mb: 0 }
      let(:error_message) do
        filename = "site.zip"
        size = ActiveSupport::NumberHelper.number_to_human_size(::File.size(file))
        limit = ActiveSupport::NumberHelper.number_to_human_size(0)
        I18n.t("errors.messages.too_large_file", filename: filename, size: size, limit: limit)
      end

      it "#import" do
        visit index_path
        expect(current_path).to eq index_path

        within "form#task-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
          fill_in 'item[import_date]', with: I18n.l(Time.zone.now, format: :long)
          page.accept_alert do
            click_button I18n.t('ss.buttons.import')
          end
        end

        expect(current_path).to eq index_path
        expect(page).to have_css("#errorExplanation li", text: error_message)
      end
    end
  end
end
