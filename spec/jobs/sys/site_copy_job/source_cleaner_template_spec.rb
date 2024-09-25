require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy source_cleaner_template" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:template) { create :cms_source_cleaner_template }

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
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::SourceCleanerTemplate.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "source_cleaner_templates"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::SourceCleanerTemplate.site(dest_site).count).to eq 1
        dest_template = Cms::SourceCleanerTemplate.site(dest_site).first
        expect(dest_template.name).to eq template.name
        expect(dest_template.order).to eq template.order
        expect(dest_template.state).to eq template.state
        expect(dest_template.target_type).to eq template.target_type
        expect(dest_template.target_value).to eq template.target_value
        expect(dest_template.action_type).to eq template.action_type
        expect(dest_template.replaced_value).to eq template.replaced_value
      end
    end
  end
end
