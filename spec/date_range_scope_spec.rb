require File.dirname(__FILE__) + '/spec_helper'

module CanSearch
  DateRangeScope.periods[:spec] = lambda do |now|
    (now..now + 300)
  end

  describe "all DateRange Scopes", :shared => true do
    include CanSearchSpecHelper

    it "instantiates date range scope" do
      Record.search_scopes[@scope.name].should == @scope
    end

    it "creates named_scope" do
      Record.scopes[@scope.named_scope].should_not be_nil
    end

    it "filters records by time range" do
      compare_records Record.search(@scope.name => (@now-5.days..@now-7.minutes)), [:day, :week_1, :week_2]
    end

    it "filters today's records" do
      compare_records Record.search(@scope.name => {:period => :daily}), [:default, :day]
    end
    
    it "filters daily records" do
      compare_records Record.search(@scope.name => {:period => :daily, :start => @now - 3.days}), [:week_1]
    end
    
    it "filters this week's records" do
      compare_records Record.search(@scope.name => {:period => :weekly}), [:default, :day, :week_1, :week_2]
    end
    
    it "filters this fortnight's records" do
      compare_records Record.search(@scope.name => {:period => :'bi-weekly'}), [:default, :day, :week_1, :week_2, :biweek_1, :biweek_2]
    end
    
    it "filters earlier fortnight's records" do
      compare_records Record.search(@scope.name => {:period => :'bi-weekly', :start => '2007-6-14 6:00:00'}), [:month_1, :month_2]
    end
    
    it "filters this month's records" do
      compare_records Record.search(@scope.name => {:period => :monthly}), [:default, :day, :week_1, :week_2, :biweek_1, :biweek_2, :month_1, :month_2]
    end
    
    it "filters older month's records" do
      compare_records Record.search(@scope.name => {:period => :monthly, :start => '2007-5-5'}), [:archive]
    end
  end

  describe DateRangeScope do
    describe "(DateRange Scope with no options)" do
      before do
        Record.can_search do
          scoped_by :created, :scope => :date_range
        end
        @scope = DateRangeScope.new(Record, :created, :attribute => :created_at, :scope => :date_range, :named_scope => :created)
      end

      it_should_behave_like "all DateRange Scopes"
    end

    describe "(DateRange Scope with custom attribute)" do
      before do
        Record.can_search do
          scoped_by :latest, :scope => :date_range, :attribute => :created_at
        end
        @scope = DateRangeScope.new(Record, :latest, :attribute => :created_at, :scope => :date_range, :named_scope => :latest )
      end

      it_should_behave_like "all DateRange Scopes"
    end

    describe "(DateRange Scope with custom attribute and finder)" do
      before do
        Record.can_search do
          scoped_by :latest, :scope => :date_range, :attribute => :created_at, :named_scope => :woot
        end
        @scope = DateRangeScope.new(Record, :latest, :attribute => :created_at, :scope => :date_range, :named_scope => :woot)
      end

      it_should_behave_like "all DateRange Scopes"
    end

    describe "ActiveRecord::Base.date_range_for(period, time = nil) with ActiveSupport defaults" do
      it "creates daily range" do
        Record.date_range_for(:daily, Time.utc(2008, 1, 1, 12)).should == (Time.utc(2008, 1, 1)..Time.utc(2008, 1, 2)-1.second)
      end
      
      it "creates weekly range" do
        Record.date_range_for(:weekly, Time.utc(2008, 1, 1)).should == (Time.utc(2007, 12, 31)..Time.utc(2008, 1, 7)-1.second)
      end
      
      it "creates bi-weekly range for first half of the month" do
        Record.date_range_for(:'bi-weekly', Time.utc(2008, 1, 5)).should == (Time.utc(2008, 1, 1)..Time.utc(2008, 1, 15)-1.second)
      end
      
      it "creates bi-weekly range for second half of the month" do
        Record.date_range_for(:'bi-weekly', Time.utc(2008, 1, 16)).should == (Time.utc(2008, 1, 15)..Time.utc(2008, 2, 1)-1.second)
      end
      
      it "creates monthly range" do
        Record.date_range_for(:monthly, Time.utc(2008, 1, 5)).should == (Time.utc(2008, 1, 1)..Time.utc(2008, 2, 1)-1)
      end

      it "parses time and calls #with_date_range with valid filter" do
        Record.date_range_for(:spec, '2008-1-1').should == (Time.utc(2008, 1, 1)..Time.utc(2008, 1, 1, 0, 5))
      end
      
      it "allows custom instance-level filter" do
        Record.date_periods[:custom_spec] = lambda { |now| (now..now + 420) }
        Record.date_range_for(:custom_spec, '2008-1-1').should == (Time.utc(2008, 1, 1)..Time.utc(2008, 1, 1, 0, 7))
        Record.date_periods.delete(:custom_spec)
      end
      
      it "raises exception on bad filter" do
        lambda { Record.date_range_for(:snozzberries, nil) }.should raise_error(RuntimeError)
      end
    end

    describe "ActiveRecord::Base.parse_filtered_time(time_or_string)" do
      before :all do
        def Record.public_parse_filtered_time(*args)
          parse_filtered_time(*args)
        end
      end
  
      it "converts strings to times" do
        Record.public_parse_filtered_time("2008-1-1").should == Time.utc(2008, 1, 1)
      end
    
      it "converts times to utc" do
        time   = Time.now
        time.should_not be_utc
        parsed = Record.public_parse_filtered_time(time)
        parsed.should == time
        parsed.should be_utc
      end
    
      it "raises error on bad filtered date value" do
        lambda { Record.public_parse_filtered_time(:boom) }.should raise_error(RuntimeError)
      end
    end
  end
end