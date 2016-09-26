var stepped = 0, chunks = 0, rows = 0;
var start, end;
var parser;
var pauseChecked = false;
var printStepChecked = false;
var json_data = [];
var intervalID = 0;
var uploadAtOnce = 500;
var start_point = 0;
var current_page = 0;
var url = "";

$(function()
{
	$('#submit-parse').click(function()
	{
		stepped = 0;
		chunks = 0;
		rows = 0;

		var txt = $('#input').val();
		var localChunkSize = $('#localChunkSize').val();
		var remoteChunkSize = $('#remoteChunkSize').val();
		var files = $('#files')[0].files;
		var config = buildConfig();

		// NOTE: Chunk size does not get reset if changed and then set back to empty/default value
		if (localChunkSize)
			Papa.LocalChunkSize = localChunkSize;
		if (remoteChunkSize)
			Papa.RemoteChunkSize = remoteChunkSize;

		pauseChecked = $('#step-pause').prop('checked');
		printStepChecked = $('#print-steps').prop('checked');


		if (files.length > 0)
		{
			if (!$('#stream').prop('checked') && !$('#chunk').prop('checked'))
			{
				for (var i = 0; i < files.length; i++)
				{
					if (files[i].size > 1024 * 1024 * 10)
					{
						alert("A file you've selected is larger than 10 MB; please choose to stream or chunk the input to prevent the browser from crashing.");
						return;
					}
				}
			}

			start = performance.now();
			
			$('#files').parse({
				config: config,
				before: function(file, inputElem)
				{
					console.log("Parsing file:", file);
				},
				complete: function()
				{
					console.log("Done with all files.");
				}
			});
		}
		else
		{
			start = performance.now();
			var results = Papa.parse(txt, config);
			console.log("Synchronous parse results:", results);
		}
	});

	$('#submit-unparse').click(function()
	{
		var input = $('#input').val();
		var delim = $('#delimiter').val();

		var results = Papa.unparse(input, {
			delimiter: delim
		});

		console.log("Unparse complete!");
		console.log("--------------------------------------");
		console.log(results);
		console.log("--------------------------------------");
	});

	$('#insert-tab').click(function()
	{
		$('#delimiter').val('\t');
	});

	$('#upload_to_price_comparison_device').click(function(){
		uploadTo("upload_to_price_comparison_device");
	});
});



function buildConfig()
{
	return {
		delimiter: $('#delimiter').val(),
		newline: getLineEnding(),
		header: $('#header_row').prop('checked'),
		dynamicTyping: $('#dynamicTyping').prop('checked'),
		preview: parseInt($('#preview').val() || 0),
		step: $('#stream').prop('checked') ? stepFn : undefined,
		encoding: $('#encoding').val(),
		worker: $('#worker').prop('checked'),
		comments: $('#comments').val(),
		complete: completeFn,
		error: errorFn,
		download: $('#download').prop('checked'),
		fastMode: $('#fastmode').prop('checked'),
		skipEmptyLines: $('#skipEmptyLines').prop('checked'),
		chunk: $('#chunk').prop('checked') ? chunkFn : undefined,
		beforeFirstChunk: undefined,
	};

	function getLineEnding()
	{
		if ($('#newline-n').is(':checked'))
			return "\n";
		else if ($('#newline-r').is(':checked'))
			return "\r";
		else if ($('#newline-rn').is(':checked'))
			return "\r\n";
		else
			return "";
	}
}

function stepFn(results, parserHandle)
{
	stepped++;
	rows += results.data.length;

	parser = parserHandle;
	
	if (pauseChecked)
	{
		console.log(results, results.data[0]);
		parserHandle.pause();
		return;
	}
	
	if (printStepChecked)
		console.log(results, results.data[0]);
}

function chunkFn(results, streamer, file)
{
	if (!results)
		return;
	chunks++;
	rows += results.data.length;

	parser = streamer;

	if (printStepChecked)
		console.log("Chunk data:", results.data.length, results);

	if (pauseChecked)
	{
		console.log("Pausing; " + results.data.length + " rows in chunk; file:", file);
		streamer.pause();
		return;
	}
}

function errorFn(error, file)
{
	console.log("ERROR:", error, file);
}

function completeFn()
{
	end = performance.now();
	if (!$('#stream').prop('checked')
			&& !$('#chunk').prop('checked')
			&& arguments[0]
			&& arguments[0].data)
		rows = arguments[0].data.length;
	
	console.log("Finished input (async). Time:", end-start, arguments);
	console.log("Rows:", rows, "Stepped:", stepped, "Chunks:", chunks);

	json_data = arguments[0].data;

	$('#upload_to_price_comparison_device').prop("disabled", false);
}

function uploadTo(location){
	console.log("click");

	switch(location){
		case "upload_to_price_comparison_device":
			url = "/price_comparison_devices";
			break;
		default:
			alert("error");
	}

	if(url !== ""){

		// calculate start_point
		if($("#starting_pos").val() !== ""){
			start_point = Number($("#starting_pos").val());
		}

		// Show progress
		$(".pages_all").text(Math.ceil(json_data.length / uploadAtOnce));
		current_page = Math.ceil(start_point / uploadAtOnce);
		$(".pages_current").text(current_page);
		$('.entries_current').text(start_point);
		$('.entries_all').text(json_data.length);

		uploadData(start_point, url);
	}
}

function uploadData(start_point, url){
	console.log(start_point);
	console.log(json_data.length);

	// check if there are entries to upload left
	if(start_point < json_data.length){
		// disable button and start alternating "loading" div
		$('#upload_to_price_comparison_device').prop("disabled", true);
		intervalID = setInterval(function(){
			$('.loading').toggle();
		}, 1500);


		// upload
		var jqxhr = $.post( url, 
		{
			devices: json_data.slice(start_point, start_point + uploadAtOnce),
		},
		function(data) {
		  console.log("upload successful:");

		  // update progress
		  start_point = start_point + uploadAtOnce;
		  current_page = current_page + 1;
		  $(".pages_current").text(current_page);
		  $('.entries_current').text(start_point);

		  // try to upload next page
		  uploadData(start_point, url);
		})
		  .done(function(data) {
		    if (data.status === "error"){
					for(var k=0; k < data.details.length; k++){
						console.log(data.details[k]);
					}
		    }
		  })
		  .fail(function() {
		    //console.log( "error" );
		  })
		  .always(function() {
		    // enable button again and stop alternating "loading" div
			  $('#upload_to_price_comparison_device').prop("disabled", false);
			  clearInterval(intervalID);
			  $('.loading').hide();
		});
	}
}