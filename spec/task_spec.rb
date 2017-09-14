require "spec_helper"
require "rake"
require "resqutils/task"

describe Resqutils::Task do
  let(:io) { StringIO.new }
  subject(:task) { described_class.new(io: io) }

  describe "#invoke" do
    let(:rake_task) { instance_double(Rake::Task) }
    before do
      ENV.delete("TERM_CHILD")
      ENV.delete("RESQUE_TERM_TIMEOUT")
      allow(Rake::Task).to receive(:[]).with("resque:work").and_return(rake_task)
    end

    it "calls through to the rake task" do
      allow(rake_task).to receive(:invoke)
      task.invoke
      expect(rake_task).to have_received(:invoke)
    end

    it "sets TERM_CHILD and RESQUE_TERM_TIMEOUT in the ENV" do
      allow(rake_task).to receive(:invoke)
      task.invoke
      expect(ENV["TERM_CHILD"]).to eq("1")
      expect(ENV["RESQUE_TERM_TIMEOUT"]).to eq("10")
    end

    it "leaves TERM_CHILD alone if set in ENV" do
      ENV["TERM_CHILD"] = "0"
      allow(rake_task).to receive(:invoke)
      task.invoke
      expect(ENV["TERM_CHILD"]).to eq("0")
    end

    it "leaves RESQUE_TERM_TIMEOUT alone if set in ENV" do
      ENV["RESQUE_TERM_TIMEOUT"] = "20"
      allow(rake_task).to receive(:invoke)
      task.invoke
      expect(ENV["RESQUE_TERM_TIMEOUT"]).to eq("20")
    end

    it "logs about Redis::BaseError instead of raising" do
      allow(rake_task).to receive(:invoke).and_raise(Redis::BaseError)
      expect {
        task.invoke
      }.not_to raise_error
      expect(rake_task).to have_received(:invoke)
      expect(io.string).to match(/Unhandled Redis Error from Resque Worker/i)
    end

    it "raises other errors" do
      allow(rake_task).to receive(:invoke).and_raise(StandardError)
      expect {
        task.invoke
      }.to raise_error(StandardError)
      expect(rake_task).to have_received(:invoke)
    end
  end
end
