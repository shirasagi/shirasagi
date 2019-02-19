require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, tmpdir: true, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }

  context "with standard form" do
    let(:name) { unique_id }

    before do
      login_gws_user
    end

    describe "ss-2579" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on I18n.t("ss.links.new")
        # click_on I18n.t("gws/workflow.forms.default")

        within "form#item-form" do
          fill_in "item[name]", with: name
          click_on I18n.t("ss.buttons.upload")
        end
        within "#cboxLoadedContent" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_on I18n.t("ss.buttons.save")
        end
        within "form#item-form" do
          expect(page).to have_content("logo.png")
          click_on I18n.t("ss.buttons.save")
        end

        expect(Gws::Workflow::File.site(site).count).to eq 1

        visit gws_workflow_files_path(site: site, state: "all")
        click_on name
        click_on I18n.t("ss.links.copy")
        within "form" do
          click_on I18n.t("ss.buttons.save")
        end

        expect(Gws::Workflow::File.site(site).count).to eq 2
        prefix = I18n.t("workflow.cloned_name_prefix")
        expect(Gws::Workflow::File.site(site).where(name: "[#{prefix}] #{name}")).to be_present
      end
    end
  end
end
