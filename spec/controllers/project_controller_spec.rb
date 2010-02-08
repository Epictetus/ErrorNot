require 'spec_helper'

describe ProjectsController do

  integrate_views

  describe 'with an anonymous user' do
    it 'should not see index' do
      get :index
      response.should redirect_to(new_user_session_path('unauthenticated' => true))
    end
    it 'should not see show' do
      get :show, :id => Factory(:project).id
      response.should redirect_to(new_user_session_path('unauthenticated' => true))
    end
    it 'should not can create project' do
      post :create, :project => { :name => 'My big project' }
      response.should redirect_to(new_user_session_path('unauthenticated' => true))
    end
    it 'should not can edit a project' do
      get :edit, :id => Factory(:project).id.to_s
      response.should redirect_to(new_user_session_path('unauthenticated' => true))
    end
  end

  describe 'with a user logged' do
    before do
      @user = make_user
      sign_in @user
    end

    describe 'GET #index' do
      it 'should success without project' do
        get :index
        response.should be_success
      end

      it 'should success with a lot of project' do
        2.times { Factory(:project) }
        get :index
        response.should be_success
      end

      it 'should see his project only' do
        user_project = make_project_with_admin(@user)
        non_user_project = Factory(:project)
        get :index
        assert_equal [user_project], assigns[:projects]
      end
    end

    describe 'GET #new' do
      it 'should be success' do
        get :new
        response.should be_success
      end
    end

    describe 'POST #create' do
      it 'should be create a project and redirect to errors on this project' do
        lambda do
          post :create, :project => { :name => 'My big project' }
        end.should change(Project, :count)
        response.should redirect_to(project_errors_path(Project.last(:order => 'created_at')))
        flash[:notice].should == 'Your project is create'
      end

      it 'should not redirect if bad project post' do
        lambda do
          post :create, :project => { :name => '' }
        end.should_not change(Project, :count)
        response.should be_success
      end
    end

    describe 'GET #edit' do

      it 'should edit a project where user is admin' do
        project = make_project_with_admin(@user)
        get :edit, :id => project.id.to_s
        response.should be_success
      end

      it 'should not edit a project where user is not admin' do
        project = make_project_with_admin(Factory(:user))
        get :edit, :id => project.id.to_s
        response_is_401
      end

    end

    describe 'PUT #update' do
      it 'should update project name if user is admin on this project' do
        project = make_project_with_admin(@user)
        put :update, :project => {:name => 'foo'}, :id => project.id
        response.should redirect_to(project_errors_url(project))
        project.reload.name.should == 'foo'
      end

      it 'should not update project name if user is not admin on this project' do
        project = make_project_with_admin(Factory(:user))
        put :update, :project => {:name => 'foo'}, :id => project.id
        response_is_401
        project.reload.name.should_not == 'foo'
      end
    end

    describe 'PUT #add_member' do
      it 'should redirect_to edit with flash[:notice] if user is admin of project' do
        project = make_project_with_admin(@user)
        put :add_member, :email => 'foo@bar.com', :id => project.id.to_s
        response.should redirect_to(edit_project_url(project))
        flash[:notice].should == I18n.t('flash.projects.add_member.success')
      end

      it 'should not add member in project because user is not admin on this project' do
        project = make_project_with_admin(Factory(:user))
        put :add_member, :email => 'foo@bar.com', :id => project.id.to_s
        response_is_401
      end
    end
  end

end
