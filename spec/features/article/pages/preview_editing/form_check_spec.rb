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
  let(:max_length) { 12 }
  let!(:column1) do
    create(
      :cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text',
      max_length: max_length
    )
  end

  before do
    site.set(auto_keywords: 'enabled', auto_description: 'enabled')

    node.st_form_ids = [ form.id ]
    node.save!

    login_cms_user
  end

  describe "form check with entry form on preview editing" do
    let(:column1_value1) { unique_id }
    let(:column1_value2) { "a" * (max_length + 1) }
    let(:delete_max_length_script) do
      <<~SCRIPT.freeze
        const el = document.querySelector("[name='item[column_values][][in_wrap][value]']");
        if (el) {
          el.removeAttribute('maxlength');
        }
      SCRIPT
    end

    context "with new column" do
      let!(:item) do
        create(:article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: state)
      end

      shared_examples "what form check is on new column" do
        it do
          visit cms_preview_path(site: site, path: item.preview_path)

          within "#ss-preview" do
            within ".ss-preview-wrap-column-edit-mode" do
              wait_event_to_fire "ss:inplaceModeChanged" do
                click_on I18n.t("cms.inplace_edit")
              end
            end
          end

          #
          # Form Check
          #
          wait_event_to_fire("ss:inplaceEditFrameInitialized") do
            page.within_frame page.first("#ss-preview-form-palette") do
              within ".column-value-palette" do
                click_on column1.name
              end
            end
          end
          page.within_frame page.first("#ss-preview-dialog-frame") do
            within "#item-form" do
              within ".column-value-cms-column-textfield" do
                page.execute_script(delete_max_length_script)
                fill_in "item[column_values][][in_wrap][value]", with: column1_value1
              end
              click_on I18n.t("cms.form_check")
            end
            within "#item-form" do
              expect(page).to have_css("#errorFormChecker", text: I18n.t("errors.template.no_errors"))
            end

            within "#item-form" do
              within ".column-value-cms-column-textfield" do
                page.execute_script(delete_max_length_script)
                fill_in "item[column_values][][in_wrap][value]", with: column1_value2
              end
              click_on I18n.t("cms.form_check")
            end
            within "#item-form" do
              expect(page).to have_css("#errorFormChecker", text: I18n.t("errors.messages.too_long", count: max_length))
            end
          end
        end
      end

      context "with public page" do
        let(:state) { "public" }

        it_behaves_like "what form check is on new column"
      end

      context "with closed page" do
        let(:state) { "closed" }

        it_behaves_like "what form check is on new column"
      end
    end

    context "with existing column" do
      let!(:item) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: state,
          column_values: [
            column1.value_type.new(column: column1, value: column1_value1, order: 0),
          ]
        )
      end

      shared_examples "what form check is on existing column" do
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
          expect(item.column_values.count).to eq 1
          column_values = item.column_values.order_by(order: 1, name: 1).to_a
          column_values[0].tap do |column_value|
            expect(page).to have_css(".ss-preview-column[data-column-id='#{column_value.id}']", text: column_value.value)
          end

          #
          # Form Check
          #
          first(:xpath, "//*[text()='#{column1_value1}']").click
          within "#ss-preview-overlay" do
            click_on I18n.t("ss.links.edit")
          end
          page.within_frame page.first("#ss-preview-dialog-frame") do
            within "#item-form" do
              click_on I18n.t("cms.form_check")
            end
            within "#item-form" do
              expect(page).to have_css("#errorFormChecker", text: I18n.t("errors.template.no_errors"))
            end

            within "#item-form" do
              within ".column-value-cms-column-textfield" do
                page.execute_script(delete_max_length_script)
                fill_in "item[column_values][][in_wrap][value]", with: column1_value2
              end
              click_on I18n.t("cms.form_check")
            end
            within "#item-form" do
              expect(page).to have_css("#errorFormChecker", text: I18n.t("errors.messages.too_long", count: max_length))
            end
          end
        end
      end

      context "with public page" do
        let(:state) { "public" }

        it_behaves_like "what form check is on existing column"
      end

      context "with closed page" do
        let(:state) { "closed" }

        it_behaves_like "what form check is on existing column"
      end
    end
  end
end
