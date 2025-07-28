require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy loop_setting" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:translate_lang) { create :translate_lang_ja }

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
        expect(Translate::Lang.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "translate_langs"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Translate::Lang.site(dest_site).count).to eq 1
        dest_translate_lang = Translate::Lang.site(dest_site).first
        expect(dest_translate_lang.name).to eq translate_lang.name
        expect(dest_translate_lang.code).to eq translate_lang.code
        expect(dest_translate_lang.mock_code).to eq translate_lang.mock_code
        expect(dest_translate_lang.google_translation_code).to eq translate_lang.google_translation_code
        expect(dest_translate_lang.microsoft_translator_text_code).to eq translate_lang.microsoft_translator_text_code
        expect(dest_translate_lang.accept_languages).to eq translate_lang.accept_languages
      end
    end
  end
end
