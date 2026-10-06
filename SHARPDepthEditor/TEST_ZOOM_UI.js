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
vm.runInContext('setZoomAt(2,[250,180])',sandbox);
let b=el.canvas.getBoundingClientRect();
assert(Math.abs(b.left+250/1100*b.width-250)<1e-6);
assert(Math.abs(b.top+180/800*b.height-180)<1e-6);
assert.equal(el.zoom.value,'2');
function event(code,key,target={tagName:'BODY'}){return {code,key,target,preventDefault(){this.prevented=true}}}
handlers.keydown(event('Equal','='));assert.equal(el.zoom.value,'2');
handlers.keydown(event('KeyZ','z',{tagName:'INPUT'}));handlers.keydown(event('Equal','='));assert.equal(el.zoom.value,'2');
handlers.keydown(event('KeyZ','z'));handlers.keydown(event('Equal','='));assert(Math.abs(Number(el.zoom.value)-2.24)<1e-6);
frame(0);for(let t=16;t<=160;t+=16)frame(t);assert(Number(el.zoom.value)>2.24);
handlers.keyup(event('Equal','='));assert.equal(frame,null);
handlers.keydown(event('Minus','-'));assert(frame);handlers.keyup(event('KeyZ','z'));assert.equal(frame,null);
vm.runInContext('setZoomAt(100,[250,180])',sandbox);assert.equal(el.zoom.value,'32');
vm.runInContext('setZoomAt(.1,[250,180])',sandbox);assert.equal(el.zoom.value,'1');
handlers.keydown(event('KeyZ','z'));handlers.keydown(event('NumpadAdd','+'));handlers.blur();assert.equal(frame,null);
console.log('PASS: pointer anchor, tap/continuous zoom, key release/blur stop, input protection, numpad keys, limits.');
// Real scroll boundaries: when image is narrower than viewport, scroll clamps
// at zero. The original chosen image point must survive that phase.
let scrollX=0,scrollY=0;
Object.defineProperty(el.viewport,'scrollLeft',{get:()=>scrollX,set:v=>{scrollX=Math.max(0,Math.min(Math.max(0,el.canvas.getBoundingClientRect().width-el.viewport.clientWidth),v))}});
Object.defineProperty(el.viewport,'scrollTop',{get:()=>scrollY,set:v=>{scrollY=Math.max(0,Math.min(Math.max(0,el.canvas.getBoundingClientRect().height-el.viewport.clientHeight),v))}});
vm.runInContext('fitImage()',sandbox);
b=el.canvas.getBoundingClientRect();assert(b.width<=el.viewport.clientWidth&&b.height<=el.viewport.clientHeight);
let chosenX=b.width*.9,chosenY=40;
el.canvas.focus=()=>{sandbox.document.activeElement=el.canvas};sandbox.document.activeElement=el.zoom;
el.canvas.onpointermove({clientX:chosenX,clientY:chosenY});
assert.equal(sandbox.document.activeElement,el.canvas,'Hover must remove stale dropdown focus');
vm.runInContext('setZoomAt(1.12,zoomAnchor)',sandbox);
assert.equal(el.viewport.scrollLeft,0);
assert(Math.abs(vm.runInContext('zoomTarget.u',sandbox)-.9)<1e-6);
vm.runInContext('setZoomAt(1.25,zoomAnchor);setZoomAt(4,zoomAnchor)',sandbox);
b=el.canvas.getBoundingClientRect();
assert(Math.abs(b.left+.9*b.width-chosenX)<1e-6,'Chosen upper-right target drifted after zero-scroll phase');
handlers.keydown(event('KeyZ','z'));handlers.keydown(event('Digit0','0'));
assert.equal(el.zoom.value,'1');assert.equal(el.viewport.scrollLeft,0);assert.equal(el.viewport.scrollTop,0);
handlers.keyup(event('KeyZ','z'));
console.log('PASS: real scroll clamping, preserved right-side target, hover focus, whole-image Fit, Z+0.');
