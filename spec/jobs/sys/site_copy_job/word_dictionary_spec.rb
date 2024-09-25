require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy word_dictionary" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:dictionary) { create :cms_word_dictionary }

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
        expect(Cms::WordDictionary.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "word_dictionaries"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::WordDictionary.site(dest_site).count).to eq 1
        dest_dictionary = Cms::WordDictionary.site(dest_site).first
        expect(dest_dictionary.name).to eq dictionary.name
        expect(dest_dictionary.body).to eq dictionary.body
      end
    end
  end
end
