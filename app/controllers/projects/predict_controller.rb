class Projects::PredictController < Projects::ApplicationController

  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end
end
