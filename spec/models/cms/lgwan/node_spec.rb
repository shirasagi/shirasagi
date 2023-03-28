require 'spec_helper'

describe Cms::Lgwan::Page, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { create_once :article_node_page, filename: unique_id, name: "article" }

  let(:name) { unique_id }
  let(:filename) { unique_id }
  let(:job) { Cms::Node::GenerateJob.bind(site_id: site, node_id: item) }

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
    context "node" do
      it "save and upate" do
        with_lgwan_web do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_web do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end
      end

      it "rename" do
        with_lgwan_web do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_web do
          path_was = item.path
          file_was = path_was.sub("#{Rails.root}/", "")

          expect(enqueued_jobs.size).to eq 0
          item.filename = filename
          item.update!

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was]]
        end
      end

      it "close" do
        with_lgwan_web do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_web do
          path_was = item.path
          file_was = path_was.sub("#{Rails.root}/", "")
          file_was1 = "#{file_was}/index.html"
          file_was2 = "#{file_was}/rss.xml"

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was2, file_was1]]
        end
      end

      it "remove" do
        with_lgwan_web do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_web do
          path_was = item.path
          file_was = path_was.sub("#{Rails.root}/", "")

          expect(enqueued_jobs.size).to eq 0
          item.destroy

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was]]
        end
      end
    end
  end

  context "lgwan cms" do
    context "node" do
      it "save and upate" do
        with_lgwan_cms do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_cms do
          item.name = name
          item.update!
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end
      end

      it "rename" do
        with_lgwan_cms do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_cms do
          path_was = item.path
          file_was = path_was.sub("#{Rails.root}/", "")
          item.filename = filename
          item.update!
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was)).to be false
          expect(::File.exist?(item.path)).to be true
        end
      end

      it "close" do
        with_lgwan_cms do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_cms do
          path_was = item.path
          path_was1 = "#{path_was}/index.html"
          path_was2 = "#{path_was}/rss.xml"
          item.state = "closed"
          item.update!
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was1)).to be false
          expect(::File.exist?(path_was2)).to be false
        end
      end

      it "remove" do
        with_lgwan_cms do
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_lgwan_cms do
          job.perform_now
          expect(::File.exist?(item.path)).to be true
        end

        with_lgwan_cms do
          path_was = item.path
          item.destroy
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was)).to be false
        end
      end
    end
  end
end
