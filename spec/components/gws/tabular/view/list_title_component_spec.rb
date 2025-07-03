require 'spec_helper'

describe Gws::Tabular::View::ListTitleComponent, type: :component, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1, readable_setting_range: "public",
      workflow_state: 'enabled')
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  let(:title_column_ids) { [ column1.id ] }
  let!(:view) do
    create(
      :gws_tabular_view_list, :gws_tabular_view_editable,
      cur_site: site, cur_space: space, cur_form: form, state: 'public',
      title_column_ids: title_column_ids, readable_setting_range: "public")
  end

  around do |example|
    with_request_url("/.g#{site.id}/tabular/#{space.id}/#{form.id}/#{view.id}/files") do
      with_controller_class(Gws::Tabular::FilesController) do
        example.run
      end
    end
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  describe "#render_in" do
    let(:column1_value) { unique_id }
    let(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_data1) do
      file_model.create!(
        cur_site: site, cur_user: user, cur_space: space, cur_form: form,
        "col_#{column1.id}" => column1_value, workflow_user: user, workflow_state: 'approve',
        destination_treat_state: 'no_need_to_treat', requested: now - 1.day, approved: now)
    end
    let(:trash) { nil }
    let(:component) do
      described_class.new(
        cur_site: site, cur_user: user, cur_space: space, cur_form: form, cur_release: form.current_release,
        cur_view: view, item: file_data1, trash: trash)
    end

    context "with text field" do
      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present

            anchor.elements[0].tap do |content|
              expect(content.name).to eq "div"
              expect(content.attr('class')).to include('gws-tabular-column', 'gws-tabular-column-text_field')
              expect(content.attr('data-column-id')).to eq column1.id.to_s
              expect(content.to_html).to include column1_value
            end
          end
        end
      end
    end

    context "with 'updated'" do
      let(:title_column_ids) { %w(updated) }

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.l(file_data1.updated, format: :picker)
          end
        end
      end
    end

    context "with 'created'" do
      let(:title_column_ids) { %w(created) }

      before do
        file_data1.set(created: now - 1.week)
      end

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.l(file_data1.created, format: :picker)
          end
        end
      end
    end

    context "with 'deleted'" do
      let(:title_column_ids) { %w(deleted) }

      before do
        file_data1.set(deleted: now - 2.weeks)
      end

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.l(file_data1.deleted, format: :picker)
          end
        end
      end
    end

    context "with 'updated_or_deleted'" do
      let(:title_column_ids) { %w(updated_or_deleted) }

      before do
        file_data1.set(deleted: now - 2.weeks)
      end

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.l(file_data1.updated, format: :picker)
          end
        end
      end

      context "in trash" do
        let(:trash) { true }

        it do
          render_inline(component).tap do |html|
            html.elements[0].tap do |anchor|
              expect(anchor.name).to eq "a"
              expect(anchor.attr('class')).to eq 'title'
              expect(anchor.attr('href')).to be_present
              expect(anchor.to_html).to include I18n.l(file_data1.deleted, format: :picker)
            end
          end
        end
      end
    end

    context "with 'approved'" do
      let(:title_column_ids) { %w(approved) }

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.l(file_data1.approved, format: :picker)
          end
        end
      end
    end

    context "with 'workflow_state'" do
      let(:title_column_ids) { %w(workflow_state) }

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include I18n.t("workflow.state.#{file_data1.workflow_state}")
          end
        end
      end
    end

    context "with 'destination_treat_state'" do
      let(:title_column_ids) { %w(destination_treat_state) }

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include file_data1.label(:destination_treat_state)
          end
        end
      end
    end

    context "with invalid column" do
      let(:title_column_ids) { [ unique_id ] }

      it do
        render_inline(component).tap do |html|
          html.elements[0].tap do |anchor|
            expect(anchor.name).to eq "a"
            expect(anchor.attr('class')).to eq 'title'
            expect(anchor.attr('href')).to be_present
            expect(anchor.to_html).to include file_data1.id.to_s
          end
        end
      end
    end
  end
end
