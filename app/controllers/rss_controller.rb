class RssController < ApplicationController

  def noticias
      response.headers["Content-Type"] = 'text/xml'
      render :layout => false
  end

  def cola_moderacion
    raise AccessDenied unless (params[:secret] && params[:secret].to_s != '')
    @user = User.find_by_secret(params[:secret])

    if @user
      # TODO copypasted
      @news = News.pending
      @events = Event.pending
      @downloads = Download.pending
      @demos = Demo.pending
      @polls = Poll.pending
      @images = Image.pending
      @tutorials = Tutorial.pending
      @columns = Column.pending
      @interviews = Interview.pending
      @reviews = Review.pending
      @funthings = Funthing.pending
    end

    response.headers["Content-Type"] = 'text/xml'
    render :layout => false
  end
end
