require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy theme_template" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:template) { create :cms_theme_template }

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
        expect(Cms::ThemeTemplate.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "theme_templates"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::ThemeTemplate.site(dest_site).count).to eq 1
        dest_template = Cms::ThemeTemplate.site(dest_site).first
        expect(dest_template.name).to eq template.name
        expect(dest_template.class_name).to eq template.class_name
        expect(dest_template.css_path).to eq template.css_path
        expect(dest_template.order).to eq template.order
        expect(dest_template.state).to eq template.state
        expect(dest_template.default_theme).to eq template.default_theme
        expect(dest_template.high_contrast_mode).to eq template.high_contrast_mode
        expect(dest_template.font_color).to eq template.font_color
        expect(dest_template.background_color).to eq template.background_color
      end
    end
  end
end
