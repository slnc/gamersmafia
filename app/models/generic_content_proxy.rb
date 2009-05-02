class GenericContentProxy
  def initialize(cls, mode=nil)
    @mode = mode
    @cls = cls
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      args = _add_restriction_to_cond(*args)
      t = Term.single_toplevel(:code => 'gm')
      if %w(gm arena).include? @mode
        Term.find(:all, :conditions => 'parent_id IS NULL AND (game_id IS NOT NULL OR platform_id IS NOT NULL)').each { |t| t.add_sibling(t) }
      else
        raise "mode #{@mode} not understood"
        # TODO portal arena
      end
      
      # t.set_dummy
      t.add_content_type_mask(@cls.name) unless args.kind_of?(Array) && args.last[:content_type] 
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
    
    # options.delete(:content_type) if options[:content_type]
    
    if new_conds.size > 0
      if options[:conditions].kind_of?(Array)
        options[:conditions][0] = "#{options[:conditions][0]} AND #{new_conds.join(' AND ')}"
      elsif options[:conditions] then
        options[:conditions] = "#{options[:conditions]} AND #{new_conds.join(' AND ')}"
      else
        options[:conditions] = new_conds.join(' AND ')
      end
    end
    args.push(options)
  end
end
