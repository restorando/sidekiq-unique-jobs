module SidekiqUniqueJobs
  class Config < OpenStruct
    TESTING_CONSTANT ||= 'Testing'.freeze
    CONFIG_ACCESSORS = [
      :unique_prefix,
      :default_expiration,
      :default_lock,
      :redis_mode
    ].freeze

    def inline_testing_enabled?
      testing_enabled? && Sidekiq::Testing.inline?
    end

    def mocking?
      inline_testing_enabled? && redis_test_mode.to_sym == :mock
    end

    def testing_enabled?
      Sidekiq.const_defined?(TESTING_CONSTANT) && Sidekiq::Testing.enabled?
    end

    def unique_args_enabled?
      config.unique_args_enabled
    end
  end
end
