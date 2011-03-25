/**
 * DWUser.com XML Flash Slideshow v4: SWF embed script
 * Version 4.0.0
 *
 * This software is (c) 2009 DWUser.com
 * http://www.dwuser.com/ 
 */

XMLFlashSlideshow_v4 = function(p)
{
	var level = (p.level && p.level == 'b') ? 'b' : 'a'; var k=1;
	if (p.fixPaths && p.fixPaths == 'false'){// do nothing about detecting/fixing paths
	} else {
		var scriptSearchStr = 'v4flashslideshow/slideshow.js';
		var scriptList = document.getElementsByTagName('script');
		for (var i=0; i<scriptList.length; i++)
		{
			var src = scriptList[i].src;
			if (src && src.indexOf(scriptSearchStr) == (src.length - (scriptSearchStr).length))
			{
				// found the path to the supporting files
				var path = src.substr(0, src.length - ('slideshow.js').length);
				//alert('found path: ' + path);
				p.swf = path + 'slideshow_v4' + level + '.swf';
				break;
			}
		}
	}
	if (!p.swf) { alert('XFS v4: No SWF path specified, and auto-path detection disabled.  Slideshow cannot be created.'); return; };
	p.swf = p.swf.replace(/slideshow_v4.?\.swf$/i, 'slideshow_v4' + level + '.swf');
	if (p.id && p.id.length > 0){ 
		var contentHolder = document.getElementById(p.id);
		var id = p.id; 
	} else {
		var id = 'xfs_v4_' + (new Date().getTime()) + '_' + String(Math.random()).split('.').join('_');
		var contentHolder = XMLFlashSlideshow_v4_findContentHolder(); 
		contentHolder.id = id;
	}
	XMLFlashSlideshow_v4_ssIDRef = id;
	try{
	//maybe needed in future (or escape flashvar values)???  if (p.initXML) p.initXML = p.initXML.split('"').join('&quot;');
	var version = (level == 'a') ? '9.0.28' : '10.0.0'; k++; // may bump up to 9.0.124 in future...
	var expressInstallSwfurl = p.swf.replace(/(.*\/?)slideshow_v4.\.swf/i, '$1expressInstall.swf');
	if (p.detectionVersion) version = p.detectionVersion;
	if (p.noDetection) version = '0';
	if (p.redirect && p.redirect.length > 0 && !swfobject.hasFlashPlayerVersion(version)) { document.location = p.redirect; return; }
	var bgcolor = (p.backgroundColor && p.backgroundColor.length == 7) ? p.backgroundColor : '#FFFFFF';
	var params = {wmode:'transparent', allowscriptaccess:'always', allowfullscreen:'true', bgcolor:bgcolor};
	var flashvars = {embedID:id, nodeHolder:'div'+k};
	var attributes = {styleClass:'dwuser_xfs_v4_noOutline'};
	if (navigator.appVersion.indexOf("MSIE")!=-1 && (p.isIE == undefined || p.isIE != 'false') ) {
		flashvars['isIE'] = 'true';
	}
	for (var j in p) { //add all the rest
		if (j.indexOf('_param_') == 0)
			params[j.substr(7)] = p[j];
		else
			flashvars[j] = XMLFlashSlideshow_v4_escapePlus(p[j]);
	}
	swfobject.embedSWF(p.swf, id, p.width, p.height, version, expressInstallSwfurl, flashvars, params, attributes);
	}catch(e){}
	// permalink support - e.g. mypage.html?xfs4_gid=myGallery - added 8-25-09
	if (XMLFlashSlideshow_v4_gup('xfs4_gid') != '' || XMLFlashSlideshow_v4_gup('xfs4_iid') != '')
	{
		setTimeout('XMLFlashSlideshow_v4_enablePermalink();', 20);
	}
	// prevent border in ff3 - added 10-19-09
	try
	{
		var createCSS = function(selector, declaration) {
			var ua = navigator.userAgent.toLowerCase();
			var isIE = (/msie/.test(ua)) && !(/opera/.test(ua)) && (/win/.test(ua));
			var style_node = document.createElement("style");
			style_node.setAttribute("type", "text/css");
			style_node.setAttribute("media", "screen"); 
			if (!isIE) style_node.appendChild(document.createTextNode(selector + " {" + declaration + "}"));
			document.getElementsByTagName("head")[0].appendChild(style_node);
			// use alternative methods for IE
			if (isIE && document.styleSheets && document.styleSheets.length > 0) {
				var last_style_node = document.styleSheets[document.styleSheets.length - 1];
				if (typeof(last_style_node.addRule) == "object") last_style_node.addRule(selector, declaration);
			}
		};
		createCSS('.dwuser_xfs_v4_noOutline', 'outline: none;');
	}catch(e) {/*css error*/}
}

XMLFlashSlideshow_v4_enablePermalink = function()
{
	if (typeof(window['XMLFlashSlideshow_v4_getInitialImage']) == 'undefined')
	{
		var gid = XMLFlashSlideshow_v4_gup('xfs4_gid');
		var iid = XMLFlashSlideshow_v4_gup('xfs4_iid');
		var theID = (gid != '') ? gid : iid;
		XMLFlashSlideshow_v4_getInitialImage = function()
		{
			return unescape(theID);
		}
	}
}
XMLFlashSlideshow_v4_gup = function ( name )
{
	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS = "[\\?&]"+name+"=([^&#]*)";
	var regex = new RegExp( regexS );
	var results = regex.exec( window.location.href );
	if( results == null )
		return "";
	else
		return results[1];
}
XMLFlashSlideshow_v4_findContentHolder = function()
{ 
	var id = "temp" + Math.floor(Math.random()*100000); 
	document.write('<span style="display:none;" id="' + id + '"></span>'); 
	var r = document.getElementById(id); // .previousSibling; 
	for (var i=0; i<10; i++)
	{
		r = r.previousSibling;
		if (r && r.nodeName.toLowerCase() == 'div' && r.className == 'dwuser_xfs_v4_holder')
		{
			return r;
		}
	}
	//var c = 0; 
	return r; //.previousSibling.previousSibling; 
} 
XMLFlashSlideshow_v4_escapePlus = function(s)
{
	//s = s.split('%').join('%25'); // (no longer necessary)
	if (encodeURIComponent) 
		s = encodeURIComponent(s);
	else
		s = escape(s);
	return s;
}

// The SlideshowInterface pass-through callers
var XMLFlashSlideshow_v4_ssIDRef;
XMLFlashSlideshow_v4_setImage = function(uniqid)
{
	if (XMLFlashSlideshow_v4_ssIDRef)
	{
		try	{
			swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_setImage(uniqid);
		} catch (e)	{ alert('Unable to make XMLFlashSlideshow_v4_setImage call.  An error occurred: ' + e);	}
	} else { alert('Unable to make XMLFlashSlideshow_v4_setImage call.  An error occurred: No slideshow reference available.'); }
}
XMLFlashSlideshow_v4_requestGallery = function(uniqid)
{
	if (XMLFlashSlideshow_v4_ssIDRef)
	{
		try {
			swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_requestGallery(uniqid);
		} catch (e) { alert('Unable to make XMLFlashSlideshow_v4_requestGallery call.  An error occurred: ' + e); }
	} else { alert('Unable to make XMLFlashSlideshow_v4_requestGallery call.  An error occurred: No slideshow reference available.'); }
}
XMLFlashSlideshow_v4_setLayoutView = function(viewid)
{
	if (XMLFlashSlideshow_v4_ssIDRef)
	{
		try {
			swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_setLayoutView(viewid);
		} catch (e) { alert('Unable to make XMLFlashSlideshow_v4_setLayoutView call.  An error occurred: ' + e); }
	} else { alert('Unable to make XMLFlashSlideshow_v4_setLayoutView call.  An error occurred: No slideshow reference available.'); }
}
XMLFlashSlideshow_v4_popup = function(url,name,options)
{
	var w = window.open(url,name,options);
	if (!w)
	{
		var swfSuccess = true;
		if (XMLFlashSlideshow_v4_ssIDRef)
		{
			try {
				var resp = swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_newWindowPopup(url);
				if (resp == 'fail') swfSuccess = false;
			} catch (e) { swfSuccess = false; /*alert('Unable to make XMLFlashSlideshow_v4_popup call.  An error occurred: ' + e);*/ }
		} else { swfSuccess = false; /*alert('Unable to make XMLFlashSlideshow_v4_popup call.  An error occurred: No slideshow reference available.');*/ }
		if (!swfSuccess)
		{
			var isSafari = false; var isWin = false;
			try { if (navigator.vendor.indexOf('Apple') != -1) isSafari=true; } catch (e){}
			try { if (navigator.platform.indexOf('Win') != -1) isWin=true; } catch (e){}
			var msg = 'Please temporarily disable your popup blocker.';
			if (isSafari && isWin) msg = 'Please temporarily disable your popup blocker.  You can do this with CTRL + SHIFT + K.';
			if (isSafari && !isWin) msg = 'Please temporarily disable your popup blocker.  You can do this with the "Safari" > "Block Pop-Up Windows" menu option.';
			alert(msg);
		}
	}
	return false;
}
XMLFlashSlideshow_v4_getXML = function()
{
	if (XMLFlashSlideshow_v4_ssIDRef)
	{
		try {
			return swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_getXML();
		} catch (e) { alert('Unable to make XMLFlashSlideshow_v4_getXML call.  An error occurred: ' + e); }
	} else { alert('Unable to make XMLFlashSlideshow_v4_getXML call.  An error occurred: No slideshow reference available.'); }
	return null;
}
XMLFlashSlideshow_v4_setPlaying = function(playing)
{
	if (XMLFlashSlideshow_v4_ssIDRef)
	{
		try	{
			swfobject.getObjectById(XMLFlashSlideshow_v4_ssIDRef).XMLFlashSlideshow_v4_setPlaying(playing);
		} catch (e)	{ alert('Unable to make XMLFlashSlideshow_v4_setPlaying call.  An error occurred: ' + e);	}
	} else { alert('Unable to make XMLFlashSlideshow_v4_setPlaying call.  An error occurred: No slideshow reference available.'); }
}


/*	SWFObject v2.2 <http://code.google.com/p/swfobject/> 
	is released under the MIT License <http://www.opensource.org/licenses/mit-license.php> 
*/
var swfobject=function(){var D="undefined",r="object",S="Shockwave Flash",W="ShockwaveFlash.ShockwaveFlash",q="application/x-shockwave-flash",R="SWFObjectExprInst",x="onreadystatechange",O=window,j=document,t=navigator,T=false,U=[h],o=[],N=[],I=[],l,Q,E,B,J=false,a=false,n,G,m=true,M=function(){var aa=typeof j.getElementById!=D&&typeof j.getElementsByTagName!=D&&typeof j.createElement!=D,ah=t.userAgent.toLowerCase(),Y=t.platform.toLowerCase(),ae=Y?/win/.test(Y):/win/.test(ah),ac=Y?/mac/.test(Y):/mac/.test(ah),af=/webkit/.test(ah)?parseFloat(ah.replace(/^.*webkit\/(\d+(\.\d+)?).*$/,"$1")):false,X=!+"\v1",ag=[0,0,0],ab=null;if(typeof t.plugins!=D&&typeof t.plugins[S]==r){ab=t.plugins[S].description;if(ab&&!(typeof t.mimeTypes!=D&&t.mimeTypes[q]&&!t.mimeTypes[q].enabledPlugin)){T=true;X=false;ab=ab.replace(/^.*\s+(\S+\s+\S+$)/,"$1");ag[0]=parseInt(ab.replace(/^(.*)\..*$/,"$1"),10);ag[1]=parseInt(ab.replace(/^.*\.(.*)\s.*$/,"$1"),10);ag[2]=/[a-zA-Z]/.test(ab)?parseInt(ab.replace(/^.*[a-zA-Z]+(.*)$/,"$1"),10):0}}else{if(typeof O.ActiveXObject!=D){try{var ad=new ActiveXObject(W);if(ad){ab=ad.GetVariable("$version");if(ab){X=true;ab=ab.split(" ")[1].split(",");ag=[parseInt(ab[0],10),parseInt(ab[1],10),parseInt(ab[2],10)]}}}catch(Z){}}}return{w3:aa,pv:ag,wk:af,ie:X,win:ae,mac:ac}}(),k=function(){if(!M.w3){return}if((typeof j.readyState!=D&&j.readyState=="complete")||(typeof j.readyState==D&&(j.getElementsByTagName("body")[0]||j.body))){f()}if(!J){if(typeof j.addEventListener!=D){j.addEventListener("DOMContentLoaded",f,false)}if(M.ie&&M.win){j.attachEvent(x,function(){if(j.readyState=="complete"){j.detachEvent(x,arguments.callee);f()}});if(O==top){(function(){if(J){return}try{j.documentElement.doScroll("left")}catch(X){setTimeout(arguments.callee,0);return}f()})()}}if(M.wk){(function(){if(J){return}if(!/loaded|complete/.test(j.readyState)){setTimeout(arguments.callee,0);return}f()})()}s(f)}}();function f(){if(J){return}try{var Z=j.getElementsByTagName("body")[0].appendChild(C("span"));Z.parentNode.removeChild(Z)}catch(aa){return}J=true;var X=U.length;for(var Y=0;Y<X;Y++){U[Y]()}}function K(X){if(J){X()}else{U[U.length]=X}}function s(Y){if(typeof O.addEventListener!=D){O.addEventListener("load",Y,false)}else{if(typeof j.addEventListener!=D){j.addEventListener("load",Y,false)}else{if(typeof O.attachEvent!=D){i(O,"onload",Y)}else{if(typeof O.onload=="function"){var X=O.onload;O.onload=function(){X();Y()}}else{O.onload=Y}}}}}function h(){if(T){V()}else{H()}}function V(){var X=j.getElementsByTagName("body")[0];var aa=C(r);aa.setAttribute("type",q);var Z=X.appendChild(aa);if(Z){var Y=0;(function(){if(typeof Z.GetVariable!=D){var ab=Z.GetVariable("$version");if(ab){ab=ab.split(" ")[1].split(",");M.pv=[parseInt(ab[0],10),parseInt(ab[1],10),parseInt(ab[2],10)]}}else{if(Y<10){Y++;setTimeout(arguments.callee,10);return}}X.removeChild(aa);Z=null;H()})()}else{H()}}function H(){var ag=o.length;if(ag>0){for(var af=0;af<ag;af++){var Y=o[af].id;var ab=o[af].callbackFn;var aa={success:false,id:Y};if(M.pv[0]>0){var ae=c(Y);if(ae){if(F(o[af].swfVersion)&&!(M.wk&&M.wk<312)){w(Y,true);if(ab){aa.success=true;aa.ref=z(Y);ab(aa)}}else{if(o[af].expressInstall&&A()){var ai={};ai.data=o[af].expressInstall;ai.width=ae.getAttribute("width")||"0";ai.height=ae.getAttribute("height")||"0";if(ae.getAttribute("class")){ai.styleclass=ae.getAttribute("class")}if(ae.getAttribute("align")){ai.align=ae.getAttribute("align")}var ah={};var X=ae.getElementsByTagName("param");var ac=X.length;for(var ad=0;ad<ac;ad++){if(X[ad].getAttribute("name").toLowerCase()!="movie"){ah[X[ad].getAttribute("name")]=X[ad].getAttribute("value")}}P(ai,ah,Y,ab)}else{p(ae);if(ab){ab(aa)}}}}}else{w(Y,true);if(ab){var Z=z(Y);if(Z&&typeof Z.SetVariable!=D){aa.success=true;aa.ref=Z}ab(aa)}}}}}function z(aa){var X=null;var Y=c(aa);if(Y&&Y.nodeName=="OBJECT"){if(typeof Y.SetVariable!=D){X=Y}else{var Z=Y.getElementsByTagName(r)[0];if(Z){X=Z}}}return X}function A(){return !a&&F("6.0.65")&&(M.win||M.mac)&&!(M.wk&&M.wk<312)}function P(aa,ab,X,Z){a=true;E=Z||null;B={success:false,id:X};var ae=c(X);if(ae){if(ae.nodeName=="OBJECT"){l=g(ae);Q=null}else{l=ae;Q=X}aa.id=R;if(typeof aa.width==D||(!/%$/.test(aa.width)&&parseInt(aa.width,10)<310)){aa.width="310"}if(typeof aa.height==D||(!/%$/.test(aa.height)&&parseInt(aa.height,10)<137)){aa.height="137"}j.title=j.title.slice(0,47)+" - Flash Player Installation";var ad=M.ie&&M.win?"ActiveX":"PlugIn",ac="MMredirectURL="+O.location.toString().replace(/&/g,"%26")+"&MMplayerType="+ad+"&MMdoctitle="+j.title;if(typeof ab.flashvars!=D){ab.flashvars+="&"+ac}else{ab.flashvars=ac}if(M.ie&&M.win&&ae.readyState!=4){var Y=C("div");X+="SWFObjectNew";Y.setAttribute("id",X);ae.parentNode.insertBefore(Y,ae);ae.style.display="none";(function(){if(ae.readyState==4){ae.parentNode.removeChild(ae)}else{setTimeout(arguments.callee,10)}})()}u(aa,ab,X)}}function p(Y){if(M.ie&&M.win&&Y.readyState!=4){var X=C("div");Y.parentNode.insertBefore(X,Y);X.parentNode.replaceChild(g(Y),X);Y.style.display="none";(function(){if(Y.readyState==4){Y.parentNode.removeChild(Y)}else{setTimeout(arguments.callee,10)}})()}else{Y.parentNode.replaceChild(g(Y),Y)}}function g(ab){var aa=C("div");if(M.win&&M.ie){aa.innerHTML=ab.innerHTML}else{var Y=ab.getElementsByTagName(r)[0];if(Y){var ad=Y.childNodes;if(ad){var X=ad.length;for(var Z=0;Z<X;Z++){if(!(ad[Z].nodeType==1&&ad[Z].nodeName=="PARAM")&&!(ad[Z].nodeType==8)){aa.appendChild(ad[Z].cloneNode(true))}}}}}return aa}function u(ai,ag,Y){var X,aa=c(Y);if(M.wk&&M.wk<312){return X}if(aa){if(typeof ai.id==D){ai.id=Y}if(M.ie&&M.win){var ah="";for(var ae in ai){if(ai[ae]!=Object.prototype[ae]){if(ae.toLowerCase()=="data"){ag.movie=ai[ae]}else{if(ae.toLowerCase()=="styleclass"){ah+=' class="'+ai[ae]+'"'}else{if(ae.toLowerCase()!="classid"){ah+=" "+ae+'="'+ai[ae]+'"'}}}}}var af="";for(var ad in ag){if(ag[ad]!=Object.prototype[ad]){af+='<param name="'+ad+'" value="'+ag[ad]+'" />'}}aa.outerHTML='<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"'+ah+">"+af+"</object>";N[N.length]=ai.id;X=c(ai.id)}else{var Z=C(r);Z.setAttribute("type",q);for(var ac in ai){if(ai[ac]!=Object.prototype[ac]){if(ac.toLowerCase()=="styleclass"){Z.setAttribute("class",ai[ac])}else{if(ac.toLowerCase()!="classid"){Z.setAttribute(ac,ai[ac])}}}}for(var ab in ag){if(ag[ab]!=Object.prototype[ab]&&ab.toLowerCase()!="movie"){e(Z,ab,ag[ab])}}aa.parentNode.replaceChild(Z,aa);X=Z}}return X}function e(Z,X,Y){var aa=C("param");aa.setAttribute("name",X);aa.setAttribute("value",Y);Z.appendChild(aa)}function y(Y){var X=c(Y);if(X&&X.nodeName=="OBJECT"){if(M.ie&&M.win){X.style.display="none";(function(){if(X.readyState==4){b(Y)}else{setTimeout(arguments.callee,10)}})()}else{X.parentNode.removeChild(X)}}}function b(Z){var Y=c(Z);if(Y){for(var X in Y){if(typeof Y[X]=="function"){Y[X]=null}}Y.parentNode.removeChild(Y)}}function c(Z){var X=null;try{X=j.getElementById(Z)}catch(Y){}return X}function C(X){return j.createElement(X)}function i(Z,X,Y){Z.attachEvent(X,Y);I[I.length]=[Z,X,Y]}function F(Z){var Y=M.pv,X=Z.split(".");X[0]=parseInt(X[0],10);X[1]=parseInt(X[1],10)||0;X[2]=parseInt(X[2],10)||0;return(Y[0]>X[0]||(Y[0]==X[0]&&Y[1]>X[1])||(Y[0]==X[0]&&Y[1]==X[1]&&Y[2]>=X[2]))?true:false}function v(ac,Y,ad,ab){if(M.ie&&M.mac){return}var aa=j.getElementsByTagName("head")[0];if(!aa){return}var X=(ad&&typeof ad=="string")?ad:"screen";if(ab){n=null;G=null}if(!n||G!=X){var Z=C("style");Z.setAttribute("type","text/css");Z.setAttribute("media",X);n=aa.appendChild(Z);if(M.ie&&M.win&&typeof j.styleSheets!=D&&j.styleSheets.length>0){n=j.styleSheets[j.styleSheets.length-1]}G=X}if(M.ie&&M.win){if(n&&typeof n.addRule==r){n.addRule(ac,Y)}}else{if(n&&typeof j.createTextNode!=D){n.appendChild(j.createTextNode(ac+" {"+Y+"}"))}}}function w(Z,X){if(!m){return}var Y=X?"visible":"hidden";if(J&&c(Z)){c(Z).style.visibility=Y}else{v("#"+Z,"visibility:"+Y)}}function L(Y){var Z=/[\\\"<>\.;]/;var X=Z.exec(Y)!=null;return X&&typeof encodeURIComponent!=D?encodeURIComponent(Y):Y}var d=function(){if(M.ie&&M.win){window.attachEvent("onunload",function(){var ac=I.length;for(var ab=0;ab<ac;ab++){I[ab][0].detachEvent(I[ab][1],I[ab][2])}var Z=N.length;for(var aa=0;aa<Z;aa++){y(N[aa])}for(var Y in M){M[Y]=null}M=null;for(var X in swfobject){swfobject[X]=null}swfobject=null})}}();return{registerObject:function(ab,X,aa,Z){if(M.w3&&ab&&X){var Y={};Y.id=ab;Y.swfVersion=X;Y.expressInstall=aa;Y.callbackFn=Z;o[o.length]=Y;w(ab,false)}else{if(Z){Z({success:false,id:ab})}}},getObjectById:function(X){if(M.w3){return z(X)}},embedSWF:function(ab,ah,ae,ag,Y,aa,Z,ad,af,ac){var X={success:false,id:ah};if(M.w3&&!(M.wk&&M.wk<312)&&ab&&ah&&ae&&ag&&Y){w(ah,false);K(function(){ae+="";ag+="";var aj={};if(af&&typeof af===r){for(var al in af){aj[al]=af[al]}}aj.data=ab;aj.width=ae;aj.height=ag;var am={};if(ad&&typeof ad===r){for(var ak in ad){am[ak]=ad[ak]}}if(Z&&typeof Z===r){for(var ai in Z){if(typeof am.flashvars!=D){am.flashvars+="&"+ai+"="+Z[ai]}else{am.flashvars=ai+"="+Z[ai]}}}if(F(Y)){var an=u(aj,am,ah);if(aj.id==ah){w(ah,true)}X.success=true;X.ref=an}else{if(aa&&A()){aj.data=aa;P(aj,am,ah,ac);return}else{w(ah,true)}}if(ac){ac(X)}})}else{if(ac){ac(X)}}},switchOffAutoHideShow:function(){m=false},ua:M,getFlashPlayerVersion:function(){return{major:M.pv[0],minor:M.pv[1],release:M.pv[2]}},hasFlashPlayerVersion:F,createSWF:function(Z,Y,X){if(M.w3){return u(Z,Y,X)}else{return undefined}},showExpressInstall:function(Z,aa,X,Y){if(M.w3&&A()){P(Z,aa,X,Y)}},removeSWF:function(X){if(M.w3){y(X)}},createCSS:function(aa,Z,Y,X){if(M.w3){v(aa,Z,Y,X)}},addDomLoadEvent:K,addLoadEvent:s,getQueryParamValue:function(aa){var Z=j.location.search||j.location.hash;if(Z){if(/\?/.test(Z)){Z=Z.split("?")[1]}if(aa==null){return L(Z)}var Y=Z.split("&");for(var X=0;X<Y.length;X++){if(Y[X].substring(0,Y[X].indexOf("="))==aa){return L(Y[X].substring((Y[X].indexOf("=")+1)))}}}return""},expressInstallCallback:function(){if(a){var X=c(R);if(X&&l){X.parentNode.replaceChild(l,X);if(Q){w(Q,true);if(M.ie&&M.win){l.style.display="block"}}if(E){E(B)}}a=false}}}}();