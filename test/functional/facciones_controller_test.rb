# -*- encoding : utf-8 -*-
require 'test_helper'

class FaccionesControllerTest < ActionController::TestCase



  test "index" do
    get :index
    assert_response :success
    assert_template 'list'
  end

  test "borrar_should_work" do
    sym_login 2
    g = Game.new({:code => 'fooli', :name => "Foo ling pun"})
    assert g.save, g.errors.full_messages_html
    f = g.faction
    assert_raises(AccessDenied) { post :borrar, { :id => f.id} }

    sym_login 1
    t = f.referenced_thing
    assert_not_nil t
    f.created_on = 3.weeks.ago
    f.save
    assert_raises(AccessDenied) { post :borrar, { :id => f.id} }
    f.created_on = 1.week.ago
    f.save
    assert_count_decreases(t.class) do
      assert_count_decreases(Faction) do
        post :borrar, { :id => f.id}
      end
    end
  end
end
