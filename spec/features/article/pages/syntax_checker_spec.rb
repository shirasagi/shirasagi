require 'spec_helper'

describe "syntax_checker", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
    group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }

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

      it "#edit 01" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html1
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 02" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 03" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 04" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html4
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit 05" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html5
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit 06" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html6
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end

      context "when syntax check is unchecked" do
        it do
          visit edit_path

          within "#addon-cms-agents-addons-body" do
            fill_in_ckeditor "item[html]", with: html1
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                uncheck I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            expect(page).to have_no_css("#errorSyntaxChecker")
          end
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id], html: html1, form_id: form.id }

      before { login_cms_user }

      context "with no columns" do
        it do
          visit edit_path

          within "#addon-cms-agents-addons-form-page" do
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                check I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            # confirm syntax check header is shown to wait for ajax completion
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      it "#edit 01" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 02" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 03" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        end
      end

      it "#edit 04" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html4
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit 05" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html5
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.alt_is_included_in_filename"))
        end
      end

      it "#edit 06" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html6
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end

      context "when syntax check is unchecked" do
        it "#edit 06" do
          visit edit_path

          within ".column-value-palette" do
            wait_for_event_fired("ss:columnAdded") do
              click_on column1.name
            end
          end
          within ".column-value-cms-column-free" do
            fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
          end
          within "#addon-cms-agents-addons-form-page" do
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                uncheck I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            expect(page).to have_no_css("#errorSyntaxChecker")
          end
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
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
        end
        expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

        wait_for_event_fired "ss:correct:done" do
          click_on I18n.t("cms.auto_correct.link")
        end
        expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
        end
        expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
      end
    end

    context "with entry form" do
      let!(:column2) { create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 2) }
      let!(:item) { create :article_page, cur_node: node, html: html1, form_id: form.id }

      before { login_cms_user }

      it "#edit 01" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit 02" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit 03" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit 04" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html1
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit 05" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html2
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t('errors.messages.invalid_multibyte_character'))

          wait_for_event_fired "ss:correct:done" do
            click_on I18n.t("cms.auto_correct.link")
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit 06" do
        visit edit_path

        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column2.name
          end
        end
        within ".column-value-cms-column-list" do
          fill_in "item[column_values][][in_wrap][lists][]", with: html3
        end
        within "#addon-cms-agents-addons-form-page" do
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end

  context "check linkText" do
    let(:html1) { "<a href=\"#{ss_file.url}\"></a>" }
    let(:html2) { "<a href=\"#{ss_file.url}\">#{ss_file.name}</a>" }
    let(:html3) { "<a href=\"#{ss_file.url}\"><img alt=\"ファイルの内容を示すテキスト\" src=\"#{ss_file.url}\" /></a>" }

    context "with cms addon body" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id] }

      before { login_cms_user }

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html1
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html2
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end

      it "#edit" do
        visit edit_path

        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html3
          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              check I18n.t("cms.syntax_check")
              click_on I18n.t("ss.buttons.run")
            end
          end

          # confirm syntax check header is shown to wait for ajax completion
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file.id], html: html1, form_id: form.id }

      before { login_cms_user }

      context "with cms/column/free" do
        it "#edit" do
          visit edit_path

          within ".column-value-palette" do
            wait_for_event_fired("ss:columnAdded") do
              click_on column1.name
            end
          end
          within ".column-value-cms-column-free" do
            fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html1
          end
          within "#addon-cms-agents-addons-form-page" do
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                check I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            # confirm syntax check header is shown to wait for ajax completion
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
          end
        end

        it "#edit" do
          visit edit_path

          within ".column-value-palette" do
            wait_for_event_fired("ss:columnAdded") do
              click_on column1.name
            end
          end
          within ".column-value-cms-column-free" do
            fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html2
          end
          within "#addon-cms-agents-addons-form-page" do
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                check I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            # confirm syntax check header is shown to wait for ajax completion
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
          end
        end

        it "#edit" do
          visit edit_path

          within ".column-value-palette" do
            wait_for_event_fired("ss:columnAdded") do
              click_on column1.name
            end
          end
          within ".column-value-cms-column-free" do
            fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html3
          end
          within "#addon-cms-agents-addons-form-page" do
            wait_for_event_fired "ss:check:done" do
              within ".cms-body-checker" do
                check I18n.t("cms.syntax_check")
                click_on I18n.t("ss.buttons.run")
              end
            end

            # confirm syntax check header is shown to wait for ajax completion
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
            expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
          end
        end
      end

      context "with cms/column/url2" do
        let!(:column1) { create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 1) }

        context "with blank link text" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within ".column-value-cms-column-urlfield2" do
              fill_in "item[column_values][][in_wrap][link_url]", with: unique_url
            end
            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            end
          end
        end

        context "with a link text which length is 3" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within ".column-value-cms-column-urlfield2" do
              fill_in "item[column_values][][in_wrap][link_url]", with: unique_url
              fill_in "item[column_values][][in_wrap][link_label]", with: "abc"
            end
            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('errors.messages.check_link_text'))
            end
          end
        end

        context "with a link text which length is 4" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within ".column-value-cms-column-urlfield2" do
              fill_in "item[column_values][][in_wrap][link_url]", with: unique_url
              fill_in "item[column_values][][in_wrap][link_label]", with: "abcd"
            end
            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            end
          end
        end
      end

      context "with cms/column/headline" do
        let!(:column1) { create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 1) }

        context "when text is blank" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[0] do
              select "h2", from: "item[column_values][][in_wrap][head]"
            end

            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            end
          end
        end

        context "when the first is h3" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[0] do
              select "h3", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('errors.messages.invalid_order_of_h'))
            end
          end
        end

        context "when h1 is following h2" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[0] do
              select "h2", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[1] do
              select "h1", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            end
          end
        end

        context "when h3 is following h1" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[0] do
              select "h1", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[1] do
              select "h3", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('errors.messages.invalid_order_of_h'))
            end
          end
        end

        context "when h3 is following h2" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[0] do
              select "h2", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within all(".column-value-cms-column-headline")[1] do
              select "h3", from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: unique_id
            end

            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            end
          end
        end
      end


      context "with cms/column/table" do
        let!(:column1) { create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 1) }

        context "with blank caption" do
          it do
            visit edit_path

            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
            within ".column-value-cms-column-table" do
              fill_in "height", with: 3
              fill_in "width", with: 3
              click_on I18n.t("cms.column_table.create")
            end
            within "#addon-cms-agents-addons-form-page" do
              wait_for_event_fired "ss:check:done" do
                within ".cms-body-checker" do
                  check I18n.t("cms.syntax_check")
                  click_on I18n.t("ss.buttons.run")
                end
              end

              # confirm syntax check header is shown to wait for ajax completion
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t('cms.syntax_check'))
              expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_table_caption"))
            end
          end
        end
      end
    end
  end

  context "continuous correction" do
    let!(:dictionary) { create :cms_word_dictionary, cur_site: site }
    let(:html) { '<p>ﾃｽﾄ</p><p>①②③④⑤⑥⑦⑧⑨</p>' }

    it do
      login_cms_user to: new_article_page_path(site: site, cid: node)
      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']", count: 10)
        end
      end

      10.times do
        wait_for_event_fired "ss:correct:done" do
          within "form#item-form" do
            within "#errorSyntaxChecker" do
              # click_button I18n.t("cms.auto_correct.link")
              first("[name='btn-correct']").click
            end
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']", count: 0)
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end
end
