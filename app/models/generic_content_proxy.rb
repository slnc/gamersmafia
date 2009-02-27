class GenericContentProxy
  def initialize(cls, clans_clause=true)
    @cls = cls
    @clans_clause = clans_clause
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      p args
      args = _add_restriction_to_cond(*args)
      p args
      t = Term.single_toplevel(:code => 'gm')
      t.set_dummy
      begin
        t.send(method_id, *args)
      rescue ArgumentError
        t.send(method_id)
      end
    end
  end
  
  private
  def _add_restriction_to_cond(*args)
    options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
    new_conds = []
    
    if options[:content_type]
      new_conds << "contents.content_type_id = #{ContentType.find_by_name(options[:content_type]).id}"
      options[:joins] = "JOIN #{Inflector::tableize(options[:content_type])} ON #{Inflector::tableize(options[:content_type])}.unique_content_id = contents.id"
    end
    
    # new_conds << "content_type_id = #{ContentType.find_by_name(options[:content_type]).id}" if options[:content_type]
    new_conds << "clan_id IS NULL" if @clans_clause

    options.delete(:content_type) if options[:content_type]
    if new_conds.size > 0
      if options[:conditions].kind_of?(Array)
        options[:conditions][0]<< "AND #{new_conds.join(' AND ')}"
      elsif options[:conditions] then
        options[:conditions]<< " AND #{new_conds.join(' AND ')}"
      else
        options[:conditions] = new_conds.join(' AND ')
      end
    end
    args.push(options)
  end
end