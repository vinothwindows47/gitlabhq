
$(document).ready(function() {
		  $("body").css("margin-bottom","120px")
                  $('#reportrange').daterangepicker(
                     {
                        startDate: moment().subtract('days', 6),
                        endDate: moment(),
                        ranges: {
                           'Today': [moment(), moment()],
                           'Yesterday': [moment().subtract('days', 1), moment().subtract('days', 1)],
                           'Last 7 Days': [moment().subtract('days', 6), moment()],
                           'Last 30 Days': [moment().subtract('days', 29), moment()],
                           'This Month': [moment().startOf('month'), moment().endOf('month')],
                           'Last Month': [moment().subtract('month', 1).startOf('month'), moment().subtract('month', 1).endOf('month')]
                        },
                        opens: 'right',
                        buttonClasses: ['btn-danger'],
                        applyClass: 'btn-small btn-success',
                        clearClass: 'btn-small',
                        separator: ' to ',
                        locale: {
                            applyLabel: 'Submit',
                            fromLabel: 'From',
                            toLabel: 'To',
                            customRangeLabel: 'Custom Range',
                            daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr','Sa'],
                            monthNames: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                            firstDay: 1
                        }
                     },
                     function(start, end) {
			
		      Start_date = start.format("YYYY-MM-DD")	
		      End_date = end.format("YYYY-MM-DD")  	   
		      getTime_period(Start_date,End_date)
                      $('#reportrange span').html(start.format('MMM D, YYYY') + ' - ' + end.format('MMM D, YYYY'));
                     }
                  );
                  //Set the initial state of the picker label
                  $('#reportrange span').html(moment().subtract('days', 6).format('MMM D, YYYY') + ' - ' + moment().format('MMM D, YYYY'));

			  $(".eventdv").click(function() {
				Selection_type = $(this).attr("id") /* set selection type such as commit event or issue event or merge event */
				eventStatistics(statistics_url)	
        		});
               });

function displayDashboard(thisclass,className)
{
	$(".overall_statistics").css("display","none")
	$("."+className).css("display","block")
	$(".sub-nav_statistics").removeClass("sub-nav_statistics_active")
	$(thisclass).addClass("sub-nav_statistics_active")
}


function getnormal_period()
{
	curdate = new Date()
	End_date = getDateformat(curdate)   /* current date format */
        curdate.setDate(curdate.getDate() - Timeperiod)
        Start_date = getDateformat(curdate)	 /* extended time period format. ex: last 7 days or last 30 days */
}

/* get Timeperiod */

function getTime_period(start,end)
{
	var oneDay = 24*60*60*1000; // hours*minutes*seconds*milliseconds
	var convert_startdate = new Date(start)
	var convert_enddate = new Date(end)
	Timeperiod = Math.round(Math.abs((convert_startdate.getTime() - convert_enddate.getTime())/(oneDay)))
	eventStatistics(statistics_url)
}

/* get required date format for sending ajax request */

function getDateformat(dateFormat)
{
     fullYear = dateFormat.getFullYear()
     month    = dateFormat.getMonth() +  1
     month.toString().length > 1 ? month = month : month = "0" + month 
     date     = dateFormat.getDate()
     return fullYear + "-" + month + "-" + date
}

/**/

function eventStatistics(statistics_url)
{
	project_id = $("#project_id").val()
	if(project_id == undefined) project_id=""
	returnData  = ajaxRequest(statistics_url,"project_id="+project_id+"&Sel_type="+Selection_type+"&period="+Timeperiod+"&st_date="+Start_date+"&end_date="+End_date,false)
   	if(returnData != "Nodata") eventStatisticsPage(returnData);

  	$(".eventdv").css("background","")	
  	$("#"+Selection_type).css("background","-webkit-linear-gradient(top, #efefef 0%, #fbfbfb 100%)").css("background","-moz-linear-gradient(center top , #EFEFEF 0%, #FBFBFB 100%) repeat scroll 0 0 transparent")

}

function eventStatisticsPage(outputData)
{
    retStatistics = outputData;
    eventGraph(retStatistics)
    total_issues = retStatistics["total_issues"]
    totalcommEvt(retStatistics["total_commits"],".pshtotal")
    totalcommEvt(retStatistics["total_merges"],".mgetotal")
    totalcommEvt(total_issues,".isuetotal")
    totalcommEvt(retStatistics["total_milestones"],".milestotal")
    if(project_id != "") issueStatistics(retStatistics,total_issues)
}

function totalcommEvt(totalevtObj,className)
{
    $(className).html(totalevtObj);
}

function issueStatistics(issueevtObj,total_issues)
{
    $(".sub-nav").css("display","block")
    issue_statistics_url = $("li.home a").attr("href")
    returnData = ajaxRequest(issue_statistics_url + "/issues/issues_statistics","period="+Timeperiod+"&st_date="+Start_date+"&end_date="+End_date,false)    
    totalissue_chk = (total_issues == 0) ? $('#created_vs_resolved').html("Nothing here.").addClass("No-Value") : created_vs_resolved_Statistics(returnData)

    issues_assignee("opened_label",returnData.opened_label_details)
    issues_assignee("closed_label",returnData.fixed_label_details)
    issues_assignee("opened_issues_users",returnData.all_opened_issues_details)
    issues_assignee("fixed_issues_users",returnData.all_fixed_issues_details)
    issues_assignee("opened_label",returnData.opened_label_details)
    bar_chart("opened_issues_by_labels_users",returnData.opened_label_by_user_details)
    bar_chart("fixed_issues_by_labels_users",returnData.fixed_label_by_user_details)
    
    var issues_obj = new Array()
    issues_obj[0] = issueevtObj["Issues_type"]["opened"]
    issues_obj[1] = issueevtObj["Issues_type"]["closed"]
    issues_obj[2] = issueevtObj["Issues_type"]["reopened"]
    issues_obj_percent = []
    for (var ass_issue=0;ass_issue<issues_obj.length;ass_issue++)
    {
	if(total_issues == 0)
	{
		issues_obj_percent = [0,0,0]
		break;
	}
        issues_obj_percent.push(parseInt(issues_obj[ass_issue])/parseInt(total_issues)*100)
    }
    for (var html_issue=0;html_issue<issues_obj.length;html_issue++)
    {
        $("#issues_type .isue_typetotal:eq("+html_issue.toString()+")").html(issues_obj[html_issue])
	$("#issues_type .isue_typebar:eq("+html_issue.toString()+")").css("width",(issues_obj_percent[html_issue]*2).toString()+"px").css("background-color","#4183c4")
        $("#issues_type .isue_typepercentage:eq("+html_issue.toString()+")").html(Math.floor(issues_obj_percent[html_issue])+"%")
    }
}

function eventGraph(pshevtObj)
{
            dataVal = pshevtObj.eventStatistics
	    if(dataVal == "NoValue") 
	    {
		Charts_statistics(Selection_type)
	    	$('#cmtStatistics_Graph').html("Nothing here.").addClass("No-Value")
		return;
	    }
	    $('#cmtStatistics_Graph').removeClass("No-Value")
	    $('#cmtStatistics_Graph').highcharts({
        chart: {
            zoomType: 'x',
            type:'area',
            marginTop: 50
        },
        title: {
            text:Charts_statistics(Selection_type) + " Statistics",
            style: {
                color: '#888',
                fontSize: '12px',
            }
        },
        legend: {
            enabled: false
        },
        tooltip: {
            shared: true,
            crosshairs: true,
            crosshairs: {
                width: 1,
                color: '#888',
                dashStyle: 'Dash',
            }
        },
        xAxis: {
            type: 'datetime',
            tickPosition: 'inside',
            maxZoom: 48 * 3600 * 1000,
            dateTimeLabelFormats: {
                day: '%b %e'
            },
            labels: {
                style: {
                    color: '#888',
                    fontSize: '10px',
                }
            },
        },
        yAxis: {
	    allowDecimals: false,
            gridLineColor: '#E4E4E4',
            title: {
                        enabled: false,
                    },
            labels: {
                    style: {
                        color: '#888',
                        fontSize: '10px',
                    }
            },
        },
        plotOptions: {
       
                  
            series: {
                marker: {
                    enabled: false
                }
            },
        },
        
        series: [{
            name:Charts_statistics(Selection_type),
            data:dataVal,
            pointStart: pointStart(),
            pointInterval: 3600000 // one day
        }]
    });
    $('#cmtStatistics_Graph tspan').last().css("display","none")
}

function created_vs_resolved_Statistics(retObj)
{
	opened_issue = retObj.opened
	closed_issue = retObj.resolved
	reopened_issue = retObj.reopened

        $('#created_vs_resolved').highcharts({
            chart: {
                type: 'column',
                borderRadius: 10
            },
            title: {
                text: ''
            },
            legend: {
		align: 'right',
                x: -70,
                verticalAlign: 'top',
                y: 20,
                floating: true,
                backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColorSolid) || 'white',
                borderColor: '#CCC',
                borderWidth: 1,
                shadow: false
            },
            xAxis: {
                type: 'datetime',
            tickPosition: 'inside',
            maxZoom: 48 * 3600 * 1000,
            dateTimeLabelFormats: {
                day: '%b %e'
            },
                labels: {
                style: {
                    color: '#888',
                    fontSize: '10px',
                }
            },
            },
            yAxis: {
                allowDecimals: false,
		stackLabels: {
                    enabled: true,
		},
                title: {
                        enabled: false,
                    },
            labels: {
                    style: {
                        color: '#888',
                        fontSize: '10px',
                    },
                stackLabels: {
                    enabled: true,
                    style: {
                        fontWeight: 'bold',
                        color: (Highcharts.theme && Highcharts.theme.textColor) || 'gray'
                    },
                },
            },
                    
            },
            tooltip: {
                shared: true,
                crosshairs: true,
                crosshairs: {
                    width: 1,
                    color: '#888',
                    dashStyle: 'Dash',
                },
                valueSuffix: ' issues'
            },
            plotOptions: {
		column: {
                    stacking: 'normal',
                },
            series: {
                fillOpacity: 0.1
            },
        },
            series: [{
                color: '#4897f1',
                name: 'Created',
                data: opened_issue,
                pointStart: pointStart(),
                pointInterval: 24*3600*1000
            }, {
                color: '#8bbc21',
                name: 'Closed',
                data: closed_issue,
                pointStart: pointStart(),
                pointInterval: 24*3600*1000
            }, {
                color: '#263c53',
                name: 'Reopened',
                data: reopened_issue,
                pointStart: pointStart(),
                pointInterval: 24*3600*1000
            }]
        });
    $('#created_vs_resolved tspan').last().css("display","none")
}

function issues_assignee(id,dataObj)
{
	if(dataObj.length == 0) 
	{
		$('#'+id).html("Nothing here.").addClass("No-Value")
                return;
	}
	$('#'+id).highcharts({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
		borderRadius: 10
            },
            title: {
                text: ''
            },
            tooltip: {
        	    pointFormat: '{series.name}: <b>{point.y}</b>'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        color: '#000000',
                        connectorColor: '#000000',
                        formatter: function() {
                            return '<b>'+ this.point.name +'</b>: '+ this.point.y;
                        }
                    }
                }
            },
            series: [{
                type: 'pie',
                name: 'Issues',
                data: dataObj
            }]
        });
	$('#'+id+' tspan').last().css("display","none")
	if($.trim($('#'+id).html()) == "") $('#'+id).html("Nothing here.").addClass("No-Value")
}

function bar_chart(Id,dataObj)
{
	category = dataObj.label
	user = dataObj.user
	value = dataObj.value

	if(category.length == 0)
        {
                $('#'+Id).html("Nothing here.").addClass("No-Value")
                return;
        }

	seriesObj = []

	for(var seriesVal=0;seriesVal < user.length;seriesVal++)
	{
		seriesObj.push({name: user[seriesVal],data:value[seriesVal]})
	}

	$('#'+Id).highcharts({
            chart: {
                type: 'bar',
		borderRadius: 10
            },
            title: {
                text: ''
            },
            xAxis: {
                categories: category
            },
            yAxis: {
		allowDecimals: false,
                min: 0,
                title: {
                    text: ''
                }
            },
            legend: {
                backgroundColor: '#FFFFFF',
                reversed: true
            },
            plotOptions: {
                series: {
                    stacking: 'normal'
                }
            },
                series: seriesObj
        });

	$('#'+Id+' tspan').last().css("display","none")

}

function pointStart()
{
    var date = new Date(End_date);
    date.setDate(date.getDate() - Timeperiod);
    return Date.UTC(date.getFullYear(),date.getMonth(),date.getDate())
}

function Charts_statistics(Seltype)
{
	var chart_text = Seltype.split("_event")[0]
	$("#selevtTxt").html(chart_text + " Report")
	return chart_text
}

