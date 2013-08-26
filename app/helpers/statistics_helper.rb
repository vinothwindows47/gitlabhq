module StatisticsHelper
        def queryevent(seltype,start_date,end_date,projectrelated)

                if seltype.eql?("Commits_event")
                        return queryRepoevent("action = ? AND DATE(updated_at) >= ? AND DATE(updated_at) <= ?", 5,start_date,end_date,projectrelated)
                end

                if seltype.eql?("Issues_event")
                        return queryRepoevent("target_type = ? AND DATE(updated_at) >= ? AND DATE(updated_at) <= ?", "Issue",start_date,end_date,projectrelated)
                end

                if seltype.eql?("Merge_event")
                        return queryRepoevent("target_type = ? AND DATE(updated_at) >= ? AND DATE(updated_at) <= ?", "MergeRequest",start_date,end_date,projectrelated)
                end

                if seltype.eql?("Milestones_event")
                        return queryRepoevent("target_type = ? AND DATE(updated_at) >= ? AND DATE(updated_at) <= ?", "Milestone",start_date,end_date,projectrelated)
                end
        end

	def queryRepoevent(queryaction,type,start_date,end_date,projectrelated)
                unless projectrelated.blank?
                        return Event.where(queryaction.concat(" AND project_id = ?"),type,start_date,end_date,projectrelated.to_i)
                end

                return Event.where(queryaction,type,start_date,end_date)
        end	

	def Repoevent(queryaction,start_date,end_date,projectrelated)

		eventObj = Event.where(queryaction,start_date,end_date).all

		unless projectrelated.blank?
                        eventObj = Event.where(queryaction.concat(" AND project_id = ?"),start_date,end_date,projectrelated.to_i).all
		end

                pushed = 0
                issues,issue_created,issue_closed,issue_reopened,issue_updated = 0,0,0,0,0
                merges,merge_created,merge_merged = 0,0,0
                miles,miles_created,miles_closed = 0,0,0

                eventObj.each do |evtobj|

			evtVal = evtobj.updated_at.localtime
                        datefmt = evtVal.strftime('%Y-%m-%d')

                        if datefmt > end_date
                                next
                        end

                        if evtobj.action == 5
				cmtcount = 1
				
				if evtobj[:data] != ""
					cmtcount = evtobj.data[:total_commits_count]
				end

                                pushed += cmtcount
                        end

                        if evtobj.target_type == "Issue"
                                issues += 1
                                if evtobj.action == 1
                                        issue_created += 1
                                end
                                if evtobj.action == 3
                                        issue_closed += 1
                                end
                                if evtobj.action == 4
                                        issue_reopened += 1
                                end
                                if evtobj.action == 2
                                        issue_updated += 1
                                end
                        end

                        if evtobj.target_type == "MergeRequest"
                                merges += 1
                                if evtobj.action == 1
                                        merge_created += 1
                                end

                                if evtobj.action == 7
                                        merge_merged += 1
                                end
                        end
			
			if evtobj.target_type == "Milestone"
                                miles += 1
                                print evtobj.action
                                if evtobj.action == 1 || evtobj.action == nil
                                        miles_created += 1
                                end

                                if evtobj.action == 3
                                        miles_closed += 1
                                end
                        end
                end


                eventDetails = {"Total_commits" => pushed,"Total_issues" => issues,"Created_issues" => issue_created,"Closed_issues" => issue_closed,"Reopened_issues" => issue_reopened,"Updated_issues" => issue_updated,"Total_merges" => merges,"Created_merges" => merge_created,"Merged" => merge_merged,"Total_milestones" => miles,"Created_milestones" => miles_created,"Closed_milestones" => miles_closed}

                return eventDetails

	end
end
