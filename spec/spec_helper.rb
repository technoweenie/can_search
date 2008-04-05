require 'rubygems'

dir = File.dirname(__FILE__)
rails_app_spec = "#{dir}/../../../../config/environment.rb"
vendor_rspec   = "#{dir}/../../rspec/lib"

if File.exist?(vendor_rspec)
  $:.unshift vendor_rspec
else
  gem 'rspec'
end

if File.exist?(rails_app_spec)
  require rails_app_spec
  Time.zone = "UTC"
else
  raise "TODO: attempt to load activerecord and activesupport from gems"
  # also, establish connection with sqlite3 or use DB env var as path to database.yml
end

$:.unshift "#{dir}/../lib"

require 'ruby-debug'
require 'spec'
require 'can_search'
require 'can_search/search_scopes'

module CanSearch
  class Record < ActiveRecord::Base
    set_table_name 'can_search_records'
    
    def self.per_page() 3 end

    def self.create_table
      connection.create_table table_name, :force => true do |t|
        t.string   :name
        t.integer  :parent_id
        t.datetime :created_at
      end
      connection.add_index :can_search_records, :name
    end
    
    def self.drop_table
      connection.drop_table table_name
    end
    
    def self.seed_data(now = Time.now.utc)
      transaction do
        create :name => 'default',  :parent_id => 1, :created_at => now - 5.minutes
        create :name => 'day',      :parent_id => 2, :created_at => now - 8.minutes
        create :name => 'week_1',   :parent_id => 1, :created_at => now - 3.days
        create :name => 'week_2',   :parent_id => 2, :created_at => now - (4.days + 20.hours)
        create :name => 'biweek_1', :parent_id => 2, :created_at => now - 8.days
        create :name => 'biweek_2', :parent_id => 1, :created_at => now - (14.days + 20.hours)
        create :name => 'month_1',  :parent_id => 2, :created_at => now - 20.days
        create :name => 'month_2',  :parent_id => 1, :created_at => now - (28.days + 20.hours)
        create :name => 'archive',  :parent_id => 1, :created_at => now - 35.days
      end
    end
  end

  module CanSearchSpecHelper
    def self.included(base)
      base.before :all do
        @now = Time.utc 2007, 6, 30, 6
        Record.create_table
        Record.seed_data @now
        @expected_index = Record.find(:all).inject({}) { |h, r| h.update r.name.to_sym => r }
      end

      base.before do
        Time.stub!(:now).and_return(@now)
      end
      
      base.after :all do
        Record.connection.drop_table :can_search_records
      end
    end

    def records(key)
      @expected_index[key]
    end
    
    def compare_records(actual, expected)
      actual = actual.sort { |x, y| y.created_at <=> x.created_at }
      expected.each do |e| 
        a_index = actual.index(records(e))
        e_index = expected.index(e)
        if a_index.nil?
          fail "Record record(#{e.inspect}) was not in the array, but should have been."
        else
          fail "Record record(#{e.inspect}) is in wrong position: #{a_index.inspect} instead of #{e_index.inspect}" unless a_index == e_index
        end
      end
      
      actual.size.should == expected.size
    end
  end
end

Debugger.start