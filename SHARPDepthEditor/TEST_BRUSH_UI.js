// Headless event/state regression tests; macOS visual operation still needs testing.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const html=fs.readFileSync(__dirname+'/editor.html','utf8');
const context2d=new Proxy({}, {get:(o,k)=>k==='getImageData'?()=>({data:new Uint8ClampedArray(4)}):()=>{}});
function element(value=''){return {value,focus(){},appendChild(){},style:{},addEventListener(){},clientWidth:1102,clientHeight:650,getContext:()=>context2d,setPointerCapture(){},getBoundingClientRect:()=>({left:0,top:0,width:4400,height:3200})}}
const elements={canvas:element(),tool:element('exclude-brush'),radius:element('5'),zoom:element('4'),viewport:element(),brushCursor:element(),status:element(),result:element()};
elements.canvas.width=1100;elements.canvas.height=800;
for(const [id,value] of Object.entries({shapeMode:'uniform',feather:'0',imageView:'photo',depthNote:'',displayMode:'overlay',overlayColor:'#00ff6e',overlayStrength:'0.8',pulse:'',editName:'Sky',editRole:'background',amount:'-0.15',draftStatus:'',saveEdit:'',undoSelection:'',redoSelection:'',sizeSlider:'0',sizeNumber:'0'}))elements[id]=element(value);
const alerts=[];
const sandbox={console,Uint8ClampedArray,Math,Number,Date,Promise,Image:class{},alert:s=>alerts.push(s),requestAnimationFrame(){return 1},cancelAnimationFrame(){},setInterval(){},window:{addEventListener(){}},document:{getElementById:id=>elements[id],createElement:()=>element(),querySelectorAll:()=>[],querySelector:()=>({})}};
vm.createContext(sandbox);
vm.runInContext(html.split('<script>')[1].split('</script>')[0],sandbox);
vm.runInContext("mask={};selected=false;canvas.onpointerdown({clientX:100,clientY:100,pointerId:1})",sandbox);
assert.equal(alerts.length,0,'Visible mask must allow brush despite pending automatic changes');
assert.equal(vm.runInContext('stroke.radius',sandbox),5);
vm.runInContext('canvas.onpointermove({clientX:120,clientY:130})',sandbox);
assert.equal(elements.brushCursor.style.width,'40px'); // diameter 10 * scale 4
assert.equal(elements.brushCursor.style.left,'120px');
elements.radius.value='10';vm.runInContext('updateBrushCursor()',sandbox);
assert.equal(elements.brushCursor.style.width,'80px');
elements.tool.value='exclude-rectangle';vm.runInContext('updateBrushCursor()',sandbox);
assert.equal(elements.brushCursor.style.display,'none');
assert.equal(elements.canvas.style.cursor,'crosshair');
elements.tool.value='exclude-brush';
vm.runInContext('start=null;stroke=null;mask=null;canvas.onpointerdown({clientX:100,clientY:100,pointerId:1})',sandbox);
assert.equal(alerts.length,1);assert(alerts[0].includes('above the image'));
assert.equal((html.match(/>Find Selection<\/button>/g)||[]).length,1);
console.log('PASS: visible-mask brush gating, radius/zoom cursor footprint, tool switching, clear no-mask guidance.');
