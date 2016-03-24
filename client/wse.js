'use strict'
// workspace explorer
this.WSE=function($e,ide){
  var pending=this.pending={}
  this.$e=$e
    .jstree({plugins:[],core:{animation:true,check_callback:true,data:function(x,f){
      var i=x.id==='#'?0:+x.id.replace(/\D+/g,'');pending[i]=f.bind(this);ide.emit('TreeList',{nodeId:i})
    }}})
    .on('click','.jstree-anchor',function(){
      ide.emit('Edit',{win:0,pos:0,text:$e.jstree('get_path',this,'.')})
      ;/^wse-leaf-/.test(this.id)||$e.jstree('refresh_node',this)
    })
}
this.WSE.prototype={
  replyTreeList:function(x){
    var f=this.pending[x.nodeId];if(!f)return
    f((x.nodeIds||[]).map(function(c,i){return{text:x.names[i],children:!!c,id:'wse-'+(c||('leaf-'+x.nodeId+'-'+i))}}))
    delete this.pending[x.nodeId]
  },
  refresh:function(){this.$e.jstree('refresh')}
}
