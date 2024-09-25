require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy loop_setting" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:loop_setting) { create :cms_loop_setting }

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
        expect(Cms::LoopSetting.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "loop_settings"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::LoopSetting.site(dest_site).count).to eq 1
        dest_loop_setting = Cms::LoopSetting.site(dest_site).first
        expect(dest_loop_setting.name).to eq loop_setting.name
        expect(dest_loop_setting.description).to eq loop_setting.description
        expect(dest_loop_setting.order).to eq loop_setting.order
        expect(dest_loop_setting.html).to eq loop_setting.html
      end
    end
  end
end
