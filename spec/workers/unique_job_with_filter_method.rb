class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue, retry: 1, backtrace: 10
  sidekiq_options unique: true, unique_args: :filtered_args

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(*)
    # NO-OP
  end

  def self.filtered_args(args)
    options = args.extract_options!
    [args.first, options['type']]
  end
end
