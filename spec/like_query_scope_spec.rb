require File.dirname(__FILE__) + '/spec_helper'

module CanSearch
  describe "all LikeQuery Scopes", :shared => true do
    include CanSearchSpecHelper

    it "instantiates like query scope" do
      Record.search_scopes[@scope.name].should == @scope
    end

    it "creates named_scope" do
      Record.scopes[@scope.named_scope].should_not be_nil
    end

    it "filters records by full name" do
      compare_records Record.search(:name => "day"), [:day]
    end
    
    it "filters records by name that doesn't match" do
      compare_records Record.search(:name => "aye"), []
    end
    
    it "doesn't filter records if the specified parameter is nil" do
     compare_records Record.search(:name => nil), [:default, :day, :week_1, :week_2, :biweek_1, :biweek_2, :month_1, :month_2, :archive ]
    end
  end

  describe LikeQueryScope do
    describe "(LikeQuery Scope with no options)" do
      before do
        Record.can_search do
          scoped_by :name, :scope => :like
        end
        @scope = LikeQueryScope.new(Record, :name, :attribute => :name, :scope => :like_query, :named_scope => :like_name)
      end
      
      it "filters records by partial name" do
        compare_records Record.search(:name => "ay"), [:day]
      end
      
      it "filters multiple records by partial name" do
        compare_records Record.search(:name => "biweek"), [:biweek_1, :biweek_2]
      end

      it_should_behave_like "all LikeQuery Scopes"
    end
    
    describe "(LikeQuery Scope with a format option for exact match)" do
       before do
         Record.can_search do
           scoped_by :name, :scope => :like, :format => "%s"
         end
         @scope = LikeQueryScope.new(Record, :name, :attribute => :name, :scope => :like_query, :named_scope => :like_name, :format => "%s")
       end
       
       it "filters records using the format" do
         compare_records Record.search(:name => "ay"), []
       end

       it_should_behave_like "all LikeQuery Scopes"
     end
  end
end