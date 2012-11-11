# -*- encoding : utf-8 -*-
require "test_helper"

class PortalsResolutionTest < ActionController::IntegrationTest
  test "urls of contents should be correct" do
    host! App.domain
    g = Game.new({
        :name => 'Diablo 3',
        :slug => 'diablo',
        :user_id => 1,
        :gaming_platform_id => 1,
    })
    assert_count_increases(Game) do
      g.save
    end
    g.create_contents_categories
    t = Term.single_toplevel(:slug => g.slug)
    sym_login 'superadmin', 'lalala'
    assert_count_increases(News) do
      post '/noticias/create', {
          :news => {
              :title => 'footapang',
              :description => 'bartapang',
          },
          :root_terms => [t.id.to_s],
      }
      assert_response :redirect
    end
    n = News.find(:first, :order => 'id desc')
    assert !n.is_public?
    host! App.domain
    post '/admin/contenidos/mass_moderate', {
        :mass_action => 'publish', :items => [n.unique_content_id.to_s],
    }
    assert_redirected_to '/admin/contenidos'
    n.reload
    assert n.is_public?
    assert_equal "http://#{g.slug}.#{App.domain}/noticias/show/#{n.id}", n.unique_content.url
  end

  test "should_resolve_main" do
    host! App.domain
    get '/'
    assert @controller.portal.kind_of?(GmPortal), @response.body
    assert_response :success, @response.body
  end

  test "should_resolve_subdomain_as_faction_portal" do
    p = FactionsPortal.find_by_code('ut')
    host! "#{p.code}.#{App.domain}"
    get '/'
    assert_response :success, @response.body

    assert_equal p.code, @controller.portal_code
  end
end
