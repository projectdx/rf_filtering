# Include this from application.rb and call rf_param_filtering() with a 
# whitelist and a blacklist set of params, as below.  Blacklisted parameters 
# are filtered first by Rails, and any other parameters not in the whitelist 
# are filtered by this code.
#
## application.rb: 
#
# require 'rf_filtering'
# ...
# class Application < Rails::Application
#   ...
#   include RFFiltering
#   RFFiltering.UnfilteredEnvironments << 'unfiltered_environment'
#   rf_param_filtering(
#     :blacklist => %w[password card_number card_number],
#     :whitelist => %w[brochure_nickname id])
#
# Welcome to the future.

module RFFiltering
  extend ActiveSupport::Concern
  
  UnfilteredEnvironments = ['development']
  FilteredReplacement = '[+++]'

  included do
    # this space intentionally left blank
  end
  
  module ClassMethods
    attr_reader :rf_filtering_blacklist, :rf_filtering_whitelist
    
    # Leaving this exposed for mockability
    def should_filter_params?
      # there are not a few non-positives in this code.
      !UnfilteredEnvironments.include?(Rails.env)
    end
    
    protected
    def rf_param_filtering(options = {})
      @rf_filtering_blacklist = (options[:blacklist] || []).map(&:to_s)
      @rf_filtering_whitelist = (options[:whitelist] || []).map(&:to_s).to_set

      config.filter_parameters += rf_filtering_blacklist
      config.filter_parameters << rf_whitelist_filter_proc
    end

    def rf_whitelist_filter_proc
      lambda do |k,v|
        next unless should_filter_params?
        next unless v.present?
        next unless v.respond_to?(:to_str) && v.respond_to?(:replace)
        next if param_filter_white_list.include?(k.to_s)
        v.replace FilteredReplacement
      end
    end
  end
  
  module InstanceMethods
    # Leaving this exposed for mockability
    def param_filter_white_list
      self.class.rf_filtering_whitelist
    end
  end
end
