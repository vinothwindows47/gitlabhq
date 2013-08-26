var pId,uId;
var updateNotification;

$(document).ready(function()
{
        pId = $("#project_id").val() /* get project_id and user_id for repository status */
        uId = $("#user_id").val()

        if(pId >= 0 && $.trim(pId) != "")
                {
                        repo_status() /* ping repository event status frequently */

                        if($(".container ul li").hasClass("home active"))
                        {
                                setTimeout("showNotificationdiv()",1000)
                        }

                        $('.container ul li.home').click(function()
                        {
                                if($(".repo_status").html()>0)
                                {
                                        updateNotification = true;
                                        setTimeout("update_notification()",1000)
                                        setTimeout("showNotificationdiv()",1000)
                                }
                        });
                }

		/* repository status getting for every 15 seconds */

		setInterval(function()
        	{
                	if(pId >= 0 && $.trim(pId) != "")
                	{
                        	repo_status()
                	}
        	},15000);
});

/* repository status ajax request sending for particular project_id with specified user for getting new notification status since last seen status */
	
function repo_status()
{
        returnData = ajaxRequest("/repo_status","project_id="+pId+"&user_id="+uId,false)
        if(returnData != "Nodata") repostatusPage(returnData)
}

/* update notification after read all event notification*/

function update_notification()
{
        returnData = ajaxRequest("/update_notification","project_id="+pId+"&user_id="+uId,false)
}

function repostatusPage(outputData)
{
        repostatusObj = outputData.notification_status

        if(repostatusObj == 0)
        {
                $(".repo_status").css("display","none")
                return;
        }
        $(".repo_status").html(repostatusObj).css("display","inline-block") /* repo notification count set in div */
}

/* Notification related events div highlighted */

function showNotificationdiv(repostatusObj)
{
    if(updateNotification == true)
    {
        $(".repo_status").css("display","none")
    }
    $("div.content_list div.event-item:lt("+$(".repo_status").html()+")").css("background", "#F9F9F9").css("border-left","2px solid #16b616");
}


