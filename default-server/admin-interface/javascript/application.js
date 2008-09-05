var ADMIN_QUEUE_PATH = '/admin/backend';
			
function toggle_element (element_id) {
	$(element_id).disabled = !$(element_id).disabled;
}

function updateSelects() {
	new Ajax.Request(ADMIN_QUEUE_PATH, {
		method:'GET',
		onSuccess: function(transport) {
		  queues = transport.responseText.evalJSON();
		  fillSelectWithQueuePaths("get-queue-name", queues);
		  fillSelectWithQueuePaths("post-queue-name", queues);
		  fillTableSpaceWithQueues("queue-table-space", queues);
		},
		onFailure: function(transport){ alert(transport.getHeader("ERROR")) }
	});
}

function updateTable() {
	new Ajax.Request(ADMIN_QUEUE_PATH, {
		method:'GET',
		onSuccess: function(transport) {
		  queues = transport.responseText.evalJSON();
		  fillTableSpaceWithQueues("queue-table-space", queues);
		},
		onFailure: function(transport){ alert(transport.getHeader("ERROR")) }
	});
}

function fillTableSpaceWithQueues(table_space, queues) {
	var list = '';	
		
	queues.each ( function (queue) {
		list += "<div><small>" + 
			'<input type="checkbox" class="queue_to_delete" value="' + queue[0] + '"/><strong>' + 
			queue[0] + "</strong><br />(" + queue[1] + "/" + queue[2] +") bytes (" + 
			queue[3] + "/" + queue[4] + ") messages</small> " +
			'</div>';
	});

	$(table_space).innerHTML = list;
}

function fillSelectWithQueuePaths(select_id, queues) {
	// remove all current
	while ($(select_id).hasChildNodes()) {
		$(select_id).removeChild($(select_id).lastChild);
	}
	
	queues.each ( function (queue) {
		elem = document.createElement("option");
		elem.label = elem.value = elem.text = queue[0]; 
		$(select_id).appendChild(elem);
	});
}

function getMessageFromQueue(button_id, select_id, output_id) {	
	new Ajax.Request($(select_id).value, {
		method:'GET',
		onLoading: function(transport) {
		  toggle_element(button_id);
		},
		onSuccess: function(transport) {
		  if (transport.status == 200) {
		  	$(output_id).innerHTML = transport.responseText;
		  	updateTable();
		  } else {
                  alert("There is no message in the queue");
			$(output_id).innerHTML = " == NO MESSAGE IN THE QUEUE ==";
                }
		  toggle_element(button_id);
		},
		onFailure: function(transport){ 
		  alert(transport.getHeader("ERROR"));
		  toggle_element(button_id);
		}
	});
}

function sendMessageToQueue(button_id, select_id, input_id) {	
	new Ajax.Request($(select_id).value, {
		method:'POST',
		postBody: $(input_id).value,
		contentType: "text/plain", 
		onLoading: function(transport) {
		  toggle_element(button_id);
		},
		onSuccess: function(transport) {
		  updateTable();
		  toggle_element(button_id);
		},
		onFailure: function(transport) { 
		  alert(transport.getHeader("ERROR"));
		  toggle_element(button_id);
		}
	});
}

function createQueue() {
	new Ajax.Request(ADMIN_QUEUE_PATH, {
		method: 'POST',
		postBody: "_method=create" + 
		  "&path=" + "/" + $("queue-create-path").value + 
		  "&max_messages=" + parseInt($("queue-create-max-messages").value) + 
		  "&max_size=" + $("queue-create-size").value,
		onSuccess: function(transport) {
		  updateSelects();
		  updateTable();
		  alert("Queue /" + $("queue-create-path").value + " created successfully");
		},
		onFailure: function(transport){ alert(transport.getHeader("ERROR")) }
	});
}

function deleteQueue(delete_radio) {
	radios = document.getElementsByClassName(delete_radio);
	for (i = 0; i < radios.length; i++) {
		radio = radios[i]
		if (radio.checked) {
			new Ajax.Request(ADMIN_QUEUE_PATH, {
				method: 'POST',
				postBody: "_method=delete&path=" + radio.value,
				onSuccess: function(transport) {
				  updateSelects();
				  updateTable();
				  alert("Queue " + radio.value + " successfully deleted");
				},
				onFailure: function(transport){ alert(transport.getHeader("ERROR")) }
			});
		}
	}
}
