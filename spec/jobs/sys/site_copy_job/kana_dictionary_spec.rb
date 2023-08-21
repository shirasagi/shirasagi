require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy kana dictionary" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:dic) { create :kana_dictionary }

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
        expect(Kana::Dictionary.site(site).count).to eq 1
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Kana::Dictionary.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "dictionaries"
        task.save!

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Kana::Dictionary.site(dest_site).count).to eq 1
        dest_dic = Kana::Dictionary.site(dest_site).first
        expect(dest_dic.name).to eq dic.name
        expect(dest_dic.body).to eq dic.body
      end
    end
  end
end
