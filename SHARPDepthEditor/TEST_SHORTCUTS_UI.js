const fs=require('fs'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync(__dirname+'/editor.html','utf8'),handlers={};
const context2d=new Proxy({}, {get:(o,k)=>k==='getImageData'?()=>({data:new Uint8ClampedArray(4)}):()=>{}});
function element(value=''){return {value,focus(){},style:{},appendChild(){},addEventListener(){},clientWidth:1102,clientHeight:650,scrollLeft:0,scrollTop:0,getContext:()=>context2d,setPointerCapture(){},getBoundingClientRect:()=>({left:0,top:0,width:1102,height:650})}}
const el={canvas:element(),tool:element('exclude-brush'),radius:element('5'),zoom:element('1'),viewport:element(),brushCursor:element(),status:element(),result:element()};
el.canvas.width=1100;el.canvas.height=800;
el.canvas.getBoundingClientRect=()=>{let width=parseFloat(el.canvas.style.width)||1100;return {left:-el.viewport.scrollLeft,top:-el.viewport.scrollTop,width,height:width*800/1100}};
for(const [id,value] of Object.entries({shapeMode:'uniform',feather:'0',imageView:'photo',depthNote:'',displayMode:'overlay',overlayColor:'#00ff6e',overlayStrength:'0.8',pulse:'',editName:'Sky',editRole:'background',amount:'-0.15',draftStatus:'',saveEdit:'',undoSelection:'',redoSelection:'',sizeSlider:'0',sizeNumber:'0'}))el[id]=element(value);
let frame=null;
const sandbox={console,Uint8ClampedArray,Math,Number,Date,Promise,Image:class{},alert(){},setInterval(){},requestAnimationFrame:fn=>{frame=fn;return 1},cancelAnimationFrame:()=>{frame=null},window:{addEventListener:(name,fn)=>handlers[name]=fn},document:{getElementById:id=>el[id],createElement:()=>element(),querySelectorAll:()=>[],querySelector:()=>({})}};
vm.createContext(sandbox);vm.runInContext(html.split('<script>')[1].split('</script>')[0],sandbox);

function event(code,key,target={tagName:'BODY'}){return {code,key,target,preventDefault(){this.prevented=true}}}
const posted=[];
sandbox.fetch=async(url,options)=>{posted.push(JSON.parse(options.body));return {json:async()=>({ok:true})}};
sandbox.confirm=()=>true;
(async()=>{
vm.runInContext('hover=[100,100];points=[[100,100,"bg"],[300,100,"fg"]];rect=[0,0,500,400];mask={};selected=true',sandbox);
const right=event('BracketRight',']');right.metaKey=true;handlers.keydown(right);
assert.equal(el.radius.value,'6');assert(right.prevented);
const left=event('BracketLeft','[');left.metaKey=true;handlers.keydown(left);assert.equal(el.radius.value,'5');
for(let i=0;i<110;i++)handlers.keydown(left);assert.equal(el.radius.value,'1');
for(let i=0;i<110;i++)handlers.keydown(right);assert.equal(el.radius.value,'100');
const input=event('BracketLeft','[',{tagName:'INPUT'});input.metaKey=true;handlers.keydown(input);assert.equal(el.radius.value,'100');
assert.equal(vm.runInContext('hoveredSample()',sandbox),0);
handlers.keydown(event('Backspace','Backspace'));
await new Promise(resolve=>setImmediate(resolve));
assert.equal(vm.runInContext('points.length',sandbox),1);
assert.equal(posted.length,1);assert.equal(posted[0].points[0][0],300);
assert.equal(vm.runInContext('selected',sandbox),false);
sandbox.confirm=()=>false;vm.runInContext('hover=[300,100]',sandbox);
handlers.keydown(event('Delete','Delete'));await new Promise(resolve=>setImmediate(resolve));
assert.equal(vm.runInContext('points.length',sandbox),1);assert.equal(posted.length,1);
vm.runInContext('hover=[600,600]',sandbox);
assert.equal(vm.runInContext('hoveredSample()',sandbox),-1);
const plain=event('BracketLeft','[');handlers.keydown(plain);assert.equal(el.radius.value,'99');
handlers.keydown(event('Space',' '));assert.equal(el.canvas.style.cursor,'grab');
el.viewport.scrollLeft=40;el.viewport.scrollTop=60;el.canvas.onpointerdown({clientX:100,clientY:100,pointerId:1,preventDefault(){}});el.canvas.onpointermove({clientX:80,clientY:70});assert.equal(el.viewport.scrollLeft,60);assert.equal(el.viewport.scrollTop,90);assert.equal(vm.runInContext('stroke',sandbox),null);handlers.keyup(event('Space',' '));assert.equal(vm.runInContext('pan',sandbox),null);
console.log('PASS: plain brackets and Space-pan;  Command-bracket resize/repeat/bounds, input safety, nearest dot deletion, persistence, cancel.');
})().catch(e=>{console.error(e);process.exitCode=1});
