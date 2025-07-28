require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form1) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:form2) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:form1_column_free) do
    create(:cms_column_free, cur_site: site, cur_form: form1, required: "optional")
  end
  let!(:form2_column_free) do
    create(:cms_column_free, cur_site: site, cur_form: form2, required: "optional")
  end
  let(:name) { unique_id }

  before do
    # cms_role.add_to_set(permissions: %w(read_cms_body_layouts))
    site.set(auto_keywords: 'enabled', auto_description: 'enabled')
    node.st_form_ids = [ form1.id, form2.id ]
    node.save!
  end

  context 'ckeditor instance management' do
    before { login_cms_user }

    it do
      visit new_article_page_path(site: site, cid: node)

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 1
      expect(instances).to include("item_html")

      # change to form1
      within 'form#item-form' do
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form1.name, from: 'in_form_id'
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 1
      expect(instances).to include("item_html")

      # add free column
      within 'form#item-form' do
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on form1_column_free.name
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 2
      expect(instances).to include("item_html")
      instances.reject { |instance| instance == "item_html" }.each { |instance| expect(instance).to start_with "column-value-" }

      # add 1 more free column
      within 'form#item-form' do
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on form1_column_free.name
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 3
      expect(instances).to include("item_html")
      instances.reject { |instance| instance == "item_html" }.each { |instance| expect(instance).to start_with "column-value-" }

      # delete free column
      within first(".column-value-cms-column-free") do
        within ".column-value-header" do
          wait_for_event_fired("ss:columnDeleted") do
            page.accept_confirm(I18n.t("ss.confirm.delete")) do
              click_on I18n.t("ss.links.delete")
            end
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 2
      expect(instances).to include("item_html")
      instances.reject { |instance| instance == "item_html" }.each { |instance| expect(instance).to start_with "column-value-" }

      # change to form2
      within 'form#item-form' do
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form2.name, from: 'in_form_id'
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 1
      expect(instances).to include("item_html")

      # add free column
      within 'form#item-form' do
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on form2_column_free.name
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 2
      expect(instances).to include("item_html")
      instances.reject { |instance| instance == "item_html" }.each { |instance| expect(instance).to start_with "column-value-" }

      # change to default form
      within 'form#item-form' do
        wait_for_event_fired("ss:formDeactivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select I18n.t("cms.default_form"), from: 'in_form_id'
          end
        end
      end

      wait_for_all_ckeditors_ready
      instances = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instances.length).to eq 2
      expect(instances).to include("item_html")
      instances.reject { |instance| instance == "item_html" }.each { |instance| expect(instance).to start_with "column-value-" }
    end
  end
end
