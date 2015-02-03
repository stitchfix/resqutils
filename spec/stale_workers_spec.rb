require 'spec_helper'

describe Resqutils::StaleWorkers do
  describe "each" do
    let(:workers) {
      [
        worker,
        worker(Time.now - 3601),
        worker(Time.now - 5401),
        worker,
        worker(Time.now - 7201),
      ]
    }

    before do
      ENV.delete("RESQUTILS_SECONDS_TO_BE_CONSIDERED_STALE")
      allow(Resque).to receive(:workers).and_return(workers)
    end

    context "default stale seconds" do

      context "properly formed workers" do
        subject(:stale_workers) { described_class.new }

        context "with block" do
          it "yields each stale worker" do
            stale = []
            stale_workers.each do |stale_worker|
              stale << stale_worker
            end
            expect(stale.size).to eq(3)
            expect(stale).to include(workers[1])
            expect(stale).to include(workers[2])
            expect(stale).to include(workers[4])
          end
        end
        context "without block" do
          it "returns an enumerator we can use" do
            stale_worker_ids = stale_workers.each.map { |stale_worker|
              stale_worker.id
            }
            expect(stale_worker_ids.size).to eq(3)
            expect(stale_worker_ids).to include(workers[1].id)
            expect(stale_worker_ids).to include(workers[2].id)
            expect(stale_worker_ids).to include(workers[4].id)
          end
        end
      end
      context "some mangled workers" do

        let(:workers) {
          [
            worker,
            worker(Time.now - 3601),
            worker("mangled time"),
            "blah",
            Object.new,
          ]
        }

        subject(:stale_workers) { described_class.new }

        it "yields each umangled stale worker" do
          stale = []
          stale_workers.each do |stale_worker|
            stale << stale_worker
          end
          expect(stale.size).to eq(1)
          expect(stale).to include(workers[1])
        end
      end
    end
    context "customized stale seconds" do
      subject(:stale_workers) { described_class.new(7100) }

      context "with block" do
        it "yields each stale worker" do
          stale = []
          stale_workers.each do |stale_worker|
            stale << stale_worker
          end
          expect(stale.size).to eq(1)
          expect(stale).to include(workers[4])
        end
      end
      context "without block" do
        it "returns an enumerator we can use" do
          stale_worker_ids = stale_workers.each.map { |stale_worker|
            stale_worker.id
          }
          expect(stale_worker_ids.size).to eq(1)
          expect(stale_worker_ids).to include(workers[4].id)
        end
      end
    end
    context "using the environment" do
      context "with a sane value" do
        before do
          ENV["RESQUTILS_SECONDS_TO_BE_CONSIDERED_STALE"] = "5400"
        end
        subject(:stale_workers) { described_class.new(7100) }

        context "with block" do
          it "yields each stale worker" do
            stale = []
            stale_workers.each do |stale_worker|
              stale << stale_worker
            end
            expect(stale.size).to eq(2)
            expect(stale).to include(workers[2])
            expect(stale).to include(workers[4])
          end
        end
        context "without block" do
          it "returns an enumerator we can use" do
            stale_worker_ids = stale_workers.each.map { |stale_worker|
              stale_worker.id
            }
            expect(stale_worker_ids.size).to eq(2)
            expect(stale_worker_ids).to include(workers[2].id)
            expect(stale_worker_ids).to include(workers[4].id)
          end
        end
      end

      context "erroneous values" do
        it "does not like 0" do
          ENV["RESQUTILS_SECONDS_TO_BE_CONSIDERED_STALE"] = "0"
          expect {
            described_class.new
          }.to raise_error(/you set a stale value of 0 seconds, making all jobs stale.*probably not what you want/i)
        end
        it "does not like floats that are 0" do
          ENV["RESQUTILS_SECONDS_TO_BE_CONSIDERED_STALE"] = "0.0000001"
          expect {
            described_class.new
          }.to raise_error(/you set a stale value of 0 seconds, making all jobs stale.*probably not what you want/i)
        end
      end
    end
  end

  def worker(run_at = Time.now)
    double("resque worker", id: SecureRandom.uuid, job: { "queue" => "whatever",
                                                          "run_at" => run_at.to_s,
                                                          "payload" => { "class" => "Foo", "args" => [] } })
  end
end
