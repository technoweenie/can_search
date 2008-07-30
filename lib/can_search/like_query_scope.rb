module CanSearch
  # Generates a named scope for searching with a "LIKE ?" query. A format option can be specified 
  # to change the string used for matching. The default matching string is "%?%".
  #
  #   class Topic
  #     can_search do
  #       scoped_by :name, :scope => :like
  #     end
  #   end
  #
  #   Topic.search(:name => "john")
  #
  class LikeQueryScope < BaseScope
    def initialize(model, name, options = {})
      super
      @named_scope = options[:named_scope] || "like_#{name}".to_sym
      @format      = options[:format]      || "%%%s%%"
      @model.named_scope @named_scope, lambda { |q| {:conditions => ["#{@name} LIKE ?", @format % q]} }
    end

    def scope_for(finder, options = {})
      query = options.delete(@name)
      query.blank? ? finder : finder.send(@named_scope, query)
    end
  end
  
  SearchScopes.scope_types[:like] = LikeQueryScope
end