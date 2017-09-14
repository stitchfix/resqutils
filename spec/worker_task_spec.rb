require "spec_helper"
require "rake"
require "resqutils/worker_task"

describe "resqutils:work task" do
  let(:resque_work_task) { instance_double(Rake::Task) }
  before do
    allow(Rake::Task).to receive(:[]).with("resque:work").and_return(resque_work_task)
    allow(Rake::Task).to receive(:[]).with("resqutils:work").and_call_original
  end

  it "calls #invoke" do
    allow(resque_work_task).to receive(:invoke)
    Rake::Task["resqutils:work"].invoke
    expect(resque_work_task).to have_received(:invoke)
  end

end
