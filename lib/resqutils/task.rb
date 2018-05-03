require "resque/tasks"

module Resqutils
  class Task
    def initialize(io: Kernel)
      @io = io
    end

    def invoke
      ENV["TERM_CHILD"] ||= "1"
      ENV["RESQUE_TERM_TIMEOUT"] ||= "10"
      Rake::Task['resque:work'].invoke
    rescue Redis::BaseError => ex
      @io.puts "Unhandled Redis Error from Resque Worker: #{ex.message}"
    end
  end
end
