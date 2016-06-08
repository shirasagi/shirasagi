require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy editor_template" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:template) { create :cms_editor_template }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ""
      task.save!
    end

    describe "without options" do
      before do
        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::EditorTemplate.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "editor_templates"
        task.save!

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::EditorTemplate.site(dest_site).count).to eq 1
        dest_template = Cms::EditorTemplate.site(dest_site).first
        expect(dest_template.name).to eq template.name
        expect(dest_template.description).to eq template.description
        expect(dest_template.html).to eq template.html
      end
    end

    describe "with thumb" do
      before do
        task.copy_contents = "editor_templates"
        task.save!

        file = create :ss_file, site_id: site.id
        template.thumb_id = file.id
        template.save!

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::EditorTemplate.site(dest_site).count).to eq 1
        dest_template = Cms::EditorTemplate.site(dest_site).first
        expect(dest_template.name).to eq template.name
        expect(dest_template.description).to eq template.description
        expect(dest_template.html).to eq template.html
        expect(dest_template.thumb_id).not_to be_nil
        expect(dest_template.thumb_id).not_to eq template.thumb_id
        expect(dest_template.thumb.site_id).to eq dest_site.id
      end
    end
  end
end
