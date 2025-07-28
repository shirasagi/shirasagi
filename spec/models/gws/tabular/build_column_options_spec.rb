require 'spec_helper'

describe Gws::Tabular, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1, readable_setting_range: "public",
      workflow_state: workflow_state)
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  describe "#build_column_options" do
    let(:release) { form.current_release }

    context "with workflow_state is 'disabled'" do
      let(:workflow_state) { 'disabled' }

      it do
        options = described_class.build_column_options(release, site: site)
        expect(options).to have(5).items
        expect(options).to include([ column1.name, column1.id.to_s ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.updated"), "updated" ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.created"), "created" ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.deleted"), "deleted" ])
        expect(options).to include(
          [ I18n.t("gws/tabular.options.column.updated_or_deleted"), "updated_or_deleted", { only: %i[title meta] } ]
        )
      end
    end

    context "with workflow_state is 'enabled'" do
      let(:workflow_state) { 'enabled' }

      it do
        options = described_class.build_column_options(release, site: site)
        expect(options).to have(5 + 3).items
        expect(options).to include([ column1.name, column1.id.to_s ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.updated"), "updated" ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.created"), "created" ])
        expect(options).to include([ I18n.t("mongoid.attributes.ss/document.deleted"), "deleted" ])
        expect(options).to include(
          [ I18n.t("gws/tabular.options.column.updated_or_deleted"), "updated_or_deleted", { only: %i[title meta] } ]
        )
        # ワークフロー系のオプション
        expect(options).to include([ I18n.t("mongoid.attributes.workflow/approver.approved"), "approved" ])
        expect(options).to include([ I18n.t("mongoid.attributes.workflow/approver.workflow_state"), "workflow_state" ])
        expect(options).to include(
          [ I18n.t("mongoid.attributes.gws/workflow2/destination_state.destination_treat_state"), "destination_treat_state" ]
        )
      end
    end
  end
end
