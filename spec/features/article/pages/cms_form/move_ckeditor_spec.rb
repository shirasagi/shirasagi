require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let!(:column9) do
    create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
  end

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context '#5489: https://github.com/shirasagi/shirasagi/issues/5489' do
    before { login_cms_user }

    it do
      visit new_article_page_path(site: site, cid: node)
      wait_for_all_ckeditors_ready

      instance_count = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instance_count.length).to eq 1

      within 'form#item-form' do
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column9.name
          end
        end
      end

      wait_for_all_ckeditors_ready

      instance_count = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instance_count.length).to eq 2

      within 'form#item-form' do
        within "#addon-cms-agents-addons-form-page" do
          within ".column-value-cms-column-free" do
            wait_for_event_fired("column:afterMove") { click_on "keyboard_arrow_up" }
          end
        end
      end

      wait_for_all_ckeditors_ready

      instance_count = page.evaluate_script("Object.keys(CKEDITOR.instances)")
      expect(instance_count.length).to eq 2

      within 'form#item-form' do
        within "#addon-cms-agents-addons-form-page" do
          within ".column-value-cms-column-free" do
            expect(page).to have_css(".cke_toolbox")
          end
        end
      end
    end
  end
end
