require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy loop_setting" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:translate_text_cache) do
      Translate::TextCache.create(
        cur_site: site, api: SS.config.translate.api_options.to_a.sample[0], update_state: %w(auto manually).sample,
        text: "text-#{unique_id}", original_text: "original_text-#{unique_id}",
        source: "source-#{unique_id}", target: "target-#{unique_id}"
      )
    end

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
        expect(::Translate::TextCache.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "translate_text_caches"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(::Translate::TextCache.site(dest_site).count).to eq 1
        dest_translate_text_cache = ::Translate::TextCache.site(dest_site).first
        expect(dest_translate_text_cache.api).to eq translate_text_cache.api
        expect(dest_translate_text_cache.update_state).to eq translate_text_cache.update_state
        expect(dest_translate_text_cache.text).to eq translate_text_cache.text
        expect(dest_translate_text_cache.original_text).to eq translate_text_cache.original_text
        expect(dest_translate_text_cache.source).to eq translate_text_cache.source
        expect(dest_translate_text_cache.target).to eq translate_text_cache.target
      end
    end
  end
end
