
/* 

  ================================================
  PVII Glide Panel Magic scripts
  Copyright (c) 2008 Project Seven Development
  www.projectseven.com
  Version: version 1.7.4 build: 1-07
  ================================================
  
 */

var p7GP=false,p7GPMi=false,p7GPMctl=[],p7gpmA=navigator.userAgent.toLowerCase();
function P7_setGPM(){
	var i,h;
	if(!document.getElementById){
		return;
	}
	h='\n<st'+'yle type="text/css">\n';
	h+='.p7GPW {overflow:hidden;}\n';
	h+='.p7GPcontentwrapper {display:none}\n';
	h+='.p7GPsidebar {display:none}\n';
	for(i=1;i<21;i++){
		h+="#p7GPc"+i+"_1 {display:block;}\n";
	}
	h+='</s'+'tyle>';
	document.write(h);
}
P7_setGPM();

function P7_GPMaddLoad(){
	if(!document.getElementById){
		return;
	}
	if(window.addEventListener){
		window.addEventListener("load",P7_initGPM,false);
	}
	else if(window.attachEvent){
		window.attachEvent("onload",P7_initGPM);
	}
	else if(typeof window.onload=='function'){
		var p7vloadit=onload;
		window.onload=function(){
			p7vloadit();
			P7_initGPM();
		};
	}
	else{
		window.onload=P7_initGPM;
	}
	p7GPMi=true;
}
function P7_opGPM(){
	var h='',hh,b,cn,sD,d,tB,cTD,mD;
	if(!document.getElementById){
		return;
	}
	p7GPMctl[p7GPMctl.length]=arguments;
	if(!p7GPMi){
		P7_GPMaddLoad();
	}
}
function P7_initGPM(){
	var i,j,tB,dd,tD,tA,tg,cP,dh;
	for(i=0;i<p7GPMctl.length;i++){
		tB=document.getElementById(p7GPMctl[i][0]);
		if(tB){
			tB.p7opt=p7GPMctl[i];
			if(navigator.appVersion.indexOf("MSIE 5")>-1){
				tB.p7opt[2]=0;
			}
			dd=tB.id.replace("GP_","GPt_");
			tD=document.getElementById(tB.id.replace("GP_","GPt_"));
			if(tD){
				tA=tD.getElementsByTagName("A");
				tg='p7GPtrg';
				for(j=0;j<tA.length;j++){
					if(tA[j].id && tA[j].id.indexOf(tg)===0){
						tA[j].onclick=function(){
							return P7_GPMshow(this);
						};
						tA[j].p7state='closed';
						tA[j].p7GPMpr=tB.id;
						tA[j].p7GPMtr=tD.id;
						cP=document.getElementById(tA[j].id.replace("trg","c"));
						if(cP){
							tA[j].p7GPMc=cP.id;
						}
						else{
							tA[j].p7GPMc=false;
						}
					}
				}
				dh='p7GPtrg'+tA[0].id.slice(7,8)+'_'+tB.p7opt[1];
				P7_GPMtrig(dh);
				if(tB.p7opt[3]==1){
					P7_GPMmark(tB.id);
				}
			}
		}
	}
	P7_GPMurl();
	p7GP=true;
}
function P7_GPMtrig(tr){
	var tA=document.getElementById(tr);
	if(tA){
		P7_GPMshow(tA);
	}
}
function P7_GPMshow(a){
	var i,m=true,pD,tR,tA,ch,nh,vP,tP,th=-1,op,cd,wH;
	wH=window.location.href;
	if(!a.p7GPMc){
		a.className='p7GPcurrentmark';
		if(wH==a.href){
			return false;
		}
		else{
			return true;
		}
	}
	pD=document.getElementById(a.p7GPMpr);
	tR=document.getElementById(a.p7GPMtr);
	vP=document.getElementById(a.p7GPMtr.replace("t","w"));
	if(pD.p7opt[4]==1&&p7GP){
		window.location.hash="#gpm"+a.id.substring(7);
	}
	tA=tR.getElementsByTagName("A");
	if(pD.p7opt[2]>0){
		if(vP.p7gpmG){
			clearTimeout(vP.p7gpmG);
		}
	}
	ch=vP.offsetHeight;
	vP.style.height=ch+"px";
	for(i=0;i<tA.length;i++){
		if(tA[i].p7GPMtr){
			if(tA[i].p7GPMc){
				tP=document.getElementById(tA[i].p7GPMc);
			}
			if(tA[i]==a){
				tA[i].className="down";
				tA[i].p7state="open";
				if(tA[i].p7GPMc){
					m=false;
					tP.style.visiblity="hidden";
					tP.style.display="block";
					if(pD.p7opt[2]==3&&p7GP){
						op=0.05;
						cd=tP.id;
						if((navigator.appVersion.indexOf("MSIE")>-1)){
							tP.style.zoom="100%";
							tP.style.filter='alpha(opacity='+op*100+')';
						}
						else{
							tP.style.opacity=op;
						}
					}
					tP.style.visiblity="visible";
					if (pD.p7opt[5] == 1){
						P7_GPMside(a,tP);
					}
					if(pD.p7opt[2]>0&&p7GP){
						th=tP.offsetHeight;
					}
					else{
						vP.style.height="auto";
					}
				}
			}
			else{
				if(tA[i].p7GPMc){
					tA[i].className='';
					tA[i].p7state="closed";
					tP.style.display="none";
				}
			}
		}
	}
	if(th>-1){
		if(pD.p7opt[2]==3&&p7GP){
			vP.style.height="auto";
			P7_GPMfadeIn(cd,0.10);
		}
		else{
			P7_GPMglide(vP.id,ch,th,pD.p7opt[2]);
		}
	}
	return m;
}
function P7_GPMside(a,d){
	var i,tD,sb,tS;
	tD=d.getElementsByTagName("DIV");
	if(tD&&tD.length>0){
		for(i=0;i<tD.length;i++){
			if(tD[i].className&&tD[i].className=='p7GPsidebar'){
				sb=a.p7GPMpr.replace("p7GP","p7GPsb");
				tS=document.getElementById(sb);
				if(tS){
					tS.innerHTML=tD[i].innerHTML;
				}
				break;
			}
		}
	}
}
function P7_GPMph(d){
	var h,nh,dh,oh;
	d.style.height="auto";
	oh=d.offsetHeight;
	d.style.height=oh+"px";
	nh=d.offsetHeight;
	if(oh!=nh){
		nh=(oh-(nh-oh));
	}
	d.style.height="auto";
	return nh;
}
function P7_GPMglide(dd,ch,th,p){
	var w,m,d,wd,wC,tt,dy=10,inc=10,pc=0.15;
	d=document.getElementById(dd);
	m=(ch<=th)?0:1;
	if(p==2){
		tt=Math.abs( parseInt( Math.abs(th)-Math.abs(ch),10 ) );
		inc=(tt*pc<1)?1:tt*pc;
	}
	inc=(m==1)?inc*-1:inc;
	d.style.height=ch+"px";
	if(ch==th){
		d.style.height="auto";
	}
	else{
		ch+=inc;
		if(m===0){
			ch=(ch>=th)?th:ch;
		}
		else{
			ch=(ch<=th)?th:ch;
		}
		d.p7gpmG=setTimeout("P7_GPMglide('"+dd+"',"+ch+","+th+","+p+")",dy);
	}
}
function P7_GPMfadeIn(id,op){
	var im,dy=30,lm=0.99,inc,d=document.getElementById(id);
	inc=(window.opera)?0.15:0.10;
	op=(op>=lm)?lm:op;
	if((navigator.appVersion.indexOf("MSIE")>-1)){
		d.style.filter='alpha(opacity='+op*100+')';
	}
	else{
		d.style.opacity=op;
	}
	if(op<lm){
		op+=inc;
		d.p7ssmfade=setTimeout("P7_GPMfadeIn('"+id+"',"+op+")",dy);
	}
	else{
		if(d.style.filter){
			d.style.removeAttribute("filter");
		}
	}
}
function P7_GPMmark(dD){
	var i,wH,tB,tA,hH;
	wH=window.location.href;
	hH=window.location.hash;
	if(hH=="#"||hH.indexOf("#gpm")===0){
		wH=wH.replace(hH,'');
	}
	tB=document.getElementById(dD);
	if(tB){
		if(tB){
			tA=tB.getElementsByTagName("A");
			for(i=0;i<tA.length;i++){
				if(tA[i].p7GPMtr){
					if(tA[i].href==wH){
						if(tA[i].p7GPMc){
							P7_GPMshow(tA[i]);
						}
						else{
							tA[i].className='p7GPcurrentmark';
						}
						break;
					}
				}
			}
		}
	}
}
function P7_GPMurl(){
	var i,h,s,x,d='gpm';
	if(document.getElementById){
		h=document.location.search;
		if(h){
			h=h.replace('?','');
			s=h.split(/[=&]/g);
			if(s&&s.length){
				for(i=0;i<s.length;i+=2){
					if(s[i]==d){
						x=s[i+1];
						if(x){
							P7_GPMtrig('p7GPtrg'+x);
						}
					}
				}
			}
		}
		h=document.location.hash;
		if(h){
			x=h.substring(1,h.length);
			if(x && x.indexOf("gpm")===0){
				P7_GPMtrig('p7GPtrg'+x.substring(3));
			}
		}
	}
}
