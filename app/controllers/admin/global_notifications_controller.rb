class Admin::GlobalNotificationsController < AdministrationController
  
  def index
  end
  
  def new
    @global_notification = GlobalNotification.new 
  end
  
  
  def edit
    @global_notification = GlobalNotification.find(params[:id])
  end
  
  def confirm
    @global_notification = GlobalNotification.find(params[:id])
    @global_notification.confirmed = true
    save_or_error @global_notification, "/admin/global_notifications/edit/#{@global_notification.id}", :edit
  end
  
  def create
    @global_notification = GlobalNotification.new(params[:global_notification])
    save_or_error @global_notification, "/admin/global_notifications/edit/#{@global_notification.id}", :new
  end
  
  def update
    @global_notification = GlobalNotification.find(params[:id])
    update_attributes_or_error @global_notification, "/global_notifications/edit/@global_notification.id", :edit
  end
end