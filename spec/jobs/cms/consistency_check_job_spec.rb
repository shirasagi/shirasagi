require 'spec_helper'

describe Cms::ConsistencyCheckJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  before do
    FileUtils.rm_rf(site.root_path)
  end

  context "when a file is deleted in DB" do
    let!(:ss_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, cur_user: user)
    end
    let!(:page1) do
      create(
        :cms_page, cur_site: site, cur_user: user, html: "<img src=\"#{ss_file1.url}\" />", file_ids: [ ss_file1.id ],
        state: "public")
    end

    before do
      ss_file1.reload
      expect(ss_file1.owner_item_id).to eq page1.id

      ss_file1.delete
      expect(File.size("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be > 0
    end

    it do
      expect { described_class.bind(site_id: site).perform_now(repair: true) }.to output.to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).not_to include(/ERROR/)
        expect(log.logs).to include(/#{::Regexp.escape("file #{ss_file1.id} was deleted from database.")}/)
      end

      expect(File.exist?("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be_falsey
    end
  end

  context "when a file owner is deleted in DB" do
    let!(:ss_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, cur_user: user)
    end
    let!(:page1) do
      create(
        :cms_page, cur_site: site, cur_user: user, html: "<img src=\"#{ss_file1.url}\" />", file_ids: [ ss_file1.id ],
        state: "public")
    end

    before do
      ss_file1.reload
      expect(ss_file1.owner_item_id).to eq page1.id

      page1.delete
      expect(File.size("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be > 0
    end

    it do
      expect { described_class.bind(site_id: site).perform_now(repair: true) }.to output.to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).not_to include(/ERROR/)
        expect(log.logs).to include(/#{::Regexp.escape("file #{ss_file1.id} owner isn't found.")}/)
      end

      expect(File.exist?("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be_falsey
    end
  end

  context "when a file owner is in a other site" do
    let!(:ss_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, cur_user: user)
    end
    let!(:page1) do
      create :cms_page, cur_site: site, cur_user: user, html: "<img src=\"#{ss_file1.url}\" />", file_ids: [ ss_file1.id ], state: "public"
    end
    let!(:sub_site) { create :cms_site_subdir, parent: site }
    let!(:ss_file2) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: sub_site, cur_user: user)
    end
    let!(:page2) do
      create(
        :cms_page, cur_site: sub_site, cur_user: user, html: "<img src=\"#{ss_file2.url}\" />", file_ids: [ ss_file2.id ], state: "public")
    end

    before do
      ss_file1.reload
      expect(ss_file1.owner_item_id).to eq page1.id

      ss_file2.reload
      expect(ss_file2.owner_item_id).to eq page2.id
    end

    context "with parent site" do
      it do
        expect { described_class.bind(site_id: site).perform_now(repair: true) }.to output.to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/ERROR/)
          expect(log.logs).to include(/#{::Regexp.escape("file #{ss_file2.id} owner is in a other site.")}/)
        end

        expect(File.size("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be > 0
        expect(File.size("#{ss_file2.public_dir}/#{ss_file2.filename}")).to be > 0
      end
    end

    context "with parent sub site" do
      it do
        expect { described_class.bind(site_id: sub_site).perform_now(repair: true) }.to output.to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/ERROR/)
          expect(log.logs).to include(/#{::Regexp.escape("file #{ss_file1.id} owner is in a other site.")}/)
        end

        expect(File.size("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be > 0
        expect(File.size("#{ss_file2.public_dir}/#{ss_file2.filename}")).to be > 0
      end
    end
  end

  context "when a file owner is closed" do
    let!(:ss_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, cur_user: user)
    end
    let!(:page1) do
      create :cms_page, cur_site: site, cur_user: user, html: "<img src=\"#{ss_file1.url}\" />", file_ids: [ ss_file1.id ], state: "public"
    end

    before do
      ss_file1.reload
      expect(ss_file1.owner_item_id).to eq page1.id

      page1.set(state: "closed")
      expect(File.size("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be > 0
    end

    it do
      expect { described_class.bind(site_id: site).perform_now(repair: true) }.to output.to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).not_to include(/ERROR/)
        expect(log.logs).to include(/#{::Regexp.escape("file #{ss_file1.id} owner isn't in public.")}/)
      end

      expect(File.exist?("#{ss_file1.public_dir}/#{ss_file1.filename}")).to be_falsey
    end
  end
end
