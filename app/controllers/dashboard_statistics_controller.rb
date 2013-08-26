class DashboardStatisticsController < ApplicationController

	include StatisticsHelper
	respond_to :html, :json

	def Dashboard_Activities
		seltype = params[:Sel_type]
		daysago = params[:period].to_i
		start_date = params[:st_date]
		end_date = params[:end_date]
		@project_statistics_id = params[:project_id]

		output_details = Hash.new

		evtObj = TotalEvents(start_date,end_date)

		output_details["total_commits"] = evtObj["Total_commits"]
    		output_details["total_merges"] = evtObj["Total_merges"]
    		output_details["total_issues"] = evtObj["Total_issues"]
    		output_details["total_milestones"] = evtObj["Total_milestones"]
    		output_details["eventStatistics"] = event(seltype,start_date,end_date,daysago)
		output_details["Issues_type"] = {"opened" => evtObj["Created_issues"],"closed" => evtObj["Closed_issues"],"reopened" => evtObj["Reopened_issues"]}

    		respond_to do |format|
      			format.html
      			format.json { render json: output_details }
    		end
	end

	def repo_status
		project_statistics_id = params[:project_id]
		project_user_id = params[:user_id]
		notification_details = Hash.new

		notification_count = 0

		project_cnt_obj = Event.where("project_id = ?",project_statistics_id).count

		user_notification_obj = EventNotifications.where("project_id = ? AND user_id = ?",project_statistics_id,project_user_id)
	
		if user_notification_obj.count == 0
			user_notification = EventNotifications.new
			user_notification.project_id = project_statistics_id
			user_notification.user_id = project_user_id
			user_notification.last_notification = project_cnt_obj
			user_notification.save
		else
			user_notification_obj.each do |notificationObj|
				notification_count = project_cnt_obj - notificationObj.last_notification
			end
		end

		notification_details["notification_status"] = notification_count

		respond_to do |format|
                        format.html
                        format.json { render json: notification_details } 
                end
	end

	def update_notification
		project_statistics_id = params[:project_id]
                project_user_id = params[:user_id]

		project_cnt_obj = Event.where("project_id = ?",project_statistics_id).count

                user_notification_obj = EventNotifications.where("project_id = ? AND user_id = ?",project_statistics_id,project_user_id).first
		if user_notification_obj.update_attributes(:last_notification => project_cnt_obj)
			respond_to do |format|
                        	format.json { render json: {:status => "Updated successfully"} }
                	end
		end

	end

	def createList()
		@Emptylist=[0]*24
		return @Emptylist
	end

	def TotalEvents(start_date,end_date)
                totaleventObj = Repoevent("DATE(updated_at) >= ? AND DATE(updated_at) <= ?",start_date,end_date,@project_statistics_id)
                return totaleventObj
        end

	def event(seltype,start_date,end_date,daysago)
		
		evtObj = queryevent(seltype,start_date,end_date,@project_statistics_id)
                evtObj_details = Hash.new
                date_Categories = []
                commitStatistics = []

                for day in 0..daysago
                        t=Time.parse(end_date) - (day*24*60*60)
                        str_dtformat=t.strftime('%Y-%m-%d')
                        date_Categories.push(str_dtformat)
                        evtObj_details[str_dtformat] = {"total_evtcount"=>0,"evt_hours"=>createList()}
                end

                date_Categories.reverse!

		if evtObj.count == 0
			commitStatistics = "NoValue"
			return commitStatistics
		end

                evtObj.each do |c|
                        evtVal =c.updated_at.localtime
                        datefmt = evtVal.strftime('%Y-%m-%d')

			if datefmt > end_date
				next
			end

                        hourfmt =evtVal.hour
			actioncount = 1
			if c.action == 5
				if c[:data] != ""
                                        actioncount = c.data[:total_commits_count]
					if actioncount == 0
						actioncount = 1
					end
                                end	
			end

                        evtObj_details[datefmt]["evt_hours"][hourfmt] += actioncount
                end


                date_Categories.each do |dcatg|
                        evthour = evtObj_details[dcatg]["evt_hours"]
                        commitStatistics.concat(evthour)
                end
		
		empty_statChk = 0
		commitStatistics.each { |emptyChkval| empty_statChk += emptyChkval }

		if empty_statChk == 0
			commitStatistics = "NoValue"
                        return commitStatistics
		end	
	
		return commitStatistics
	end

end
