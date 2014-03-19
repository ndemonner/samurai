require 'bundler'
Bundler.setup
Bundler.require

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end

# Chris Maddox ftw
def anonymous_class(inherited_class=Object, &block)
  Class.new(inherited_class).tap do |klass|
    klass.class_eval(&block) if block_given?
  end
end
