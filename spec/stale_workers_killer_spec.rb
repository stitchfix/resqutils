require 'spec_helper'
require 'support/worker_helper'

describe Resqutils::StaleWorkersKiller do
  include WorkerHelper
  let(:stale_workers) {
    [
      worker,
      worker,
      worker,
    ]
  }
  before do
    allow(Resque).to receive(:enqueue)
  end
  describe "kill_stale_workers" do
    before do

      described_class.new(stale_workers: stale_workers).kill_stale_workers
    end
    it "queues a job for all stale workers" do
      stale_workers.each do |worker|
        expect(Resque).to have_received(:enqueue).with(Resqutils::WorkerKillerJob,worker.id)
      end
    end
  end
  describe "::perform" do
    before do
      allow(Resqutils::StaleWorkers).to receive(:new).and_return(stale_workers)
      described_class.perform
    end
    it "queues a job for all stale workers" do
      stale_workers.each do |worker|
        expect(Resque).to have_received(:enqueue).with(Resqutils::WorkerKillerJob,worker.id)
      end
    end
  end
end
