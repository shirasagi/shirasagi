require 'spec_helper'

describe Sys::SiteExportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:file) { tmp_ss_file site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:template) { create :cms_editor_template, thumb_id: file.id }

  context 'site export' do
    around do |example|
      save_export_root = Sys::SiteExportJob.export_root
      Sys::SiteExportJob.export_root = tmpdir

      begin
        example.run
      ensure
        Sys::SiteExportJob.export_root = save_export_root
      end
    end

    it do
      job = ::Sys::SiteExportJob.new
      job.task = ::Tasks::Cms.mock_task(
        source_site_id: site.id
      )
      job.perform
      output_zip = job.instance_variable_get(:@output_zip)

      expect(::File.size(output_zip)).to be > 0
      Zip::File.open(output_zip) do |zip|
        expect(zip.read(zip.get_entry("version.json"))).not_to be_nil

        JSON.parse(zip.read(zip.get_entry("cms_editor_templates.json"))).tap do |editor_templates_json|
          expect(editor_templates_json).not_to be_nil
          puts editor_templates_json
          expect(editor_templates_json).to have(1).items
          editor_templates_json[0].tap do |editor_template_json|
            expect(editor_template_json["_id"]).to eq template.id
            expect(editor_template_json["site_id"]).to eq template.site_id
            expect(editor_template_json["name"]).to eq template.name
            expect(editor_template_json["order"]).to eq template.order
            expect(editor_template_json["description"]).to eq template.description
            expect(editor_template_json["html"]).to eq template.html
            expect(editor_template_json["thumb_id"]).to eq template.thumb_id
          end
        end
        JSON.parse(zip.read(zip.get_entry("ss_files.json"))).tap do |ss_files_json|
          file.reload
          expect(ss_files_json).not_to be_nil
          puts ss_files_json
          expect(ss_files_json).to have(1).items
          ss_files_json[0].tap do |ss_file_json|
            expect(ss_file_json["_id"]).to eq file.id
            expect(ss_file_json["name"]).to eq file.name
            expect(ss_file_json["filename"]).to eq file.filename
            expect(ss_file_json["content_type"]).to eq file.content_type
            expect(ss_file_json["model"]).to eq file.model
            expect(ss_file_json["owner_item_id"]).to eq 0
            expect(ss_file_json["owner_item_type"]).to eq file.owner_item_type
            expect(ss_file_json["export_path"]).to eq file.path.sub(SS::File.root, "files")
          end
        end
      end
    end
  end
end
