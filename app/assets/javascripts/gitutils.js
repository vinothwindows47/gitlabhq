function ajaxRequest(Url,Parameter,ifModifiedStatus)
{

        var returnResponse;

        $.ajax({
        url: Url,
        data: Parameter,
        dataType: 'json',
        cache: 'true',
        type: 'GET',
        async: false,
        ifModified:ifModifiedStatus,
        success:function(data,textStatus,jqXHR)
        {
                if(jqXHR.status != 200)
                {
                        returnResponse = "Nodata";
                }
                else
                {
                        returnResponse = data;
                }
        },
        error: function()
        {
                returnResponse = "Nodata"
        }
        });

        return returnResponse;

}

function SumOfList(listval)
{
	sum = 0
	for(i=0; i< listval.length; i++)
	{
    		sum += listval[i]
 	}

	return sum

}
