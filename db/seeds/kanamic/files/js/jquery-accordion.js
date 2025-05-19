/* Copyright KANAMIC NETWORK Co.LTD All Right Reserved */
/***********************************************
	隠しておく要素に.item数字(0-9)
	スイッチの役割をもつ要素のaタグに.switch数字(0-9)
************************************************/

$(function()
{
	for(i=0; i < 10; i++) {
		toggle = "toggleCtl" + i;
		accordionItem = '.item'+i;
		accordionSwitch = '.switch'+i;
		
		initAccordion(toggle , accordionItem ,accordionSwitch);
	}
});


function initAccordion(param1, param2, param3)
{
	var toggleStatus = readCookie(param1);
		if (toggleStatus == null) {
			toggleStatus = setStatusV(0,param1);
		}
	
	var itemNode = $(param2)
		if (toggleStatus == 0) {
			itemNode.hide();
		}

	var obj = $(param3);
	obj.click(function() {
			if (toggleStatus == 0){
				toggleStatus = setStatusV(1,param1);
			} else if(toggleStatus == 1) {
				toggleStatus = setStatusV(0,param1);
			}
		
			itemNode.toggle();
		});
}



function setStatusV(value, id)
{
	createCookie(id, value, 365);
	return readCookie(id);
}



// cookie script http://www.quirksmode.org/js/cookies.html
function createCookie(name,value,days)
{
	if (days)
	{
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}
function readCookie(name)
{
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++)
	{
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}