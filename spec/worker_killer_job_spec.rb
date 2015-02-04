require 'spec_helper'
require 'securerandom'

describe Resqutils::WorkerKillerJob do
  describe "queue" do
    before do
      ENV.delete("RESQUTILS_WORKER_KILLER_JOB_QUEUE")
      # since we are memoizing it on the class
      described_class.instance_variable_set("@queue",nil)
    end

    after do
      ENV.delete("RESQUTILS_WORKER_KILLER_JOB_QUEUE")
    end

    it "uses the worker_killer_job queue by default" do
      expect(Resque.queue_from_class(described_class)).to eq(:worker_killer_job)
    end

    it "can use a different queue if specified by the environment" do
      ENV["RESQUTILS_WORKER_KILLER_JOB_QUEUE"] = "foobar"
      expect(Resque.queue_from_class(described_class)).to eq("foobar")
    end
  end
  describe "::perform" do
    let(:workers) {
      [
        double(id: worker_id),
        double(id: worker_id),
        double(id: worker_id),
        double(id: worker_id),
        double(id: worker_id),
        double(id: worker_id),
      ]
    }

    let(:worker_to_kill) { workers[2] }

    before do
      allow(Resque).to receive(:workers).and_return(workers)
      workers.each do |worker|
        allow(worker).to receive(:unregister_worker)
      end
      described_class.perform(worker_to_kill.id)
    end

    it "unregisters the worker we want to kill" do
      expect(worker_to_kill).to have_received(:unregister_worker)
    end

    it "doesn't touch the other workers" do
      workers.reject { |_| _ == worker_to_kill }.each do |worker|
        expect(worker).not_to have_received(:unregister_worker)
      end
    end

  end

  def worker_id
    "#{SecureRandom.uuid}:#{rand(100)}:some_event"
  end
end
