require 'spec_helper'

describe Cms::Lgwan::File, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  let(:node) { create_once :article_node_page, filename: unique_id, name: "article" }
  let(:item) { create(:article_page, cur_node: node, file_ids: [file.id]) }
  let(:file) { create(:ss_file, site: site, user: user, filename: "logo.png") }

  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:job) { Cms::Page::GenerateJob.bind(site_id: site, node_id: item) }

  before do
    Fs.rm_rf site.path
    @save_config = SS.config.lgwan.mode
  end

  after do
    Fs.rm_rf site.path
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def with_lgwan_cms
    SS.config.replace_value_at(:lgwan, :mode, "cms")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def with_lgwan_web
    SS.config.replace_value_at(:lgwan, :mode, "web")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def enqueued_args
    enqueued_jobs.map do |enqueued_job|
      enqueued_job[:args][0][0]["rm"]
    end
  end

  context "lgwan web" do
    context "file in page" do
      it "save and upate" do
        with_lgwan_web do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be false
          expect(File.exist?(file.public_path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_web do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end
      end

      it "close" do
        with_lgwan_web do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be false
          expect(File.exist?(file.public_path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_web do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")
          dir = file.public_dir.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 2
          expect(enqueued_args[0]).to match_array [file_was]
          expect(enqueued_args[1]).to match_array [dir]
        end
      end

      it "remove" do
        with_lgwan_web do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be false
          expect(File.exist?(file.public_path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_web do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")
          dir = file.public_dir.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 3
          expect(enqueued_args[0]).to match_array [file_was]
          expect(enqueued_args[1]).to match_array [dir]
          expect(enqueued_args[2]).to match_array [dir]
        end
      end
    end
  end

  context "lgwan cms" do
    context "file in page" do
      it "save and upate" do
        with_lgwan_cms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end
      end

      it "close" do
        with_lgwan_cms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          path_was = item.path
          dir_was = file.public_dir

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 0

          expect(File.exist?(path_was)).to be false
          expect(File.exist?(dir_was)).to be false
        end
      end

      it "remove" do
        with_lgwan_cms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          job.perform_now
          expect(File.exist?(item.path)).to be true
          expect(File.exist?(file.public_path)).to be true
        end

        with_lgwan_cms do
          path_was = item.path
          dir_was = file.public_dir

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 0

          expect(File.exist?(path_was)).to be false
          expect(File.exist?(dir_was)).to be false
        end
      end
    end
  end
end
