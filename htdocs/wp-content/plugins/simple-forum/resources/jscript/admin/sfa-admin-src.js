/* ---------------------------------
Simple:Press
Admin Javascript
$LastChangedDate: 2010-02-09 02:58:54 +0000 (Tue, 09 Feb 2010) $
$Rev: 3458 $
------------------------------------ */

var sfupload;

/* ----------------------------------*/
/* Admin Form Loader                 */
/* ----------------------------------*/
function sfjLoadForm(formID, baseURL, targetDiv, imagePath, id, open, upgradeUrl)
{
	/* remove any current form unless instructed to leave open */
	if (open == null)
	{
		for(x=document.forms.length-1;x>=0;x--)
		{
			if (document.forms[x].id != '')
			{
				var tForm = document.getElementById(document.forms[x].id);
				if(tForm != null) {
					tForm.innerHTML='';
				}
			}
		}
	}

	/* create vars we need */
	var busyDiv = document.getElementById(targetDiv);
	var currentFormBtn = document.getElementById('c'+formID);
	var ahahURL = baseURL + '&loadform=' + formID;

	/* some sort of ID data? */
	if (id)
	{
		ahahURL = ahahURL + '&id=' + id;
	}

	/* add random num to GET param to ensure its not cached */
	ahahURL = ahahURL + '&rnd=' +  new Date().getTime();

	var spfjform = jQuery.noConflict();
	spfjform(document).ready(function()
	{
		/* fade out the msg area */
		spfjform('#sfmsgspot').fadeOut();

		/* load the busy graphic */
		busyDiv.innerHTML = '<img src="' + imagePath + 'waitbox.gif' + '" />';

		/*  now load the form - and pretty checkbox and sort if toolbar and uploader if smileys */
		spfjform('#'+targetDiv).load(ahahURL, function(a, b) {
			if(a == 'Upgrade')
			{
				spfjform('#'+targetDiv).hide();
				window.location = upgradeUrl;
				return;
			}

			spfjform("input[type=checkbox],input[type=radio]").prettyCheckboxes();

			if(formID == 'toolbar') {
				spfjform("#sftbarstan").sortable({
					handle : '.handle',
					update : function () {
						spfjform("input#stan_buttons").val(jQuery("#sftbarstan").sortable('serialize'));
					}
				});
				spfjform("#sftbarplug").sortable({
					handle : '.handle',
					update : function () {
						spfjform("input#plug_buttons").val(jQuery("#sftbarplug").sortable('serialize'));
					}
				});
			}
		});
	});
}

/* ----------------------------------*/
/* Delete a Smiley                   */
/* ----------------------------------*/
function sfjDelSmiley(url)
{
	jQuery('#sfmsgspot').load(url, function() {
		jQuery('#sfreloadsm').click();
	});
}

/* ----------------------------------*/
/* Delete a Rank Badge               */
/* ----------------------------------*/
function sfjDelBadge(url)
{
	jQuery('#sfmsgspot').load(url, function() {
		jQuery('#sfreloadfr').click();
	});
}

/* ----------------------------------*/
/* Delete a Custom Icon              */
/* ----------------------------------*/
function sfjDelIcon(url)
{
	jQuery('#sfmsgspot').load(url, function() {
		jQuery('#sfreloadci').click();
	});
}

/* ----------------------------------*/
/* Delete a Avatar                  */
/* ----------------------------------*/
function sfjDelAvatar(url)
{
	jQuery('#sfmsgspot').load(url, function() {
		jQuery('#sfreloadav').click();
	});
}

/* ----------------------------------*/
/* Open and Close of hidden divs     */
/* ----------------------------------*/

function sfjtoggleLayer(whichLayer)
{
	if (document.getElementById)
	{
		/* this is the way the standards work */
		var style2 = document.getElementById(whichLayer).style;
		style2.display = style2.display? "":"block";
	}
		else if (document.all)
	{
		/* this is the way old msie versions work */
		var style2 = document.all[whichLayer].style;
		style2.display = style2.display? "":"block";
	}
		else if (document.layers)
	{
		/* this is the way nn4 works */
		var style2 = document.layers[whichLayer].style;
		style2.display = style2.display? "":"block";
	}
	var obj = document.getElementById(whichLayer);
	if (whichLayer == 'sfpostform')
	{
		obj.scrollIntoView(false);
	}
}

/* ----------------------------------*/
/* Admin Option Tools                */
/* ----------------------------------*/

function sfjadminTool(url, target, imageFile)
{
	if(imageFile != '')
	{
		document.getElementById(target).innerHTML = '<br /><br /><img src="' + imageFile + '" /><br />';
	}
	ahahRequest(url, target);
}

function sfjadminMsg(target, imageFile, msg)
{
	var div = document.getElementById(target);
	if(imageFile != '')
	{
		div.innerHTML = '<br /><img src="' + imageFile + '" />&nbsp;&nbsp<b>' + msg + '</b><br />';
		div.style.display = "block";

	}
	return false;
}

function sfjshowSubsList(id, url, imageFile)
{
	var subForm = document.getElementById(id);
	var searchForm = document.getElementById('post-search-input');
	var delim;
	var thisValue;
	var showsubs;
	var showwatches;
	var filter;
	var groups="";
	var forums="";

	subForm.showsubs.checked ? thisValue='1' : thisValue='0';
	showsubs = "&showsubs=" + thisValue;

	subForm.showwatches.checked ? thisValue='1' : thisValue='0';
	showwatches = "&showwatches=" + thisValue;

	if(subForm.sffilterall.checked) filter="&filter=all";
	if(subForm.sffiltergroups.checked)
	{
		filter="&filter=groups";
		var groupIds = document.getElementById('grouplist');
		if(groupIds.value == '')
		{
			groups = "&groups=error";
		} else {
			var x = 0;
			for (i=0;i<groupIds.length;i++)
			{
				if (groupIds.options[i].selected)
				{
					if(x==0 ? delim="" : delim="-");
					groups += delim + groupIds.options[i].value;
					x++;
				}
			}
			if(groups != null)
			{
				groups = "&groups=" + groups;
			} else {
				groups = "&groups=error";
			}
		}
	}

	if(subForm.sffilterforums.checked)
	{
		filter="&filter=forums";
		var forumIds = document.getElementById('forumlist');
		if(forumIds.value == '')
		{
			forums = "&forums=error";
		} else {
			var x = 0;
			for (i=0;i<forumIds.length;i++)
			{
				if (forumIds.options[i].selected)
				{
					if(x==0 ? delim="" : delim="-");
					forums += delim + forumIds.options[i].value;
					x++;
				}
			}
			if(forums != null)
			{
				forums = "&forums=" + forums;
			} else {
				forums = "&forums=error";
			}
		}
	}

	var sText = '';
    if (searchForm)
    {
		sText = '&swsearch='+searchForm.form.elements['swsearch'].value;
	}

	urlGet = url + showsubs + showwatches + filter + groups + forums + encodeURI(sText);

	/* add random num to GET param to ensure its not cached */
	urlGet = urlGet + '&rnd=' +  new Date().getTime();


	if(imageFile != '')
	{
		document.getElementById('subsdisplayspot').innerHTML = '<br /><br /><img src="' + imageFile + '" /><br />';
	}
	jQuery('#subsdisplayspot').load(urlGet);
}

/* ----------------------------------*/
/* Admin Show Group Members          */
/* ----------------------------------*/

function sfjshowMemberList(url, imageFile, groupID)
{

	var memberList = document.getElementById('members-'+groupID);
	var target = 'members-'+groupID;

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	if(memberList.innerHTML == '')
	{
		if (imageFile != '')
		{
			document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
		} else {
			document.getElementById(target).innerHTML = '';
		}
		jQuery('#members-'+groupID).load(url);
	} else {
		document.getElementById(target).innerHTML = '';
	}
}

/* ----------------------------------*/
/* Admin Show Multi Select List */
/* ----------------------------------*/

function sfjUpdateMultiSelectList(url, uid)
{
	var target = 'mslist-'+uid;

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	ahahRequest(url, target);
}

function sfjFilterMultiSelectList(url, uid)
{
	var target = 'mslist-'+uid;

	filter = document.getElementById('list-filter'+uid);
	url = url + '&filter=' + filter.value;

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	ahahRequest(url, target);
}

function sfjTransferSelectList(from, to, msg)
{
	/* remove list empty message */
	jQuery('#'+to+' option[value="-1"]').remove();

	/* move the data from the from box to the to box */
	jQuery('#'+from+' option:selected').remove().appendTo('#'+to);

	/* if the from box is now empty, display message */
	if (!jQuery('#'+from+' option').length)
		jQuery('#'+from).append('<option value="-1">'+msg+'</option>');

	return false;
}

/* ----------------------------------*/
/* Admin Show Group List */
/* ----------------------------------*/

function sfjshowGroupList(url, imageFile)
{
	var target = 'selectgroup';
	sfjtoggleLayer('select-group');
	if(imageFile != '')
	{
		document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
	}

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	ahahRequest(url, target);
}

/* ----------------------------------*/
/* Admin Show Forum List */
/* ----------------------------------*/

function sfjshowForumList(url, imageFile)
{
	var target = 'selectforum';
	sfjtoggleLayer('select-forum');
	if(imageFile != '')
	{
		document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
	}

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	ahahRequest(url, target);
}

function sfjShowProfile(url, imageFile, rowid)
{
	var target = rowid;
	sfjtoggleLayer(rowid);
	if(imageFile != '')
	{
		document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
	}

	/* add random num to GET param to ensure its not cached */
	url = url + '&rnd=' +  new Date().getTime();

	ahahRequest(url, target);
}

function sfjDelPMs(url, imageFile, fade, rowid)
{
	var target = rowid;
	if (fade == 0)
	{
		if(imageFile != '')
		{
			document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
		}
	} else {
		var row = document.getElementById(target);
		if (navigator.appName == "Microsoft Internet Explorer")
		{
			sfjopacity(row.style,9,0,10,function(){sfjremoveIt(row);});
		} else {
			sfjopacity(row.style,199,0,10,function(){sfjhideIt(row);});
		}
	}

	ahahRequest(url, target);
}

function sfjDelRank(url, imageFile, fade, rowid)
{
	var target = rowid;
	if (fade == 0)
	{
		if(imageFile != '')
		{
			document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
		}
	} else {
		var row = document.getElementById(target);
		if (navigator.appName == "Microsoft Internet Explorer")
		{
			sfjopacity(row.style,9,0,10,function(){sfjremoveIt(row);});
		} else {
			sfjopacity(row.style,199,0,10,function(){sfjhideIt(row);});
		}
	}

	ahahRequest(url, target);
}

function sfjDelWatchesSubs(url, imageFile, fade, rowid)
{
	var target = rowid;

	if (fade == 0)
	{
		if(imageFile != '')
		{
			document.getElementById(target).innerHTML = '<img src="' + imageFile + '" />';
		}
	} else {
		var row = document.getElementById(target);
		if (navigator.appName == "Microsoft Internet Explorer")
		{
			sfjopacity(row.style,9,0,10,function(){sfjremoveIt(row);});
		} else {
			sfjopacity(row.style,199,0,10,function(){sfjhideIt(row);});
		}
	}

	ahahRequest(url, target);
}

function sfjDelCfield(url, imageFile, rowid)
{
	var target = rowid;

	var row = document.getElementById(target);
	if (navigator.appName == "Microsoft Internet Explorer")
	{
		sfjopacity(row.style,9,0,10,function(){sfjremoveIt(row);});
	} else {
		sfjopacity(row.style,199,0,10,function(){sfjhideIt(row);});
	}

	ahahRequest(url, target);
}

function sfjremoveIt(target)
{
	target.style.height="0px";
	target.style.borderStyle="none";
	target.style.display="none";
}

function sfjhideIt(target)
{
	target.style.visibility="collapse";
	target.style.borderStyle="none";
}

function sfjopacity(ss,s,e,m,f){
	if(s>e){
		s--;
	}else if(s<e){
		s++;
	}
	sfjsetOpacity(ss,s);
	if(s!=e){
		setTimeout(function(){sfjopacity(ss,s,e,m,f);},Math.round(m/10));
	}else if(s==e){
		if(typeof f=='function'){f();}
	}
}

function sfjsetOpacity(s,o){
	s.opacity=o/100;
	s.MozOpacity=o/100;
	s.KhtmlOpacity=o/100;
	s.filter='alpha(opacity='+o+')';
}

/* ----------------------------------*/
/* AHAH master routines              */
/* ----------------------------------*/

function ahahRequest(url,target) {
    if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
        req.onreadystatechange = function() {ahahResponse(target);};
        req.open("GET", url, true);
        req.send(null);
    } else if (window.ActiveXObject) {
        req = new ActiveXObject("Microsoft.XMLHTTP");
        if (req) {
            req.onreadystatechange = function() {ahahResponse(target);};
            req.open("GET", url, true);
            req.send();
        }
    }
}

function ahahResponse(target) {
   /* only if req is "loaded" */
   if (req.readyState == 4) {
       /* only if "OK" */
       if (req.status == 200 || req.status == 304) {
           results = req.responseText;
           document.getElementById(target).innerHTML = results;
       } else {
           document.getElementById(target).innerHTML="ahah error:\n" + req.status + ' ' + req.statusText;
       }
   }
}

/* ----------------------------------*/
/* Check/Uncheck box collection      */
/* ----------------------------------*/

function sfjcheckAll(container)
{
	jQuery(container).find('input[type=checkbox]:not(:checked)').each(function()
	{
		jQuery('label[for='+jQuery(this).attr('id')+']').trigger('click');
		if(jQuery.browser.msie)
		{
			jQuery(this).attr('checked','checked');
		}else{
			jQuery(this).trigger('click');
		};
	});
}


function sfjuncheckAll(container)
{
	jQuery(container).find('input[type=checkbox]:checked').each(function()
	{
		jQuery('label[for='+jQuery(this).attr('id')+']').trigger('click');
		if(jQuery.browser.msie)
		{
			jQuery(this).attr('checked','');
		}else{
			jQuery(this).trigger('click');
		};
	});
}

function sfjDelTbButton(button, message)
{
	if(confirm(message))
	{
		var remList = document.getElementById("delbuttons");
		var currentList = remList.value;

		if(currentList == "")
		{
			remList.value = button.id;
		} else {
			remList.value = currentList + "&" + button.id;
		}
		button.style.display = "none";
	}
}

function sfjSubmit(target)
{
	var submitField = document.getElementById(target);
	submitField.value = "update";
	document.forms[0].submit();
}

function sfjSetForumOptions(type)
{
	if(type == 'forum')
	{
		jQuery('#forumselect').hide();
		jQuery('#groupselect').show();
	} else {
		jQuery('#groupselect').hide();
		jQuery('#forumselect').show();
	}
}

function sfjSetForumSequence(action, type, id, url, target)
{
	url+='&type='+type+'&id='+id.value+'&action='+action;

	jQuery('#'+target).load(url, function(){
		jQuery("input.radiosequence").prettyCheckboxes();
	});

	jQuery('#block1').show('slow');
	jQuery('#block2').show('slow');
}

function sfjSetForumSlug(title, url, target, slugAction)
{
	url+='&action=slug&title='+escape(title.value)+'&slugaction='+slugAction;
	jQuery('#'+target).load(url, function(newslug) {
		document.getElementById(target).value = newslug;
		document.getElementById(target).disabled = false;
	});
}

this.vtip = function(vtipImage)
{
    this.xOffset = -10; /*  x distance from mouse */
    this.yOffset = 10; /* y distance from mouse */

    jQuery(".vtip").unbind().hover(
        function(e) {
            this.t = this.title;
            this.title = '';
            this.top = (e.pageY + yOffset); this.left = (e.pageX + xOffset);

            jQuery('body').append( '<p id="vtip"><img id="vtipArrow" />' + this.t + '</p>' );

            jQuery('p#vtip #vtipArrow').attr("src", vtipImage);
            jQuery('p#vtip').css("top", this.top+"px").css("left", this.left+"px").fadeIn("slow");

        },
        function() {
            this.title = this.t;
            jQuery("p#vtip").fadeOut("slow").remove();
        }
    ).mousemove(
        function(e) {
            this.top = (e.pageY + yOffset);
            this.left = (e.pageX + xOffset);

            jQuery("p#vtip").css("top", this.top+"px").css("left", this.left+"px");
        }
    );

};