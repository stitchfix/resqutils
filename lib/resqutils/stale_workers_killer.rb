module Resqutils
  # Vends stale workers that have been running "too long"
  class StaleWorkersKiller

    def self.perform
      self.new.kill_stale_workers
    end

    def initialize(options={})
      @stale_workers = options.fetch(:stale_workers, Resqutils::StaleWorkers.new)
    end
    def kill_stale_workers
      @stale_workers.each do |worker|
        Resque.enqueue(Resqutils::WorkerKillerJob,worker.id)
      end
    end
  end
end
