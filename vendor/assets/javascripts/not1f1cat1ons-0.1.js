/*!
 * not1f1cat1ons - Notification library
 * https://rentog.com/
 *
 * Author Hermann Wagner
 * Copyright Hermann Wagner
 * Released under the MIT license
 *
 * Date: 2016-30-06
 */

function Not1f1cat1ons (element_class_name, animation, hidden_position, visible_position, default_style, success_style, alert_style, warning_style, info_style){
	this._notification_element;
	this._notification_class;
	this._animation;
	this._visible_position;
	this._hidden_position;
	this._default_style;
	this._success_style;
	this._alert_style;
	this._info_style;
	this._warning_style;

	// Define the initial position and style of the notification div
	this._notification_element = $("." + element_class_name);
	this._notification_class = "." + element_class_name;

	// ANIMATION
	this._animation = {
		show_duration: 500,
		visible_duration: 2000,
		hide_duration: 2000,
		direction: "right"
	}
	for(var prop in animation){
		this._animation[prop] = animation[prop];
	}

	// VISIBLE POSITION
	this._visible_position = {
		"position": 		"fixed",
		"top": 				"100px",
		"right":  			"-2px",
	}
	if(visible_position){
		this._visible_position = visible_position;
	}

	// HIDDEN POSITION
	this._hidden_position = {
		"position": 		"fixed",
		"top": 				"100px",
		"right":  			"-202px",
		"opacity": 			"1"
	}
	if(hidden_position){
		this._hidden_position = hidden_position;
	}

	// DEFAULT STYLE
	this._default_style = {
		"width": 			"200px",
		"min-height": 		"30px",
		"border": 			"2px solid black",
		"box-shadow": 		"0 0 5px black",
		"border-radius": 	"6px 0 0 6px",
		"background-color": "black",
		"color": 			"white",
		"display": 			"none",
		"opacity": 			"1",
		"padding": 			"8px 10px",
		"font-weight": 		"bold",
		"z-index": 			"10000"
	}
	for(var prop in default_style){
		this._default_style[prop] = default_style[prop];
	}

	// Set position and style of notification element
	this._notification_element.css(this._hidden_position).css(this._default_style);

	// SUCCESS STYLE
	this._success_style = {
		"background-color": "#4caf50"
	}
	for(var prop in success_style){
		this._success_style[prop] = success_style[prop];
	}

	// WARNING STYLE
	this._warning_style = {
		"background-color": "#ffb300"
	}
	for(var prop in warning_style){
		this._warning_style[prop] = warning_style[prop];
	}

	// ALERT STYLE
	this._alert_style = {
		"background-color": "#f44336"
	}
	for(var prop in alert_style){
		this._alert_style[prop] = alert_style[prop];
	}

	// INFO STYLE
	this._info_style = {
		"background-color": "#2196f3"
	}
	for(var prop in info_style){
		this._info_style[prop] = info_style[prop];
	}
}

// Define a new notification (it is possible to overwrite the style and animation just for this one notification)
	// "success", "Saved file <b>successfully</b>", {"background-color": "green", "color": "white"}, {visibility_duration: 4000}
Not1f1cat1ons.prototype.triggerNotification = function(type, html, style, animation){
	var _style = {
		success: this._success_style,
		alert: this._alert_style,
		warning: this._warning_style,
		info: this._info_style
	}

	// If a notification is already visible
	if((Number($(this._notification_class).css('opacity'))) > 0){
		var lastElement = $($(this._notification_class)[$(this._notification_class).length-1]);
		var lowerEdgeOfLastElement = lastElement.offset().top - $(window).scrollTop() + lastElement.outerHeight();

		lastElement.clone()
					.insertAfter(lastElement)
					.css(this._default_style)
					.css(_style[type])
					.css(this._hidden_position)
					.css({"top": lowerEdgeOfLastElement + 5 + "px"});


		var lastElement = $($(this._notification_class)[$(this._notification_class).length-1]);
		var ani = {};
		ani[this._animation.direction] = this._visible_position[this._animation.direction];
		lastElement.show()
					.animate(ani, this._animation.show_duration)
					.delay(this._animation.visible_duration)
					.fadeOut(this._animation.hide_duration, function(){
																	$(this).remove();
																});
		lastElement.html(html);

	}else{
		$(this._notification_class).css(_style[type])
								.show()
								.animate(this._visible_position, this._animation.show_duration)
								.delay(this._animation.visible_duration)
								.fadeOut(this._animation.hide_duration, function(){
																				$(this).css(this._hidden_position);
																			});
		$(this._notification_class).html(html);
	}
}
