module CanSearch
  def self.extended(base)
    class << base
      attr_accessor :search_scopes
    end
  end

  # Calls either #paginate or #all on the returned scoped from #search_for.
  def search(options = {})
    options = options.dup
    search_for(options).send(options.key?(:page) ? :paginate : :all, options)
  end

  # Strips search scope keys from options and builds a scoped finder object.  This
  # returns the model if no search scopes are in use.
  def search_for(options = {})
    search_scopes.search_for(options)
  end
end