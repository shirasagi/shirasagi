require 'spec_helper'

describe "syntax_checker", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
    group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:column2) { create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 2) }

  let!(:ss_file) { create :ss_file, site: site }
  let!(:html1) { "<img src=\"#{ss_file.url}\" />" }
  let!(:html2) { "<img alt=\"\" src=\"#{ss_file.url}\" />" }
  let!(:html3) { "<img alt=\"#{ss_file.name}\" src=\"#{ss_file.url}\" />" }

  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "check imgAlt" do
    context "with cms addon body" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id] }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html1
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          click_button I18n.t("cms.syntax_check")
        end
        wait_for_ajax do
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          click_button I18n.t("cms.syntax_check")
        end
        wait_for_ajax do
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id], html: html1, form_id: form.id }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax

          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end

  context "check MultibyteCharacter" do
    let!(:html1) { "<div>Ａ-Ｚａ-ｚ０-９</div>" }
    let!(:html2) { "<div>A-Za-z0-9Ａ-Ｚａ-ｚ０-９</div>" }
    let!(:html3) { "<div>A-Za-z0-9</div>" }

    context "with cms addon body" do
      let!(:item) { create :article_page, cur_node: node }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html1
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
          end
          click_link I18n.t("cms.auto_correct.link")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          click_button I18n.t("cms.syntax_check")
        end
        wait_for_ajax do
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
        end
        click_link I18n.t("cms.auto_correct.link")
        wait_for_ajax do
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          click_button I18n.t("cms.syntax_check")
        end
        wait_for_ajax do
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, html: html1, form_id: form.id }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax

          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
          click_link I18n.t("cms.auto_correct.link")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
          click_link I18n.t("cms.auto_correct.link")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column1.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column2.name
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax

          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
          click_link I18n.t("cms.auto_correct.link")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column2.name
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))
          click_link I18n.t("cms.auto_correct.link")
          wait_for_ajax do
            expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column2.name
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")
          wait_for_ajax
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end
end
