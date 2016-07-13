;(function(){'use strict'
//This file implements the Preferences dialog.
//The contents of individual tabs are in separate files: prf_*.js
//Each of them can export the following properties:
//  name       tab title
//  id         a string used to construct DOM ids, CSS classes, etc
//  init()     called only once, before Preferences is opened for the first time
//  load()     called every time Preferences is opened
//  validate() should return a falsey value on success or a {msg,el} object on failure
//  save()     called when OK or Apply is pressed
//  resize()   called when the Preferences dialog is resized or the tab is selected
//  activate() called when the tab is selected ("activated")
//All tabs' validate() methods are invoked, if they exist, before any attempt to call save()
var tabs=D.prf_tabs={} //tab implementations self-register here

var d //DOM element for dialog, lazily initialized
function ok(){apply()&&cancel()}
function apply(){ //returns 0 on failure and 1 on success
  var v
  for(var i in tabs)if(v=tabs[i].validate&&tabs[i].validate()){
    setTimeout(function(){$.err(v.msg,v.el?function(){v.el.focus()}:null)},1)
    return 0
  }
  for(var i in tabs)tabs[i].save()
  return 1
}
function cancel(){d.hidden=1;D.ide.wins[0].focus()}
D.prf_ui=function(){
  if(!d){
    d=document.getElementById('prf_dlg')
    d.onkeydown=function(x){if(x.which===13&&!x.shiftKey&&x.ctrlKey&&!x.altKey&&!x.metaKey){ok();return!1}
                            if(x.which===27&&!x.shiftKey&&!x.ctrlKey&&!x.altKey&&!x.metaKey){cancel();return!1}}
//    onresize=function(){for(var i in tabs)tabs[i].resize&&tabs[i].resize()}
    document.getElementById('prf_dlg_ok'    ).onclick=function(){ok()    ;return!1}
    document.getElementById('prf_dlg_apply' ).onclick=function(){apply() ;return!1}
    document.getElementById('prf_dlg_cancel').onclick=function(){cancel();return!1}
    var nav=document.getElementById('prf_nav'),hdrs=nav.children,payloads=[]
    nav.onclick=function(x){return!1}
    nav.onmousedown=function(x){
      var a=x.target;if(a.nodeName!=='A')return!1
      for(var i=0;i<hdrs.length;i++){var b=a===hdrs[i];payloads[i].hidden=!b;hdrs[i].className=b?'sel':''}
      var t=tabs[a.href.replace(/.*#/,'')];t.resize&&t.resize();t.activate&&t.activate()
      x.preventDefault();return!1
    }
    for(var i=0;i<hdrs.length;i++){var id=hdrs[i].href.replace(/.*#/,''),e=document.getElementById(id)
                                   tabs[id].init(e);payloads.push(e)}
  }
  D.util.dlg(d,{w:600,h:450});for(var i in tabs)tabs[i].load()
  var t=tabs[(((document.getElementById('prf_nav').querySelector('.sel')||{}).href)||'').replace(/.*#/,'')]
  t&&t.activate&&t.activate()
}

}())
