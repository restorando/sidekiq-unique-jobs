require 'sidekiq/api'

module Sidekiq
  module UnlockMethod
    def unlock(item)
      SidekiqUniqueJobs::Unlockable.unlock(item['unique_digest'.freeze], item['jid'.freeze])
    end
  end

  class SortedEntry
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          include UnlockMethod
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
          alias_method :remove_job_orig, :remove_job
          alias_method :remove_job, :remove_job_ext
        end
      end

      def delete_ext
        unlock(item) if delete_orig
      end

      private

      def remove_job_ext
        remove_job_orig do |message|
          unlock(Sidekiq.load_json(message))
          yield message
        end
      end
    end

    include UniqueExtension if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('3.1')
  end

  class ScheduledSet
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          include UnlockMethod
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
        end
      end

      def delete_ext
        unlock(item) if delete_orig
      end

      def remove_job_ext
        remove_job_orig do |message|
          unlock(Sidekiq.load_json(message))
          yield message
        end
      end
    end
    include UniqueExtension if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('3.1')
  end

  class Job
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          include UnlockMethod
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
        end
      end

      def delete_ext
        unlock(item)
        delete_orig
      end
    end

    include UniqueExtension
  end

  class Queue
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          include UnlockMethod
          alias_method :clear_orig, :clear
          alias_method :clear, :clear_ext
        end
      end

      def clear_ext
        each(&:delete)
        clear_orig
      end
    end

    include UniqueExtension
  end

  class JobSet
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          include UnlockMethod
          if base.method_defined?(:clear)
            alias_method :clear_orig, :clear
            alias_method :clear, :clear_ext
          end

          if base.method_defined?(:delete_by_value)
            alias_method :delete_by_value_orig, :delete_by_value
            alias_method :delete_by_value, :delete_by_value_ext
          end
        end
      end

      def clear_ext
        each(&:delete)
        clear_orig
      end

      def delete_by_value_ext(name, value)
        unlock(JSON.parse(value)) if delete_by_value_orig(name, value)
      end
    end

    include UniqueExtension
  end
end
