require 'spec_helper'

describe "syntax_checker", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
    group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }

  let!(:ss_file) { create :ss_file, site: site }
  let!(:html1) { "<img src=\"#{ss_file.url}\" />" }
  let!(:html2) { "<img alt=\"\" src=\"#{ss_file.url}\" />" }
  let!(:html3) { "<img alt=\" \" src=\"#{ss_file.url}\" />" }
  let!(:html4) { "<img alt=\"#{ss_file.name}\" src=\"#{ss_file.url}\" />" }
  let!(:html5) { "<img alt=\"#{ss_file.name.upcase}\" src=\"#{ss_file.url}\" />" }
  let!(:html6) { "<img alt=\"ファイルの内容を示すテキスト\" src=\"#{ss_file.url}\" />" }

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

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html4
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html5
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html6
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id], html: html1, form_id: form.id }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html4
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html5
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit" do
        visit edit_path

        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html6
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.syntax_check")

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end
end
