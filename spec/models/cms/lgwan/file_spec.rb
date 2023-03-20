require 'spec_helper'

describe Cms::Lgwan::Page, type: :model, dbscope: :example do
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

  def with_lgcms
    SS.config.replace_value_at(:lgwan, :mode, "lgcms")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def with_inweb
    SS.config.replace_value_at(:lgwan, :mode, "inweb")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def enqueued_args
    enqueued_jobs.map do |enqueued_job|
      enqueued_job[:args][0][0]["rm"]
    end
  end

  context "inweb" do
    context "file in page" do
      it "save and upate" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
          expect(::File.exist?(file.public_path)).to be false
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_inweb do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end
      end

      it "close" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
          expect(::File.exist?(file.public_path)).to be false
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_inweb do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")
          dir = file.public_dir.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 2
          expect(enqueued_args).to match_array [[dir], [file_was]]
        end
      end

      it "remove" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
          expect(::File.exist?(file.public_path)).to be false
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_inweb do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")
          dir = file.public_dir.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 3
          expect(enqueued_args).to match_array [[dir], [dir], [file_was]]
        end
      end
    end
  end

  context "lgcms" do
    context "file in page" do
      it "save and upate" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_inweb do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end
      end

      it "close" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_lgcms do
          path_was = item.path
          dir_was = file.public_dir

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 0

          expect(::File.exist?(path_was)).to be false
          expect(::File.exist?(dir_was)).to be false
        end
      end

      it "remove" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_lgcms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
          expect(::File.exist?(file.public_path)).to be true
        end

        with_lgcms do
          path_was = item.path
          dir_was = file.public_dir

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 0

          expect(::File.exist?(path_was)).to be false
          expect(::File.exist?(dir_was)).to be false
        end
      end
    end
  end
end
