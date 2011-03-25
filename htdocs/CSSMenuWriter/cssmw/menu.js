/*-----------------------------------------------------------------------------
-  Description:
-
-  This file contains proprietary and confidential information from WebAssist.com
-  corporation.  Any unauthorized reuse, reproduction, or modification without
-  the prior written consent of WebAssist.com is strictly prohibited.
-
-  Copyright 2009 WebAssist.com Corporation.  All rights reserved.
------------------------------------------------------------------------------*/
var cssmw = {
	select_current: 0, // 1 = whole cascade, 2 = just child, 3 = just main level
	orientation: 0, // 0 = v1, 1 = horizontal, 2 = vertical
	main_ul: null,
	stopClear: false,
	hoverLI: false,
	focusLI: false,
	stopBlur: false,
	browser: {
		isIE6: false,
		isIE7: false,
		isSafari: false
	},
	
	intializeMenu: function(id,opts) {
		if (!opts) opts = {};
		var params = {
			select_current : ( opts.select_current || 0 ),
			orientation : ( opts.orientation || 0 )
		}
		//initialize variables
		var ul = document.getElementById(id);
		this.select_current = params.select_current;
		this.orientation = params.orientation;
		this.main_ul = ul;
		this.browser.isIE6 = (navigator.appName == 'Microsoft Internet Explorer' && this.ieVersion() < 7);
		this.browser.isIE7 = (navigator.appName == 'Microsoft Internet Explorer' && this.ieVersion() == 7);
		this.browser.isLteIE7 = (this.browser.isIE6 || this.browser.isIE7);
		this.browser.isSafari = (navigator.appName == "Netscape" && navigator.userAgent.indexOf("Safari") >= 0);
		
		if (this.orientation != 2) { //not done in V1 vertical include
			//set top of uls for IE 7-
			if (this.browser.isLteIE7) {
				var topOffset = ul.offsetHeight;  
				var lis = ul.childNodes;
				for(var i = 0; i < lis.length; i++) {
					if(lis[i].tagName && lis[i].tagName.toLowerCase() == 'li') {
						var uls = lis[i].childNodes;
						for(var j = 0; j < uls.length; j++) {
							if(uls[j].tagName && uls[j].tagName.toLowerCase() == 'ul') {
								uls[j].style.top = topOffset + 'px';
							}
						}
					}
				}  
			}
		}
	
		//set mouseover and mouseout for IE 6-
		var lis = this.localGetElementsByTagName(this.main_ul, 'li');
		for(var i=0; i<lis.length; i++) {
			var li = lis[i];
			this.setLIAndChildNodes(li, "hover", "link");
			if(this.browser.isIE6) {
				var uls = li.getElementsByTagName('ul');
				for(var u=0; u<uls.length; u++){
					uls[u].style.display = 'none';
				}
				li.onmouseover = this.ie6_li_mouseOver;
				li.onmouseout = this.ie6_li_mouseOut;
			}
			else {
				li.onmouseover = this.li_mouseOver;
				li.onmouseout = this.li_mouseOut;
			}
		}
		
		// for accessibility - set onfocus and onblur events
		if (ul && ul.childNodes && ul.childNodes.length) {
			for (var i=0; i<ul.childNodes.length; i++) {
				var parentLi = ul.childNodes[i];
				var aTags = this.localGetElementsByTagName(parentLi, 'a');
				for (var a=0; a<aTags.length; a++) {
					if (aTags[a] && aTags[a].href) {
						var li = aTags[a].parentNode;
						if (li) {
							while (li.tagName.toUpperCase() != "LI") {
								//set spans to hover state
								//li.className = 'hover';
								li = li.parentNode;
								if (li == ul) {
									li = false;
									break;
								}
							}
							if (li) {
								aTags[a].onfocus = this.a_focus;
								aTags[a].onblur = this.a_blur;
								aTags[a].onclick = this.a_click;
								// set up onkeypress events as well if orientation is known
								if (this.orientation) {
									aTags[a].onkeypress = this.a_onkeypress;
									aTags[a].onkeyup = this.a_onkeyup;
								}
							}
						}
					}
				}
			}
		}
		
				
		
		//highlight proper selection
		if (this.select_current) {
			if (ul && ul.childNodes && ul.childNodes.length) {
				for (var i=0; i<ul.childNodes.length; i++) {
					var parentLi = ul.childNodes[i];
					var aTags = this.localGetElementsByTagName(parentLi, 'a');
					for (var a=0; a<aTags.length; a++) {
						if (aTags[a] && aTags[a].href) {
							var li = aTags[a].parentNode;
							if (li) {
								while (li.tagName.toUpperCase() != "LI") {
									//set spans to hover state
									li.className = 'hover';
									li = li.parentNode;
									if (li == ul) {
										li = false;
										break;
									}
								}
								if (li) {
									if (this.shouldHighlightPage(li)) {
										this.setLiToCurrent(li);
									}
								}
							}
						}
					}
				}
			}
		}
		this.main_ul = ul;
	}, //end initialization
	
	
	//methods used by events
	ie6_li_mouseOver: function(e) {
		cssmw.clearHoverLIs();
		cssmw.setHovFocLI(this, "hoverLI");
		var doBlur = (cssmw.focusLI && true);
		cssmw.clearFocusLIs();
		if (doBlur) {
			cssmw.blurFocus();
			cssmw.clearFocus();
		}
		cssmw.setLIAndChildNodes(this, "link", "hover");
		var ul = this.getElementsByTagName('ul')[0];
		if(ul) ul.style.display = 'block';
	},
	
	ie6_li_mouseOut: function(e) {
		cssmw.clearHoverLIs();
		var ul = this.getElementsByTagName('ul')[0];
		cssmw.setLIAndChildNodes(this, "hover", "link");
		if(ul) ul.style.display = 'none';
	},
	
	
	li_mouseOver: function(e) {
		cssmw.clearHoverLIs();
		cssmw.setHovFocLI(this, "hoverLI");
		var doBlur = (cssmw.focusLI && true);
		cssmw.clearFocusLIs();
		if (doBlur) {
			cssmw.blurFocus();
			cssmw.clearFocus();
		}
	},
	
	li_mouseOut: function(e) {
		cssmw.clearHoverLIs();
	},
	
	a_focus: function(e) {
		var li = this.parentNode;
		while (li && li.tagName.toLowerCase() != "li") {
			li = li.parentNode;
		}
		if (!li) return;
		cssmw.clearFocusLIs();
		cssmw.setHovFocLI(li, "focusLI");
		cssmw.setLIAndChildNodes(li, "link", "hover");
		if (cssmw.browser.isIE6) {
			var ul = cssmw.localGetElementsByTagName(li, 'ul')[0];
			if(ul) ul.style.display = 'block';
		}
	},
	
	a_click: function(e) {
		cssmw.clearFocusLIs();
		cssmw.clearFocus();
	},
	
	a_blur: function(e) {
		if (cssmw.stopBlur) {
			return;
		}
		if (cssmw.focusLI) {
			cssmw.remHovFocLI(cssmw.focusLI, "focusLI");
		}
		setTimeout("cssmw.clearFocus();", 1);
	},
	
	a_onkeypress: function(e) {
		//do nothing on key down, only on key up
	},
	
	a_onkeyup: function(e) {
		if (!cssmw.orientation) return;
		var key = 0;
		if (window.event) {
			key = window.event.keyCode;
		}
		else if (e.keyCode) {
			key = e.keyCode;
		}
		cssmw.doKeyPress(key, this);
	},
	
	//methods for main object
	doKeyPress: function(key, presentA) {
		var li = presentA.parentNode;
		while (li && li.parentNode && li.tagName.toLowerCase() != "li") {
			li = li.parentNode;
		}
		if (!li || li.tagName.toLowerCase() != "li") return;
		var level = 0;
		var ul = li.parentNode;
		if (!ul) return;
		if (ul.className) {
			var tLevel = String(ul.className).match(/level-(\d*)/);
			if (tLevel) {
				level = parseInt(tLevel[1]);
				if (isNaN(level)) level = 0;
			}
		}
		var liToSelect = false;
		switch (key) {
			case 37: //left key
				//move left in top level of horizontal list, nothing for vertical
				if (level == 0 && this.orientation == 1) {
					liToSelect = this.browseGetSibling(ul, li, -1);
				}
				else if ((level == 1 && this.orientation != 1) || // do nothing if first sub level of horizontal
					(level > 1)) {  //otherwise move out of sub-level for all
					liToSelect = this.browseGetParent(ul);
				}
				break;
			case 38: //up key
				//do nothing in a top-level horizontal
				if (level == 0 && this.orientation == 1) {
					return;
				}
				liToSelect = this.browseGetSibling(ul, li, -1);
				if (!liToSelect && level == 1 && this.orientation == 1) {
					//top level of first sub of a horizontal menu, move out

					liToSelect = this.browseGetParent(ul);
				}
				break;
			case 39: //right key
				//move right in top level of horizontal list
				if (level == 0 && this.orientation == 1) {
					liToSelect = this.browseGetSibling(ul, li, 1);
				}
				else {
					//enter child list if it exists
					liToSelect = this.browseGetChild(li);
				}
				break;
			case 40: //down key
				//move into child in top level of horizontal list
				if (level == 0 && this.orientation == 1) {
					liToSelect = this.browseGetChild(li);
				}
				else {
					//move down anywhere else
					liToSelect = this.browseGetSibling(ul, li, 1);
				}
				break;
		}
		if (liToSelect) {
			var aTags = this.localGetElementsByTagName(liToSelect, "A");
			if (aTags.length) {
				aTags[0].focus(); 
			}
		}
	},
	
	browseGetParent: function(presentLI) {
		var parentLI = presentLI.parentNode;
		while (parentLI && parentLI.parentNode && parentLI.tagName.toLowerCase() != "li") {
			parentLI = parentLI.parentNode;
		}
		if (parentLI && parentLI.tagName.toLowerCase() == "li") return parentLI;
		return false;
	},
	
	browseGetChild: function(presentLI) {
		var tULs = this.localGetElementsByTagName(presentLI, "ul");
		if (tULs.length && tULs[0].childNodes && tULs[0].childNodes.length) {
			return this.localGetElementsByTagName(tULs[0], "li")[0];
		}
		return false;
	},
	
	browseGetSibling: function(presentUL, presentLI, plusMinus) {
		var tLIs = this.localGetElementsByTagName(presentUL, "li");
		var childLIs = [];
		for (var n=0; n<tLIs.length; n++) {
			if (tLIs[n].parentNode == presentUL) {
				childLIs.push(tLIs[n]);
			}
		}
		for (var n=0; n<childLIs.length; n++) {
			if (childLIs[n] == presentLI) {
				if (n+plusMinus >= 0 && n+plusMinus != childLIs.length) {
					return childLIs[n+plusMinus];
				}
				break;
			}
		}
		return false;
	},
	
	
	clearHoverLIs: function() {
		this.clearHovFocLIs("hoverLI");
	},
	clearFocusLIs: function() {
		this.clearHovFocLIs("focusLI");
	},
	clearHovFocLIs: function(toClear) {
		var myLIs = this.localGetElementsByTagName(this.main_ul, "li");
		for (var n=0; n<myLIs.length; n++) {
			this.remHovFocLI(myLIs[n], toClear);
		}
	},
	isHovFocLI: function(tLI, toFind) {
		var ie6find = "ie6" + toFind.toLowerCase();
		return (tLI && (tLI.getAttribute(toFind) || (this.browser.isIE6 && this.hasClassName(tLI, ie6find))));
	},
	setHovFocLI: function(tLI, toSet) {
		var ie6find = "ie6" + toSet.toLowerCase();
		switch (toSet) {
			case "hoverLI":
				this.hoverLI = tLI;
				break;
			case "focusLI":
				this.focusLI = tLI;
				break;
		}
		if (tLI && !this.isHovFocLI(tLI, toSet)) {
			if (this.browser.isIE6) {
				this.addClassName(tLI, ie6find);
			}
			else {
				tLI.setAttribute(toSet, toSet);
			}
		}
	},
	remHovFocLI: function(tLI, toRem) {
		var ie6find = "ie6" + toRem.toLowerCase();
		if (!tLI) {
			switch (toRem) {
				case "hoverLI":
					tLI = this.hoverLI;
					break;
				case "focusLI":
					tLI = this.focusLI;
					break;
			}
		}
		if (tLI) {
			if (this.browser.isIE6) {
				this.remClassName(tLI, ie6find);
			}
			else {
				tLI.removeAttribute(toRem);
			}
			switch (toRem) {
				case "hoverLI":
					this.hoverLI = false;
					break;
				case "focusLI":
					this.focusLI = false;
					break;
			}
		}
	},
	
	blurFocus: function() {
		if (this.focusLI) {
			var tATags = this.localGetElementsByTagName(this.focusLI, "a");
			if (tATags && tATags.length) {
				this.stopBlur = true;
				tATags[0].blur();
				this.stopBlur = false;
			}
			this.remHovFocLI(false, "focusLI");
		}
	},
	
	liChildOfLI: function(tNeedle, tHaystack, toFind) {
		if (tNeedle == tHaystack || this.isHovFocLI(tHaystack, toFind)) {
			return true;
		}
		var myLIs = this.localGetElementsByTagName(tHaystack, "li");
		if (myLIs && myLIs.length) {
			for (var m=0; m<myLIs.length; m++) {
				if (tNeedle == myLIs[m] || this.isHovFocLI(myLIs[m], toFind)) {
					return true;
				}
			}
		}
		return false;
	},
	
	clearFocus: function() {
		if (this.stopClear) {
			this.stopClear = false;
			return;
		}
		var liTags = this.localGetElementsByTagName(this.main_ul, "li");
		for (var n=0; n<liTags.length; n++) {
			var myState = "link";
			if (this.focusLI && this.liChildOfLI(this.focusLI, liTags[n], "focusLI")) {
				myState = "hover";
			}
			if (this.browser.isIE6) {
				if (myState == "link" && this.hoverLI && this.liChildOfLI(this.hoverLI, liTags[n], "hoverLI")) {
					myState = "hover";
				}
				if (myState == "link") {
					var myUL = liTags[n].parentNode;
					var ulTags = this.localGetElementsByTagName(liTags[n], "ul");
					if (ulTags.length) {
						for (var m=0; m<ulTags.length; m++) {
							ulTags[m].style.display = "none";
						}
					}
				}
				//if (myUL && myUL != this.main_ul && (!myUL.style || (!myUL.style.display || myUL.style.display != 'none'))) {
					//myUL.style.display = "none";
				//}
			}
			switch (myState) {
				case "link":
					this.setLIAndChildNodes(liTags[n], "hover", "link");
					break;
				case "hover":
					this.setLIAndChildNodes(liTags[n], "link", "hover");
					break;
			}
		}
	},
	
	setLIAndChildNodes: function(tLI, toRem, toAdd) {
		this.remClassName(tLI, toRem, toAdd);
		var tChild = tLI.childNodes[0];
		while (tChild && tChild.tagName) {
			if (tChild.tagName.toLowerCase() == "a" || tChild.tagName.toLowerCase() == "span") {
				this.remClassName(tChild, toRem, toAdd);
			}
			if (!tChild.childNodes || !tChild.childNodes.length) {
				break;
			}
			tChild = tChild.childNodes[0];
		}
	},
	
	localGetElementsByTagName: function(tNode, tagName) {
		if (tNode.getElementsByTagName) return tNode.getElementsByTagName(tagName);
		var retArr = [];
		var myChildren = tNode.childNodes;
		if (myChildren && myChildren.length) {
			for (var n=0; n<myChildren.length; n++) {
				if (myChildren[n].tagName && myChildren[n].tagName.toUpperCase() == tagName.toUpperCase()) {
					retArr.push(myChildren[n]);
				}
				if (myChildren[n].childNodes && myChildren[n].childNodes.length) {
					if (tNode.localGetElementsByTagName) {
						var childRet = tNode.localGetElementsByTagName(myChildren[n], tagName);
					}
					else {
						var childRet = this.localGetElementsByTagName(myChildren[n], tagName);
					}
					if (childRet.length) {
						for (var c=0; c<childRet.length; c++) {
							retArr.push(childRet[c]);
						}
					}
				}
			}
		}
		return retArr;
	},
		
	ieVersion: function() {
		var ua = navigator.userAgent.toLowerCase();
		var offset = ua.indexOf("msie ");  
		return (offset == -1) ? 0 : parseFloat(ua.substring(offset + 5, ua.indexOf(";", offset)));
	},
	
	shouldHighlightPage: function(liNode) {
		switch (this.select_current) {
			case 1:
				if (liNode.getElementsByTagName) {
					var locATags = liNode.getElementsByTagName('a');
				}
				else {
					var locATags = this.localGetElementsByTagName(liNode, 'a');
				}
				for (var n=0; n<locATags.length; n++) {
					if (locATags[n].href && this.testPageLocation(locATags[n].href)) {
						return true;
					}
				}
				break;
			case 2:
				if (liNode.getElementsByTagName) {
					var locATags = liNode.getElementsByTagName('a');
				}
				else {
					var locATags = this.localGetElementsByTagName(liNode, 'a');
				}
				if (locATags.length && locATags[0].href && this.testPageLocation(locATags[0].href)) {
					return true;
				}
				break;
			case 3:
				if (liNode.parentNode && liNode.parentNode.tagName.toUpperCase() == "UL") {
					return (liNode.parentNode.className && liNode.parentNode.className == "level-0");
				}
				break;
		}
		return false;
	},
	
	testPageLocation: function(testLoc) {
		if (!this.select_current || !testLoc) return false;
		var hrefString = document.location.href ? document.location.href : document.location;
		if (hrefString.indexOf("://") >= 0) {
			hrefString = hrefString.substring(hrefString.indexOf("://") + 3);
			if (hrefString.charAt(0) == "/") {
				hrefString = hrefString.substring(1);
			}
			hrefString = hrefString.substring(hrefString.indexOf("/"));
		}
		if (testLoc.indexOf("://") >= 0) {
			testLoc = testLoc.substring(testLoc.indexOf("://") + 3);
			if (testLoc.charAt(0) == "/") {
				testLoc = testLoc.substring(1);
			}
			testLoc = testLoc.substring(testLoc.indexOf("/"));
		}
		var hrefFolder = hrefString.substring(0, hrefString.lastIndexOf("/") + 1);
		var testFolder = testLoc.substring(0, testLoc.lastIndexOf("/") + 1);
		if (hrefFolder.toLowerCase() != testFolder.toLowerCase()) return false; // folder must match
		var hrefPage = hrefString.substring(hrefFolder.length);
		var testPage = testLoc.substring(testFolder.length);
		var hrefURLVars = "";
		var testURLVars = "";
		if (hrefPage.indexOf("?") >= 0) {
			hrefURLVars = hrefPage.substring(hrefPage.indexOf("?") + 1);
			hrefPage = hrefPage.substring(0, hrefPage.indexOf("?"));
		}
		if (testPage.indexOf("?") >= 0) {
			testURLVars = testPage.substring(testPage.indexOf("?") + 1);
			testPage = testPage.substring(0, testPage.indexOf("?"));
		}
		if (testPage == "#") testPage = hrefPage;
		if (hrefPage.toLowerCase() != testPage.toLowerCase()) return false; // file name must match
		var tVarArr = testURLVars.split("&");
		var hrefURLVars = "&" + hrefURLVars + "&";
		//all url vars in the link must be in the page url
		for (var n=0; n<tVarArr.length; n++) {
			if (hrefURLVars.indexOf("&" + tVarArr[n] + "&") < 0) {
				return false;
			}
		}
		return true;
	},
	
	setLiToCurrent: function(tNode) {
		var spans = this.localGetElementsByTagName(tNode, 'span');
		var span = (spans.length) ? spans[0] : false;
		var atags = this.localGetElementsByTagName(tNode, 'a');
		var a = (atags.length) ? atags[0] : false;
		this.addClassName(tNode, "current");
		if(span) {
			this.addClassName(span, "current");
			if (span.childNodes && span.childNodes.length) {
				var span2 = span.childNodes[0];
				if (span2 && span2.tagName && span2.tagName.toLowerCase() == "span") {
					this.addClassName(span2, "current");
				}
			}
		}
		if(a) {
			this.addClassName(a, "current");
		}
	},
	
	getClassExpressions: function(toFind) {
		return [new RegExp("^" + toFind + "\\s", "g"),
				new RegExp("\\s" + toFind + "\\b", "g"),
				new RegExp("^" + toFind + "$", "g")];
	},
	
	hasClassName: function(tElm, toFind) {
		var tClassName = String(tElm.className);
		if (tClassName == "undefined") tClassName = "";
		if (tClassName.indexOf(toFind) < 0) {
			return false;
		}
		var tPattnArr = this.getClassExpressions(toFind);
		var tIndex = -1;
		for (var n=0; n<tPattnArr.length; n++) {
			tIndex = tClassName.search(tPattnArr[n]);
			if (tIndex >= 0) {
				return true;
			}
		}
		return false;
	},
	
	addClassName: function(tElm, toAdd) {
		if (!this.hasClassName(tElm, toAdd)) {
			var tClassName = String(tElm.className);
			if (tClassName == "undefined") tClassName = "";
			tClassName += ( (tClassName != "") ? " " : "" ) + toAdd;
			tElm.className = tClassName;
		}
	},
	
	remClassName: function(tElm, toRem, toAdd) {
		if (this.hasClassName(tElm, toRem)) {
			var tClassName = String(tElm.className);
			if (tClassName == "undefined") tClassName = "";
			var remPattns = this.getClassExpressions(toRem);
			for (var n=0; n<remPattns.length; n++) {
				tClassName = tClassName.replace(remPattns[n], "");
			}
			tElm.className = tClassName;
		}
		if (toRem == "hover") {
			toAdd = "link";
		}
		if (toAdd) {
			this.addClassName(tElm, toAdd);
		}
	}
}
