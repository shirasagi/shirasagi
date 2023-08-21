require 'spec_helper'
require 'timecop'

describe Recommend::CreateSimilarityScoresJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site, name: "another", host: "another", domains: "another.localhost.jp" }
  let!(:tokens) { Array.new(5) { SecureRandom.hex(16) } }

  describe ".perform_later" do
    context "with 7days" do
      before do
        # site logs
        Timecop.travel(8.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page1.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page2.html").save!
          end
        end

        Timecop.travel(4.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page2.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page3.html").save!
          end
        end

        Timecop.travel(1.day.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page3.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page4.html").save!
          end
        end

        # site2 logs
        Timecop.travel(8.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page1.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page2.html").save!
          end
        end

        Timecop.travel(4.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page2.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page3.html").save!
          end
        end

        Timecop.travel(1.day.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page3.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page4.html").save!
          end
        end

        perform_enqueued_jobs do
          described_class.bind(site_id: site.id).perform_later
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(Recommend::SimilarityScore.count).to be > 0
        expect(Recommend::SimilarityScore.where(path: "/site/page1.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page2.html").first).not_to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page3.html").first).not_to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page4.html").first).not_to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page1.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page2.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page3.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page4.html").first).to be_nil
      end
    end

    context "with 3days" do
      before do
        # site logs
        Timecop.travel(8.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page1.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page2.html").save!
          end
        end

        Timecop.travel(4.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page2.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page3.html").save!
          end
        end

        Timecop.travel(1.day.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site, token: token, path: "/site/page3.html").save!
            Recommend::History::Log.new(site: site, token: token, path: "/site/page4.html").save!
          end
        end

        # site2 logs
        Timecop.travel(8.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page1.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page2.html").save!
          end
        end

        Timecop.travel(4.days.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page2.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page3.html").save!
          end
        end

        Timecop.travel(1.day.ago) do
          tokens.each do |token|
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page3.html").save!
            Recommend::History::Log.new(site: site2, token: token, path: "/site2/page4.html").save!
          end
        end

        perform_enqueued_jobs do
          described_class.bind(site_id: site.id).perform_later("3")
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(Recommend::SimilarityScore.count).to be > 0
        expect(Recommend::SimilarityScore.where(path: "/site/page1.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page2.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page3.html").first).not_to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site/page4.html").first).not_to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page1.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page2.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page3.html").first).to be_nil
        expect(Recommend::SimilarityScore.where(path: "/site2/page4.html").first).to be_nil
      end
    end
  end
end
