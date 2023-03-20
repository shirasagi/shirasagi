require 'spec_helper'

describe Cms::Lgwan::Page, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }

  let(:name) { unique_id }
  let(:filename) { unique_id }

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
    before { SS.config.replace_value_at(:lgwan, :mode, "inweb") }

    context "page" do
      it "save and upate" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_inweb do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end
      end

      it "rename" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_inweb do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.filename = filename
          item.update!
          expect(item.path).to eq "#{site.path}/docs/#{filename}.html"

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was]]
          expect(::File.exist?(path_was)).to be false
          expect(::File.exist?(item.path)).to be false
        end
      end

      it "close" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_inweb do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was]]
          expect(::File.exist?(path_was)).to be false
        end
      end

      it "remove" do
        with_inweb do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be false
        end

        with_inweb do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 1
          expect(enqueued_args).to match_array [[file_was]]
          expect(::File.exist?(path_was)).to be false
        end
      end
    end
  end

  context "lgcms" do
    before { SS.config.replace_value_at(:lgwan, :mode, "lgcms") }

    context "page" do
      it "save and upate" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end

        with_lgcms do
          expect(enqueued_jobs.size).to eq 0
          item.name = name
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end
      end

      it "rename" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end

        with_lgcms do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.filename = filename
          item.update!
          expect(item.path).to eq "#{site.path}/docs/#{filename}.html"

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was)).to be false
          expect(::File.exist?(item.path)).to be true
        end
      end

      it "close" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end

        with_lgcms do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.state = "closed"
          item.update!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was)).to be false
        end
      end

      it "remove" do
        with_lgcms do
          node
          item
          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(item.path)).to be true
        end

        with_lgcms do
          path_was = item.path
          file_was = path_was.delete_prefix("#{Rails.root}/")

          expect(enqueued_jobs.size).to eq 0
          item.destroy!

          expect(enqueued_jobs.size).to eq 0
          expect(::File.exist?(path_was)).to be false
        end
      end
    end
  end
end

