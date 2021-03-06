module SidekiqUniqueJobs
  module Lock
    class WhileExecuting
      def self.synchronize(item, redis_pool = nil, &block)
        new(item, redis_pool).synchronize(&block)
      end

      def initialize(item, redis_pool = nil)
        @unique_digest = item['unique_digest'.freeze]
        @run_key = "#{@unique_digest}:run"
        @mutex = Mutex.new
        @redis_pool = redis_pool
      end

      def synchronize(&_block)
        @mutex.lock
        sleep 0.001 until locked?

        yield

      ensure
        SidekiqUniqueJobs.connection(@redis_pool) { |c| c.del @run_key }
        @mutex.unlock
      end

      def locked?
        Scripts.call(:synchronize, @redis_pool, keys: [@run_key], argv: [Time.now.to_i]) == 1
      end
    end
  end
end
