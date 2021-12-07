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

  describe "swap column in entry form on preview editing" do
    let(:column1_value1_value) { unique_id }
    let(:column1_value2_value) { unique_id }
    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: state,
        column_values: [
          column1.value_type.new(column: column1, value: column1_value1_value),
          column1.value_type.new(column: column1, value: column1_value2_value),
        ]
      )
    end

    describe "move down" do
      shared_examples "what move down is" do
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
          # Move first column value down
          #
          first(:xpath, "//*[text()='#{column1_value1_value}']").click
          if state == "public"
            within "#ss-preview-overlay" do
              first(".ss-preview-overlay-btn-move-down").click
            end
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("workflow.notice.created_branch_page"))
          else
            within "#ss-preview-overlay" do
              wait_event_to_fire "column:moved" do
                first(".ss-preview-overlay-btn-move-down").click
              end
            end
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("ss.notice.moved"))
          end

          item.reload
          if state == "public"
            expect(item.branches.count).to eq 1
            branch = item.branches.first
            expect(branch.column_values.count).to eq 2
            column_values = branch.column_values.order_by(order: 1, name: 1).to_a
          else
            expect(item.column_values.count).to eq 2
            column_values = item.column_values.order_by(order: 1, name: 1).to_a
          end
          column_value1 = column_values[0]
          expect(column_value1.value).to eq column1_value2_value
          expect(column_value1.order).to eq 0
          column_value2 = column_values[1]
          expect(column_value2.value).to eq column1_value1_value
          expect(column_value2.order).to eq 1

          #
          # Move first column value down, again
          #
          first(:xpath, "//*[text()='#{column1_value2_value}']").click
          within "#ss-preview-overlay" do
            wait_event_to_fire "column:moved" do
              first(".ss-preview-overlay-btn-move-down").click
            end
          end

          item.reload
          if state == "public"
            expect(item.branches.count).to eq 1
            branch = item.branches.first
            expect(branch.column_values.count).to eq 2
            column_values = branch.column_values.order_by(order: 1, name: 1).to_a
          else
            expect(item.column_values.count).to eq 2
            column_values = item.column_values.order_by(order: 1, name: 1).to_a
          end
          column_value1 = column_values[0]
          expect(column_value1.value).to eq column1_value1_value
          expect(column_value1.order).to eq 0
          column_value2 = column_values[1]
          expect(column_value2.value).to eq column1_value2_value
          expect(column_value2.order).to eq 1
        end
      end

      context "with public page" do
        let(:state) { "public" }

        it_behaves_like "what move down is"
      end

      context "with closed page" do
        let(:state) { "closed" }

        it_behaves_like "what move down is"
      end
    end

    describe "move up" do
      shared_examples "what move up is" do
        it do
          visit cms_preview_path(site: site, path: item.preview_path)

          wait_event_to_fire "ss:inplaceModeChanged" do
            within "#ss-preview" do
              within ".ss-preview-wrap-column-edit-mode" do
                click_on I18n.t("cms.inplace_edit")
              end
            end
          end

          # item.reload
          expect(item.column_values.count).to eq 2
          column_values = item.column_values.order_by(order: 1, name: 1).to_a
          column_values[0].tap do |column_value|
            expect(page).to have_css(".ss-preview-column[data-column-id='#{column_value.id}']", text: column_value.value)
          end
          column_values[1].tap do |column_value|
            expect(page).to have_css(".ss-preview-column[data-column-id='#{column_value.id}']", text: column_value.value)
          end

          #
          # Move last column value up
          #
          first(:xpath, "//*[text()='#{column1_value2_value}']").click
          if state == "public"
            within "#ss-preview-overlay" do
              first(".ss-preview-overlay-btn-move-up").click
            end
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("workflow.notice.created_branch_page"))
          else
            within "#ss-preview-overlay" do
              wait_event_to_fire "column:moved" do
                first(".ss-preview-overlay-btn-move-up").click
              end
            end
            expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("ss.notice.moved"))
          end

          item.reload
          if state == "public"
            expect(item.branches.count).to eq 1
            branch = item.branches.first
            expect(branch.column_values.count).to eq 2
            column_values = branch.column_values.order_by(order: 1, name: 1).to_a
          else
            expect(item.column_values.count).to eq 2
            column_values = item.column_values.order_by(order: 1, name: 1).to_a
          end
          column_value1 = column_values[0]
          expect(column_value1.value).to eq column1_value2_value
          expect(column_value1.order).to eq 0
          column_value2 = column_values[1]
          expect(column_value2.value).to eq column1_value1_value
          expect(column_value2.order).to eq 1

          #
          # Move last column value up, again
          #
          first(:xpath, "//*[text()='#{column1_value1_value}']").click
          within "#ss-preview-overlay" do
            wait_event_to_fire "column:moved" do
              first(".ss-preview-overlay-btn-move-up").click
            end
          end

          item.reload
          if state == "public"
            expect(item.branches.count).to eq 1
            branch = item.branches.first
            expect(branch.column_values.count).to eq 2
            column_values = branch.column_values.order_by(order: 1, name: 1).to_a
          else
            expect(item.column_values.count).to eq 2
            column_values = item.column_values.order_by(order: 1, name: 1).to_a
          end
          column_value1 = column_values[0]
          expect(column_value1.value).to eq column1_value1_value
          expect(column_value1.order).to eq 0
          column_value2 = column_values[1]
          expect(column_value2.value).to eq column1_value2_value
          expect(column_value2.order).to eq 1
        end
      end

      context "with public page" do
        let(:state) { "public" }

        it_behaves_like "what move up is"
      end

      context "with closed page" do
        let(:state) { "closed" }

        it_behaves_like "what move up is"
      end
    end
  end
end
