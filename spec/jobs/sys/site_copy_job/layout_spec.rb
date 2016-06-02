require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy layout" do
    let(:site) { cms_site }
    let!(:layout) { create :cms_layout, cur_site: site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ""
      task.save!

      perform_enqueued_jobs do
        Sys::SiteCopyJob.perform_now
      end
    end

    it do
      dest_site = Cms::Site.find_by(host: target_host_host)
      expect(dest_site.name).to eq target_host_name
      expect(dest_site.domains).to include target_host_domain
      expect(dest_site.group_ids).to eq site.group_ids

      dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)
      expect(dest_layout.name).to eq layout.name
      expect(dest_layout.user_id).to eq layout.user_id
      expect(dest_layout.html).to eq layout.html

      expect(Job::Log.count).to eq 1
      log = Job::Log.first
      expect(log.logs).not_to include(include('WARN'))
      expect(log.logs).not_to include(include('ERROR'))
      expect(log.logs).to include(include('INFO -- : Completed Job'))
    end
  end
end
