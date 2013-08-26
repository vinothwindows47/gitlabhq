class Projects::IssuesController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :issue, only: [:edit, :update, :show]

  # Allow read any issue
  before_filter :authorize_read_issue!

  # Allow write(create) issue
  before_filter :authorize_write_issue!, only: [:new, :create]

  # Allow modify issue
  before_filter :authorize_modify_issue!, only: [:edit, :update]

  respond_to :js, :html

  def index
    terms = params['issue_search']

    @issues = issues_filtered
    @issues = @issues.where("title LIKE ?", "%#{terms}%") if terms.present?
    @issues = @issues.page(params[:page]).per(20)

    assignee_id, milestone_id = params[:assignee_id], params[:milestone_id]
    @assignee = @project.team.find(assignee_id) if assignee_id.present? && !assignee_id.to_i.zero?
    @milestone = @project.milestones.find(milestone_id) if milestone_id.present? && !milestone_id.to_i.zero?

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render layout: false }
    end
  end

  def new
    @issue = @project.issues.new(params[:issue])
    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    @note = @project.notes.new(noteable: @issue)
    @target_type = :issue
    @target_id = @issue.id

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @issue = @project.issues.new(params[:issue])
    @issue.author = current_user
    @issue.save

    respond_to do |format|
      format.html do
        if @issue.valid?
          redirect_to project_issue_path(@project, @issue)
        else
          render :new
        end
      end
      format.js
    end
  end

  def update
    @issue.update_attributes(params[:issue].merge(author_id_of_changes: current_user.id))

    respond_to do |format|
      format.js
      format.html do
        if @issue.valid?
          redirect_to [@project, @issue]
        else
          render :edit
        end
      end
    end
  end

  def bulk_update
    result = Issues::BulkUpdateContext.new(project, current_user, params).execute
    redirect_to :back, notice: "#{result[:count]} issues updated"
  end

  def issues_statistics
	timeperiod = params[:period].to_i
	start_date = params[:st_date]
	end_date = params[:end_date]
        proj_issueevtObj = @project.events.where("DATE(updated_at) >= :start_date AND DATE(updated_at) <= :end_date AND target_type = :type",{start_date: start_date, end_date: end_date, type: "Issue"})
        issueObj_details = Hash.new
	date_Categories, all_opened_issues_userlist, all_opened_issues_userlist_count = [], [], []
	all_fixed_issues_userlist, all_fixed_issues_userlist_count = [], []
	opened_label_list, opened_label_list_count = [], []
	fixed_label_list, fixed_label_list_count = [], []
	opened_label_categories, opened_user_label_name, opened_label_count_categories = [], [], []
	fixed_label_categories, fixed_user_label_name, fixed_label_count_categories = [], [], []
	resolved_list = [0] * (timeperiod+1)
	created_list = [0] * (timeperiod+1)
	reopened_list = [0] * (timeperiod+1)

	openissueCnt, openmajorissueCnt, fixedissueCnt, fixedmajorissueCnt = 0, 0, 0, 0

	
	for day in 0..timeperiod
		t=Time.parse(end_date) - (day*24*60*60)
                str_dtformat=t.strftime('%Y-%m-%d')
                date_Categories.push(str_dtformat)
	end
	
	date_Categories.reverse!

	proj_issueevtObj.each do |issueevtItem|
		evtVal = issueevtItem.updated_at.localtime
		datefmt = evtVal.strftime('%Y-%m-%d')

		if datefmt > end_date
			next
		end

		if issueevtItem.action == 1
			created_list[date_Categories.index(datefmt)] += 1
		elsif issueevtItem.action == 3
			resolved_list[date_Categories.index(datefmt)] += 1
		else
			reopened_list[date_Categories.index(datefmt)] += 1
		end

		ass_id = issueevtItem.author_id

		if ass_id != nil
                        assignee_name = @project.users.find(ass_id).username
                else
                        assignee_name = "unassigned"
                end

		issue_labelobj = @project.issues.find(issueevtItem.target_id).labels

                issue_labelobj.each do |isueobj|
	
			@labelname = isueobj.name

			if @labelname == nil or @labelname == ""
				@labelname = "unnamed tag"
			else
				@labelname = @labelname.downcase
			end

			if issueevtItem.action == 1 or issueevtItem.action == 4 or issueevtItem.action == 2

				if not opened_label_list.include? @labelname
                                	opened_label_list.push(@labelname)
                        	end

                        	opened_label_index = opened_label_list.index(@labelname)
                        	opened_label_index_details = opened_label_list_count[opened_label_index]
				
				if opened_label_index_details == nil
                           		opened_label_list_count[opened_label_index] = 1
                        	else
                                	opened_label_list_count[opened_label_index] += 1
                        	end

				opened_label_user_index = opened_user_label_name

                                if not opened_label_categories.include? @labelname
                                        opened_label_categories.push(@labelname)
                                end

                                if not opened_user_label_name.include? assignee_name
                                        opened_user_label_name.push(assignee_name)
                                end

                                opened_label_user_index = opened_user_label_name.index(assignee_name)
                                opened_label_categories_index = opened_label_categories.index(@labelname)

                                if opened_label_count_categories[opened_label_user_index] == nil
                                        opened_label_count_categories[opened_label_user_index] = [0]
				end
			
                                if opened_label_count_categories[opened_label_user_index][opened_label_categories_index] == nil
                                	opened_label_count_categories[opened_label_user_index][opened_label_categories_index] = 1
                                else
                                        opened_label_count_categories[opened_label_user_index][opened_label_categories_index] += 1
                                end				

			else
				if not fixed_label_list.include? @labelname
                                        fixed_label_list.push(@labelname)
                                end

                                fixed_label_index = fixed_label_list.index(@labelname)
                                fixed_label_index_details = fixed_label_list_count[fixed_label_index]

                                if fixed_label_index_details == nil
                                        fixed_label_list_count[fixed_label_index] = 1
                                else
                                        fixed_label_list_count[fixed_label_index] += 1
                                end

				fixed_label_user_index = fixed_user_label_name
				
				if not fixed_label_categories.include? @labelname
	                                fixed_label_categories.push(@labelname)
        	                end

				if not fixed_user_label_name.include? assignee_name
					fixed_user_label_name.push(assignee_name)
                		end

				fixed_label_user_index = fixed_user_label_name.index(assignee_name)
				fixed_label_categories_index = fixed_label_categories.index(@labelname)

				
				if fixed_label_count_categories[fixed_label_user_index] == nil
					fixed_label_count_categories[fixed_label_user_index] = [0]
				end
					
				if fixed_label_count_categories[fixed_label_user_index][fixed_label_categories_index] == nil
					fixed_label_count_categories[fixed_label_user_index][fixed_label_categories_index] = 1
				else
					fixed_label_count_categories[fixed_label_user_index][fixed_label_categories_index] += 1
				end

			end
                end

		for fixedUserlabel_createdlist in 0..fixed_user_label_name.count
			fixed_label_count_categories.push([0] * fixed_label_categories.count)	
		end
	
		if issueevtItem.action == 1 or issueevtItem.action == 4 or issueevtItem.action == 2

			openissueCnt += 1
	
			if not all_opened_issues_userlist.include? assignee_name
				all_opened_issues_userlist.push(assignee_name)
			end

			opened_assignee_index = all_opened_issues_userlist.index(assignee_name)
			all_opened_issues_userlist_details = all_opened_issues_userlist_count[opened_assignee_index]

			if all_opened_issues_userlist_details == nil
				all_opened_issues_userlist_count[opened_assignee_index] = 1
			else
				all_opened_issues_userlist_count[opened_assignee_index] += 1
			end

		else

			fixedissueCnt += 1

                        if not all_fixed_issues_userlist.include? assignee_name
                                all_fixed_issues_userlist.push(assignee_name)
                        end

                        fixed_assignee_index = all_fixed_issues_userlist.index(assignee_name)
                        all_fixed_issues_userlist_details = all_fixed_issues_userlist_count[fixed_assignee_index]

                        if all_fixed_issues_userlist_details == nil
                                all_fixed_issues_userlist_count[fixed_assignee_index] = 1
			else
				all_fixed_issues_userlist_count[fixed_assignee_index] += 1
			end
	
		end
	end

	issueObj_details["opened"] = created_list
	issueObj_details["resolved"] = resolved_list
	issueObj_details["reopened"] = reopened_list

	issueObj_details["all_opened_issues_details"] = all_opened_issues_userlist.zip(all_opened_issues_userlist_count)
	issueObj_details["all_fixed_issues_details"] = all_fixed_issues_userlist.zip(all_fixed_issues_userlist_count)
	issueObj_details["opened_label_details"] = opened_label_list.zip(opened_label_list_count)
	issueObj_details["fixed_label_details"] = fixed_label_list.zip(fixed_label_list_count)
	issueObj_details["opened_label_by_user_details"] = {"label" => opened_label_categories, "user" => opened_user_label_name, "value" => opened_label_count_categories}

	issueObj_details["fixed_label_by_user_details"] = {"label" => fixed_label_categories, "user" => fixed_user_label_name, "value" => fixed_label_count_categories}
	
	issueObj_details["issueCnt"] = { "total_openIssue" => openissueCnt, "total_majoropenIssue" => openmajorissueCnt, "total_fixedIssue" => fixedissueCnt, "total_majorfixedIssue" => fixedmajorissueCnt }
	
        respond_to do |format|
                format.html
                format.json { render json: issueObj_details }
        end
  end

  protected

  def issue
    @issue ||= @project.issues.find(params[:id])
  end

  def authorize_modify_issue!
    return render_404 unless can?(current_user, :modify_issue, @issue)
  end

  def authorize_admin_issue!
    return render_404 unless can?(current_user, :admin_issue, @issue)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled
  end

  def issues_filtered
    @issues = Issues::ListContext.new(project, current_user, params).execute
  end
end
