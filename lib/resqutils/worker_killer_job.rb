module Resqutils
  # Can be queued to kill a worker.  By default, will be queued to the 'worker_killer_job' queue, however
  # you can specify RESQUTILS_WORKER_KILLER_JOB_QUEUE in the environment to set an override.  Of course, you can always
  # forcibly enqueue it as needed.
  class WorkerKillerJob
    def self.queue
      @queue ||= begin
                   queue = String(ENV["RESQUTILS_WORKER_KILLER_JOB_QUEUE"]).strip
                   queue.length == 0 ? :worker_killer_job : queue
                 end
    end
    def self.perform(worker_id)
      Resque.workers.select { |_| _.id == worker_id }.each(&:unregister_worker)
    end
  end
end
