module CanSearch
  # Generates a named scope for searching by time ranges.  You can either specify
  # your own time range, or specify a single time and use one of the periods to determine
  # the range.
  #
  #   class Topic
  #     can_search do
  #       scoped_by :created, :scope => :date_range
  #     end
  #   end
  #
  #   Topic.search(:created => (time1..time2))   # Topic.created(time1..time2)
  #   Topic.search(:created => \
  #     {:period => :daily, :start => Time.now}) # Topic.created(Time.now, Time.now + 1.day)
  #
  class DateRangeScope < BaseScope
    # Default collection of all date range periods.  A period is simply a proc
    # that returns a time range calculated from the given time.  
    def self.periods() @periods ||= {} end
    periods.update \
      :daily => lambda { |now|
          today = now.midnight
          (today..today + 1.day - 1.second)
      },
      :weekly => lambda { |now|
        mon = now.beginning_of_week
        (mon..mon + 1.week - 1.second)
      },
      :'bi-weekly' => lambda { |now|
        today = now.midnight
        today.day >= 15 ? (today.change(:day => 15)..today.end_of_month) : (today.beginning_of_month..today.change(:day => 15) - 1.second)
      },
      :monthly => lambda { |now|
        (now.beginning_of_month..now.end_of_month)
      }

    # The attribute adds a '_at' suffix to the scope name (:created => :created_at).
    # The named_scope uses the scope name by default.
    def initialize(model, name, options = {})
      super
      @attribute = options[:attribute] || begin
        name_str = name.to_s
        name_str =~ /_at$/ ? name : (name_str << "_at").to_sym
      end
      @named_scope = options[:named_scope] || @name
      @model.named_scope @named_scope, lambda { |range|
        if range.respond_to?(:[])
          range = range[:period] && @model.date_range_for(range[:period], range[:start])
        end
        if range
          {:conditions => "#{@model.table_name}.#{@attribute} #{range.to_s :db}"}
        else
          {}
        end
      }
    end

    def scope_for(finder, options = {})
      if value = options.delete(@name)
        finder.send(@named_scope, value)
      else
        finder
      end
    end
  end

  # Shortcut to CanSearch::DateRangeScope.periods
  def date_periods() @date_periods ||= CanSearch::DateRangeScope.periods end

  # Returns a range for the given time using the date period.
  def date_range_for(period_name, time = nil)
    if period = date_periods[period_name.to_sym]
      period.call(parse_filtered_time(time))
    else
      raise "Invalid period: #{period_name.inspect}"
    end
  end

protected
  # Parses the given time.  Strings are parsed with the current time zone, times are
  # converted to the current time zone, and a nil value assumes you want Time.zone.now.
  def parse_filtered_time(time = nil)
    case time
      when String then Time.zone.parse(time)
      when nil    then Time.zone.now
      when Time, ActiveSupport::TimeWithZone then time.in_time_zone
      else raise "Invalid time: #{time.inspect}"
    end
  end

  # Add this scope type
  SearchScopes.scope_types[:date_range] = DateRangeScope
end