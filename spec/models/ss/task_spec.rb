require 'spec_helper'

describe SS::Task, dbscope: :example do
  describe "#running?" do
    let(:now) { Time.zone.now.beginning_of_minute }
    subject! { described_class.create!(name: unique_id, state: "running", started: now) }

    it do
      Timecop.freeze(now) do
        expect(subject.running?).to be_truthy
      end

      Timecop.freeze(now + SS::Task::RUN_EXPIRATION - 1.second) do
        expect(subject.running?).to be_truthy
      end

      Timecop.freeze(now + SS::Task::RUN_EXPIRATION) do
        expect(subject.running?).to be_falsey
      end
    end
  end

  describe "#ready" do
    let(:now) { Time.zone.now.beginning_of_minute }
    subject! { described_class.create!(name: unique_id, state: state) }

    before do
      subject.set(updated: now.utc)
    end

    context "when state is stop" do
      let(:state) { described_class::STATE_STOP }

      it do
        expect(subject.ready).to be_truthy

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is ready" do
      let(:state) { described_class::STATE_READY }

      it do
        expect(subject.ready).to be_falsey
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION - 1.second) do
          expect(subject.ready).to be_falsey
        end
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION) do
          expect(subject.ready).to be_truthy
        end

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is running" do
      let(:state) { described_class::STATE_RUNNING }

      it do
        expect(subject.ready).to be_falsey
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION - 1.second) do
          expect(subject.ready).to be_falsey
        end
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION) do
          expect(subject.ready).to be_truthy
        end

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is completed" do
      let(:state) { described_class::STATE_COMPLETED }

      it do
        expect(subject.ready).to be_truthy

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is failed" do
      let(:state) { described_class::STATE_FAILED }

      it do
        expect(subject.ready).to be_truthy

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is interrupted" do
      let(:state) { described_class::STATE_INTERRUPTED }

      it do
        expect(subject.ready).to be_truthy

        expect(subject.state).to eq "ready"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_blank
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end
  end

  describe "#start" do
    let(:now) { Time.zone.now.beginning_of_minute }
    subject! { described_class.create!(name: unique_id, state: state) }

    before do
      subject.set(updated: now.utc)
    end

    context "when state is stop" do
      let(:state) { described_class::STATE_STOP }

      it do
        expect(subject.start).to be_truthy

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is ready" do
      let(:state) { described_class::STATE_READY }

      it do
        expect(subject.start).to be_truthy

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is running" do
      let(:state) { described_class::STATE_RUNNING }

      it do
        expect(subject.start).to be_falsey
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION - 1.second) do
          expect(subject.start).to be_falsey
        end
        Timecop.freeze(now + SS::Task::RUN_EXPIRATION) do
          expect(subject.start).to be_truthy
        end

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is completed" do
      let(:state) { described_class::STATE_COMPLETED }

      it do
        expect(subject.start).to be_truthy

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is failed" do
      let(:state) { described_class::STATE_FAILED }

      it do
        expect(subject.start).to be_truthy

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is interrupted" do
      let(:state) { described_class::STATE_INTERRUPTED }

      it do
        expect(subject.start).to be_truthy

        expect(subject.state).to eq "running"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_blank
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end
  end

  describe "#run_with" do
    let(:state) { described_class::STATE_STOP }
    subject! { described_class.create!(name: unique_id, state: state) }

    context "pass resolved as block" do
      it do
        resolved = false
        rejected = false

        subject.run_with(rejected: ->{ rejected = true }) do
          resolved = true
        end

        expect(resolved).to be_truthy
        expect(rejected).to be_falsey

        expect(subject.state).to eq "completed"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_present
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "pass resolved as proc" do
      it do
        resolved = false
        rejected = false

        subject.run_with(resolved: ->{ resolved = true }, rejected: ->{ rejected = true })

        expect(resolved).to be_truthy
        expect(rejected).to be_falsey

        expect(subject.state).to eq "completed"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_present
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when state is running" do
      let(:state) { described_class::STATE_RUNNING }

      it do
        resolved = false
        rejected = false

        subject.run_with(resolved: ->{ resolved = true }, rejected: ->{ rejected = true })

        expect(resolved).to be_falsey
        expect(rejected).to be_truthy

        expect(subject.state).to eq "running"
      end
    end

    context "when standard error occurred" do
      it do
        expectation = expect { subject.run_with { raise ArgumentError } }
        expectation.to raise_error(ArgumentError).and output(include("ArgumentError\n")).to_stdout

        expect(subject.state).to eq "failed"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_present
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when interrupt occurred" do
      it do
        expectation = expect { subject.run_with { raise described_class::Interrupt } }
        expectation.to raise_error(described_class::Interrupt).and output(include("Interrupt\n")).to_stdout

        expect(subject.state).to eq "interrupted"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_present
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end

    context "when non-standard error occurred" do
      it do
        expectation = expect { subject.run_with { raise NotImplementedError } }
        expectation.to raise_error(NotImplementedError).and output(include("NotImplementedError\n")).to_stdout

        expect(subject.state).to eq "failed"
        expect(subject.interrupt).to be_blank
        expect(subject.started).to be_present
        expect(subject.closed).to be_present
        expect(subject.total_count).to eq 0
        expect(subject.current_count).to eq 0
      end
    end
  end

  describe "#run_with and #log_items" do
    let(:state) { described_class::STATE_STOP }
    subject! { described_class.create!(name: unique_id, state: state) }

    it do
      expect(subject.log_sequence).to eq 0
      expect(subject.log_items.length).to eq 0

      expect do
        subject.run_with { subject.log "log-1" }
      end.to output.to_stdout

      expect(subject.log_sequence).to eq 1
      expect(subject.log_items.length).to eq 1

      expect do
        subject.run_with { subject.log "log-2" }
      end.to output.to_stdout

      expect(subject.log_sequence).to eq 2
      expect(subject.log_items.length).to eq 2
    end
  end

  describe "#purge_old_logs" do
    let(:now) { Time.zone.now.change(usec: 0) }
    let(:state) { described_class::STATE_STOP }
    subject! { described_class.create!(name: unique_id, state: state, log_sequence: 500) }
    let!(:log1) do
      path = "#{subject.base_dir}/291_#{subject.id}.log"
      FileUtils.mkdir_p(subject.base_dir)
      time = now - SS.config.job.keep_logs - 1
      Timecop.freeze(time) do
        File.open(path, "wt") do |f|
          f.puts unique_id
        end

        FileUtils.touch(path, mtime: time.to_time)
      end
      path
    end
    let!(:log1_meta) do
      path = log1.sub(".log", "") + "-meta.json"
      File.open(path, "wt") do |f|
        f.puts unique_id
      end
      path
    end
    let!(:log2) do
      path = "#{subject.base_dir}/394_#{subject.id}.log"
      FileUtils.mkdir_p(subject.base_dir)
      time = now - SS.config.job.keep_logs
      Timecop.freeze(time) do
        File.open(path, "wt") do |f|
          f.puts unique_id
        end

        FileUtils.touch(path, mtime: time.to_time)
      end
      path
    end
    let!(:log2_perf) do
      path = log2.sub(".log", "") + "-performance.log.gz"
      File.open(path, "wt") do |f|
        f.puts unique_id
      end
      path
    end
    let!(:log3) do
      path = "#{subject.base_dir}/498_#{subject.id}.log"
      FileUtils.mkdir_p(subject.base_dir)
      time = now - SS.config.job.keep_logs + 1
      Timecop.freeze(time) do
        File.open(path, "wt") do |f|
          f.puts unique_id
        end

        FileUtils.touch(path, mtime: time.to_time)
      end
      path
    end

    it do
      expect(subject.log_items.length).to eq 3

      Timecop.freeze(now) do
        subject.send(:purge_old_logs)

        expect(File.exist?(log1)).to be_falsey
        expect(File.exist?(log1_meta)).to be_falsey
        expect(File.exist?(log2)).to be_falsey
        expect(File.exist?(log2_perf)).to be_falsey
        expect(File.size(log3)).to be > 0
      end

      expect(subject.log_items.length).to eq 1
    end
  end
end
