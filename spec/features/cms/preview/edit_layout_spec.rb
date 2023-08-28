require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "with article page" do
    let(:node) { create :article_node_page, cur_site: site }
    let(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout) }

    before { login_cms_user }

    context "pc preview" do
      let(:preview_path) { cms_preview_path(site: site, path: item.url[1..-1]) }

      context "layout exists in the site top" do
        let(:layout) { create :cms_layout, cur_site: site }
        let(:layout_path) { cms_layout_path(site, layout) }

        it do
          visit preview_path
          new_window = window_opened_by do
            within "#ss-preview" do
              click_on I18n.t("cms.layout")
            end
          end
          within_window new_window do
            expect(current_path).to eq layout_path

            click_on I18n.t("ss.links.edit")
            within "form#item-form" do
              click_button I18n.t('ss.buttons.save')
            end
            wait_for_notice I18n.t("ss.notice.saved")
          end
          layout.reload
          expect(layout.parent).to eq false
        end
      end

      context "layout exists under the node" do
        let(:layout) { create :cms_layout, cur_site: site, cur_node: node }
        let(:layout_path) { node_layout_path(site, node, layout) }

        it do
          visit preview_path
          new_window = window_opened_by do
            within "#ss-preview" do
              click_on I18n.t("cms.layout")
            end
          end
          within_window new_window do
            expect(current_path).to eq layout_path

            click_on I18n.t("ss.links.edit")
            within "form#item-form" do
              click_button I18n.t('ss.buttons.save')
            end
            wait_for_notice I18n.t("ss.notice.saved")
          end
          layout.reload
          expect(layout.parent.id).to eq node.id
        end
      end
    end

    context "mobile preview" do
      let(:layout) { create :cms_layout, cur_site: site }
      let(:preview_path) { cms_preview_path(site: site, path: "#{site.mobile_location}#{item.url}"[1..-1]) }

      it do
        visit preview_path
        within "#ss-preview" do
          expect(page).to have_no_button I18n.t("cms.layout")
        end
      end
    end
  end
end
