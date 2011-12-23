require File.dirname(__FILE__) + '/../../../../test/test_helper'

if AbTest.table_exists?
  class AbTestTest < ActiveSupport::TestCase  
    test "should_properly_assign_untreated_user" do
     (1..8).each do |treatments|
        r = Range.new(0, treatments)
        @t = AbTest.new({:name => "Foobar #{treatments}", :treatments => treatments, :min_difference => 0.05, :metrics => [:comments]}) # a/b test
        assert @t.save, @t.errors.full_messages_html
        @new_treatment = @t.assign_visitor_to_treatment('a1')
        assert_not_nil @new_treatment
        assert r.include?(@new_treatment), @new_treatment
      end
    end
    
    test "should_properly_remember_treated_user" do
      test_should_properly_assign_untreated_user
      User.db_query("INSERT INTO treated_visitors(visitor_id, ab_test_id, treatment) VALUES('a1', #{@t.id}, #{@new_treatment});")
      assert_equal [@new_treatment, false], @t.get_visitor_treatment_num('a1')
    end
    
    test "should_switch_treatment_to_previous_if_anon_user_becomes_logged_in" do
      test_should_properly_remember_treated_user
      User.db_query("UPDATE treated_visitors SET user_id = 1 WHERE visitor_id = 'a1';")
      User.db_query("INSERT INTO treated_visitors(visitor_id, ab_test_id, treatment) VALUES('a2', #{@t.id}, #{@new_treatment + 1});")
      assert_equal [@new_treatment + 1, false], @t.get_visitor_treatment_num('a2')
      assert_equal [@new_treatment, false], @t.get_visitor_treatment_num('a2', 1)
    end
    
    def atest_should_properly_distribute_users
      treatments = 1
      @t = AbTest.new({:name => "Foobar #{treatments}", :treatments => treatments, :min_difference => 0.05}) # a/b test
      assert @t.save
      1000.times do |i|
        @t.assign_visitor_to_treatment("#{i}")
      end
      #p @t.get_assigned_visitors_rates
    end
    
    def atest_should_properly_return_conversion_rates_for_comments_and_0_for_treatment
      @t = AbTest.new({:name => "Comentarios", :treatments => 1, :min_difference => 0.05, :metrics => [:comments]}) # a/b test
      assert @t.save
      add_pageview({:visitor_id => 0, :session_id => 0, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 0, :session_id => 0, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-0"})
      add_pageview({:visitor_id => 1, :session_id => 1, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 2, :session_id => 2, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      
      # User.db_query("INSERT INTO stats.pageviews(ip, session_id, url, referer, controller, action, abtest_treatment) VALUES('127.0.0.1', '0', 'http://laflecha.net/comentarios/create', 'comentarios', 'create', '#{t.id}-0');")
      rates = @t.conversion_rates[:comments]
      assert_equal 2, rates[0][:impressions] 
      assert_equal 1, rates[0][:conversions]
      assert_equal 0.5, rates[0][:rate]
      assert_equal 1, rates[1][:impressions]
      assert_equal 0, rates[1][:conversions]
      assert_equal 0, rates[1][:rate]
      assert_equal -1.0, rates[1][:relative_rate]
    end
    
    def atest_should_properly_return_conversion_rates_for_comments_where_base_is_yet_0
      @t = AbTest.new({:name => "Comentarios", :treatments => 2, :min_difference => 0.05, :metrics => [:comments]}) # a/b test
      assert @t.save
      add_pageview({:visitor_id => 0, :session_id => 0, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 1, :session_id => 1, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 2, :session_id => 2, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      
      add_pageview({:visitor_id => 3, :session_id => 3, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 4, :session_id => 4, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 4, :session_id => 4, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-1"})
      
      rates = @t.conversion_rates[:comments]
      assert_equal 3, rates[0][:impressions] 
      assert_equal 0, rates[0][:conversions]
      assert_equal 0, rates[0][:rate]
      assert_equal 2, rates[1][:impressions]
      assert_equal 1, rates[1][:conversions]
      assert_equal 0.5, rates[1][:rate]
      assert_equal 0.0, rates[1][:relative_rate]
      assert_equal 0, rates[2][:impressions]
      assert_equal 0, rates[2][:conversions]
      assert_equal 0.0, rates[2][:rate]
      assert_equal 0.0, rates[2][:relative_rate]
    end
    
    # TODO test_conversion_rates_
    def atest_conversion_rates_clickthrough
      # TODO limitar a contar solo una vez por sesión? por qué?? por qué lo hacemos en goals?
      @t = AbTest.new({:name => "Comentarios", :treatments => 3, :min_difference => 0.05, :metrics => [:clickthrough]}) # a/b test
      assert @t.save
      User.db_query("UPDATE ab_tests SET created_on = now() - '1 minute'::interval WHERE id = #{@t.id}")
      add_pageview({:visitor_id => 0, :session_id => 0, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 1, :session_id => 1, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 2, :session_id => 2, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 2, :session_id => 2, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-0"})
      add_pageview({:visitor_id => 3, :session_id => 3, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "0"}})
      add_pageview({:visitor_id => 3, :session_id => 3, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-0"})
      
      add_pageview({:visitor_id => 4, :session_id => 4, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 4, :session_id => 4, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-1"})
      add_pageview({:visitor_id => 5, :session_id => 5, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 6, :session_id => 6, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 6, :session_id => 6, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-1"})
      add_pageview({:visitor_id => 7, :session_id => 7, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "1"}})
      add_pageview({:visitor_id => 7, :session_id => 7, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-1"})
      
      add_pageview({:visitor_id => 8, :session_id => 8, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "2"}})
      add_pageview({:visitor_id => 8, :session_id => 8, :controller => 'comentarios', :action => 'crear', "campaign" => "xab#{@t.id}-2"})
      add_pageview({:visitor_id => 9, :session_id => 9, :controller => 'noticias', :action => 'noticia', :abtest_treatment => {@t.id.to_s => "2"}})
      
      rates = @t.conversion_rates[:clickthrough]
      assert_equal 4, rates[0][:impressions] 
      assert_equal 2, rates[0][:conversions]
      assert_equal 0.5, rates[0][:rate]
      assert_equal 4, rates[1][:impressions]
      assert_equal 3, rates[1][:conversions]
      assert_equal 3/4.0, rates[1][:rate]
      assert_equal 0.5, rates[1][:relative_rate] # TODO
      assert_equal 2, rates[2][:impressions]
      assert_equal 1, rates[2][:conversions]
      assert_equal 0.5, rates[2][:rate]
      assert_equal 0.0, rates[2][:relative_rate] # TODO
    end
    
    def add_pageview(fields)
      if fields[:abtest_treatment]
        orig_abtest_treatment = fields[:abtest_treatment]
        
        fields[:abtest_treatment] = fields[:abtest_treatment].to_json  
        if User.db_query("SELECT * FROM treated_visitors WHERE ab_test_id = #{orig_abtest_treatment.keys[0]} AND visitor_id = '#{fields[:visitor_id]}'").size == 0
          User.db_query("INSERT INTO treated_visitors(ab_test_id, visitor_id, treatment) VALUES(#{orig_abtest_treatment.keys[0]}, '#{fields[:visitor_id]}', #{orig_abtest_treatment.values[0]})")
        end
      end
      insert_sql = "#{fields.keys.join(', ')}"
      values_sql = "#{fields.values.collect {|c| User.connection.quote(c.to_s) }.join(', ')}"
      User.db_query("INSERT INTO stats.pageviews(ip, #{insert_sql}) VALUES('127.0.0.1', #{values_sql})")
    end
  end
  
end