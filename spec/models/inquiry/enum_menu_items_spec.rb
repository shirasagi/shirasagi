require 'spec_helper'

describe Inquiry, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group.id ] }
  let(:helpers) { Rails.application.routes.url_helpers }

  describe ".enum_menu_items" do
    context "with site admin" do
      let!(:user) { cms_user }

      it do
        menu_items = Inquiry.enum_menu_items(site, node, user).to_a
        expect(menu_items.length).to eq 4
        menu_items[0].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.column")
          expect(menu_item.path).to eq helpers.inquiry_columns_path(site: site, cid: node)
        end
        menu_items[1].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.answer")
          expect(menu_item.path).to eq helpers.inquiry_answers_path(site: site, cid: node)
        end
        menu_items[2].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.result")
          expect(menu_item.path).to eq helpers.inquiry_results_path(site: site, cid: node)
        end
        menu_items[3].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.feedback")
          expect(menu_item.path).to eq helpers.inquiry_feedbacks_path(site: site, cid: node)
        end
      end
    end

    context "with column editor" do
      let!(:role) do
        permissions = %w(
          read_private_cms_nodes
          read_other_inquiry_columns edit_other_inquiry_columns delete_other_inquiry_columns)
        create :cms_role, cur_site: site, name: unique_id, permissions: permissions
      end
      let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

      it do
        menu_items = Inquiry.enum_menu_items(site, node, user).to_a
        expect(menu_items.length).to eq 1
        menu_items[0].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.column")
          expect(menu_item.path).to eq helpers.inquiry_columns_path(site: site, cid: node)
        end
      end
    end

    context "with answer charge" do
      let!(:role) do
        permissions = %w(
          read_private_cms_nodes
          read_private_inquiry_answers edit_private_inquiry_answers)
        create :cms_role, cur_site: site, name: unique_id, permissions: permissions
      end
      let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

      it do
        menu_items = Inquiry.enum_menu_items(site, node, user).to_a
        expect(menu_items.length).to eq 2
        menu_items[0].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.answer")
          expect(menu_item.path).to eq helpers.inquiry_answers_path(site: site, cid: node)
        end
        menu_items[1].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.result")
          expect(menu_item.path).to eq helpers.inquiry_results_path(site: site, cid: node)
        end
      end
    end

    context "with answer manager" do
      let!(:role) do
        permissions = %w(
          read_private_cms_nodes
          read_private_inquiry_answers edit_private_inquiry_answers delete_private_inquiry_answers)
        create :cms_role, cur_site: site, name: unique_id, permissions: permissions
      end
      let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

      it do
        menu_items = Inquiry.enum_menu_items(site, node, user).to_a
        expect(menu_items.length).to eq 3
        menu_items[0].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.answer")
          expect(menu_item.path).to eq helpers.inquiry_answers_path(site: site, cid: node)
        end
        menu_items[1].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.result")
          expect(menu_item.path).to eq helpers.inquiry_results_path(site: site, cid: node)
        end
        menu_items[2].tap do |menu_item|
          expect(menu_item.label).to eq I18n.t("inquiry.feedback")
          expect(menu_item.path).to eq helpers.inquiry_feedbacks_path(site: site, cid: node)
        end
      end
    end
  end
end
