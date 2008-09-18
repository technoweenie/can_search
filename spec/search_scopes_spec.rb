require File.dirname(__FILE__) + '/spec_helper'

module CanSearch
  describe "all Reference Scopes", :shared => true do
    include CanSearchSpecHelper

    it "instantiates reference scope" do
      Record.search_scopes[@scope.name].should == @scope
    end

    it "creates named_scope" do
      Record.scopes[@scope.named_scope].should_not be_nil
    end

    it "paginates records" do
      compare_records Record.search(:page => nil, @scope.name => [2]), [:day, :week_2, :biweek_1]
    end if ActiveRecord::Base.respond_to?(:paginate)
    
    it "filters records with plural value from named_scope" do
      compare_records Record.search(@scope.name => [2]), [:day, :week_2, :biweek_1, :month_1]
    end
    
    it "filters records with singular value from named_scope" do
      compare_records Record.search(@scope.singular_name => 2), [:day, :week_2, :biweek_1, :month_1]
    end
    
    it "filters records with plural record value from named_scope" do
      compare_records Record.search(@scope.name => [records(:day)]), [:day, :week_2, :biweek_1, :month_1]
    end
    
    it "filters records with singular record value from named_scope" do
      compare_records Record.search(@scope.singular_name => records(:day)), [:day, :week_2, :biweek_1, :month_1]
    end
  end

  describe SearchScopes do
    describe "(Reference Scope with no options)" do
      before do
        Record.can_search do
          scoped_by :parents
        end
        @scope = ReferenceScope.new(Record, :parents, :attribute => :parent_id, :singular => :parent, :scope => :reference, :named_scope => :by_parents)
      end

      it_should_behave_like "all Reference Scopes"
    end

    describe "(Reference Scope with custom attribute)" do
      before do
        Record.can_search do
          scoped_by :masters, :attribute => :parent_id
        end
        @scope = ReferenceScope.new(Record, :masters, :attribute => :parent_id, :singular => :master, :scope => :reference, :named_scope => :by_masters)
      end

      it_should_behave_like "all Reference Scopes"
    end

    describe "(Reference Scope with custom attribute and finder name)" do
      before do
        Record.can_search do
          scoped_by :masters, :attribute => :parent_id, :named_scope => :great_scott
        end
        @scope = ReferenceScope.new(Record, :masters, :attribute => :parent_id, :singular => :master, :scope => :reference, :named_scope => :great_scott)
      end
  
      it_should_behave_like "all Reference Scopes"
    end
    
    describe "(add prexisting scopes with a custom scope)" do
      include CanSearchSpecHelper
      before do      
        @scope = Record.named_scope :example, lambda { |name| {:conditions => {:name => name} } }
        Record.named_scope :peanut_butter, lambda { |id| {:conditions => {:parent_id => id} } }
        Record.can_search do
          add_existing_scopes :example, :peanut_butter
        end
      end
      
      it "uses custom scopes" do
        record = Record.create! :name => "this", :parent_id => 3
        Record.search(:example => "this", :peanut_butter => record.parent_id).should == [ record ]
      end
      
      it "excludes unused scopes" do
        record = Record.create! :name => "that", :parent_id => 3
        Record.search(:example => "that").should == [ record ]
      end
      
      it "includes scopes if they set to nil" do
        record = Record.create! :name => nil, :parent_id => 3
        Record.search(:example => nil, :peanut_butter => nil).should == [ ]
      end
    end
  end
end
