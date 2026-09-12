/* UIU Dock store: seed + LocalStorage + a11y + validation helpers */
const DB_KEY='uiu_dock_v1';
function loadDB(){
  try{const raw=localStorage.getItem(DB_KEY);if(raw){const d=JSON.parse(raw);migrateDB(d);localStorage.setItem(DB_KEY,JSON.stringify(d));return d;}}catch(e){}
  const db={courses:window.SEED_COURSES,resources:window.SEED_RESOURCES.map((r,i)=>({...r,id:i+1,status:'approved'})),rooms:window.SEED_ROOMS.map((r,i)=>({...r,id:i+1})),msgs:window.SEED_MSGS,user:null,rated:{},reports:seedReports(),suspended:[]};
  migrateDB(db);
  localStorage.setItem(DB_KEY,JSON.stringify(db));return db;
}
/* Backfill newer collections + stable message ids on old saves */
let __mid=1000;
function migrateDB(d){
  d.rated=d.rated||{};
  if(!Array.isArray(d.accounts))d.accounts=[];
  /* Adopt a pre-existing signed-in name as a registered account */
  if(d.user&&d.user.role==='student'&&!d.accounts.some(a=>a.name.toLowerCase()===String(d.user.name).toLowerCase()))
    d.accounts.push({name:d.user.name,sid:'',created:'demo'});
  if(!Array.isArray(d.reports))d.reports=seedReports();
  if(!Array.isArray(d.suspended))d.suspended=[];
  if(!d.muted||typeof d.muted!=='object')d.muted={};
  if(!Array.isArray(d.audit))d.audit=seedAudit();
  Object.keys(d.msgs||{}).forEach(c=>{(d.msgs[c]||[]).forEach(m=>{if(m.id==null)m.id='m'+(__mid++);});});
  return d;
}
function seedReports(){
  return [
    {id:'r1',kind:'resource',refId:3,label:'Past Questions Summer 2024-25',by:'Student',reason:'Possible outdated syllabus version',status:'open',at:'Today 10:31 AM'},
    {id:'r2',kind:'message',refId:null,course:'CSE 222',label:'Peer: “check pinned resources”',by:'Student',reason:'Looks like spam',status:'open',at:'Today 10:44 AM'}
  ];
}
function seedAudit(){
  return [
    {at:'Today 09:12 AM',by:'Administrator',action:'Approved resource',target:'SQL JOIN Practice Sheet (CSE 222)'},
    {at:'Today 09:40 AM',by:'Administrator',action:'Removed message',target:'CSE 221 chat'},
    {at:'Today 10:02 AM',by:'Administrator',action:'Resolved report',target:'Past Questions Summer 2024-25'},
    {at:'Today 10:20 AM',by:'Administrator',action:'Suspended user',target:'spam_bot_01'}
  ];
}
function logAudit(action,target){
  try{const db=getDB();const me=db.user?db.user.name:'Administrator';
  db.audit.unshift({at:new Date().toLocaleString([],{month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}),by:me,action,target:target||''});
  db.audit=db.audit.slice(0,100);saveDB(db);}catch(e){}
}
/* Trust: 100 minus 25 per open flag, floor 5 */
function trustOf(name){
  try{const db=getDB();const flags=db.reports.filter(r=>r.status==='open'&&(r.by===name||(r.label||'').indexOf(name)>-1)).length;
  const against=db.reports.filter(r=>r.status==='open'&&((r.label||'').toLowerCase().indexOf(String(name).toLowerCase().split(':')[0])>-1)).length;
  return Math.max(5,100-25*Math.max(flags,against));}catch(e){return 100;}
}
function isMuted(name){
  try{const db=getDB();const until=db.muted[name];if(!until)return 0;
  if(until<Date.now()){delete db.muted[name];saveDB(db);return 0;}return until;}catch(e){return 0;}
}
function muteUser(name,days){
  const db=getDB();db.muted[name]=Date.now()+(days||7)*864e5;saveDB(db);
  logAudit('Muted user ('+(days||7)+' days)',name);
}
function fileReport(kind,info){
  const db=getDB();
  const me=db.user?db.user.name:'Guest';
  if(db.suspended.includes(me)){toast('Your account is suspended — action blocked.');return false;}
  db.reports.unshift({id:'r'+Date.now(),kind,refId:info.refId||null,course:info.course||null,label:info.label||'',by:me,reason:info.reason||'No reason given',status:'open',at:new Date().toLocaleString([],{month:'short',day:'numeric',hour:'numeric',minute:'2-digit'})});
  saveDB(db);return true;
}
function isSuspended(name){return getDB().suspended.includes(name);}
function saveDB(db){localStorage.setItem(DB_KEY,JSON.stringify(db));}
function getDB(){return loadDB();}
let toastTimer=null;
function toast(m,withUndo){
  const t=document.getElementById('toast');if(!t){alert(m);return;}
  t.innerHTML='';t.append(document.createTextNode(m));
  if(withUndo){const b=document.createElement('button');b.className='btn small ghost';b.style.marginLeft='10px';b.textContent='Undo';b.onclick=()=>{withUndo();t.classList.remove('show');};t.append(b);}
  t.classList.add('show');t.setAttribute('aria-live','polite');
  clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.remove('show'),3500);
}
function showErr(id,msg){const e=document.getElementById(id);if(!e)return;e.textContent=msg||'';e.classList.toggle('show',!!msg);}
/* Modal: focus trap + Esc + preserve data on close (do not clear inputs) + morph-from-trigger origin */
let lastFocus=null,lastPointer={x:innerWidth/2,y:140};
addEventListener('pointerdown',e=>{lastPointer={x:e.clientX,y:e.clientY};},{passive:true});
function motionOK(){return !matchMedia('(prefers-reduced-motion: reduce)').matches;}
function withVT(fn){if(document.startViewTransition&&motionOK()){try{return document.startViewTransition(()=>{fn();});}catch(e){fn();return null;}}fn();return null;}
function openModal(id,trigger){id=id||'m';lastFocus=document.activeElement||trigger||null;const bg=document.getElementById(id);if(!bg)return;
  const r=(trigger&&trigger.getBoundingClientRect&&trigger.getBoundingClientRect())||null;
  const ox=r?((lastPointer.x-r.left)/Math.max(1,r.width)*100):(lastPointer.x/innerWidth*100);
  const oy=r?((lastPointer.y-r.top)/Math.max(1,r.height)*100):10;
  document.documentElement.style.setProperty('--modal-ox',Math.min(100,Math.max(0,ox))+'%');
  document.documentElement.style.setProperty('--modal-oy',Math.min(100,Math.max(0,oy))+'%');
  withVT(()=>{bg.classList.add('open');
  const dlg=bg.querySelector('.modal');if(dlg){dlg.setAttribute('role','dialog');dlg.setAttribute('aria-modal','true');}
  /* Prefill submitter/host name from signed-in user (only if untouched) */
  try{const u=currentUser();['uBy','nBy'].forEach(function(fid){const el=bg.querySelector('#'+fid);if(el&&!el.value&&u)el.value=u.name;});}catch(e){}
  const f=bg.querySelector('input,select,textarea,button');if(f)f.focus();});
  bg.onkeydown=function(e){if(e.key==='Escape')closeModal(id);
    if(e.key==='Tab'){const els=[...bg.querySelectorAll('input,select,textarea,button')].filter(x=>!x.disabled);if(!els.length)return;
      const first=els[0],last=els[els.length-1];
      if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}
      else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}};}
function closeModal(id){id=id||'m';const bg=document.getElementById(id);if(bg)bg.classList.remove('open');if(lastFocus&&lastFocus.focus)lastFocus.focus();}
function toggleNav(){const n=document.getElementById('mainNav');if(!n)return;n.classList.toggle('open');const t=document.querySelector('.nav-toggle');if(t)t.setAttribute('aria-expanded',n.classList.contains('open')?'true':'false');}
/* Auth: students via login.html (role student only). Admins via admin.html gate (demo code below). */
const DEMO_ADMIN={username:'admin',password:'admin123'};
function currentUser(){try{return getDB().user||null;}catch(e){return null;}}
function isAdmin(){const u=currentUser();return !!(u&&u.role==='admin');}
function studentLogin(name){const db=getDB();db.user={name:name,role:'student'};saveDB(db);return db.user;}
function adminLogin(u,p){if(u===DEMO_ADMIN.username&&p===DEMO_ADMIN.password){const db=getDB();db.user={name:'Administrator',role:'admin'};saveDB(db);return true;}return false;}
function logout(){const db=getDB();db.user=null;saveDB(db);}
/* Accounts: guests must register before uploading, joining or chatting */
function registerAccount(name,sid){
  const db=getDB();name=(name||'').trim();sid=(sid||'').trim();
  if(!name||!sid)return {ok:false,msg:'Enter name and student ID.'};
  if(db.accounts.some(a=>a.name.toLowerCase()===name.toLowerCase()))return {ok:false,msg:'That name already has an account — log in instead.'};
  db.accounts.push({name,sid,created:new Date().toISOString()});
  db.user={name,role:'student'};saveDB(db);return {ok:true};
}
function loginAccount(name){
  const db=getDB();name=(name||'').trim();
  const acc=db.accounts.find(a=>a.name.toLowerCase()===name.toLowerCase());
  if(!acc)return {ok:false,msg:'No account found for that name — create one first.'};
  db.user={name:acc.name,role:'student'};saveDB(db);return {ok:true};
}
/* Gate for members-only actions: guests get a nudge + redirect */
function requireAuth(msg){
  if(currentUser())return true;
  toast(msg||'Create an account to continue');
  setTimeout(()=>{location.href='login.html';},900);
  return false;
}
/* Hide every admin trace from non-admins: nav link, footer links, admin-only blocks */
function hideAdminTraces(){
  if(isAdmin())return;
  document.querySelectorAll('[data-admin-only]').forEach(el=>el.remove());
  const nav=document.getElementById('mainNav');
  if(nav)nav.querySelectorAll('a[href="admin.html"]').forEach(a=>a.remove());
}
/* Show signed-in name on every page's Login link (was home-only) */
function paintAuth(){
  const u=currentUser();if(!u)return;
  const link=document.getElementById('loginLink')||(document.getElementById('mainNav')||document).querySelector('a[href="login.html"]');
  if(link)link.textContent='Hi, '+u.name;
}
document.addEventListener('DOMContentLoaded',hideAdminTraces);
document.addEventListener('DOMContentLoaded',paintAuth);
function validURL(v){if(!v)return true;try{new URL(v.startsWith('http')?v:'https://'+v);return true;}catch(e){return false;}}
function escapeHTML(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];});}
function linkHref(v){if(!v)return '';return /^https?:\/\//i.test(v)?v:'https://'+v;}
/* Click-outside to dismiss dialogs (Esc + focus-trap already in openModal) */
(function(){document.querySelectorAll('.modal-bg').forEach(function(bg){bg.addEventListener('mousedown',function(e){if(e.target===bg)closeModal(bg.id);});});})();
/* Motion continuity: topbar depth on scroll + chat-head swap pulse */
(function(){let tick=false;function onScroll(){const b=document.querySelector('.topbar');if(b)b.classList.toggle('scrolled',window.scrollY>8);tick=false;}window.addEventListener('scroll',()=>{if(!tick){tick=true;requestAnimationFrame(onScroll);}},{passive:true});onScroll();})();
function pulseChatHead(){const h=document.querySelector('.chat-head');if(!h)return;h.classList.remove('swapped');void h.offsetWidth;h.classList.add('swapped');}
function markFreshMessage(){const box=document.getElementById('msgs');if(!box)return;const items=box.querySelectorAll('.msg');items.forEach(m=>m.classList.remove('fresh'));const last=items[items.length-1];if(last)last.classList.add('fresh');}
/* Overdrive: cinematic same-document page morphs (progressive enhancement; native cross-document VT handled by CSS @view-transition) */
(function(){if(!document.startViewTransition)return;
  addEventListener('click',e=>{const a=e.target.closest&&e.target.closest('a[href]');if(!a)return;
    const href=a.getAttribute('href');if(!href||href.startsWith('#')||href.startsWith('http')||href.startsWith('mailto:')||a.target==='_blank'||e.metaKey||e.ctrlKey||e.shiftKey||e.altKey)return;
    if(!href.endsWith('.html'))return;if(!motionOK())return;
    try{const u=new URL(href,location.href);if(u.origin!==location.origin)return;}catch(err){return;}
    e.preventDefault();withVT(()=>{location.href=href;});});})();
/* Overdrive: scroll progress fallback (CSS scroll-driven timeline wins where supported) + smoothed hero spotlight */
(function(){let bar=document.querySelector('.scroll-progress');
  if(!bar){bar=document.createElement('div');bar.className='scroll-progress';bar.setAttribute('aria-hidden','true');document.body.prepend(bar);}
  const cssScroll=(CSS.supports&&CSS.supports('animation-timeline: scroll()'));
  if(!cssScroll){let tick=false;const set=()=>{const h=document.documentElement;const max=h.scrollHeight-h.clientHeight;bar.style.transform='scaleX('+(max>0?(h.scrollTop/max):0)+')';tick=false;};
    addEventListener('scroll',()=>{if(!tick){tick=true;requestAnimationFrame(set);}},{passive:true});set();}
  const hero=document.getElementById('hero'),spot=document.getElementById('heroSpot');
  if(hero&&spot&&matchMedia('(pointer:fine)').matches&&motionOK()){
    let tx=30,ty=30,cx=30,cy=30,raf=0;
    const loop=()=>{cx+=(tx-cx)*.12;cy+=(ty-cy)*.12;spot.style.setProperty('--mx',cx+'%');spot.style.setProperty('--my',cy+'%');
      if(Math.abs(tx-cx)>.05||Math.abs(ty-cy)>.05)raf=requestAnimationFrame(loop);else raf=0;};
    hero.addEventListener('pointermove',e=>{const r=hero.getBoundingClientRect();tx=(e.clientX-r.left)/r.width*100;ty=(e.clientY-r.top)/r.height*100;if(!raf)raf=requestAnimationFrame(loop);},{passive:true});}})();
