require 'spec_helper'

describe "cms_generate_pages", type: :feature, dbscope: :example, js: :true do
  let!(:site) { cms_site }
  let!(:node) { create :cms_node_page, cur_site: site }
  let!(:node_1) { create :cms_node_page, cur_site: site }
  let(:index_path) { node_conf_path site.id, node }
  let(:edit_path) { edit_node_conf_path site.id, node }
  let(:delete_path) { delete_node_conf_path site.id, node }

  context "Try Move Function" do
    before { login_cms_user }

    it "#move" do
      save_filename = node.filename

      visit index_path
      click_link(I18n.t("ss.links.move"))

      within "form#item-form" do
        within(".destination") do
          wait_for_cbox_opened { click_link(I18n.t("cms.apis.nodes.index")) }
        end
      end
      within_cbox do
        expect(page).to have_css("tr[data-id='#{node_1.id}']", text: node_1.name)
        wait_for_cbox_closed { click_on node_1.name }
      end
      within "form#item-form" do
        within(".destination") do
          expect(page).to have_css("tr[data-id='#{node_1.id}']", text: node_1.name)
        end
        click_on I18n.t("ss.buttons.move")
      end

      within_cbox do
        wait_for_turbo_frame("#contents-frame")
        find("#confirm_changes").click
        click_on I18n.t("ss.buttons.move")
      end
      wait_for_notice I18n.t("ss.notice.moved")

      Cms::Node.find(node.id).tap do |after_move|
        expect(after_move.parent.id).to eq node_1.id
        expect(after_move.filename).to eq "#{node_1.filename}/#{save_filename}"
      end
    end

    it "when cancel" do
      visit index_path
      click_link(I18n.t("ss.links.move"))

      within "form#item-form" do
        within(".destination") do
          wait_for_cbox_opened { click_link(I18n.t("cms.apis.nodes.index")) }
        end
      end
      within_cbox do
        expect(page).to have_css("tr[data-id='#{node_1.id}']", text: node_1.name)
        wait_for_cbox_closed { click_on node_1.name }
      end
      within "form#item-form" do
        within(".destination") do
          expect(page).to have_css("tr[data-id='#{node_1.id}']", text: node_1.name)
        end
        click_on I18n.t("ss.buttons.move")
      end
      wait_for_ajax

      within_cbox do
        click_on I18n.t("ss.buttons.close")
      end

      expect(current_path).to eq move_confirm_node_conf_path(site: site, cid: node)
      expect(page).to have_css("form#item-form")
    end

    it "when slash('/') is given" do
      visit index_path
      click_link(I18n.t("ss.links.move"))
      wait_for_ajax

      within "form#item-form" do
        fill_in "item[destination_basename]", with: "#{node_1.filename}/#{unique_id}"
        click_on I18n.t("ss.buttons.move")
      end
      message = I18n.t("errors.messages.invalid_filename")
      attribute = I18n.t("activemodel.attributes.cms/node/move_service.destination_basename")
      message = I18n.t("errors.format", attribute: attribute, message: message)
      wait_for_error message
    end

    context "keep the same parent folder after move" do
      let(:node) { create :cms_node_page, cur_node: node_1 }
      let(:new_basename) { unique_id }

      it "#move" do
        expect(node.parent).to eq node_1

        visit index_path
        click_link(I18n.t("ss.links.move"))
        wait_for_ajax

        within "form#item-form" do
          fill_in "item[destination_basename]", with: new_basename
          click_on I18n.t("ss.buttons.move")
        end

        within_cbox do
          wait_for_turbo_frame("#contents-frame")
          find("#confirm_changes").click
          click_on I18n.t("ss.buttons.move")
        end
        wait_for_notice I18n.t("ss.notice.moved")

        Cms::Node.find(node.id).tap do |after_move|
          expect(after_move.parent.id).to eq node_1.id
          expect(after_move.filename).to eq "#{node_1.filename}/#{new_basename}"
        end
      end
    end
  end
end
