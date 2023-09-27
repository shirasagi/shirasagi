require 'spec_helper'

describe "article_node_page_condition_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:name) { "name-#{unique_id}" }
  let(:basename) { "basename-#{unique_id}" }
  let!(:form) { create!(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:col1) { create!(:cms_column_select, cur_site: site, cur_form: form, required: 'optional', order: 5) }
  let!(:col2) { create!(:cms_column_radio_button, cur_site: site, cur_form: form, required: 'optional', order: 6) }
  let!(:col3) { create!(:cms_column_check_box, cur_site: site, cur_form: form, required: 'optional', order: 7) }
  let!(:layout) { create_cms_layout }

  context "basic crud" do
    let(:condition_value1) { "condition_value-#{unique_id}" }
    let(:condition_value2) { "condition_value-#{unique_id}" }

    before { login_cms_user }

    it do
      #
      # Create
      #
      visit cms_nodes_path(site: site)
      click_on I18n.t("ss.links.new")

      within "#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t("ss.links.change")
          end
        end
      end
      wait_for_cbox do
        within ".mod-article" do
          click_on I18n.t("cms.nodes.article/page")
        end
      end
      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename
        select layout.name, from: "item[layout_id]"

        within "#addon-event-agents-addons-page_list" do
          wait_cbox_open do
            click_on I18n.t("cms.apis.forms.index")
          end
        end
      end
      wait_for_cbox do
        wait_cbox_close do
          click_on form.name
        end
      end
      within "#item-form" do
        within "#addon-event-agents-addons-page_list" do
          select col1.name, from: "item[condition_forms][filters][][column_name]"
          fill_in "item[condition_forms][filters][][condition_values]", with: condition_value1
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Node::Page.all.count).to eq 1

      node = Article::Node::Page.all.first
      expect(node.condition_forms).to have(1).items
      node.condition_forms.first.tap do |condition_form|
        expect(condition_form.form_id).to eq form.id
        expect(condition_form.filters).to have(1).item
        condition_form.filters.first.tap do |filter|
          expect(filter.column_id).to eq col1.id
          expect(filter.condition_kind).to eq "any_of"
          expect(filter.condition_values).to have(1).item
          expect(filter.condition_values).to include(condition_value1)
        end
      end

      #
      # Update
      #
      visit cms_node_path(site: site, id: node)
      click_on I18n.t("ss.links.edit")
      within "#item-form" do
        within "#addon-event-agents-addons-page_list" do
          within first(".filter-table .filter-setting") do
            select col2.name, from: "item[condition_forms][filters][][column_name]"
            fill_in "item[condition_forms][filters][][condition_values]", with: condition_value2
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Node::Page.all.count).to eq 1

      node = Article::Node::Page.all.first
      expect(node.condition_forms).to have(1).items
      node.condition_forms.first.tap do |condition_form|
        expect(condition_form.form_id).to eq form.id
        expect(condition_form.filters).to have(1).item
        condition_form.filters.first.tap do |filter|
          expect(filter.column_id).to eq col2.id
          expect(filter.condition_kind).to eq "any_of"
          expect(filter.condition_values).to have(1).item
          expect(filter.condition_values).to include(condition_value2)
        end
      end

      #
      # Delete Filter
      #
      visit cms_node_path(site: site, id: node)
      click_on I18n.t("ss.links.edit")
      within "#item-form" do
        within "#addon-event-agents-addons-page_list" do
          within first(".filter-table .filter-setting") do
            wait_event_to_fire("ss:conditionFormFilterRemoved") do
              click_on I18n.t("ss.buttons.delete")
            end
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Node::Page.all.count).to eq 1

      node = Article::Node::Page.all.first
      expect(node.condition_forms).to have(1).items
      node.condition_forms.first.tap do |condition_form|
        expect(condition_form.form_id).to eq form.id
        expect(condition_form.filters).to be_blank
      end

      #
      # Delete Form
      #
      visit cms_node_path(site: site, id: node)
      click_on I18n.t("ss.links.edit")
      within "#item-form" do
        wait_event_to_fire "change" do
          within "#addon-event-agents-addons-page_list" do
            within first(".form-table tr[data-id]") do
              click_on I18n.t("ss.buttons.delete")
            end
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Node::Page.all.count).to eq 1

      node = Article::Node::Page.all.first
      expect(node.condition_forms).to be_blank
    end
  end
end
