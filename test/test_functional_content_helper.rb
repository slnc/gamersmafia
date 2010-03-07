module TestCaseMixings
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def test_common_content_crud(opt={})
      cattr_accessor :opt, :content_name, :content_sym, :content_class, :post_vars
      
      opt = {:authed_user_id => 1, :non_authed_user_id => 2}.merge(opt)
      self.content_name = opt[:name]
      self.content_sym = ActiveSupport::Inflector::underscore(opt[:name]).to_sym
      self.content_class = Object.const_get(opt[:name])
      
      self.post_vars = {self.content_sym => opt[:form_vars]}
      self.post_vars[:categories_terms] = opt[:categories_terms] if opt[:categories_terms]
      self.post_vars[:root_terms] = opt[:root_terms] if opt[:root_terms]
      
      class_eval <<-END
       include TestFunctionalContentHelperMethods
      END
      
      test "should_show_index" do
        setup_functional_content_hbr
        get :index
        assert_response :success
      end
      
      test "should_show_published_to_everybody" do
        setup_functional_content_hbr
        get :show, {:id => 1}
        assert_response :success
        assert_template 'show'
        
        get :show, {:id => 1}, {:user => opt[:authed_user_id]}
        assert_response :success
        assert_template 'show'
        
        
        get :show, {:id => 1}, {:user => opt[:non_authed_user_id]}
        assert_response :success
        assert_template 'show'
      end
      
      test "should_not_show_unpublished" do
        setup_functional_content_hbr
        assert_raises(ActiveRecord::RecordNotFound) do
          get :show, {:id => 2}
        end
      end
      
      test "should_show_unpublished_to_ppl_with_edit_permissions" do
        setup_functional_content_hbr
        sym_login 'superadmin'
        get :show, {:id => 2}
        assert_response :success
      end
      
      test "should_show_deleted_to_ppl_with_edit_permissions" do
        setup_functional_content_hbr
        sym_login 'superadmin'
        get :show, {:id => 3}
        assert_response :success
      end
      
      test "should_not_show_deleted" do
        setup_functional_content_hbr
        assert_raises(ActiveRecord::RecordNotFound) do
          get :show, {:id => 3}
        end
      end
      
      test "should_allow_new_only_to_registered" do
        setup_functional_content_hbr
        assert_raises(AccessDenied) do
          get :new
        end
        
        sym_login 2 # unauthed
        get :new
        assert_response :success
        assert_template 'new'
        
        sym_login 1 # authed
        get :new
        assert_response :success
        assert_template 'new'
      end
      
      test "should_allow_new_in_portals" do
        # @request.host = %w(Funthing).include?(content_class.name) ? "bazar.#{App.domain}" : App.domain
        setup_functional_content_hbr
        test_should_allow_new_only_to_registered
      end
      
      test "should_not_allow_to_create_if_not_authed" do
        num_news = content_class.count
        
        assert_raises(AccessDenied) do
          post :create, post_vars
        end
      end
      
      test "should_not_allow_to_create_if_authed_but_antiflood_total" do
        sym_login 4
        assert User.find(4).update_attributes(:antiflood_level => 5)
        
        num_news = content_class.count
        post :create, post_vars
        assert_response :success
        assert_not_nil flash[:error]
        assert_equal num_news, content_class.count
      end
      
      
      test "should_allow_to_create_if_registered" do
        num_news = content_class.count
        post :create, post_vars, { :user => opt[:authed_user_id] }
        assert_response :redirect, @response.body
        assert_redirected_to :action => 'index'
        
        assert_equal num_news + 1, content_class.count
      end
      
      test "should_redirect_to_draft_if_created_as_draft" do
        return unless Cms::contents_classes_publishable.include?(Object.const_get(ActiveSupport::Inflector::camelize(content_sym.to_s)))
        num_news = content_class.count
        
        post :create, post_vars.merge({:draft => 1}), { :user => opt[:authed_user_id] }
        
        assert_response :redirect
        assert_redirected_to :action => 'edit', :id => content_class.find(:first, :order => 'id DESC').id
        
        assert_equal num_news + 1, content_class.count
      end
      
      test "should_change_from_draft_to_pending_if_unselected_draft_checkbox" do
        return unless Cms::contents_classes_publishable.include?(Object.const_get(ActiveSupport::Inflector::camelize(content_sym.to_s)))
        sym_login opt[:authed_user_id] 
        num_news = content_class.count
        origpvars = post_vars.clone # TODO PERF 
        post :create, post_vars.clone.merge({:draft => 1})
        assert_response :redirect
        assert_redirected_to :action => 'edit', :id => content_class.find(:first, :order => 'id DESC').id
        
        assert_equal num_news + 1, content_class.count
        o = content_class.find(:first, :order => 'id DESC')
        assert_equal Cms::DRAFT, o.state

        post :update, post_vars.merge({:id => o.id})
        assert_response :redirect
        o.reload
        assert_equal Cms::PENDING, o.state
      end
      
      test "should_redirect_to_new_page_if_missing_fields" do
        post :create, {content_sym => {}}, { :user => opt[:authed_user_id] }
        assert_response :success
        assert_template 'new'
      end
      
      test "should_not_allow_to_edit_if_not_authed" do
        assert_raises(AccessDenied) { get :edit, :id => 1 }
      end
      
      # Con nuevo sistema de permisos no es necesario este check
      #test "should_not_allow_to_edit_if_authed_but_no_perms" do
      #  assert_raises(AccessDenied) { get :edit, {:id => 1}, {:user => opt[:non_authed_user_id]} }
      #end
      
      test "should_allow_to_edit_if_authed" do
        get :edit, {:id => 1}, {:user => opt[:authed_user_id]}
        assert_response :success
        assert_template 'edit'
        
        assert_not_nil assigns(content_sym)
        assert assigns(content_sym).valid?
      end
      
      test "should_not_allow_update_if_not_authed" do
        assert_raises(AccessDenied) do
          post :update, {:id => 1}
        end
      end
      
      test "should_not_allow_update_if_authed_and_no_perms" do
        assert_raises(AccessDenied) { post :update, post_vars.merge({:id => 1}), {:user => opt[:non_authed_user_id]} }
      end
      
      test "should_allow_update_published_if_authed_superadmin" do
        post_vars[content_sym] = post_vars[content_sym].merge(:approved_by_user_id => 1)
        post :update, post_vars.merge({:id => 1}), {:user => opt[:authed_user_id]}
        assert_response :redirect
        obj = Object.const_get(ActiveSupport::Inflector::camelize(content_sym.to_s)).find(1)
        assert_redirected_to ApplicationController.gmurl(obj)
      end
      
      test "should_allow_update_published_if_authed_faction_leader" do
        obj = Object.const_get(ActiveSupport::Inflector::camelize(content_sym.to_s)).find(2)
        obj.created_on = 1.week.ago
        obj.save
        return unless obj.respond_to? :is_categorizable?
        assert_not_nil obj
        f = Organizations.find_by_content(obj)
        assert_not_nil f
        
        panzer = User.find_by_login('panzer')
        if f then
          if !f.is_bigboss?(panzer)
            f.update_boss(panzer)
            assert f.is_bigboss?(panzer)
          end
          
          post :update, post_vars.merge({:id => 2}), {:user => panzer.id}
          assert_response :redirect
        end
      end
      
      test "should_allow_edit_published_if_authed_faction_leader" do
        get :edit, {:id => 2}, {:user => opt[:authed_user_id]}
        assert_response :success
      end
      
      test "should_allow_edit_published_if_authed_superadmin" do
        get :edit, {:id => 2}, {:user => opt[:authed_user_id]}
        assert_response :success
      end
      
      test "should_allow_update_unpublished_if_authed_superadmin" do
        return unless Cms::contents_classes_publishable.include?(Object.const_get(ActiveSupport::Inflector::camelize(content_sym.to_s)))
        post_vars[content_sym] = post_vars[content_sym].merge(:approved_by_user_id => nil)
        post :update, post_vars.merge({:id => 2}), {:user => opt[:authed_user_id]}
        assert_response :redirect
        assert_redirected_to :action => 'edit', :id => 2 # ya que el contenido 2 está pendiente de publicar
      end
      
      test "should_not_allow_destroy_if_not_authed" do
        assert_not_nil content_class.find(1)
        assert_raises(AccessDenied) { post :destroy, {:id => 1} }
      end
      
      test "should_not_allow_to_destroy_if_authed_but_no_perms" do
        assert_not_nil content_class.find(1)
        assert_raises(AccessDenied) { post :destroy, {:id => 1}, {:user => opt[:non_authed_user_id]} }
      end
      
      test "should_allow_to_destroy_if_authed_and_superadmin" do
        assert_not_nil content_class.find(1)
        post :destroy, {:id => 1}, {:user => opt[:authed_user_id]}
        assert_response :redirect
        assert_redirected_to :action => 'index'
        assert_equal Cms::DELETED, content_class.find(1).state
      end
      
      # Solo diferenciamos entre usuarios anónimos, registrados y autorizados
      # para modificaciones. No es el propósito de estos tests comprobar que
      # is_editor? y compañía funcionan
    end
  end
end

module TestFunctionalContentHelperMethods
  def setup_functional_content_hbr
    if %w(Funthing).include?(content_class.name)
      @request.host =  "bazar.#{App.domain}"
    elsif %w(Demo Bet).include?(content_class.name)
      @request.host =  "arena.#{App.domain}"
    else
      @request.host = "ut.#{App.domain}"
    end
  end
end


ActiveSupport::TestCase.send(:include, TestCaseMixings)
