require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy share file" do
    let(:site) { cms_site }
    let(:user) { cms_user }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:file) { create :cms_file, site_id: site.id, user_id: user.id }

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
        expect(Cms::File.where(site_id: site.id).count).to eq 1
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::File.where(site_id: dest_site.id).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "files"
        task.save!

        puts "file.size=#{file.size}, #{::File.size(file.path)}"

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::File.site(dest_site).count).to eq 1
        dest_file = Cms::File.site(dest_site).first
        expect(dest_file.name).to eq file.name
        expect(dest_file.model).to eq file.model
        expect(dest_file.state).to eq file.state
        expect(dest_file.filename).to eq file.filename
        expect(dest_file.size).to eq file.size
        expect(dest_file.content_type).to eq file.content_type
        expect(dest_file.path).not_to eq file.path
        expect(::IO.binread(dest_file.path)).to eq ::IO.binread(file.path)
      end
    end
  end
end
