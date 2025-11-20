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

  describe "copy liquid format loop_setting" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:liquid_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        html: "{% for item in items %}<div>{{ item.name }}</div>{% endfor %}",
        state: "public",
        name: "Liquid Setting #{unique_id}")
    end

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = "loop_settings"
      task.save!

      perform_enqueued_jobs do
        ss_perform_now Sys::SiteCopyJob
      end
    end

    it "copies liquid format loop_setting with html_format field" do
      dest_site = Cms::Site.find_by(host: target_host_host)
      expect(Cms::LoopSetting.site(dest_site).count).to eq 1
      dest_loop_setting = Cms::LoopSetting.site(dest_site).first
      expect(dest_loop_setting.name).to eq liquid_setting.name
      expect(dest_loop_setting.html_format).to eq "liquid"
      expect(dest_loop_setting.html).to eq liquid_setting.html
      expect(dest_loop_setting.state).to eq liquid_setting.state
    end
  end

  describe "copy node with loop_setting_id reference" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:liquid_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        html: "{% for item in items %}<div>{{ item.name }}</div>{% endfor %}",
        state: "public",
        name: "Liquid Setting #{unique_id}")
    end
    let!(:node) do
      create(:article_node_page,
        cur_site: site,
        loop_format: "liquid",
        loop_setting_id: liquid_setting.id)
    end

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ["loop_settings", "pages"]
      task.save!

      perform_enqueued_jobs do
        ss_perform_now Sys::SiteCopyJob
      end
    end

    it "resolves loop_setting_id reference correctly" do
      dest_site = Cms::Site.find_by(host: target_host_host)
      dest_loop_setting = Cms::LoopSetting.site(dest_site).first
      expect(dest_loop_setting).to be_present

      dest_node = Cms::Node.site(dest_site).where(filename: node.filename).first
      expect(dest_node).to be_present
      expect(dest_node.loop_setting_id).to eq dest_loop_setting.id
      expect(dest_node.loop_format).to eq "liquid"
      expect(dest_node.loop_setting).to eq dest_loop_setting
    end
  end
end
