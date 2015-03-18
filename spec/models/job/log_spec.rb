require 'spec_helper'

describe Job::Log, dbscope: :example do
  let(:job) { create(:job_model) }

  context "with running log" do
    subject { create(:job_log, :job_log_running, job: job) }

    it { expect(subject.save_term_options).not_to be_nil }
    it { expect(subject.delete_term_options).not_to be_nil }
    it { expect(subject.start_label).to eq subject.started.strftime("%Y-%m-%d %H:%m") }
    it { expect(subject.closed_label).to eq "" }
    it { expect(subject.joined_jobs).to eq subject.logs.join("\n") }
  end

  context "with completed log" do
    subject { create(:job_log, :job_log_completed, job: job) }

    it { expect(subject.save_term_options).not_to be_nil }
    it { expect(subject.delete_term_options).not_to be_nil }
    it { expect(subject.start_label).to eq subject.started.strftime("%Y-%m-%d %H:%m") }
    it { expect(subject.closed_label).to eq subject.closed.strftime("%Y-%m-%d %H:%m") }
    it { expect(subject.joined_jobs).to eq subject.logs.join("\n") }
  end
end
