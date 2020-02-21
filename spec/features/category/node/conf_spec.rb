require 'spec_helper'

describe "category_node_conf", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  let(:cms_node) { create :cms_node }
  let(:category_node_node) { create :category_node_node }
  let(:category_node_page) { create :category_node_page }

  context "with auth" do
    before { login_cms_user }

    context "cms node" do
      let(:conf_path) { node_conf_path site.id, cms_node }

      it "#split" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_link I18n.t('ss.links.split')
      end

      it "#integrate" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_link I18n.t('ss.links.integrate')
      end
    end

    context "category node node" do
      let(:conf_path) { node_conf_path site.id, category_node_node }

      it "#split" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        click_on I18n.t('ss.links.split')

        within "form" do
          fill_in "item[in_partial_name]", with: "modified"
          fill_in "item[in_partial_basename]", with: "basename"
          click_button I18n.t('ss.buttons.split')
        end

        expect(current_path).to eq conf_path
      end

      it "#integrate" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        click_on I18n.t('ss.links.integrate')
      end
    end

    context "category node page" do
      let(:conf_path) { node_conf_path site.id, category_node_page }

      it "#split" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        click_on I18n.t('ss.links.split')

        within "form" do
          fill_in "item[in_partial_name]", with: "modified"
          fill_in "item[in_partial_basename]", with: "basename"
          click_button I18n.t('ss.buttons.split')
        end

        expect(current_path).to eq conf_path
      end

      it "#integrate" do
        visit conf_path
        expect(current_path).not_to eq sns_login_path
        click_on I18n.t('ss.links.integrate')
      end
    end
  end
end
