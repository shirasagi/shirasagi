require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:part) { create :cms_part_free, html: '<div id="part" class="part"><br><br><br>free html part<br><br><br></div>' }
  let(:layout_html) do
    <<~HTML.freeze
      <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimum-scale=1.0,maximum-scale=2.0">
      </head>
      <body>
        <br><br><br>
        {{ part "#{part.filename.sub(/\..*/, '')}" }}
        <div id="main" class="page">
          {{ yield }}
        </div>
      </body>
      </html>
    HTML
  end
  let!(:layout) { create :cms_layout, html: layout_html }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end

  before do
    site.set(auto_keywords: 'enabled', auto_description: 'enabled')

    node.st_form_ids = [ form.id ]
    node.save!

    login_cms_user
  end

  describe "delete column with entry form on preview editing" do
    let(:column1_value1_value1) { unique_id }
    let(:column1_value2_value1) { unique_id }
    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: state,
        column_values: [
          column1.value_type.new(column: column1, value: column1_value1_value1, order: 0),
          column1.value_type.new(column: column1, value: column1_value2_value1, order: 1),
        ]
      )
    end

    describe "delete" do
      shared_examples "what delete is" do
        it do
          visit cms_preview_path(site: site, path: item.preview_path)

          within "#ss-preview" do
            within ".ss-preview-wrap-column-edit-mode" do
              wait_event_to_fire "ss:inplaceModeChanged" do
                click_on I18n.t("cms.inplace_edit")
              end
            end
          end

          item.reload
          expect(item.column_values.count).to eq 2
          column_values = item.column_values.order_by(order: 1, name: 1).to_a
          column_values[0].tap do |column_value|
            expect(page).to have_css(".ss-preview-column[data-column-id='#{column_value.id}']", text: column_value.value)
          end
          column_values[1].tap do |column_value|
            expect(page).to have_css(".ss-preview-column[data-column-id='#{column_value.id}']", text: column_value.value)
          end

          #
          # Delete
          #
          first(:xpath, "//*[text()='#{column1_value1_value1}']").click
          within "#ss-preview-overlay" do
            page.accept_confirm(I18n.t("ss.confirm.delete")) do
              click_on I18n.t("ss.links.delete")
            end
          end
          if state == "public"
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("workflow.notice.created_branch_page"))
          else
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("ss.notice.deleted"))
          end

          item.reload
          if state == "public"
            expect(item.branches.count).to eq 1
            now_editing_item = item.branches.first
          else
            now_editing_item = item
          end

          expect(now_editing_item.column_values.count).to eq 1
          column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
          column_value1 = column_values[0]
          expect(column_value1.column_id).to eq column1.id
          expect(column_value1.value).to eq column1_value2_value1
          expect(column_value1.order).to eq 1
        end
      end

      context "with public page" do
        let(:state) { "public" }

        it_behaves_like "what delete is"
      end

      context "with closed page" do
        let(:state) { "closed" }

        it_behaves_like "what delete is"
      end
    end
  end
end
