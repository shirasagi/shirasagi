require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "move with form" do
    let!(:source_group) { create(:revision_new_group) }
    let!(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset) { create(:move_changeset, revision_id: revision.id, source: source_group) }

    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text', order: 10)
    end
    let!(:column2) do
      create(:cms_column_text_area, cur_site: site, cur_form: form, order: 20)
    end
    let!(:column3) do
      create(:cms_column_free, cur_site: site, cur_form: form, order: 30)
    end

    let!(:source_page1) do
      # regular article page
      main_contact = source_group.contact_groups.where(main_state: "main").first
      html = <<~HTML.freeze
        <div>
          <p>TEL: <a href="tel:#{main_contact.contact_tel}">#{main_contact.contact_tel}</a></p>
          <p>FAX: <a href="tel:#{main_contact.contact_fax}">#{main_contact.contact_fax}</a></p>
          <p>Email: <a href="mailto:#{main_contact.contact_email}">#{main_contact.contact_email}</a></p>
        </div>
      HTML

      create(:article_page, cur_site: site, html: html)
    end
    let!(:source_page2) do
      # article page with form
      main_contact = source_group.contact_groups.where(main_state: "main").first

      text = <<~TEXT.freeze
        TEL: #{main_contact.contact_tel}
        FAX: #{main_contact.contact_fax}
      TEXT
      html = <<~HTML.freeze
        <div>
          <p>TEL: <a href="tel:#{main_contact.contact_tel}">#{main_contact.contact_tel}</a></p>
          <p>FAX: <a href="tel:#{main_contact.contact_fax}">#{main_contact.contact_fax}</a></p>
          <p>Email: <a href="mailto:#{main_contact.contact_email}">#{main_contact.contact_email}</a></p>
        </div>
      HTML

      create(
        :article_page, cur_site: site,
        form: form, column_values: [
          column1.value_type.new(column: column1, value: "TEL: #{main_contact.contact_tel}"),
          column2.value_type.new(column: column2, value: text),
          column3.value_type.new(column: column3, value: html)
        ]
      )
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      # skip checking group because groups is already checked in move_spec.rb

      # check page
      Cms::Page.find(source_page1.id).tap do |page_after_move|
        source_main_contact = source_group.contact_groups.where(main_state: "main").first
        expect(page_after_move.html).not_to include(source_main_contact.contact_tel)
        expect(page_after_move.html).not_to include(source_main_contact.contact_fax)
        expect(page_after_move.html).not_to include(source_main_contact.contact_email)

        destination = changeset.destinations.first
        destination_main_contact = destination["contact_groups"].find { |contact| contact["main_state"] == "main" }
        expect(page_after_move.html).to include(destination_main_contact["contact_tel"])
        expect(page_after_move.html).to include(destination_main_contact["contact_fax"])
        expect(page_after_move.html).to include(destination_main_contact["contact_email"])
      end
      Cms::Page.find(source_page2.id).tap do |page_after_move|
        source_main_contact = source_group.contact_groups.where(main_state: "main").first
        column_values = page_after_move.column_values.to_a
        column_values[0].tap do |column_value|
          # text field
          expect(column_value.column_id).to eq column1.id
          expect(column_value.value).not_to include(source_main_contact.contact_tel)
        end
        column_values[1].tap do |column_value|
          # text area
          expect(column_value.column_id).to eq column2.id
          expect(column_value.value).not_to include(source_main_contact.contact_tel)
          expect(column_value.value).not_to include(source_main_contact.contact_fax)
        end
        column_values[2].tap do |column_value|
          # free
          expect(column_value.column_id).to eq column3.id
          expect(column_value.value).not_to include(source_main_contact.contact_tel)
          expect(column_value.value).not_to include(source_main_contact.contact_fax)
          expect(column_value.value).not_to include(source_main_contact.contact_email)
        end

        destination = changeset.destinations.first
        destination_main_contact = destination["contact_groups"].find { |contact| contact["main_state"] == "main" }
        column_values[0].tap do |column_value|
          # text field
          expect(column_value.column_id).to eq column1.id
          expect(column_value.value).to include(destination_main_contact["contact_tel"])
        end
        column_values[1].tap do |column_value|
          # text area
          expect(column_value.column_id).to eq column2.id
          expect(column_value.value).to include(destination_main_contact["contact_tel"])
          expect(column_value.value).to include(destination_main_contact["contact_fax"])
        end
        column_values[2].tap do |column_value|
          # free
          expect(column_value.column_id).to eq column3.id
          expect(column_value.value).to include(destination_main_contact["contact_tel"])
          expect(column_value.value).to include(destination_main_contact["contact_fax"])
          expect(column_value.value).to include(destination_main_contact["contact_email"])
        end
      end

      task.reload
      expect(task.state).to eq 'completed'
      expect(task.entity_logs.count).to eq 3
      expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
      expect(task.entity_logs[0]['changes']).to include('name')
      expect(task.entity_logs[1]['model']).to eq 'Cms::Page'
      expect(task.entity_logs[1]['class']).to eq 'Article::Page'
      expect(task.entity_logs[1]['id']).to eq source_page1.id.to_s
      expect(task.entity_logs[1]['changes']).to be_present
      expect(task.entity_logs[2]['model']).to eq 'Cms::Page'
      expect(task.entity_logs[2]['class']).to eq 'Article::Page'
      expect(task.entity_logs[2]['id']).to eq source_page2.id.to_s
      expect(task.entity_logs[2]['changes']).to be_present
    end
  end
end
