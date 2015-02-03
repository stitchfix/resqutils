module Resqutils
  # Vends stale workers that have been running "too long"
  class StaleWorkers
    include Enumerable

    # Create a StaleWorkers instance.
    #
    # seconds_to_be_considered_stale:: if present, this is the number of seconds a worker will have to have been
    #                                  running to be considered stale
    def initialize(seconds_to_be_considered_stale = 3600)
      @seconds_to_be_considered_stale = seconds_to_be_considered_stale_from_env! || seconds_to_be_considered_stale
    end

    # Yield all currently stale workers.  The yielded objects are Resque's representation, which is not
    # well documented, however you can reasonably assume it will respond to #id, #queue, and #run_at
    def each(&block)
      if block.nil?
        stale_workers.to_enum
      else
        stale_workers.each(&block)
      end
    end

  private

    def stale_workers
      Resque.workers.map(&self.method(:worker_with_start_time)).select(&:stale?).map(&:worker)
    end

    def worker_with_start_time(worker)
      WorkerWithStartTime.new(worker,@seconds_to_be_considered_stale)
    end

    def seconds_to_be_considered_stale_from_env!
      seconds_to_be_considered_stale = String(ENV["RESQUTILS_SECONDS_TO_BE_CONSIDERED_STALE"])
      if seconds_to_be_considered_stale.strip.length == 0
        nil
      elsif seconds_to_be_considered_stale.to_i == 0
        raise "You set a stale value of 0 seconds, making all jobs stale; probably not what you want"
      else
        seconds_to_be_considered_stale.to_i
      end
    end

    class WorkerWithStartTime
      attr_reader :worker
      def initialize(worker,seconds_to_be_considered_stale)
        @worker = worker
        @seconds_to_be_considered_stale = seconds_to_be_considered_stale
        @start_time = Time.parse(worker.job["run_at"]) rescue nil
      end

      def stale?
        return false if @start_time.nil?
        @start_time <= (Time.now - @seconds_to_be_considered_stale)
      end
    end
  end
end
