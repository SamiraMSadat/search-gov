class UsersController < SslController
  layout 'sites'
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
    render layout: 'application'
  end

  def create
    @user = User.new(params[:user])
    if verify_recaptcha(:model => @user, :message => 'Word verification is incorrect') && @user.save
      if @user.is_affiliate?
        if @user.has_government_affiliated_email?
          flash[:success] = "Thank you for signing up. To continue the signup process, check your inbox, so we may verify your email address."
        else
          flash[:success] = "Sorry! You don't have a .gov or .mil email address so we need some more information from you before approving your account."
        end
      else
        flash[:success] = 'Thank you for registering for USA.gov Search Services.'
      end
      redirect_to account_path
    else
      flash.delete(:recaptcha_error)
      render action: :new, layout: 'application'
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:success] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def developer_redirect
  end

  private
  def require_user
    redirect_to developer_redirect_url if super.nil? and current_user.is_developer?
  end
end
