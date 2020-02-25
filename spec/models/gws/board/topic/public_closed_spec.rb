require 'spec_helper'

RSpec.describe Gws::Board::Topic, type: :model, dbscope: :example do
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:release_date) { now + 1.hour }
  let(:close_date) { release_date + 1.hour }
  let(:item) { create :gws_board_topic, state: "public", release_date: release_date, close_date: close_date }

  context "when state is closed" do
    before do
      item.state = "closed"
      item.save!
    end

    context "it is just before release_date" do
      it do
        travel_to(release_date - 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is at release_date" do
      it do
        travel_to(release_date) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is just after release_date" do
      it do
        travel_to(release_date + 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is just before close_date" do
      it do
        travel_to(close_date - 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is at close_date" do
      it do
        travel_to(close_date) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is just after close_date" do
      it do
        travel_to(close_date + 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end
  end

  context "when state is public" do
    before do
      item.state = "public"
      item.save!
    end

    context "it is just before release_date" do
      it do
        travel_to(release_date - 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is at release_date" do
      it do
        travel_to(release_date) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 1
          expect(Gws::Board::Topic.topic.and_public.first.id).to eq item.id
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 0

          expect(item.public?).to be_truthy
          expect(item.closed?).to be_falsey
        end
      end
    end

    context "it is just after release_date" do
      it do
        travel_to(release_date + 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 1
          expect(Gws::Board::Topic.topic.and_public.first.id).to eq item.id
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 0

          expect(item.public?).to be_truthy
          expect(item.closed?).to be_falsey
        end
      end
    end

    context "it is just before close_date" do
      it do
        travel_to(close_date - 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 1
          expect(Gws::Board::Topic.topic.and_public.first.id).to eq item.id
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 0

          expect(item.public?).to be_truthy
          expect(item.closed?).to be_falsey
        end
      end
    end

    context "it is at close_date" do
      it do
        travel_to(close_date) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end

    context "it is just after close_date" do
      it do
        travel_to(close_date + 1.second) do
          expect(Gws::Board::Topic.topic.and_public.count).to eq 0
          expect(Gws::Board::Topic.topic.and_closed.count).to eq 1
          expect(Gws::Board::Topic.topic.and_closed.first.id).to eq item.id

          expect(item.public?).to be_falsey
          expect(item.closed?).to be_truthy
        end
      end
    end
  end
end
