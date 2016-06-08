require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy part" do
    let(:site) { cms_site }
    let!(:part) { create :cms_part_free, cur_site: site, html: '<div class="part"></div>' }
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

      dest_part = Cms::Part.site(dest_site).find_by(filename: part.filename)
      dest_part = dest_part.becomes_with_route
      expect(dest_part.name).to eq part.name
      expect(dest_part.user_id).to eq part.user_id
      expect(dest_part.html).to eq part.html

      expect(Job::Log.count).to eq 1
      log = Job::Log.first
      expect(log.logs).not_to include(include('WARN'))
      expect(log.logs).not_to include(include('ERROR'))
      expect(log.logs).to include(include('INFO -- : Completed Job'))
    end
  end
end
