require 'spec_helper'

describe "cms_api_tokens", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create(:cms_api_token, site: site) }
  let(:name) { unique_id }

  let(:index_path) { cms_api_tokens_path site.id }
  let(:new_path) { new_cms_api_token_path site.id }
  let(:show_path) { cms_api_token_path site.id, item }
  let(:delete_path) { delete_cms_api_token_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    context "#index" do
      it do
        visit index_path
        expect(current_path).to eq index_path
      end
    end

    context "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        within "#addon-basic" do
          expect(page).to have_css("dd", text: name)
        end
      end
    end

    context "#show" do
      it do
        visit show_path
        within "#addon-basic" do
          expect(page).to have_css("dd", text: item.name)
          expect(page).to have_css("dd", text: item.jwt_id)
          expect(page).to have_css("dd", text: item.to_jwt)
        end
      end
    end

    context "#delete" do
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
