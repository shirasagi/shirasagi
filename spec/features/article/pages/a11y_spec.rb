require 'spec_helper'

# アクセシビリティチェック実行後の自動修正を実行すると以下の問題点の修正を確認するテスト
# 1) 項目のドロップダウンが空になる
# 2) 空のまま保存すると項目が最後に配置される
# 3) などなど
describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let!(:node) { create :article_node_page, cur_site: site }

  context "confirm that order is normal after a11y auto correct" do
    let!(:article1) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: "closed",
        column_values: [
          column1.value_type.new(column: column1, value: unique_id),
          column1.value_type.new(column: column1, value: "Ａ-Ｚａ-ｚ０-９"),
          column1.value_type.new(column: column1, value: unique_id),
        ]
      )
    end

    before do
      node.st_form_ids = [ form.id ]
      node.st_form_default = form
      node.save!
    end

    it do
      login_cms_user to: edit_article_page_path(site: site, cid: node, id: article1)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      # アクセシビリティを実行する前に保存して order に適切な値をセットさせる
      within 'form#item-form' do
        wait_for_cbox_opened { click_on I18n.t('ss.buttons.draft_save') }
      end
      within_cbox do
        click_on I18n.t("ss.buttons.ignore_alert")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      Article::Page.all.first.tap do |item|
        item.column_values.to_a.tap do |column_values|
          expect(column_values).to have(3).items
          column_values[0].tap do |column_value|
            expect(column_value.order).to eq 0
          end
          column_values[1].tap do |column_value|
            expect(column_value.order).to eq 1
          end
          column_values[2].tap do |column_value|
            expect(column_value.order).to eq 2
          end
        end
      end

      # アクセシビリティ実行＆自動修正実行
      visit edit_article_page_path(site: site, cid: node, id: article1)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within 'form#item-form' do
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
        end
        expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
        end
        expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))

        within "#addon-cms-agents-addons-form-page" do
          Article::Page.all.first.tap do |item|
            item.column_values.to_a.tap do |column_values|
              within "#column-value-#{column_values[0].id}" do
                expect(page.all('[name="item[column_values][][order]"] option').count).to eq 3
                page.find('[name="item[column_values][][order]"] option:checked').tap do |selected|
                  expect(selected.value).to eq "0"
                  expect(selected.text.strip).to eq "1"
                end
              end
              within "#column-value-#{column_values[1].id}" do
                expect(page.all('[name="item[column_values][][order]"] option').count).to eq 3
                page.find('[name="item[column_values][][order]"] option:checked').tap do |selected|
                  expect(selected.value).to eq "1"
                  expect(selected.text.strip).to eq "2"
                end
              end
              within "#column-value-#{column_values[2].id}" do
                expect(page.all('[name="item[column_values][][order]"] option').count).to eq 3
                page.find('[name="item[column_values][][order]"] option:checked').tap do |selected|
                  expect(selected.value).to eq "2"
                  expect(selected.text.strip).to eq "3"
                end
              end
            end
          end
        end

        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |item|
        item.column_values.to_a.tap do |column_values|
          expect(column_values).to have(3).items
          column_values[0].tap do |column_value|
            expect(column_value.order).to eq 0
          end
          column_values[1].tap do |column_value|
            expect(column_value.order).to eq 1
          end
          column_values[2].tap do |column_value|
            expect(column_value.order).to eq 2
          end
        end
      end
    end
  end
end
