require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) { create(:inquiry_node_form, cur_site: site, layout_id: layout.id, inquiry_captcha: "disabled") }
  let!(:email) { "#{unique_id}@example.jp" }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context "not use select_form_column" do
    context "email required" do
      let!(:email_column) do
        create(:inquiry_column_email, site: site, node: node, required: "required",
          input_confirm: "enabled")
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 2)
        within all("fieldset.column")[0] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end

        # nothing input
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.blank")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input email
        within "form" do
          fill_in "item[#{email_column.id}]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.mismatch")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input confirm
        within "form" do
          fill_in "item[#{email_column.id}_confirm]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end
    end

    context "email not required" do
      let!(:email_column) do
        create(:inquiry_column_email, site: site, node: node, required: "optional",
          input_confirm: "enabled")
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 2)
        within all("fieldset.column")[0] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        # nothing input
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 2)
        within all("fieldset.column")[0] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        # input email
        within "form" do
          fill_in "item[#{email_column.id}]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.mismatch")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input confirm
        within "form" do
          fill_in "item[#{email_column.id}_confirm]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end
    end
  end

  context "use select_form_column" do
    context "email not required" do
      let!(:select_form_column) do
        create(:inquiry_column_form_select, site: site, node: node, required: "required")
      end
      let!(:email_column) do
        create(:inquiry_column_email, site: site, node: node, required: "optional",
          input_confirm: "enabled", required_in_select_form: %w(必要))
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 3)
        within all("fieldset.column")[0] do
          expect(page).to have_text(select_form_column.name)
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        within ".fields.form-select" do
          choose "不要"
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        # nothing input
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 3)
        within all("fieldset.column")[0] do
          expect(page).to have_text(select_form_column.name)
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        within ".fields.form-select" do
          choose "不要"
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        # input email
        within "form" do
          fill_in "item[#{email_column.id}]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.mismatch")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input confirm
        within "form" do
          fill_in "item[#{email_column.id}_confirm]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end

      it do
        visit node.url

        expect(page).to have_selector("fieldset.column", count: 3)
        within all("fieldset.column")[0] do
          expect(page).to have_text(select_form_column.name)
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_no_text(I18n.t('inquiry.required_field'))
        end

        within ".fields.form-select" do
          choose "必要"
        end
        within all("fieldset.column")[1] do
          expect(page).to have_text(email_column.name)
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end
        within all("fieldset.column")[2] do
          expect(page).to have_text(I18n.t("inquiry.confirm_input", name: email_column.name))
          expect(page).to have_text(I18n.t('inquiry.required_field'))
        end

        # nothing input
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.blank")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input email
        within "form" do
          fill_in "item[#{email_column.id}]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_css("#errorExplanation", text: "#{email_column.name}#{I18n.t("errors.messages.mismatch")}")
        expect(page).to have_no_button(I18n.t('inquiry.submit'))

        # input confirm
        within "form" do
          fill_in "item[#{email_column.id}_confirm]", with: email
        end
        within "footer" do
          click_on I18n.t('inquiry.confirm')
        end
        expect(page).to have_no_css("#errorExplanation")
        expect(page).to have_button(I18n.t('inquiry.submit'))
      end
    end
  end
end
