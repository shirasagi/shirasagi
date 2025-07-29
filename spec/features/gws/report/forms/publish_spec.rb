require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "closed" }

  before { login_gws_user }

  context "publish form" do
    context "with usual case" do
      it do
        visit gws_report_forms_path(site: site)
        click_on form.name
        click_on I18n.t("gws/workflow.links.publish")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.published')

        form.reload
        expect(form.state).to eq "public"
      end
    end

    context "when is published by others during publishing" do
      it do
        visit gws_report_forms_path(site: site)
        click_on form.name
        click_on I18n.t("gws/workflow.links.publish")

        form.state = "public"
        form.save!

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.published')

        form.reload
        expect(form.state).to eq "public"
      end
    end
  end

  context "depublish form" do
    before do
      form.state = "public"
      form.save!
    end

    context "with usual case" do
      it do
        visit gws_report_forms_path(site: site)
        click_on form.name
        click_on I18n.t("gws/workflow.links.depublish")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.depublished')

        form.reload
        expect(form.state).to eq "closed"
      end
    end

    context "when is depublished by others during depublishing" do
      it do
        visit gws_report_forms_path(site: site)
        click_on form.name
        click_on I18n.t("gws/workflow.links.depublish")

        form.state = "closed"
        form.save!

        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.depublished')

        form.reload
        expect(form.state).to eq "closed"
      end
    end
  end
end
