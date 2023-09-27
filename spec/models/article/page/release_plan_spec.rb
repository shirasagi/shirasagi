require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  context "when release plan is given" do
    let(:body) { Array.new(rand(2..5)) { unique_id }.join("\n") }
    let(:current) { Time.zone.now.beginning_of_minute }
    let(:release_date) { current + 1.day }
    let(:close_date) { release_date + 1.day }
    subject do
      create(
        :article_page, cur_node: node, state: "public", released: current, html: body,
        release_date: release_date, close_date: close_date
      )
    end

    describe "release plan lifecycle" do
      it do
        # before release date, state is "ready" even though page is created as "public"
        expect(subject.state).to eq "ready"
        expect(subject.released).to eq current
        expect(subject.release_date).to eq release_date
        expect(subject.close_date).to eq close_date

        # just before release date
        Timecop.freeze(release_date - 1.second) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output.to_stdout
        end

        subject.reload
        expect(subject.state).to eq "ready"
        expect(subject.released).to eq current
        expect(subject.release_date).to eq release_date
        expect(subject.close_date).to eq close_date

        # at release date
        Timecop.freeze(release_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
        end

        subject.reload
        expect(subject.state).to eq "public"
        expect(subject.released).to eq current
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to eq close_date

        # just before close date
        Timecop.freeze(close_date - 1.second) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output.to_stdout
        end

        subject.reload
        expect(subject.state).to eq "public"
        expect(subject.released).to eq current
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to eq close_date

        # at close date
        Timecop.freeze(close_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
        end

        subject.reload
        expect(subject.state).to eq "closed"
        expect(subject.released).to eq current
        # finally, both release_date and close_data are nil, only release_date leaves
        expect(subject.release_date).to be_nil
        expect(subject.close_date).to be_nil
      end
    end

    describe ".and_public" do
      it do
        # ensure that subject is created
        subject.reload

        # without specific date to and_public
        expect(described_class.and_public.count).to eq 0
        # just before release date
        expect(described_class.and_public(release_date - 1.second).count).to eq 0
        # at release date
        expect(described_class.and_public(release_date).count).to eq 1
        # just before close date
        expect(described_class.and_public(close_date - 1.second).count).to eq 1
        # at close date
        expect(described_class.and_public(close_date).count).to eq 0

        # at release date
        Timecop.freeze(release_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          subject.reload

          # without specific date to and_public
          expect(described_class.and_public.count).to eq 1
          # at release date
          expect(described_class.and_public(release_date).count).to eq 1
          # just before close date
          expect(described_class.and_public(close_date - 1.second).count).to eq 1
          # at close date
          expect(described_class.and_public(close_date).count).to eq 0

          # PAST is unknown because release date is set to nil, so that page is detected as public
          expect(described_class.and_public(release_date - 1.second).count).to eq 1
        end

        # at close date
        Timecop.freeze(close_date) do
          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          subject.reload

          # without specific date to and_public
          expect(described_class.and_public.count).to eq 0
          # at close date
          expect(described_class.and_public(close_date).count).to eq 0

          # PAST is unknown because release date is set to nil, so that page is detected as closed
          expect(described_class.and_public(release_date - 1.second).count).to eq 0
          expect(described_class.and_public(release_date).count).to eq 0
          expect(described_class.and_public(close_date - 1.second).count).to eq 0
        end
      end
    end

    describe "consistency of `#public?` and `.and_public`" do
      it do
        # just before release date
        expect(described_class.and_public(release_date - 1.second).count).to eq 0
        Timecop.freeze(release_date - 1.second) do
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_falsey
        end

        # at release date
        expect(described_class.and_public(release_date).count).to eq 1
        Timecop.freeze(release_date) do
          # before page is released
          subject.reload
          expect(described_class.and_public.count).to eq 1
          expect(subject.public?).to be_falsey

          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          # after page was released
          subject.reload
          expect(described_class.and_public.count).to eq 1
          expect(described_class.and_public.first).to eq subject
          expect(subject.public?).to be_truthy
        end
        expect(described_class.and_public(release_date).count).to eq 1

        # at close date
        expect(described_class.and_public(close_date).count).to eq 0
        Timecop.freeze(close_date) do
          # before page is closed
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_truthy

          job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
          expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout

          # after page was closed
          subject.reload
          expect(described_class.and_public.count).to eq 0
          expect(subject.public?).to be_falsey
        end
        expect(described_class.and_public(close_date).count).to eq 0
      end
    end
  end

  context "ss-4868" do
    let(:body) { Array.new(rand(2..5)) { unique_id }.join("\n") }
    let(:now) { Time.zone.now.beginning_of_minute }
    # released is at some future date
    let(:released) { now + 1.week }
    let(:release_date) { now + 1.day }
    let(:close_date) { released + 1.day }
    subject! do
      create(
        :article_page, cur_node: node, state: "public", released: released, html: body,
        release_date: release_date, close_date: close_date
      )
    end

    # .and_public(nil) と .and_public(date) とが一貫性のない応答をするのが https://github.com/shirasagi/shirasagi/issues/4868 の原因。
    # .and_public(nil) と .and_public(date) との一貫性を調査する。
    it do
      # just before release date
      expected = Timecop.freeze(release_date - 1.second) { described_class.and_public.count }
      expect(described_class.and_public(release_date - 1.second).count).to eq expected
      expect(expected).to eq 0

      # at release date
      expected = Timecop.freeze(release_date) { described_class.and_public.count }
      expect(described_class.and_public(release_date).count).to eq expected

      # at release date after release page job is completed
      Timecop.freeze(release_date) do
        job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
        expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
      end
      expected = Timecop.freeze(release_date) { described_class.and_public.count }
      expect(described_class.and_public(release_date).count).to eq expected
      expect(expected).to eq 1

      # at close date
      expected = Timecop.freeze(close_date) { described_class.and_public.count }
      expect(described_class.and_public(close_date).count).to eq expected

      # at close date after release page job is completed
      Timecop.freeze(close_date) do
        job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
        expect { job.perform_now }.to output(include(subject.full_url + "\n")).to_stdout
      end
      expected = Timecop.freeze(close_date) { described_class.and_public.count }
      expect(described_class.and_public(close_date).count).to eq expected
      expect(expected).to eq 0
    end
  end
end
