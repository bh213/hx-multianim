var ud=Object.defineProperty;var cd=(e,n,t)=>n in e?ud(e,n,{enumerable:!0,configurable:!0,writable:!0,value:t}):e[n]=t;var _e=(e,n,t)=>cd(e,typeof n!="symbol"?n+"":n,t);(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))r(i);new MutationObserver(i=>{for(const l of i)if(l.type==="childList")for(const o of l.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&r(o)}).observe(document,{childList:!0,subtree:!0});function t(i){const l={};return i.integrity&&(l.integrity=i.integrity),i.referrerPolicy&&(l.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?l.credentials="include":i.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function r(i){if(i.ep)return;i.ep=!0;const l=t(i);fetch(i.href,l)}})();var dd=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};function Ms(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var Ds={exports:{}},Fi={},Os={exports:{}},A={};/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var kr=Symbol.for("react.element"),fd=Symbol.for("react.portal"),pd=Symbol.for("react.fragment"),md=Symbol.for("react.strict_mode"),hd=Symbol.for("react.profiler"),gd=Symbol.for("react.provider"),vd=Symbol.for("react.context"),yd=Symbol.for("react.forward_ref"),xd=Symbol.for("react.suspense"),wd=Symbol.for("react.memo"),kd=Symbol.for("react.lazy"),ya=Symbol.iterator;function _d(e){return e===null||typeof e!="object"?null:(e=ya&&e[ya]||e["@@iterator"],typeof e=="function"?e:null)}var As={isMounted:function(){return!1},enqueueForceUpdate:function(){},enqueueReplaceState:function(){},enqueueSetState:function(){}},Is=Object.assign,Us={};function Tt(e,n,t){this.props=e,this.context=n,this.refs=Us,this.updater=t||As}Tt.prototype.isReactComponent={};Tt.prototype.setState=function(e,n){if(typeof e!="object"&&typeof e!="function"&&e!=null)throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");this.updater.enqueueSetState(this,e,n,"setState")};Tt.prototype.forceUpdate=function(e){this.updater.enqueueForceUpdate(this,e,"forceUpdate")};function Bs(){}Bs.prototype=Tt.prototype;function yo(e,n,t){this.props=e,this.context=n,this.refs=Us,this.updater=t||As}var xo=yo.prototype=new Bs;xo.constructor=yo;Is(xo,Tt.prototype);xo.isPureReactComponent=!0;var xa=Array.isArray,Ws=Object.prototype.hasOwnProperty,wo={current:null},Hs={key:!0,ref:!0,__self:!0,__source:!0};function Vs(e,n,t){var r,i={},l=null,o=null;if(n!=null)for(r in n.ref!==void 0&&(o=n.ref),n.key!==void 0&&(l=""+n.key),n)Ws.call(n,r)&&!Hs.hasOwnProperty(r)&&(i[r]=n[r]);var a=arguments.length-2;if(a===1)i.children=t;else if(1<a){for(var u=Array(a),d=0;d<a;d++)u[d]=arguments[d+2];i.children=u}if(e&&e.defaultProps)for(r in a=e.defaultProps,a)i[r]===void 0&&(i[r]=a[r]);return{$$typeof:kr,type:e,key:l,ref:o,props:i,_owner:wo.current}}function Sd(e,n){return{$$typeof:kr,type:e.type,key:n,ref:e.ref,props:e.props,_owner:e._owner}}function ko(e){return typeof e=="object"&&e!==null&&e.$$typeof===kr}function Cd(e){var n={"=":"=0",":":"=2"};return"$"+e.replace(/[=:]/g,function(t){return n[t]})}var wa=/\/+/g;function Gi(e,n){return typeof e=="object"&&e!==null&&e.key!=null?Cd(""+e.key):n.toString(36)}function Qr(e,n,t,r,i){var l=typeof e;(l==="undefined"||l==="boolean")&&(e=null);var o=!1;if(e===null)o=!0;else switch(l){case"string":case"number":o=!0;break;case"object":switch(e.$$typeof){case kr:case fd:o=!0}}if(o)return o=e,i=i(o),e=r===""?"."+Gi(o,0):r,xa(i)?(t="",e!=null&&(t=e.replace(wa,"$&/")+"/"),Qr(i,n,t,"",function(d){return d})):i!=null&&(ko(i)&&(i=Sd(i,t+(!i.key||o&&o.key===i.key?"":(""+i.key).replace(wa,"$&/")+"/")+e)),n.push(i)),1;if(o=0,r=r===""?".":r+":",xa(e))for(var a=0;a<e.length;a++){l=e[a];var u=r+Gi(l,a);o+=Qr(l,n,t,u,i)}else if(u=_d(e),typeof u=="function")for(e=u.call(e),a=0;!(l=e.next()).done;)l=l.value,u=r+Gi(l,a++),o+=Qr(l,n,t,u,i);else if(l==="object")throw n=String(e),Error("Objects are not valid as a React child (found: "+(n==="[object Object]"?"object with keys {"+Object.keys(e).join(", ")+"}":n)+"). If you meant to render a collection of children, use an array instead.");return o}function $r(e,n,t){if(e==null)return e;var r=[],i=0;return Qr(e,r,"","",function(l){return n.call(t,l,i++)}),r}function Ed(e){if(e._status===-1){var n=e._result;n=n(),n.then(function(t){(e._status===0||e._status===-1)&&(e._status=1,e._result=t)},function(t){(e._status===0||e._status===-1)&&(e._status=2,e._result=t)}),e._status===-1&&(e._status=0,e._result=n)}if(e._status===1)return e._result.default;throw e._result}var Ee={current:null},Kr={transition:null},bd={ReactCurrentDispatcher:Ee,ReactCurrentBatchConfig:Kr,ReactCurrentOwner:wo};function Qs(){throw Error("act(...) is not supported in production builds of React.")}A.Children={map:$r,forEach:function(e,n,t){$r(e,function(){n.apply(this,arguments)},t)},count:function(e){var n=0;return $r(e,function(){n++}),n},toArray:function(e){return $r(e,function(n){return n})||[]},only:function(e){if(!ko(e))throw Error("React.Children.only expected to receive a single React element child.");return e}};A.Component=Tt;A.Fragment=pd;A.Profiler=hd;A.PureComponent=yo;A.StrictMode=md;A.Suspense=xd;A.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=bd;A.act=Qs;A.cloneElement=function(e,n,t){if(e==null)throw Error("React.cloneElement(...): The argument must be a React element, but you passed "+e+".");var r=Is({},e.props),i=e.key,l=e.ref,o=e._owner;if(n!=null){if(n.ref!==void 0&&(l=n.ref,o=wo.current),n.key!==void 0&&(i=""+n.key),e.type&&e.type.defaultProps)var a=e.type.defaultProps;for(u in n)Ws.call(n,u)&&!Hs.hasOwnProperty(u)&&(r[u]=n[u]===void 0&&a!==void 0?a[u]:n[u])}var u=arguments.length-2;if(u===1)r.children=t;else if(1<u){a=Array(u);for(var d=0;d<u;d++)a[d]=arguments[d+2];r.children=a}return{$$typeof:kr,type:e.type,key:i,ref:l,props:r,_owner:o}};A.createContext=function(e){return e={$$typeof:vd,_currentValue:e,_currentValue2:e,_threadCount:0,Provider:null,Consumer:null,_defaultValue:null,_globalName:null},e.Provider={$$typeof:gd,_context:e},e.Consumer=e};A.createElement=Vs;A.createFactory=function(e){var n=Vs.bind(null,e);return n.type=e,n};A.createRef=function(){return{current:null}};A.forwardRef=function(e){return{$$typeof:yd,render:e}};A.isValidElement=ko;A.lazy=function(e){return{$$typeof:kd,_payload:{_status:-1,_result:e},_init:Ed}};A.memo=function(e,n){return{$$typeof:wd,type:e,compare:n===void 0?null:n}};A.startTransition=function(e){var n=Kr.transition;Kr.transition={};try{e()}finally{Kr.transition=n}};A.unstable_act=Qs;A.useCallback=function(e,n){return Ee.current.useCallback(e,n)};A.useContext=function(e){return Ee.current.useContext(e)};A.useDebugValue=function(){};A.useDeferredValue=function(e){return Ee.current.useDeferredValue(e)};A.useEffect=function(e,n){return Ee.current.useEffect(e,n)};A.useId=function(){return Ee.current.useId()};A.useImperativeHandle=function(e,n,t){return Ee.current.useImperativeHandle(e,n,t)};A.useInsertionEffect=function(e,n){return Ee.current.useInsertionEffect(e,n)};A.useLayoutEffect=function(e,n){return Ee.current.useLayoutEffect(e,n)};A.useMemo=function(e,n){return Ee.current.useMemo(e,n)};A.useReducer=function(e,n,t){return Ee.current.useReducer(e,n,t)};A.useRef=function(e){return Ee.current.useRef(e)};A.useState=function(e){return Ee.current.useState(e)};A.useSyncExternalStore=function(e,n,t){return Ee.current.useSyncExternalStore(e,n,t)};A.useTransition=function(){return Ee.current.useTransition()};A.version="18.3.1";Os.exports=A;var $=Os.exports;const pe=Ms($);/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var $d=$,Pd=Symbol.for("react.element"),Nd=Symbol.for("react.fragment"),Fd=Object.prototype.hasOwnProperty,Td=$d.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,jd={key:!0,ref:!0,__self:!0,__source:!0};function Ks(e,n,t){var r,i={},l=null,o=null;t!==void 0&&(l=""+t),n.key!==void 0&&(l=""+n.key),n.ref!==void 0&&(o=n.ref);for(r in n)Fd.call(n,r)&&!jd.hasOwnProperty(r)&&(i[r]=n[r]);if(e&&e.defaultProps)for(r in n=e.defaultProps,n)i[r]===void 0&&(i[r]=n[r]);return{$$typeof:Pd,type:e,key:l,ref:o,props:i,_owner:Td.current}}Fi.Fragment=Nd;Fi.jsx=Ks;Fi.jsxs=Ks;Ds.exports=Fi;var y=Ds.exports,Cl={},Gs={exports:{}},Ae={},Ys={exports:{}},Xs={};/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */(function(e){function n(N,L){var O=N.length;N.push(L);e:for(;0<O;){var j=O-1>>>1,D=N[j];if(0<i(D,L))N[j]=L,N[O]=D,O=j;else break e}}function t(N){return N.length===0?null:N[0]}function r(N){if(N.length===0)return null;var L=N[0],O=N.pop();if(O!==L){N[0]=O;e:for(var j=0,D=N.length,re=D>>>1;j<re;){var ge=2*(j+1)-1,Ue=N[ge],sn=ge+1,nt=N[sn];if(0>i(Ue,O))sn<D&&0>i(nt,Ue)?(N[j]=nt,N[sn]=O,j=sn):(N[j]=Ue,N[ge]=O,j=ge);else if(sn<D&&0>i(nt,O))N[j]=nt,N[sn]=O,j=sn;else break e}}return L}function i(N,L){var O=N.sortIndex-L.sortIndex;return O!==0?O:N.id-L.id}if(typeof performance=="object"&&typeof performance.now=="function"){var l=performance;e.unstable_now=function(){return l.now()}}else{var o=Date,a=o.now();e.unstable_now=function(){return o.now()-a}}var u=[],d=[],v=1,m=null,p=3,g=!1,x=!1,w=!1,z=typeof setTimeout=="function"?setTimeout:null,c=typeof clearTimeout=="function"?clearTimeout:null,s=typeof setImmediate<"u"?setImmediate:null;typeof navigator<"u"&&navigator.scheduling!==void 0&&navigator.scheduling.isInputPending!==void 0&&navigator.scheduling.isInputPending.bind(navigator.scheduling);function f(N){for(var L=t(d);L!==null;){if(L.callback===null)r(d);else if(L.startTime<=N)r(d),L.sortIndex=L.expirationTime,n(u,L);else break;L=t(d)}}function h(N){if(w=!1,f(N),!x)if(t(u)!==null)x=!0,B(_);else{var L=t(d);L!==null&&se(h,L.startTime-N)}}function _(N,L){x=!1,w&&(w=!1,c(E),E=-1),g=!0;var O=p;try{for(f(L),m=t(u);m!==null&&(!(m.expirationTime>L)||N&&!X());){var j=m.callback;if(typeof j=="function"){m.callback=null,p=m.priorityLevel;var D=j(m.expirationTime<=L);L=e.unstable_now(),typeof D=="function"?m.callback=D:m===t(u)&&r(u),f(L)}else r(u);m=t(u)}if(m!==null)var re=!0;else{var ge=t(d);ge!==null&&se(h,ge.startTime-L),re=!1}return re}finally{m=null,p=O,g=!1}}var C=!1,b=null,E=-1,R=5,P=-1;function X(){return!(e.unstable_now()-P<R)}function je(){if(b!==null){var N=e.unstable_now();P=N;var L=!0;try{L=b(!0,N)}finally{L?ke():(C=!1,b=null)}}else C=!1}var ke;if(typeof s=="function")ke=function(){s(je)};else if(typeof MessageChannel<"u"){var nn=new MessageChannel,M=nn.port2;nn.port1.onmessage=je,ke=function(){M.postMessage(null)}}else ke=function(){z(je,0)};function B(N){b=N,C||(C=!0,ke())}function se(N,L){E=z(function(){N(e.unstable_now())},L)}e.unstable_IdlePriority=5,e.unstable_ImmediatePriority=1,e.unstable_LowPriority=4,e.unstable_NormalPriority=3,e.unstable_Profiling=null,e.unstable_UserBlockingPriority=2,e.unstable_cancelCallback=function(N){N.callback=null},e.unstable_continueExecution=function(){x||g||(x=!0,B(_))},e.unstable_forceFrameRate=function(N){0>N||125<N?console.error("forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported"):R=0<N?Math.floor(1e3/N):5},e.unstable_getCurrentPriorityLevel=function(){return p},e.unstable_getFirstCallbackNode=function(){return t(u)},e.unstable_next=function(N){switch(p){case 1:case 2:case 3:var L=3;break;default:L=p}var O=p;p=L;try{return N()}finally{p=O}},e.unstable_pauseExecution=function(){},e.unstable_requestPaint=function(){},e.unstable_runWithPriority=function(N,L){switch(N){case 1:case 2:case 3:case 4:case 5:break;default:N=3}var O=p;p=N;try{return L()}finally{p=O}},e.unstable_scheduleCallback=function(N,L,O){var j=e.unstable_now();switch(typeof O=="object"&&O!==null?(O=O.delay,O=typeof O=="number"&&0<O?j+O:j):O=j,N){case 1:var D=-1;break;case 2:D=250;break;case 5:D=1073741823;break;case 4:D=1e4;break;default:D=5e3}return D=O+D,N={id:v++,callback:L,priorityLevel:N,startTime:O,expirationTime:D,sortIndex:-1},O>j?(N.sortIndex=O,n(d,N),t(u)===null&&N===t(d)&&(w?(c(E),E=-1):w=!0,se(h,O-j))):(N.sortIndex=D,n(u,N),x||g||(x=!0,B(_))),N},e.unstable_shouldYield=X,e.unstable_wrapCallback=function(N){var L=p;return function(){var O=p;p=L;try{return N.apply(this,arguments)}finally{p=O}}}})(Xs);Ys.exports=Xs;var zd=Ys.exports;/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Ld=$,Oe=zd;function S(e){for(var n="https://reactjs.org/docs/error-decoder.html?invariant="+e,t=1;t<arguments.length;t++)n+="&args[]="+encodeURIComponent(arguments[t]);return"Minified React error #"+e+"; visit "+n+" for the full message or use the non-minified dev environment for full errors and additional helpful warnings."}var Zs=new Set,rr={};function Jn(e,n){Ct(e,n),Ct(e+"Capture",n)}function Ct(e,n){for(rr[e]=n,e=0;e<n.length;e++)Zs.add(n[e])}var mn=!(typeof window>"u"||typeof window.document>"u"||typeof window.document.createElement>"u"),El=Object.prototype.hasOwnProperty,Rd=/^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,ka={},_a={};function Md(e){return El.call(_a,e)?!0:El.call(ka,e)?!1:Rd.test(e)?_a[e]=!0:(ka[e]=!0,!1)}function Dd(e,n,t,r){if(t!==null&&t.type===0)return!1;switch(typeof n){case"function":case"symbol":return!0;case"boolean":return r?!1:t!==null?!t.acceptsBooleans:(e=e.toLowerCase().slice(0,5),e!=="data-"&&e!=="aria-");default:return!1}}function Od(e,n,t,r){if(n===null||typeof n>"u"||Dd(e,n,t,r))return!0;if(r)return!1;if(t!==null)switch(t.type){case 3:return!n;case 4:return n===!1;case 5:return isNaN(n);case 6:return isNaN(n)||1>n}return!1}function be(e,n,t,r,i,l,o){this.acceptsBooleans=n===2||n===3||n===4,this.attributeName=r,this.attributeNamespace=i,this.mustUseProperty=t,this.propertyName=e,this.type=n,this.sanitizeURL=l,this.removeEmptyString=o}var he={};"children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style".split(" ").forEach(function(e){he[e]=new be(e,0,!1,e,null,!1,!1)});[["acceptCharset","accept-charset"],["className","class"],["htmlFor","for"],["httpEquiv","http-equiv"]].forEach(function(e){var n=e[0];he[n]=new be(n,1,!1,e[1],null,!1,!1)});["contentEditable","draggable","spellCheck","value"].forEach(function(e){he[e]=new be(e,2,!1,e.toLowerCase(),null,!1,!1)});["autoReverse","externalResourcesRequired","focusable","preserveAlpha"].forEach(function(e){he[e]=new be(e,2,!1,e,null,!1,!1)});"allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope".split(" ").forEach(function(e){he[e]=new be(e,3,!1,e.toLowerCase(),null,!1,!1)});["checked","multiple","muted","selected"].forEach(function(e){he[e]=new be(e,3,!0,e,null,!1,!1)});["capture","download"].forEach(function(e){he[e]=new be(e,4,!1,e,null,!1,!1)});["cols","rows","size","span"].forEach(function(e){he[e]=new be(e,6,!1,e,null,!1,!1)});["rowSpan","start"].forEach(function(e){he[e]=new be(e,5,!1,e.toLowerCase(),null,!1,!1)});var _o=/[\-:]([a-z])/g;function So(e){return e[1].toUpperCase()}"accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height".split(" ").forEach(function(e){var n=e.replace(_o,So);he[n]=new be(n,1,!1,e,null,!1,!1)});"xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type".split(" ").forEach(function(e){var n=e.replace(_o,So);he[n]=new be(n,1,!1,e,"http://www.w3.org/1999/xlink",!1,!1)});["xml:base","xml:lang","xml:space"].forEach(function(e){var n=e.replace(_o,So);he[n]=new be(n,1,!1,e,"http://www.w3.org/XML/1998/namespace",!1,!1)});["tabIndex","crossOrigin"].forEach(function(e){he[e]=new be(e,1,!1,e.toLowerCase(),null,!1,!1)});he.xlinkHref=new be("xlinkHref",1,!1,"xlink:href","http://www.w3.org/1999/xlink",!0,!1);["src","href","action","formAction"].forEach(function(e){he[e]=new be(e,1,!1,e.toLowerCase(),null,!0,!0)});function Co(e,n,t,r){var i=he.hasOwnProperty(n)?he[n]:null;(i!==null?i.type!==0:r||!(2<n.length)||n[0]!=="o"&&n[0]!=="O"||n[1]!=="n"&&n[1]!=="N")&&(Od(n,t,i,r)&&(t=null),r||i===null?Md(n)&&(t===null?e.removeAttribute(n):e.setAttribute(n,""+t)):i.mustUseProperty?e[i.propertyName]=t===null?i.type===3?!1:"":t:(n=i.attributeName,r=i.attributeNamespace,t===null?e.removeAttribute(n):(i=i.type,t=i===3||i===4&&t===!0?"":""+t,r?e.setAttributeNS(r,n,t):e.setAttribute(n,t))))}var yn=Ld.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,Pr=Symbol.for("react.element"),lt=Symbol.for("react.portal"),ot=Symbol.for("react.fragment"),Eo=Symbol.for("react.strict_mode"),bl=Symbol.for("react.profiler"),qs=Symbol.for("react.provider"),Js=Symbol.for("react.context"),bo=Symbol.for("react.forward_ref"),$l=Symbol.for("react.suspense"),Pl=Symbol.for("react.suspense_list"),$o=Symbol.for("react.memo"),wn=Symbol.for("react.lazy"),eu=Symbol.for("react.offscreen"),Sa=Symbol.iterator;function Lt(e){return e===null||typeof e!="object"?null:(e=Sa&&e[Sa]||e["@@iterator"],typeof e=="function"?e:null)}var ee=Object.assign,Yi;function Bt(e){if(Yi===void 0)try{throw Error()}catch(t){var n=t.stack.trim().match(/\n( *(at )?)/);Yi=n&&n[1]||""}return`
`+Yi+e}var Xi=!1;function Zi(e,n){if(!e||Xi)return"";Xi=!0;var t=Error.prepareStackTrace;Error.prepareStackTrace=void 0;try{if(n)if(n=function(){throw Error()},Object.defineProperty(n.prototype,"props",{set:function(){throw Error()}}),typeof Reflect=="object"&&Reflect.construct){try{Reflect.construct(n,[])}catch(d){var r=d}Reflect.construct(e,[],n)}else{try{n.call()}catch(d){r=d}e.call(n.prototype)}else{try{throw Error()}catch(d){r=d}e()}}catch(d){if(d&&r&&typeof d.stack=="string"){for(var i=d.stack.split(`
`),l=r.stack.split(`
`),o=i.length-1,a=l.length-1;1<=o&&0<=a&&i[o]!==l[a];)a--;for(;1<=o&&0<=a;o--,a--)if(i[o]!==l[a]){if(o!==1||a!==1)do if(o--,a--,0>a||i[o]!==l[a]){var u=`
`+i[o].replace(" at new "," at ");return e.displayName&&u.includes("<anonymous>")&&(u=u.replace("<anonymous>",e.displayName)),u}while(1<=o&&0<=a);break}}}finally{Xi=!1,Error.prepareStackTrace=t}return(e=e?e.displayName||e.name:"")?Bt(e):""}function Ad(e){switch(e.tag){case 5:return Bt(e.type);case 16:return Bt("Lazy");case 13:return Bt("Suspense");case 19:return Bt("SuspenseList");case 0:case 2:case 15:return e=Zi(e.type,!1),e;case 11:return e=Zi(e.type.render,!1),e;case 1:return e=Zi(e.type,!0),e;default:return""}}function Nl(e){if(e==null)return null;if(typeof e=="function")return e.displayName||e.name||null;if(typeof e=="string")return e;switch(e){case ot:return"Fragment";case lt:return"Portal";case bl:return"Profiler";case Eo:return"StrictMode";case $l:return"Suspense";case Pl:return"SuspenseList"}if(typeof e=="object")switch(e.$$typeof){case Js:return(e.displayName||"Context")+".Consumer";case qs:return(e._context.displayName||"Context")+".Provider";case bo:var n=e.render;return e=e.displayName,e||(e=n.displayName||n.name||"",e=e!==""?"ForwardRef("+e+")":"ForwardRef"),e;case $o:return n=e.displayName||null,n!==null?n:Nl(e.type)||"Memo";case wn:n=e._payload,e=e._init;try{return Nl(e(n))}catch{}}return null}function Id(e){var n=e.type;switch(e.tag){case 24:return"Cache";case 9:return(n.displayName||"Context")+".Consumer";case 10:return(n._context.displayName||"Context")+".Provider";case 18:return"DehydratedFragment";case 11:return e=n.render,e=e.displayName||e.name||"",n.displayName||(e!==""?"ForwardRef("+e+")":"ForwardRef");case 7:return"Fragment";case 5:return n;case 4:return"Portal";case 3:return"Root";case 6:return"Text";case 16:return Nl(n);case 8:return n===Eo?"StrictMode":"Mode";case 22:return"Offscreen";case 12:return"Profiler";case 21:return"Scope";case 13:return"Suspense";case 19:return"SuspenseList";case 25:return"TracingMarker";case 1:case 0:case 17:case 2:case 14:case 15:if(typeof n=="function")return n.displayName||n.name||null;if(typeof n=="string")return n}return null}function Rn(e){switch(typeof e){case"boolean":case"number":case"string":case"undefined":return e;case"object":return e;default:return""}}function nu(e){var n=e.type;return(e=e.nodeName)&&e.toLowerCase()==="input"&&(n==="checkbox"||n==="radio")}function Ud(e){var n=nu(e)?"checked":"value",t=Object.getOwnPropertyDescriptor(e.constructor.prototype,n),r=""+e[n];if(!e.hasOwnProperty(n)&&typeof t<"u"&&typeof t.get=="function"&&typeof t.set=="function"){var i=t.get,l=t.set;return Object.defineProperty(e,n,{configurable:!0,get:function(){return i.call(this)},set:function(o){r=""+o,l.call(this,o)}}),Object.defineProperty(e,n,{enumerable:t.enumerable}),{getValue:function(){return r},setValue:function(o){r=""+o},stopTracking:function(){e._valueTracker=null,delete e[n]}}}}function Nr(e){e._valueTracker||(e._valueTracker=Ud(e))}function tu(e){if(!e)return!1;var n=e._valueTracker;if(!n)return!0;var t=n.getValue(),r="";return e&&(r=nu(e)?e.checked?"true":"false":e.value),e=r,e!==t?(n.setValue(e),!0):!1}function li(e){if(e=e||(typeof document<"u"?document:void 0),typeof e>"u")return null;try{return e.activeElement||e.body}catch{return e.body}}function Fl(e,n){var t=n.checked;return ee({},n,{defaultChecked:void 0,defaultValue:void 0,value:void 0,checked:t??e._wrapperState.initialChecked})}function Ca(e,n){var t=n.defaultValue==null?"":n.defaultValue,r=n.checked!=null?n.checked:n.defaultChecked;t=Rn(n.value!=null?n.value:t),e._wrapperState={initialChecked:r,initialValue:t,controlled:n.type==="checkbox"||n.type==="radio"?n.checked!=null:n.value!=null}}function ru(e,n){n=n.checked,n!=null&&Co(e,"checked",n,!1)}function Tl(e,n){ru(e,n);var t=Rn(n.value),r=n.type;if(t!=null)r==="number"?(t===0&&e.value===""||e.value!=t)&&(e.value=""+t):e.value!==""+t&&(e.value=""+t);else if(r==="submit"||r==="reset"){e.removeAttribute("value");return}n.hasOwnProperty("value")?jl(e,n.type,t):n.hasOwnProperty("defaultValue")&&jl(e,n.type,Rn(n.defaultValue)),n.checked==null&&n.defaultChecked!=null&&(e.defaultChecked=!!n.defaultChecked)}function Ea(e,n,t){if(n.hasOwnProperty("value")||n.hasOwnProperty("defaultValue")){var r=n.type;if(!(r!=="submit"&&r!=="reset"||n.value!==void 0&&n.value!==null))return;n=""+e._wrapperState.initialValue,t||n===e.value||(e.value=n),e.defaultValue=n}t=e.name,t!==""&&(e.name=""),e.defaultChecked=!!e._wrapperState.initialChecked,t!==""&&(e.name=t)}function jl(e,n,t){(n!=="number"||li(e.ownerDocument)!==e)&&(t==null?e.defaultValue=""+e._wrapperState.initialValue:e.defaultValue!==""+t&&(e.defaultValue=""+t))}var Wt=Array.isArray;function yt(e,n,t,r){if(e=e.options,n){n={};for(var i=0;i<t.length;i++)n["$"+t[i]]=!0;for(t=0;t<e.length;t++)i=n.hasOwnProperty("$"+e[t].value),e[t].selected!==i&&(e[t].selected=i),i&&r&&(e[t].defaultSelected=!0)}else{for(t=""+Rn(t),n=null,i=0;i<e.length;i++){if(e[i].value===t){e[i].selected=!0,r&&(e[i].defaultSelected=!0);return}n!==null||e[i].disabled||(n=e[i])}n!==null&&(n.selected=!0)}}function zl(e,n){if(n.dangerouslySetInnerHTML!=null)throw Error(S(91));return ee({},n,{value:void 0,defaultValue:void 0,children:""+e._wrapperState.initialValue})}function ba(e,n){var t=n.value;if(t==null){if(t=n.children,n=n.defaultValue,t!=null){if(n!=null)throw Error(S(92));if(Wt(t)){if(1<t.length)throw Error(S(93));t=t[0]}n=t}n==null&&(n=""),t=n}e._wrapperState={initialValue:Rn(t)}}function iu(e,n){var t=Rn(n.value),r=Rn(n.defaultValue);t!=null&&(t=""+t,t!==e.value&&(e.value=t),n.defaultValue==null&&e.defaultValue!==t&&(e.defaultValue=t)),r!=null&&(e.defaultValue=""+r)}function $a(e){var n=e.textContent;n===e._wrapperState.initialValue&&n!==""&&n!==null&&(e.value=n)}function lu(e){switch(e){case"svg":return"http://www.w3.org/2000/svg";case"math":return"http://www.w3.org/1998/Math/MathML";default:return"http://www.w3.org/1999/xhtml"}}function Ll(e,n){return e==null||e==="http://www.w3.org/1999/xhtml"?lu(n):e==="http://www.w3.org/2000/svg"&&n==="foreignObject"?"http://www.w3.org/1999/xhtml":e}var Fr,ou=function(e){return typeof MSApp<"u"&&MSApp.execUnsafeLocalFunction?function(n,t,r,i){MSApp.execUnsafeLocalFunction(function(){return e(n,t,r,i)})}:e}(function(e,n){if(e.namespaceURI!=="http://www.w3.org/2000/svg"||"innerHTML"in e)e.innerHTML=n;else{for(Fr=Fr||document.createElement("div"),Fr.innerHTML="<svg>"+n.valueOf().toString()+"</svg>",n=Fr.firstChild;e.firstChild;)e.removeChild(e.firstChild);for(;n.firstChild;)e.appendChild(n.firstChild)}});function ir(e,n){if(n){var t=e.firstChild;if(t&&t===e.lastChild&&t.nodeType===3){t.nodeValue=n;return}}e.textContent=n}var Kt={animationIterationCount:!0,aspectRatio:!0,borderImageOutset:!0,borderImageSlice:!0,borderImageWidth:!0,boxFlex:!0,boxFlexGroup:!0,boxOrdinalGroup:!0,columnCount:!0,columns:!0,flex:!0,flexGrow:!0,flexPositive:!0,flexShrink:!0,flexNegative:!0,flexOrder:!0,gridArea:!0,gridRow:!0,gridRowEnd:!0,gridRowSpan:!0,gridRowStart:!0,gridColumn:!0,gridColumnEnd:!0,gridColumnSpan:!0,gridColumnStart:!0,fontWeight:!0,lineClamp:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,tabSize:!0,widows:!0,zIndex:!0,zoom:!0,fillOpacity:!0,floodOpacity:!0,stopOpacity:!0,strokeDasharray:!0,strokeDashoffset:!0,strokeMiterlimit:!0,strokeOpacity:!0,strokeWidth:!0},Bd=["Webkit","ms","Moz","O"];Object.keys(Kt).forEach(function(e){Bd.forEach(function(n){n=n+e.charAt(0).toUpperCase()+e.substring(1),Kt[n]=Kt[e]})});function au(e,n,t){return n==null||typeof n=="boolean"||n===""?"":t||typeof n!="number"||n===0||Kt.hasOwnProperty(e)&&Kt[e]?(""+n).trim():n+"px"}function su(e,n){e=e.style;for(var t in n)if(n.hasOwnProperty(t)){var r=t.indexOf("--")===0,i=au(t,n[t],r);t==="float"&&(t="cssFloat"),r?e.setProperty(t,i):e[t]=i}}var Wd=ee({menuitem:!0},{area:!0,base:!0,br:!0,col:!0,embed:!0,hr:!0,img:!0,input:!0,keygen:!0,link:!0,meta:!0,param:!0,source:!0,track:!0,wbr:!0});function Rl(e,n){if(n){if(Wd[e]&&(n.children!=null||n.dangerouslySetInnerHTML!=null))throw Error(S(137,e));if(n.dangerouslySetInnerHTML!=null){if(n.children!=null)throw Error(S(60));if(typeof n.dangerouslySetInnerHTML!="object"||!("__html"in n.dangerouslySetInnerHTML))throw Error(S(61))}if(n.style!=null&&typeof n.style!="object")throw Error(S(62))}}function Ml(e,n){if(e.indexOf("-")===-1)return typeof n.is=="string";switch(e){case"annotation-xml":case"color-profile":case"font-face":case"font-face-src":case"font-face-uri":case"font-face-format":case"font-face-name":case"missing-glyph":return!1;default:return!0}}var Dl=null;function Po(e){return e=e.target||e.srcElement||window,e.correspondingUseElement&&(e=e.correspondingUseElement),e.nodeType===3?e.parentNode:e}var Ol=null,xt=null,wt=null;function Pa(e){if(e=Cr(e)){if(typeof Ol!="function")throw Error(S(280));var n=e.stateNode;n&&(n=Ri(n),Ol(e.stateNode,e.type,n))}}function uu(e){xt?wt?wt.push(e):wt=[e]:xt=e}function cu(){if(xt){var e=xt,n=wt;if(wt=xt=null,Pa(e),n)for(e=0;e<n.length;e++)Pa(n[e])}}function du(e,n){return e(n)}function fu(){}var qi=!1;function pu(e,n,t){if(qi)return e(n,t);qi=!0;try{return du(e,n,t)}finally{qi=!1,(xt!==null||wt!==null)&&(fu(),cu())}}function lr(e,n){var t=e.stateNode;if(t===null)return null;var r=Ri(t);if(r===null)return null;t=r[n];e:switch(n){case"onClick":case"onClickCapture":case"onDoubleClick":case"onDoubleClickCapture":case"onMouseDown":case"onMouseDownCapture":case"onMouseMove":case"onMouseMoveCapture":case"onMouseUp":case"onMouseUpCapture":case"onMouseEnter":(r=!r.disabled)||(e=e.type,r=!(e==="button"||e==="input"||e==="select"||e==="textarea")),e=!r;break e;default:e=!1}if(e)return null;if(t&&typeof t!="function")throw Error(S(231,n,typeof t));return t}var Al=!1;if(mn)try{var Rt={};Object.defineProperty(Rt,"passive",{get:function(){Al=!0}}),window.addEventListener("test",Rt,Rt),window.removeEventListener("test",Rt,Rt)}catch{Al=!1}function Hd(e,n,t,r,i,l,o,a,u){var d=Array.prototype.slice.call(arguments,3);try{n.apply(t,d)}catch(v){this.onError(v)}}var Gt=!1,oi=null,ai=!1,Il=null,Vd={onError:function(e){Gt=!0,oi=e}};function Qd(e,n,t,r,i,l,o,a,u){Gt=!1,oi=null,Hd.apply(Vd,arguments)}function Kd(e,n,t,r,i,l,o,a,u){if(Qd.apply(this,arguments),Gt){if(Gt){var d=oi;Gt=!1,oi=null}else throw Error(S(198));ai||(ai=!0,Il=d)}}function et(e){var n=e,t=e;if(e.alternate)for(;n.return;)n=n.return;else{e=n;do n=e,n.flags&4098&&(t=n.return),e=n.return;while(e)}return n.tag===3?t:null}function mu(e){if(e.tag===13){var n=e.memoizedState;if(n===null&&(e=e.alternate,e!==null&&(n=e.memoizedState)),n!==null)return n.dehydrated}return null}function Na(e){if(et(e)!==e)throw Error(S(188))}function Gd(e){var n=e.alternate;if(!n){if(n=et(e),n===null)throw Error(S(188));return n!==e?null:e}for(var t=e,r=n;;){var i=t.return;if(i===null)break;var l=i.alternate;if(l===null){if(r=i.return,r!==null){t=r;continue}break}if(i.child===l.child){for(l=i.child;l;){if(l===t)return Na(i),e;if(l===r)return Na(i),n;l=l.sibling}throw Error(S(188))}if(t.return!==r.return)t=i,r=l;else{for(var o=!1,a=i.child;a;){if(a===t){o=!0,t=i,r=l;break}if(a===r){o=!0,r=i,t=l;break}a=a.sibling}if(!o){for(a=l.child;a;){if(a===t){o=!0,t=l,r=i;break}if(a===r){o=!0,r=l,t=i;break}a=a.sibling}if(!o)throw Error(S(189))}}if(t.alternate!==r)throw Error(S(190))}if(t.tag!==3)throw Error(S(188));return t.stateNode.current===t?e:n}function hu(e){return e=Gd(e),e!==null?gu(e):null}function gu(e){if(e.tag===5||e.tag===6)return e;for(e=e.child;e!==null;){var n=gu(e);if(n!==null)return n;e=e.sibling}return null}var vu=Oe.unstable_scheduleCallback,Fa=Oe.unstable_cancelCallback,Yd=Oe.unstable_shouldYield,Xd=Oe.unstable_requestPaint,te=Oe.unstable_now,Zd=Oe.unstable_getCurrentPriorityLevel,No=Oe.unstable_ImmediatePriority,yu=Oe.unstable_UserBlockingPriority,si=Oe.unstable_NormalPriority,qd=Oe.unstable_LowPriority,xu=Oe.unstable_IdlePriority,Ti=null,on=null;function Jd(e){if(on&&typeof on.onCommitFiberRoot=="function")try{on.onCommitFiberRoot(Ti,e,void 0,(e.current.flags&128)===128)}catch{}}var qe=Math.clz32?Math.clz32:tf,ef=Math.log,nf=Math.LN2;function tf(e){return e>>>=0,e===0?32:31-(ef(e)/nf|0)|0}var Tr=64,jr=4194304;function Ht(e){switch(e&-e){case 1:return 1;case 2:return 2;case 4:return 4;case 8:return 8;case 16:return 16;case 32:return 32;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return e&4194240;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return e&130023424;case 134217728:return 134217728;case 268435456:return 268435456;case 536870912:return 536870912;case 1073741824:return 1073741824;default:return e}}function ui(e,n){var t=e.pendingLanes;if(t===0)return 0;var r=0,i=e.suspendedLanes,l=e.pingedLanes,o=t&268435455;if(o!==0){var a=o&~i;a!==0?r=Ht(a):(l&=o,l!==0&&(r=Ht(l)))}else o=t&~i,o!==0?r=Ht(o):l!==0&&(r=Ht(l));if(r===0)return 0;if(n!==0&&n!==r&&!(n&i)&&(i=r&-r,l=n&-n,i>=l||i===16&&(l&4194240)!==0))return n;if(r&4&&(r|=t&16),n=e.entangledLanes,n!==0)for(e=e.entanglements,n&=r;0<n;)t=31-qe(n),i=1<<t,r|=e[t],n&=~i;return r}function rf(e,n){switch(e){case 1:case 2:case 4:return n+250;case 8:case 16:case 32:case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return n+5e3;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return-1;case 134217728:case 268435456:case 536870912:case 1073741824:return-1;default:return-1}}function lf(e,n){for(var t=e.suspendedLanes,r=e.pingedLanes,i=e.expirationTimes,l=e.pendingLanes;0<l;){var o=31-qe(l),a=1<<o,u=i[o];u===-1?(!(a&t)||a&r)&&(i[o]=rf(a,n)):u<=n&&(e.expiredLanes|=a),l&=~a}}function Ul(e){return e=e.pendingLanes&-1073741825,e!==0?e:e&1073741824?1073741824:0}function wu(){var e=Tr;return Tr<<=1,!(Tr&4194240)&&(Tr=64),e}function Ji(e){for(var n=[],t=0;31>t;t++)n.push(e);return n}function _r(e,n,t){e.pendingLanes|=n,n!==536870912&&(e.suspendedLanes=0,e.pingedLanes=0),e=e.eventTimes,n=31-qe(n),e[n]=t}function of(e,n){var t=e.pendingLanes&~n;e.pendingLanes=n,e.suspendedLanes=0,e.pingedLanes=0,e.expiredLanes&=n,e.mutableReadLanes&=n,e.entangledLanes&=n,n=e.entanglements;var r=e.eventTimes;for(e=e.expirationTimes;0<t;){var i=31-qe(t),l=1<<i;n[i]=0,r[i]=-1,e[i]=-1,t&=~l}}function Fo(e,n){var t=e.entangledLanes|=n;for(e=e.entanglements;t;){var r=31-qe(t),i=1<<r;i&n|e[r]&n&&(e[r]|=n),t&=~i}}var V=0;function ku(e){return e&=-e,1<e?4<e?e&268435455?16:536870912:4:1}var _u,To,Su,Cu,Eu,Bl=!1,zr=[],bn=null,$n=null,Pn=null,or=new Map,ar=new Map,_n=[],af="mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(" ");function Ta(e,n){switch(e){case"focusin":case"focusout":bn=null;break;case"dragenter":case"dragleave":$n=null;break;case"mouseover":case"mouseout":Pn=null;break;case"pointerover":case"pointerout":or.delete(n.pointerId);break;case"gotpointercapture":case"lostpointercapture":ar.delete(n.pointerId)}}function Mt(e,n,t,r,i,l){return e===null||e.nativeEvent!==l?(e={blockedOn:n,domEventName:t,eventSystemFlags:r,nativeEvent:l,targetContainers:[i]},n!==null&&(n=Cr(n),n!==null&&To(n)),e):(e.eventSystemFlags|=r,n=e.targetContainers,i!==null&&n.indexOf(i)===-1&&n.push(i),e)}function sf(e,n,t,r,i){switch(n){case"focusin":return bn=Mt(bn,e,n,t,r,i),!0;case"dragenter":return $n=Mt($n,e,n,t,r,i),!0;case"mouseover":return Pn=Mt(Pn,e,n,t,r,i),!0;case"pointerover":var l=i.pointerId;return or.set(l,Mt(or.get(l)||null,e,n,t,r,i)),!0;case"gotpointercapture":return l=i.pointerId,ar.set(l,Mt(ar.get(l)||null,e,n,t,r,i)),!0}return!1}function bu(e){var n=Wn(e.target);if(n!==null){var t=et(n);if(t!==null){if(n=t.tag,n===13){if(n=mu(t),n!==null){e.blockedOn=n,Eu(e.priority,function(){Su(t)});return}}else if(n===3&&t.stateNode.current.memoizedState.isDehydrated){e.blockedOn=t.tag===3?t.stateNode.containerInfo:null;return}}}e.blockedOn=null}function Gr(e){if(e.blockedOn!==null)return!1;for(var n=e.targetContainers;0<n.length;){var t=Wl(e.domEventName,e.eventSystemFlags,n[0],e.nativeEvent);if(t===null){t=e.nativeEvent;var r=new t.constructor(t.type,t);Dl=r,t.target.dispatchEvent(r),Dl=null}else return n=Cr(t),n!==null&&To(n),e.blockedOn=t,!1;n.shift()}return!0}function ja(e,n,t){Gr(e)&&t.delete(n)}function uf(){Bl=!1,bn!==null&&Gr(bn)&&(bn=null),$n!==null&&Gr($n)&&($n=null),Pn!==null&&Gr(Pn)&&(Pn=null),or.forEach(ja),ar.forEach(ja)}function Dt(e,n){e.blockedOn===n&&(e.blockedOn=null,Bl||(Bl=!0,Oe.unstable_scheduleCallback(Oe.unstable_NormalPriority,uf)))}function sr(e){function n(i){return Dt(i,e)}if(0<zr.length){Dt(zr[0],e);for(var t=1;t<zr.length;t++){var r=zr[t];r.blockedOn===e&&(r.blockedOn=null)}}for(bn!==null&&Dt(bn,e),$n!==null&&Dt($n,e),Pn!==null&&Dt(Pn,e),or.forEach(n),ar.forEach(n),t=0;t<_n.length;t++)r=_n[t],r.blockedOn===e&&(r.blockedOn=null);for(;0<_n.length&&(t=_n[0],t.blockedOn===null);)bu(t),t.blockedOn===null&&_n.shift()}var kt=yn.ReactCurrentBatchConfig,ci=!0;function cf(e,n,t,r){var i=V,l=kt.transition;kt.transition=null;try{V=1,jo(e,n,t,r)}finally{V=i,kt.transition=l}}function df(e,n,t,r){var i=V,l=kt.transition;kt.transition=null;try{V=4,jo(e,n,t,r)}finally{V=i,kt.transition=l}}function jo(e,n,t,r){if(ci){var i=Wl(e,n,t,r);if(i===null)ul(e,n,r,di,t),Ta(e,r);else if(sf(i,e,n,t,r))r.stopPropagation();else if(Ta(e,r),n&4&&-1<af.indexOf(e)){for(;i!==null;){var l=Cr(i);if(l!==null&&_u(l),l=Wl(e,n,t,r),l===null&&ul(e,n,r,di,t),l===i)break;i=l}i!==null&&r.stopPropagation()}else ul(e,n,r,null,t)}}var di=null;function Wl(e,n,t,r){if(di=null,e=Po(r),e=Wn(e),e!==null)if(n=et(e),n===null)e=null;else if(t=n.tag,t===13){if(e=mu(n),e!==null)return e;e=null}else if(t===3){if(n.stateNode.current.memoizedState.isDehydrated)return n.tag===3?n.stateNode.containerInfo:null;e=null}else n!==e&&(e=null);return di=e,null}function $u(e){switch(e){case"cancel":case"click":case"close":case"contextmenu":case"copy":case"cut":case"auxclick":case"dblclick":case"dragend":case"dragstart":case"drop":case"focusin":case"focusout":case"input":case"invalid":case"keydown":case"keypress":case"keyup":case"mousedown":case"mouseup":case"paste":case"pause":case"play":case"pointercancel":case"pointerdown":case"pointerup":case"ratechange":case"reset":case"resize":case"seeked":case"submit":case"touchcancel":case"touchend":case"touchstart":case"volumechange":case"change":case"selectionchange":case"textInput":case"compositionstart":case"compositionend":case"compositionupdate":case"beforeblur":case"afterblur":case"beforeinput":case"blur":case"fullscreenchange":case"focus":case"hashchange":case"popstate":case"select":case"selectstart":return 1;case"drag":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"mousemove":case"mouseout":case"mouseover":case"pointermove":case"pointerout":case"pointerover":case"scroll":case"toggle":case"touchmove":case"wheel":case"mouseenter":case"mouseleave":case"pointerenter":case"pointerleave":return 4;case"message":switch(Zd()){case No:return 1;case yu:return 4;case si:case qd:return 16;case xu:return 536870912;default:return 16}default:return 16}}var Cn=null,zo=null,Yr=null;function Pu(){if(Yr)return Yr;var e,n=zo,t=n.length,r,i="value"in Cn?Cn.value:Cn.textContent,l=i.length;for(e=0;e<t&&n[e]===i[e];e++);var o=t-e;for(r=1;r<=o&&n[t-r]===i[l-r];r++);return Yr=i.slice(e,1<r?1-r:void 0)}function Xr(e){var n=e.keyCode;return"charCode"in e?(e=e.charCode,e===0&&n===13&&(e=13)):e=n,e===10&&(e=13),32<=e||e===13?e:0}function Lr(){return!0}function za(){return!1}function Ie(e){function n(t,r,i,l,o){this._reactName=t,this._targetInst=i,this.type=r,this.nativeEvent=l,this.target=o,this.currentTarget=null;for(var a in e)e.hasOwnProperty(a)&&(t=e[a],this[a]=t?t(l):l[a]);return this.isDefaultPrevented=(l.defaultPrevented!=null?l.defaultPrevented:l.returnValue===!1)?Lr:za,this.isPropagationStopped=za,this}return ee(n.prototype,{preventDefault:function(){this.defaultPrevented=!0;var t=this.nativeEvent;t&&(t.preventDefault?t.preventDefault():typeof t.returnValue!="unknown"&&(t.returnValue=!1),this.isDefaultPrevented=Lr)},stopPropagation:function(){var t=this.nativeEvent;t&&(t.stopPropagation?t.stopPropagation():typeof t.cancelBubble!="unknown"&&(t.cancelBubble=!0),this.isPropagationStopped=Lr)},persist:function(){},isPersistent:Lr}),n}var jt={eventPhase:0,bubbles:0,cancelable:0,timeStamp:function(e){return e.timeStamp||Date.now()},defaultPrevented:0,isTrusted:0},Lo=Ie(jt),Sr=ee({},jt,{view:0,detail:0}),ff=Ie(Sr),el,nl,Ot,ji=ee({},Sr,{screenX:0,screenY:0,clientX:0,clientY:0,pageX:0,pageY:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,getModifierState:Ro,button:0,buttons:0,relatedTarget:function(e){return e.relatedTarget===void 0?e.fromElement===e.srcElement?e.toElement:e.fromElement:e.relatedTarget},movementX:function(e){return"movementX"in e?e.movementX:(e!==Ot&&(Ot&&e.type==="mousemove"?(el=e.screenX-Ot.screenX,nl=e.screenY-Ot.screenY):nl=el=0,Ot=e),el)},movementY:function(e){return"movementY"in e?e.movementY:nl}}),La=Ie(ji),pf=ee({},ji,{dataTransfer:0}),mf=Ie(pf),hf=ee({},Sr,{relatedTarget:0}),tl=Ie(hf),gf=ee({},jt,{animationName:0,elapsedTime:0,pseudoElement:0}),vf=Ie(gf),yf=ee({},jt,{clipboardData:function(e){return"clipboardData"in e?e.clipboardData:window.clipboardData}}),xf=Ie(yf),wf=ee({},jt,{data:0}),Ra=Ie(wf),kf={Esc:"Escape",Spacebar:" ",Left:"ArrowLeft",Up:"ArrowUp",Right:"ArrowRight",Down:"ArrowDown",Del:"Delete",Win:"OS",Menu:"ContextMenu",Apps:"ContextMenu",Scroll:"ScrollLock",MozPrintableKey:"Unidentified"},_f={8:"Backspace",9:"Tab",12:"Clear",13:"Enter",16:"Shift",17:"Control",18:"Alt",19:"Pause",20:"CapsLock",27:"Escape",32:" ",33:"PageUp",34:"PageDown",35:"End",36:"Home",37:"ArrowLeft",38:"ArrowUp",39:"ArrowRight",40:"ArrowDown",45:"Insert",46:"Delete",112:"F1",113:"F2",114:"F3",115:"F4",116:"F5",117:"F6",118:"F7",119:"F8",120:"F9",121:"F10",122:"F11",123:"F12",144:"NumLock",145:"ScrollLock",224:"Meta"},Sf={Alt:"altKey",Control:"ctrlKey",Meta:"metaKey",Shift:"shiftKey"};function Cf(e){var n=this.nativeEvent;return n.getModifierState?n.getModifierState(e):(e=Sf[e])?!!n[e]:!1}function Ro(){return Cf}var Ef=ee({},Sr,{key:function(e){if(e.key){var n=kf[e.key]||e.key;if(n!=="Unidentified")return n}return e.type==="keypress"?(e=Xr(e),e===13?"Enter":String.fromCharCode(e)):e.type==="keydown"||e.type==="keyup"?_f[e.keyCode]||"Unidentified":""},code:0,location:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,repeat:0,locale:0,getModifierState:Ro,charCode:function(e){return e.type==="keypress"?Xr(e):0},keyCode:function(e){return e.type==="keydown"||e.type==="keyup"?e.keyCode:0},which:function(e){return e.type==="keypress"?Xr(e):e.type==="keydown"||e.type==="keyup"?e.keyCode:0}}),bf=Ie(Ef),$f=ee({},ji,{pointerId:0,width:0,height:0,pressure:0,tangentialPressure:0,tiltX:0,tiltY:0,twist:0,pointerType:0,isPrimary:0}),Ma=Ie($f),Pf=ee({},Sr,{touches:0,targetTouches:0,changedTouches:0,altKey:0,metaKey:0,ctrlKey:0,shiftKey:0,getModifierState:Ro}),Nf=Ie(Pf),Ff=ee({},jt,{propertyName:0,elapsedTime:0,pseudoElement:0}),Tf=Ie(Ff),jf=ee({},ji,{deltaX:function(e){return"deltaX"in e?e.deltaX:"wheelDeltaX"in e?-e.wheelDeltaX:0},deltaY:function(e){return"deltaY"in e?e.deltaY:"wheelDeltaY"in e?-e.wheelDeltaY:"wheelDelta"in e?-e.wheelDelta:0},deltaZ:0,deltaMode:0}),zf=Ie(jf),Lf=[9,13,27,32],Mo=mn&&"CompositionEvent"in window,Yt=null;mn&&"documentMode"in document&&(Yt=document.documentMode);var Rf=mn&&"TextEvent"in window&&!Yt,Nu=mn&&(!Mo||Yt&&8<Yt&&11>=Yt),Da=" ",Oa=!1;function Fu(e,n){switch(e){case"keyup":return Lf.indexOf(n.keyCode)!==-1;case"keydown":return n.keyCode!==229;case"keypress":case"mousedown":case"focusout":return!0;default:return!1}}function Tu(e){return e=e.detail,typeof e=="object"&&"data"in e?e.data:null}var at=!1;function Mf(e,n){switch(e){case"compositionend":return Tu(n);case"keypress":return n.which!==32?null:(Oa=!0,Da);case"textInput":return e=n.data,e===Da&&Oa?null:e;default:return null}}function Df(e,n){if(at)return e==="compositionend"||!Mo&&Fu(e,n)?(e=Pu(),Yr=zo=Cn=null,at=!1,e):null;switch(e){case"paste":return null;case"keypress":if(!(n.ctrlKey||n.altKey||n.metaKey)||n.ctrlKey&&n.altKey){if(n.char&&1<n.char.length)return n.char;if(n.which)return String.fromCharCode(n.which)}return null;case"compositionend":return Nu&&n.locale!=="ko"?null:n.data;default:return null}}var Of={color:!0,date:!0,datetime:!0,"datetime-local":!0,email:!0,month:!0,number:!0,password:!0,range:!0,search:!0,tel:!0,text:!0,time:!0,url:!0,week:!0};function Aa(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n==="input"?!!Of[e.type]:n==="textarea"}function ju(e,n,t,r){uu(r),n=fi(n,"onChange"),0<n.length&&(t=new Lo("onChange","change",null,t,r),e.push({event:t,listeners:n}))}var Xt=null,ur=null;function Af(e){Wu(e,0)}function zi(e){var n=ct(e);if(tu(n))return e}function If(e,n){if(e==="change")return n}var zu=!1;if(mn){var rl;if(mn){var il="oninput"in document;if(!il){var Ia=document.createElement("div");Ia.setAttribute("oninput","return;"),il=typeof Ia.oninput=="function"}rl=il}else rl=!1;zu=rl&&(!document.documentMode||9<document.documentMode)}function Ua(){Xt&&(Xt.detachEvent("onpropertychange",Lu),ur=Xt=null)}function Lu(e){if(e.propertyName==="value"&&zi(ur)){var n=[];ju(n,ur,e,Po(e)),pu(Af,n)}}function Uf(e,n,t){e==="focusin"?(Ua(),Xt=n,ur=t,Xt.attachEvent("onpropertychange",Lu)):e==="focusout"&&Ua()}function Bf(e){if(e==="selectionchange"||e==="keyup"||e==="keydown")return zi(ur)}function Wf(e,n){if(e==="click")return zi(n)}function Hf(e,n){if(e==="input"||e==="change")return zi(n)}function Vf(e,n){return e===n&&(e!==0||1/e===1/n)||e!==e&&n!==n}var en=typeof Object.is=="function"?Object.is:Vf;function cr(e,n){if(en(e,n))return!0;if(typeof e!="object"||e===null||typeof n!="object"||n===null)return!1;var t=Object.keys(e),r=Object.keys(n);if(t.length!==r.length)return!1;for(r=0;r<t.length;r++){var i=t[r];if(!El.call(n,i)||!en(e[i],n[i]))return!1}return!0}function Ba(e){for(;e&&e.firstChild;)e=e.firstChild;return e}function Wa(e,n){var t=Ba(e);e=0;for(var r;t;){if(t.nodeType===3){if(r=e+t.textContent.length,e<=n&&r>=n)return{node:t,offset:n-e};e=r}e:{for(;t;){if(t.nextSibling){t=t.nextSibling;break e}t=t.parentNode}t=void 0}t=Ba(t)}}function Ru(e,n){return e&&n?e===n?!0:e&&e.nodeType===3?!1:n&&n.nodeType===3?Ru(e,n.parentNode):"contains"in e?e.contains(n):e.compareDocumentPosition?!!(e.compareDocumentPosition(n)&16):!1:!1}function Mu(){for(var e=window,n=li();n instanceof e.HTMLIFrameElement;){try{var t=typeof n.contentWindow.location.href=="string"}catch{t=!1}if(t)e=n.contentWindow;else break;n=li(e.document)}return n}function Do(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n&&(n==="input"&&(e.type==="text"||e.type==="search"||e.type==="tel"||e.type==="url"||e.type==="password")||n==="textarea"||e.contentEditable==="true")}function Qf(e){var n=Mu(),t=e.focusedElem,r=e.selectionRange;if(n!==t&&t&&t.ownerDocument&&Ru(t.ownerDocument.documentElement,t)){if(r!==null&&Do(t)){if(n=r.start,e=r.end,e===void 0&&(e=n),"selectionStart"in t)t.selectionStart=n,t.selectionEnd=Math.min(e,t.value.length);else if(e=(n=t.ownerDocument||document)&&n.defaultView||window,e.getSelection){e=e.getSelection();var i=t.textContent.length,l=Math.min(r.start,i);r=r.end===void 0?l:Math.min(r.end,i),!e.extend&&l>r&&(i=r,r=l,l=i),i=Wa(t,l);var o=Wa(t,r);i&&o&&(e.rangeCount!==1||e.anchorNode!==i.node||e.anchorOffset!==i.offset||e.focusNode!==o.node||e.focusOffset!==o.offset)&&(n=n.createRange(),n.setStart(i.node,i.offset),e.removeAllRanges(),l>r?(e.addRange(n),e.extend(o.node,o.offset)):(n.setEnd(o.node,o.offset),e.addRange(n)))}}for(n=[],e=t;e=e.parentNode;)e.nodeType===1&&n.push({element:e,left:e.scrollLeft,top:e.scrollTop});for(typeof t.focus=="function"&&t.focus(),t=0;t<n.length;t++)e=n[t],e.element.scrollLeft=e.left,e.element.scrollTop=e.top}}var Kf=mn&&"documentMode"in document&&11>=document.documentMode,st=null,Hl=null,Zt=null,Vl=!1;function Ha(e,n,t){var r=t.window===t?t.document:t.nodeType===9?t:t.ownerDocument;Vl||st==null||st!==li(r)||(r=st,"selectionStart"in r&&Do(r)?r={start:r.selectionStart,end:r.selectionEnd}:(r=(r.ownerDocument&&r.ownerDocument.defaultView||window).getSelection(),r={anchorNode:r.anchorNode,anchorOffset:r.anchorOffset,focusNode:r.focusNode,focusOffset:r.focusOffset}),Zt&&cr(Zt,r)||(Zt=r,r=fi(Hl,"onSelect"),0<r.length&&(n=new Lo("onSelect","select",null,n,t),e.push({event:n,listeners:r}),n.target=st)))}function Rr(e,n){var t={};return t[e.toLowerCase()]=n.toLowerCase(),t["Webkit"+e]="webkit"+n,t["Moz"+e]="moz"+n,t}var ut={animationend:Rr("Animation","AnimationEnd"),animationiteration:Rr("Animation","AnimationIteration"),animationstart:Rr("Animation","AnimationStart"),transitionend:Rr("Transition","TransitionEnd")},ll={},Du={};mn&&(Du=document.createElement("div").style,"AnimationEvent"in window||(delete ut.animationend.animation,delete ut.animationiteration.animation,delete ut.animationstart.animation),"TransitionEvent"in window||delete ut.transitionend.transition);function Li(e){if(ll[e])return ll[e];if(!ut[e])return e;var n=ut[e],t;for(t in n)if(n.hasOwnProperty(t)&&t in Du)return ll[e]=n[t];return e}var Ou=Li("animationend"),Au=Li("animationiteration"),Iu=Li("animationstart"),Uu=Li("transitionend"),Bu=new Map,Va="abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(" ");function Dn(e,n){Bu.set(e,n),Jn(n,[e])}for(var ol=0;ol<Va.length;ol++){var al=Va[ol],Gf=al.toLowerCase(),Yf=al[0].toUpperCase()+al.slice(1);Dn(Gf,"on"+Yf)}Dn(Ou,"onAnimationEnd");Dn(Au,"onAnimationIteration");Dn(Iu,"onAnimationStart");Dn("dblclick","onDoubleClick");Dn("focusin","onFocus");Dn("focusout","onBlur");Dn(Uu,"onTransitionEnd");Ct("onMouseEnter",["mouseout","mouseover"]);Ct("onMouseLeave",["mouseout","mouseover"]);Ct("onPointerEnter",["pointerout","pointerover"]);Ct("onPointerLeave",["pointerout","pointerover"]);Jn("onChange","change click focusin focusout input keydown keyup selectionchange".split(" "));Jn("onSelect","focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(" "));Jn("onBeforeInput",["compositionend","keypress","textInput","paste"]);Jn("onCompositionEnd","compositionend focusout keydown keypress keyup mousedown".split(" "));Jn("onCompositionStart","compositionstart focusout keydown keypress keyup mousedown".split(" "));Jn("onCompositionUpdate","compositionupdate focusout keydown keypress keyup mousedown".split(" "));var Vt="abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(" "),Xf=new Set("cancel close invalid load scroll toggle".split(" ").concat(Vt));function Qa(e,n,t){var r=e.type||"unknown-event";e.currentTarget=t,Kd(r,n,void 0,e),e.currentTarget=null}function Wu(e,n){n=(n&4)!==0;for(var t=0;t<e.length;t++){var r=e[t],i=r.event;r=r.listeners;e:{var l=void 0;if(n)for(var o=r.length-1;0<=o;o--){var a=r[o],u=a.instance,d=a.currentTarget;if(a=a.listener,u!==l&&i.isPropagationStopped())break e;Qa(i,a,d),l=u}else for(o=0;o<r.length;o++){if(a=r[o],u=a.instance,d=a.currentTarget,a=a.listener,u!==l&&i.isPropagationStopped())break e;Qa(i,a,d),l=u}}}if(ai)throw e=Il,ai=!1,Il=null,e}function G(e,n){var t=n[Xl];t===void 0&&(t=n[Xl]=new Set);var r=e+"__bubble";t.has(r)||(Hu(n,e,2,!1),t.add(r))}function sl(e,n,t){var r=0;n&&(r|=4),Hu(t,e,r,n)}var Mr="_reactListening"+Math.random().toString(36).slice(2);function dr(e){if(!e[Mr]){e[Mr]=!0,Zs.forEach(function(t){t!=="selectionchange"&&(Xf.has(t)||sl(t,!1,e),sl(t,!0,e))});var n=e.nodeType===9?e:e.ownerDocument;n===null||n[Mr]||(n[Mr]=!0,sl("selectionchange",!1,n))}}function Hu(e,n,t,r){switch($u(n)){case 1:var i=cf;break;case 4:i=df;break;default:i=jo}t=i.bind(null,n,t,e),i=void 0,!Al||n!=="touchstart"&&n!=="touchmove"&&n!=="wheel"||(i=!0),r?i!==void 0?e.addEventListener(n,t,{capture:!0,passive:i}):e.addEventListener(n,t,!0):i!==void 0?e.addEventListener(n,t,{passive:i}):e.addEventListener(n,t,!1)}function ul(e,n,t,r,i){var l=r;if(!(n&1)&&!(n&2)&&r!==null)e:for(;;){if(r===null)return;var o=r.tag;if(o===3||o===4){var a=r.stateNode.containerInfo;if(a===i||a.nodeType===8&&a.parentNode===i)break;if(o===4)for(o=r.return;o!==null;){var u=o.tag;if((u===3||u===4)&&(u=o.stateNode.containerInfo,u===i||u.nodeType===8&&u.parentNode===i))return;o=o.return}for(;a!==null;){if(o=Wn(a),o===null)return;if(u=o.tag,u===5||u===6){r=l=o;continue e}a=a.parentNode}}r=r.return}pu(function(){var d=l,v=Po(t),m=[];e:{var p=Bu.get(e);if(p!==void 0){var g=Lo,x=e;switch(e){case"keypress":if(Xr(t)===0)break e;case"keydown":case"keyup":g=bf;break;case"focusin":x="focus",g=tl;break;case"focusout":x="blur",g=tl;break;case"beforeblur":case"afterblur":g=tl;break;case"click":if(t.button===2)break e;case"auxclick":case"dblclick":case"mousedown":case"mousemove":case"mouseup":case"mouseout":case"mouseover":case"contextmenu":g=La;break;case"drag":case"dragend":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"dragstart":case"drop":g=mf;break;case"touchcancel":case"touchend":case"touchmove":case"touchstart":g=Nf;break;case Ou:case Au:case Iu:g=vf;break;case Uu:g=Tf;break;case"scroll":g=ff;break;case"wheel":g=zf;break;case"copy":case"cut":case"paste":g=xf;break;case"gotpointercapture":case"lostpointercapture":case"pointercancel":case"pointerdown":case"pointermove":case"pointerout":case"pointerover":case"pointerup":g=Ma}var w=(n&4)!==0,z=!w&&e==="scroll",c=w?p!==null?p+"Capture":null:p;w=[];for(var s=d,f;s!==null;){f=s;var h=f.stateNode;if(f.tag===5&&h!==null&&(f=h,c!==null&&(h=lr(s,c),h!=null&&w.push(fr(s,h,f)))),z)break;s=s.return}0<w.length&&(p=new g(p,x,null,t,v),m.push({event:p,listeners:w}))}}if(!(n&7)){e:{if(p=e==="mouseover"||e==="pointerover",g=e==="mouseout"||e==="pointerout",p&&t!==Dl&&(x=t.relatedTarget||t.fromElement)&&(Wn(x)||x[hn]))break e;if((g||p)&&(p=v.window===v?v:(p=v.ownerDocument)?p.defaultView||p.parentWindow:window,g?(x=t.relatedTarget||t.toElement,g=d,x=x?Wn(x):null,x!==null&&(z=et(x),x!==z||x.tag!==5&&x.tag!==6)&&(x=null)):(g=null,x=d),g!==x)){if(w=La,h="onMouseLeave",c="onMouseEnter",s="mouse",(e==="pointerout"||e==="pointerover")&&(w=Ma,h="onPointerLeave",c="onPointerEnter",s="pointer"),z=g==null?p:ct(g),f=x==null?p:ct(x),p=new w(h,s+"leave",g,t,v),p.target=z,p.relatedTarget=f,h=null,Wn(v)===d&&(w=new w(c,s+"enter",x,t,v),w.target=f,w.relatedTarget=z,h=w),z=h,g&&x)n:{for(w=g,c=x,s=0,f=w;f;f=it(f))s++;for(f=0,h=c;h;h=it(h))f++;for(;0<s-f;)w=it(w),s--;for(;0<f-s;)c=it(c),f--;for(;s--;){if(w===c||c!==null&&w===c.alternate)break n;w=it(w),c=it(c)}w=null}else w=null;g!==null&&Ka(m,p,g,w,!1),x!==null&&z!==null&&Ka(m,z,x,w,!0)}}e:{if(p=d?ct(d):window,g=p.nodeName&&p.nodeName.toLowerCase(),g==="select"||g==="input"&&p.type==="file")var _=If;else if(Aa(p))if(zu)_=Hf;else{_=Bf;var C=Uf}else(g=p.nodeName)&&g.toLowerCase()==="input"&&(p.type==="checkbox"||p.type==="radio")&&(_=Wf);if(_&&(_=_(e,d))){ju(m,_,t,v);break e}C&&C(e,p,d),e==="focusout"&&(C=p._wrapperState)&&C.controlled&&p.type==="number"&&jl(p,"number",p.value)}switch(C=d?ct(d):window,e){case"focusin":(Aa(C)||C.contentEditable==="true")&&(st=C,Hl=d,Zt=null);break;case"focusout":Zt=Hl=st=null;break;case"mousedown":Vl=!0;break;case"contextmenu":case"mouseup":case"dragend":Vl=!1,Ha(m,t,v);break;case"selectionchange":if(Kf)break;case"keydown":case"keyup":Ha(m,t,v)}var b;if(Mo)e:{switch(e){case"compositionstart":var E="onCompositionStart";break e;case"compositionend":E="onCompositionEnd";break e;case"compositionupdate":E="onCompositionUpdate";break e}E=void 0}else at?Fu(e,t)&&(E="onCompositionEnd"):e==="keydown"&&t.keyCode===229&&(E="onCompositionStart");E&&(Nu&&t.locale!=="ko"&&(at||E!=="onCompositionStart"?E==="onCompositionEnd"&&at&&(b=Pu()):(Cn=v,zo="value"in Cn?Cn.value:Cn.textContent,at=!0)),C=fi(d,E),0<C.length&&(E=new Ra(E,e,null,t,v),m.push({event:E,listeners:C}),b?E.data=b:(b=Tu(t),b!==null&&(E.data=b)))),(b=Rf?Mf(e,t):Df(e,t))&&(d=fi(d,"onBeforeInput"),0<d.length&&(v=new Ra("onBeforeInput","beforeinput",null,t,v),m.push({event:v,listeners:d}),v.data=b))}Wu(m,n)})}function fr(e,n,t){return{instance:e,listener:n,currentTarget:t}}function fi(e,n){for(var t=n+"Capture",r=[];e!==null;){var i=e,l=i.stateNode;i.tag===5&&l!==null&&(i=l,l=lr(e,t),l!=null&&r.unshift(fr(e,l,i)),l=lr(e,n),l!=null&&r.push(fr(e,l,i))),e=e.return}return r}function it(e){if(e===null)return null;do e=e.return;while(e&&e.tag!==5);return e||null}function Ka(e,n,t,r,i){for(var l=n._reactName,o=[];t!==null&&t!==r;){var a=t,u=a.alternate,d=a.stateNode;if(u!==null&&u===r)break;a.tag===5&&d!==null&&(a=d,i?(u=lr(t,l),u!=null&&o.unshift(fr(t,u,a))):i||(u=lr(t,l),u!=null&&o.push(fr(t,u,a)))),t=t.return}o.length!==0&&e.push({event:n,listeners:o})}var Zf=/\r\n?/g,qf=/\u0000|\uFFFD/g;function Ga(e){return(typeof e=="string"?e:""+e).replace(Zf,`
`).replace(qf,"")}function Dr(e,n,t){if(n=Ga(n),Ga(e)!==n&&t)throw Error(S(425))}function pi(){}var Ql=null,Kl=null;function Gl(e,n){return e==="textarea"||e==="noscript"||typeof n.children=="string"||typeof n.children=="number"||typeof n.dangerouslySetInnerHTML=="object"&&n.dangerouslySetInnerHTML!==null&&n.dangerouslySetInnerHTML.__html!=null}var Yl=typeof setTimeout=="function"?setTimeout:void 0,Jf=typeof clearTimeout=="function"?clearTimeout:void 0,Ya=typeof Promise=="function"?Promise:void 0,ep=typeof queueMicrotask=="function"?queueMicrotask:typeof Ya<"u"?function(e){return Ya.resolve(null).then(e).catch(np)}:Yl;function np(e){setTimeout(function(){throw e})}function cl(e,n){var t=n,r=0;do{var i=t.nextSibling;if(e.removeChild(t),i&&i.nodeType===8)if(t=i.data,t==="/$"){if(r===0){e.removeChild(i),sr(n);return}r--}else t!=="$"&&t!=="$?"&&t!=="$!"||r++;t=i}while(t);sr(n)}function Nn(e){for(;e!=null;e=e.nextSibling){var n=e.nodeType;if(n===1||n===3)break;if(n===8){if(n=e.data,n==="$"||n==="$!"||n==="$?")break;if(n==="/$")return null}}return e}function Xa(e){e=e.previousSibling;for(var n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="$"||t==="$!"||t==="$?"){if(n===0)return e;n--}else t==="/$"&&n++}e=e.previousSibling}return null}var zt=Math.random().toString(36).slice(2),ln="__reactFiber$"+zt,pr="__reactProps$"+zt,hn="__reactContainer$"+zt,Xl="__reactEvents$"+zt,tp="__reactListeners$"+zt,rp="__reactHandles$"+zt;function Wn(e){var n=e[ln];if(n)return n;for(var t=e.parentNode;t;){if(n=t[hn]||t[ln]){if(t=n.alternate,n.child!==null||t!==null&&t.child!==null)for(e=Xa(e);e!==null;){if(t=e[ln])return t;e=Xa(e)}return n}e=t,t=e.parentNode}return null}function Cr(e){return e=e[ln]||e[hn],!e||e.tag!==5&&e.tag!==6&&e.tag!==13&&e.tag!==3?null:e}function ct(e){if(e.tag===5||e.tag===6)return e.stateNode;throw Error(S(33))}function Ri(e){return e[pr]||null}var Zl=[],dt=-1;function On(e){return{current:e}}function Y(e){0>dt||(e.current=Zl[dt],Zl[dt]=null,dt--)}function Q(e,n){dt++,Zl[dt]=e.current,e.current=n}var Mn={},we=On(Mn),Ne=On(!1),Gn=Mn;function Et(e,n){var t=e.type.contextTypes;if(!t)return Mn;var r=e.stateNode;if(r&&r.__reactInternalMemoizedUnmaskedChildContext===n)return r.__reactInternalMemoizedMaskedChildContext;var i={},l;for(l in t)i[l]=n[l];return r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=n,e.__reactInternalMemoizedMaskedChildContext=i),i}function Fe(e){return e=e.childContextTypes,e!=null}function mi(){Y(Ne),Y(we)}function Za(e,n,t){if(we.current!==Mn)throw Error(S(168));Q(we,n),Q(Ne,t)}function Vu(e,n,t){var r=e.stateNode;if(n=n.childContextTypes,typeof r.getChildContext!="function")return t;r=r.getChildContext();for(var i in r)if(!(i in n))throw Error(S(108,Id(e)||"Unknown",i));return ee({},t,r)}function hi(e){return e=(e=e.stateNode)&&e.__reactInternalMemoizedMergedChildContext||Mn,Gn=we.current,Q(we,e),Q(Ne,Ne.current),!0}function qa(e,n,t){var r=e.stateNode;if(!r)throw Error(S(169));t?(e=Vu(e,n,Gn),r.__reactInternalMemoizedMergedChildContext=e,Y(Ne),Y(we),Q(we,e)):Y(Ne),Q(Ne,t)}var cn=null,Mi=!1,dl=!1;function Qu(e){cn===null?cn=[e]:cn.push(e)}function ip(e){Mi=!0,Qu(e)}function An(){if(!dl&&cn!==null){dl=!0;var e=0,n=V;try{var t=cn;for(V=1;e<t.length;e++){var r=t[e];do r=r(!0);while(r!==null)}cn=null,Mi=!1}catch(i){throw cn!==null&&(cn=cn.slice(e+1)),vu(No,An),i}finally{V=n,dl=!1}}return null}var ft=[],pt=0,gi=null,vi=0,Be=[],We=0,Yn=null,dn=1,fn="";function Un(e,n){ft[pt++]=vi,ft[pt++]=gi,gi=e,vi=n}function Ku(e,n,t){Be[We++]=dn,Be[We++]=fn,Be[We++]=Yn,Yn=e;var r=dn;e=fn;var i=32-qe(r)-1;r&=~(1<<i),t+=1;var l=32-qe(n)+i;if(30<l){var o=i-i%5;l=(r&(1<<o)-1).toString(32),r>>=o,i-=o,dn=1<<32-qe(n)+i|t<<i|r,fn=l+e}else dn=1<<l|t<<i|r,fn=e}function Oo(e){e.return!==null&&(Un(e,1),Ku(e,1,0))}function Ao(e){for(;e===gi;)gi=ft[--pt],ft[pt]=null,vi=ft[--pt],ft[pt]=null;for(;e===Yn;)Yn=Be[--We],Be[We]=null,fn=Be[--We],Be[We]=null,dn=Be[--We],Be[We]=null}var De=null,Me=null,Z=!1,Ze=null;function Gu(e,n){var t=He(5,null,null,0);t.elementType="DELETED",t.stateNode=n,t.return=e,n=e.deletions,n===null?(e.deletions=[t],e.flags|=16):n.push(t)}function Ja(e,n){switch(e.tag){case 5:var t=e.type;return n=n.nodeType!==1||t.toLowerCase()!==n.nodeName.toLowerCase()?null:n,n!==null?(e.stateNode=n,De=e,Me=Nn(n.firstChild),!0):!1;case 6:return n=e.pendingProps===""||n.nodeType!==3?null:n,n!==null?(e.stateNode=n,De=e,Me=null,!0):!1;case 13:return n=n.nodeType!==8?null:n,n!==null?(t=Yn!==null?{id:dn,overflow:fn}:null,e.memoizedState={dehydrated:n,treeContext:t,retryLane:1073741824},t=He(18,null,null,0),t.stateNode=n,t.return=e,e.child=t,De=e,Me=null,!0):!1;default:return!1}}function ql(e){return(e.mode&1)!==0&&(e.flags&128)===0}function Jl(e){if(Z){var n=Me;if(n){var t=n;if(!Ja(e,n)){if(ql(e))throw Error(S(418));n=Nn(t.nextSibling);var r=De;n&&Ja(e,n)?Gu(r,t):(e.flags=e.flags&-4097|2,Z=!1,De=e)}}else{if(ql(e))throw Error(S(418));e.flags=e.flags&-4097|2,Z=!1,De=e}}}function es(e){for(e=e.return;e!==null&&e.tag!==5&&e.tag!==3&&e.tag!==13;)e=e.return;De=e}function Or(e){if(e!==De)return!1;if(!Z)return es(e),Z=!0,!1;var n;if((n=e.tag!==3)&&!(n=e.tag!==5)&&(n=e.type,n=n!=="head"&&n!=="body"&&!Gl(e.type,e.memoizedProps)),n&&(n=Me)){if(ql(e))throw Yu(),Error(S(418));for(;n;)Gu(e,n),n=Nn(n.nextSibling)}if(es(e),e.tag===13){if(e=e.memoizedState,e=e!==null?e.dehydrated:null,!e)throw Error(S(317));e:{for(e=e.nextSibling,n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="/$"){if(n===0){Me=Nn(e.nextSibling);break e}n--}else t!=="$"&&t!=="$!"&&t!=="$?"||n++}e=e.nextSibling}Me=null}}else Me=De?Nn(e.stateNode.nextSibling):null;return!0}function Yu(){for(var e=Me;e;)e=Nn(e.nextSibling)}function bt(){Me=De=null,Z=!1}function Io(e){Ze===null?Ze=[e]:Ze.push(e)}var lp=yn.ReactCurrentBatchConfig;function At(e,n,t){if(e=t.ref,e!==null&&typeof e!="function"&&typeof e!="object"){if(t._owner){if(t=t._owner,t){if(t.tag!==1)throw Error(S(309));var r=t.stateNode}if(!r)throw Error(S(147,e));var i=r,l=""+e;return n!==null&&n.ref!==null&&typeof n.ref=="function"&&n.ref._stringRef===l?n.ref:(n=function(o){var a=i.refs;o===null?delete a[l]:a[l]=o},n._stringRef=l,n)}if(typeof e!="string")throw Error(S(284));if(!t._owner)throw Error(S(290,e))}return e}function Ar(e,n){throw e=Object.prototype.toString.call(n),Error(S(31,e==="[object Object]"?"object with keys {"+Object.keys(n).join(", ")+"}":e))}function ns(e){var n=e._init;return n(e._payload)}function Xu(e){function n(c,s){if(e){var f=c.deletions;f===null?(c.deletions=[s],c.flags|=16):f.push(s)}}function t(c,s){if(!e)return null;for(;s!==null;)n(c,s),s=s.sibling;return null}function r(c,s){for(c=new Map;s!==null;)s.key!==null?c.set(s.key,s):c.set(s.index,s),s=s.sibling;return c}function i(c,s){return c=zn(c,s),c.index=0,c.sibling=null,c}function l(c,s,f){return c.index=f,e?(f=c.alternate,f!==null?(f=f.index,f<s?(c.flags|=2,s):f):(c.flags|=2,s)):(c.flags|=1048576,s)}function o(c){return e&&c.alternate===null&&(c.flags|=2),c}function a(c,s,f,h){return s===null||s.tag!==6?(s=yl(f,c.mode,h),s.return=c,s):(s=i(s,f),s.return=c,s)}function u(c,s,f,h){var _=f.type;return _===ot?v(c,s,f.props.children,h,f.key):s!==null&&(s.elementType===_||typeof _=="object"&&_!==null&&_.$$typeof===wn&&ns(_)===s.type)?(h=i(s,f.props),h.ref=At(c,s,f),h.return=c,h):(h=ri(f.type,f.key,f.props,null,c.mode,h),h.ref=At(c,s,f),h.return=c,h)}function d(c,s,f,h){return s===null||s.tag!==4||s.stateNode.containerInfo!==f.containerInfo||s.stateNode.implementation!==f.implementation?(s=xl(f,c.mode,h),s.return=c,s):(s=i(s,f.children||[]),s.return=c,s)}function v(c,s,f,h,_){return s===null||s.tag!==7?(s=Kn(f,c.mode,h,_),s.return=c,s):(s=i(s,f),s.return=c,s)}function m(c,s,f){if(typeof s=="string"&&s!==""||typeof s=="number")return s=yl(""+s,c.mode,f),s.return=c,s;if(typeof s=="object"&&s!==null){switch(s.$$typeof){case Pr:return f=ri(s.type,s.key,s.props,null,c.mode,f),f.ref=At(c,null,s),f.return=c,f;case lt:return s=xl(s,c.mode,f),s.return=c,s;case wn:var h=s._init;return m(c,h(s._payload),f)}if(Wt(s)||Lt(s))return s=Kn(s,c.mode,f,null),s.return=c,s;Ar(c,s)}return null}function p(c,s,f,h){var _=s!==null?s.key:null;if(typeof f=="string"&&f!==""||typeof f=="number")return _!==null?null:a(c,s,""+f,h);if(typeof f=="object"&&f!==null){switch(f.$$typeof){case Pr:return f.key===_?u(c,s,f,h):null;case lt:return f.key===_?d(c,s,f,h):null;case wn:return _=f._init,p(c,s,_(f._payload),h)}if(Wt(f)||Lt(f))return _!==null?null:v(c,s,f,h,null);Ar(c,f)}return null}function g(c,s,f,h,_){if(typeof h=="string"&&h!==""||typeof h=="number")return c=c.get(f)||null,a(s,c,""+h,_);if(typeof h=="object"&&h!==null){switch(h.$$typeof){case Pr:return c=c.get(h.key===null?f:h.key)||null,u(s,c,h,_);case lt:return c=c.get(h.key===null?f:h.key)||null,d(s,c,h,_);case wn:var C=h._init;return g(c,s,f,C(h._payload),_)}if(Wt(h)||Lt(h))return c=c.get(f)||null,v(s,c,h,_,null);Ar(s,h)}return null}function x(c,s,f,h){for(var _=null,C=null,b=s,E=s=0,R=null;b!==null&&E<f.length;E++){b.index>E?(R=b,b=null):R=b.sibling;var P=p(c,b,f[E],h);if(P===null){b===null&&(b=R);break}e&&b&&P.alternate===null&&n(c,b),s=l(P,s,E),C===null?_=P:C.sibling=P,C=P,b=R}if(E===f.length)return t(c,b),Z&&Un(c,E),_;if(b===null){for(;E<f.length;E++)b=m(c,f[E],h),b!==null&&(s=l(b,s,E),C===null?_=b:C.sibling=b,C=b);return Z&&Un(c,E),_}for(b=r(c,b);E<f.length;E++)R=g(b,c,E,f[E],h),R!==null&&(e&&R.alternate!==null&&b.delete(R.key===null?E:R.key),s=l(R,s,E),C===null?_=R:C.sibling=R,C=R);return e&&b.forEach(function(X){return n(c,X)}),Z&&Un(c,E),_}function w(c,s,f,h){var _=Lt(f);if(typeof _!="function")throw Error(S(150));if(f=_.call(f),f==null)throw Error(S(151));for(var C=_=null,b=s,E=s=0,R=null,P=f.next();b!==null&&!P.done;E++,P=f.next()){b.index>E?(R=b,b=null):R=b.sibling;var X=p(c,b,P.value,h);if(X===null){b===null&&(b=R);break}e&&b&&X.alternate===null&&n(c,b),s=l(X,s,E),C===null?_=X:C.sibling=X,C=X,b=R}if(P.done)return t(c,b),Z&&Un(c,E),_;if(b===null){for(;!P.done;E++,P=f.next())P=m(c,P.value,h),P!==null&&(s=l(P,s,E),C===null?_=P:C.sibling=P,C=P);return Z&&Un(c,E),_}for(b=r(c,b);!P.done;E++,P=f.next())P=g(b,c,E,P.value,h),P!==null&&(e&&P.alternate!==null&&b.delete(P.key===null?E:P.key),s=l(P,s,E),C===null?_=P:C.sibling=P,C=P);return e&&b.forEach(function(je){return n(c,je)}),Z&&Un(c,E),_}function z(c,s,f,h){if(typeof f=="object"&&f!==null&&f.type===ot&&f.key===null&&(f=f.props.children),typeof f=="object"&&f!==null){switch(f.$$typeof){case Pr:e:{for(var _=f.key,C=s;C!==null;){if(C.key===_){if(_=f.type,_===ot){if(C.tag===7){t(c,C.sibling),s=i(C,f.props.children),s.return=c,c=s;break e}}else if(C.elementType===_||typeof _=="object"&&_!==null&&_.$$typeof===wn&&ns(_)===C.type){t(c,C.sibling),s=i(C,f.props),s.ref=At(c,C,f),s.return=c,c=s;break e}t(c,C);break}else n(c,C);C=C.sibling}f.type===ot?(s=Kn(f.props.children,c.mode,h,f.key),s.return=c,c=s):(h=ri(f.type,f.key,f.props,null,c.mode,h),h.ref=At(c,s,f),h.return=c,c=h)}return o(c);case lt:e:{for(C=f.key;s!==null;){if(s.key===C)if(s.tag===4&&s.stateNode.containerInfo===f.containerInfo&&s.stateNode.implementation===f.implementation){t(c,s.sibling),s=i(s,f.children||[]),s.return=c,c=s;break e}else{t(c,s);break}else n(c,s);s=s.sibling}s=xl(f,c.mode,h),s.return=c,c=s}return o(c);case wn:return C=f._init,z(c,s,C(f._payload),h)}if(Wt(f))return x(c,s,f,h);if(Lt(f))return w(c,s,f,h);Ar(c,f)}return typeof f=="string"&&f!==""||typeof f=="number"?(f=""+f,s!==null&&s.tag===6?(t(c,s.sibling),s=i(s,f),s.return=c,c=s):(t(c,s),s=yl(f,c.mode,h),s.return=c,c=s),o(c)):t(c,s)}return z}var $t=Xu(!0),Zu=Xu(!1),yi=On(null),xi=null,mt=null,Uo=null;function Bo(){Uo=mt=xi=null}function Wo(e){var n=yi.current;Y(yi),e._currentValue=n}function eo(e,n,t){for(;e!==null;){var r=e.alternate;if((e.childLanes&n)!==n?(e.childLanes|=n,r!==null&&(r.childLanes|=n)):r!==null&&(r.childLanes&n)!==n&&(r.childLanes|=n),e===t)break;e=e.return}}function _t(e,n){xi=e,Uo=mt=null,e=e.dependencies,e!==null&&e.firstContext!==null&&(e.lanes&n&&(Pe=!0),e.firstContext=null)}function Qe(e){var n=e._currentValue;if(Uo!==e)if(e={context:e,memoizedValue:n,next:null},mt===null){if(xi===null)throw Error(S(308));mt=e,xi.dependencies={lanes:0,firstContext:e}}else mt=mt.next=e;return n}var Hn=null;function Ho(e){Hn===null?Hn=[e]:Hn.push(e)}function qu(e,n,t,r){var i=n.interleaved;return i===null?(t.next=t,Ho(n)):(t.next=i.next,i.next=t),n.interleaved=t,gn(e,r)}function gn(e,n){e.lanes|=n;var t=e.alternate;for(t!==null&&(t.lanes|=n),t=e,e=e.return;e!==null;)e.childLanes|=n,t=e.alternate,t!==null&&(t.childLanes|=n),t=e,e=e.return;return t.tag===3?t.stateNode:null}var kn=!1;function Vo(e){e.updateQueue={baseState:e.memoizedState,firstBaseUpdate:null,lastBaseUpdate:null,shared:{pending:null,interleaved:null,lanes:0},effects:null}}function Ju(e,n){e=e.updateQueue,n.updateQueue===e&&(n.updateQueue={baseState:e.baseState,firstBaseUpdate:e.firstBaseUpdate,lastBaseUpdate:e.lastBaseUpdate,shared:e.shared,effects:e.effects})}function pn(e,n){return{eventTime:e,lane:n,tag:0,payload:null,callback:null,next:null}}function Fn(e,n,t){var r=e.updateQueue;if(r===null)return null;if(r=r.shared,U&2){var i=r.pending;return i===null?n.next=n:(n.next=i.next,i.next=n),r.pending=n,gn(e,t)}return i=r.interleaved,i===null?(n.next=n,Ho(r)):(n.next=i.next,i.next=n),r.interleaved=n,gn(e,t)}function Zr(e,n,t){if(n=n.updateQueue,n!==null&&(n=n.shared,(t&4194240)!==0)){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,Fo(e,t)}}function ts(e,n){var t=e.updateQueue,r=e.alternate;if(r!==null&&(r=r.updateQueue,t===r)){var i=null,l=null;if(t=t.firstBaseUpdate,t!==null){do{var o={eventTime:t.eventTime,lane:t.lane,tag:t.tag,payload:t.payload,callback:t.callback,next:null};l===null?i=l=o:l=l.next=o,t=t.next}while(t!==null);l===null?i=l=n:l=l.next=n}else i=l=n;t={baseState:r.baseState,firstBaseUpdate:i,lastBaseUpdate:l,shared:r.shared,effects:r.effects},e.updateQueue=t;return}e=t.lastBaseUpdate,e===null?t.firstBaseUpdate=n:e.next=n,t.lastBaseUpdate=n}function wi(e,n,t,r){var i=e.updateQueue;kn=!1;var l=i.firstBaseUpdate,o=i.lastBaseUpdate,a=i.shared.pending;if(a!==null){i.shared.pending=null;var u=a,d=u.next;u.next=null,o===null?l=d:o.next=d,o=u;var v=e.alternate;v!==null&&(v=v.updateQueue,a=v.lastBaseUpdate,a!==o&&(a===null?v.firstBaseUpdate=d:a.next=d,v.lastBaseUpdate=u))}if(l!==null){var m=i.baseState;o=0,v=d=u=null,a=l;do{var p=a.lane,g=a.eventTime;if((r&p)===p){v!==null&&(v=v.next={eventTime:g,lane:0,tag:a.tag,payload:a.payload,callback:a.callback,next:null});e:{var x=e,w=a;switch(p=n,g=t,w.tag){case 1:if(x=w.payload,typeof x=="function"){m=x.call(g,m,p);break e}m=x;break e;case 3:x.flags=x.flags&-65537|128;case 0:if(x=w.payload,p=typeof x=="function"?x.call(g,m,p):x,p==null)break e;m=ee({},m,p);break e;case 2:kn=!0}}a.callback!==null&&a.lane!==0&&(e.flags|=64,p=i.effects,p===null?i.effects=[a]:p.push(a))}else g={eventTime:g,lane:p,tag:a.tag,payload:a.payload,callback:a.callback,next:null},v===null?(d=v=g,u=m):v=v.next=g,o|=p;if(a=a.next,a===null){if(a=i.shared.pending,a===null)break;p=a,a=p.next,p.next=null,i.lastBaseUpdate=p,i.shared.pending=null}}while(!0);if(v===null&&(u=m),i.baseState=u,i.firstBaseUpdate=d,i.lastBaseUpdate=v,n=i.shared.interleaved,n!==null){i=n;do o|=i.lane,i=i.next;while(i!==n)}else l===null&&(i.shared.lanes=0);Zn|=o,e.lanes=o,e.memoizedState=m}}function rs(e,n,t){if(e=n.effects,n.effects=null,e!==null)for(n=0;n<e.length;n++){var r=e[n],i=r.callback;if(i!==null){if(r.callback=null,r=t,typeof i!="function")throw Error(S(191,i));i.call(r)}}}var Er={},an=On(Er),mr=On(Er),hr=On(Er);function Vn(e){if(e===Er)throw Error(S(174));return e}function Qo(e,n){switch(Q(hr,n),Q(mr,e),Q(an,Er),e=n.nodeType,e){case 9:case 11:n=(n=n.documentElement)?n.namespaceURI:Ll(null,"");break;default:e=e===8?n.parentNode:n,n=e.namespaceURI||null,e=e.tagName,n=Ll(n,e)}Y(an),Q(an,n)}function Pt(){Y(an),Y(mr),Y(hr)}function ec(e){Vn(hr.current);var n=Vn(an.current),t=Ll(n,e.type);n!==t&&(Q(mr,e),Q(an,t))}function Ko(e){mr.current===e&&(Y(an),Y(mr))}var q=On(0);function ki(e){for(var n=e;n!==null;){if(n.tag===13){var t=n.memoizedState;if(t!==null&&(t=t.dehydrated,t===null||t.data==="$?"||t.data==="$!"))return n}else if(n.tag===19&&n.memoizedProps.revealOrder!==void 0){if(n.flags&128)return n}else if(n.child!==null){n.child.return=n,n=n.child;continue}if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return null;n=n.return}n.sibling.return=n.return,n=n.sibling}return null}var fl=[];function Go(){for(var e=0;e<fl.length;e++)fl[e]._workInProgressVersionPrimary=null;fl.length=0}var qr=yn.ReactCurrentDispatcher,pl=yn.ReactCurrentBatchConfig,Xn=0,J=null,oe=null,ce=null,_i=!1,qt=!1,gr=0,op=0;function ve(){throw Error(S(321))}function Yo(e,n){if(n===null)return!1;for(var t=0;t<n.length&&t<e.length;t++)if(!en(e[t],n[t]))return!1;return!0}function Xo(e,n,t,r,i,l){if(Xn=l,J=n,n.memoizedState=null,n.updateQueue=null,n.lanes=0,qr.current=e===null||e.memoizedState===null?cp:dp,e=t(r,i),qt){l=0;do{if(qt=!1,gr=0,25<=l)throw Error(S(301));l+=1,ce=oe=null,n.updateQueue=null,qr.current=fp,e=t(r,i)}while(qt)}if(qr.current=Si,n=oe!==null&&oe.next!==null,Xn=0,ce=oe=J=null,_i=!1,n)throw Error(S(300));return e}function Zo(){var e=gr!==0;return gr=0,e}function rn(){var e={memoizedState:null,baseState:null,baseQueue:null,queue:null,next:null};return ce===null?J.memoizedState=ce=e:ce=ce.next=e,ce}function Ke(){if(oe===null){var e=J.alternate;e=e!==null?e.memoizedState:null}else e=oe.next;var n=ce===null?J.memoizedState:ce.next;if(n!==null)ce=n,oe=e;else{if(e===null)throw Error(S(310));oe=e,e={memoizedState:oe.memoizedState,baseState:oe.baseState,baseQueue:oe.baseQueue,queue:oe.queue,next:null},ce===null?J.memoizedState=ce=e:ce=ce.next=e}return ce}function vr(e,n){return typeof n=="function"?n(e):n}function ml(e){var n=Ke(),t=n.queue;if(t===null)throw Error(S(311));t.lastRenderedReducer=e;var r=oe,i=r.baseQueue,l=t.pending;if(l!==null){if(i!==null){var o=i.next;i.next=l.next,l.next=o}r.baseQueue=i=l,t.pending=null}if(i!==null){l=i.next,r=r.baseState;var a=o=null,u=null,d=l;do{var v=d.lane;if((Xn&v)===v)u!==null&&(u=u.next={lane:0,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null}),r=d.hasEagerState?d.eagerState:e(r,d.action);else{var m={lane:v,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null};u===null?(a=u=m,o=r):u=u.next=m,J.lanes|=v,Zn|=v}d=d.next}while(d!==null&&d!==l);u===null?o=r:u.next=a,en(r,n.memoizedState)||(Pe=!0),n.memoizedState=r,n.baseState=o,n.baseQueue=u,t.lastRenderedState=r}if(e=t.interleaved,e!==null){i=e;do l=i.lane,J.lanes|=l,Zn|=l,i=i.next;while(i!==e)}else i===null&&(t.lanes=0);return[n.memoizedState,t.dispatch]}function hl(e){var n=Ke(),t=n.queue;if(t===null)throw Error(S(311));t.lastRenderedReducer=e;var r=t.dispatch,i=t.pending,l=n.memoizedState;if(i!==null){t.pending=null;var o=i=i.next;do l=e(l,o.action),o=o.next;while(o!==i);en(l,n.memoizedState)||(Pe=!0),n.memoizedState=l,n.baseQueue===null&&(n.baseState=l),t.lastRenderedState=l}return[l,r]}function nc(){}function tc(e,n){var t=J,r=Ke(),i=n(),l=!en(r.memoizedState,i);if(l&&(r.memoizedState=i,Pe=!0),r=r.queue,qo(lc.bind(null,t,r,e),[e]),r.getSnapshot!==n||l||ce!==null&&ce.memoizedState.tag&1){if(t.flags|=2048,yr(9,ic.bind(null,t,r,i,n),void 0,null),de===null)throw Error(S(349));Xn&30||rc(t,n,i)}return i}function rc(e,n,t){e.flags|=16384,e={getSnapshot:n,value:t},n=J.updateQueue,n===null?(n={lastEffect:null,stores:null},J.updateQueue=n,n.stores=[e]):(t=n.stores,t===null?n.stores=[e]:t.push(e))}function ic(e,n,t,r){n.value=t,n.getSnapshot=r,oc(n)&&ac(e)}function lc(e,n,t){return t(function(){oc(n)&&ac(e)})}function oc(e){var n=e.getSnapshot;e=e.value;try{var t=n();return!en(e,t)}catch{return!0}}function ac(e){var n=gn(e,1);n!==null&&Je(n,e,1,-1)}function is(e){var n=rn();return typeof e=="function"&&(e=e()),n.memoizedState=n.baseState=e,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:vr,lastRenderedState:e},n.queue=e,e=e.dispatch=up.bind(null,J,e),[n.memoizedState,e]}function yr(e,n,t,r){return e={tag:e,create:n,destroy:t,deps:r,next:null},n=J.updateQueue,n===null?(n={lastEffect:null,stores:null},J.updateQueue=n,n.lastEffect=e.next=e):(t=n.lastEffect,t===null?n.lastEffect=e.next=e:(r=t.next,t.next=e,e.next=r,n.lastEffect=e)),e}function sc(){return Ke().memoizedState}function Jr(e,n,t,r){var i=rn();J.flags|=e,i.memoizedState=yr(1|n,t,void 0,r===void 0?null:r)}function Di(e,n,t,r){var i=Ke();r=r===void 0?null:r;var l=void 0;if(oe!==null){var o=oe.memoizedState;if(l=o.destroy,r!==null&&Yo(r,o.deps)){i.memoizedState=yr(n,t,l,r);return}}J.flags|=e,i.memoizedState=yr(1|n,t,l,r)}function ls(e,n){return Jr(8390656,8,e,n)}function qo(e,n){return Di(2048,8,e,n)}function uc(e,n){return Di(4,2,e,n)}function cc(e,n){return Di(4,4,e,n)}function dc(e,n){if(typeof n=="function")return e=e(),n(e),function(){n(null)};if(n!=null)return e=e(),n.current=e,function(){n.current=null}}function fc(e,n,t){return t=t!=null?t.concat([e]):null,Di(4,4,dc.bind(null,n,e),t)}function Jo(){}function pc(e,n){var t=Ke();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Yo(n,r[1])?r[0]:(t.memoizedState=[e,n],e)}function mc(e,n){var t=Ke();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Yo(n,r[1])?r[0]:(e=e(),t.memoizedState=[e,n],e)}function hc(e,n,t){return Xn&21?(en(t,n)||(t=wu(),J.lanes|=t,Zn|=t,e.baseState=!0),n):(e.baseState&&(e.baseState=!1,Pe=!0),e.memoizedState=t)}function ap(e,n){var t=V;V=t!==0&&4>t?t:4,e(!0);var r=pl.transition;pl.transition={};try{e(!1),n()}finally{V=t,pl.transition=r}}function gc(){return Ke().memoizedState}function sp(e,n,t){var r=jn(e);if(t={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null},vc(e))yc(n,t);else if(t=qu(e,n,t,r),t!==null){var i=Ce();Je(t,e,r,i),xc(t,n,r)}}function up(e,n,t){var r=jn(e),i={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null};if(vc(e))yc(n,i);else{var l=e.alternate;if(e.lanes===0&&(l===null||l.lanes===0)&&(l=n.lastRenderedReducer,l!==null))try{var o=n.lastRenderedState,a=l(o,t);if(i.hasEagerState=!0,i.eagerState=a,en(a,o)){var u=n.interleaved;u===null?(i.next=i,Ho(n)):(i.next=u.next,u.next=i),n.interleaved=i;return}}catch{}finally{}t=qu(e,n,i,r),t!==null&&(i=Ce(),Je(t,e,r,i),xc(t,n,r))}}function vc(e){var n=e.alternate;return e===J||n!==null&&n===J}function yc(e,n){qt=_i=!0;var t=e.pending;t===null?n.next=n:(n.next=t.next,t.next=n),e.pending=n}function xc(e,n,t){if(t&4194240){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,Fo(e,t)}}var Si={readContext:Qe,useCallback:ve,useContext:ve,useEffect:ve,useImperativeHandle:ve,useInsertionEffect:ve,useLayoutEffect:ve,useMemo:ve,useReducer:ve,useRef:ve,useState:ve,useDebugValue:ve,useDeferredValue:ve,useTransition:ve,useMutableSource:ve,useSyncExternalStore:ve,useId:ve,unstable_isNewReconciler:!1},cp={readContext:Qe,useCallback:function(e,n){return rn().memoizedState=[e,n===void 0?null:n],e},useContext:Qe,useEffect:ls,useImperativeHandle:function(e,n,t){return t=t!=null?t.concat([e]):null,Jr(4194308,4,dc.bind(null,n,e),t)},useLayoutEffect:function(e,n){return Jr(4194308,4,e,n)},useInsertionEffect:function(e,n){return Jr(4,2,e,n)},useMemo:function(e,n){var t=rn();return n=n===void 0?null:n,e=e(),t.memoizedState=[e,n],e},useReducer:function(e,n,t){var r=rn();return n=t!==void 0?t(n):n,r.memoizedState=r.baseState=n,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:e,lastRenderedState:n},r.queue=e,e=e.dispatch=sp.bind(null,J,e),[r.memoizedState,e]},useRef:function(e){var n=rn();return e={current:e},n.memoizedState=e},useState:is,useDebugValue:Jo,useDeferredValue:function(e){return rn().memoizedState=e},useTransition:function(){var e=is(!1),n=e[0];return e=ap.bind(null,e[1]),rn().memoizedState=e,[n,e]},useMutableSource:function(){},useSyncExternalStore:function(e,n,t){var r=J,i=rn();if(Z){if(t===void 0)throw Error(S(407));t=t()}else{if(t=n(),de===null)throw Error(S(349));Xn&30||rc(r,n,t)}i.memoizedState=t;var l={value:t,getSnapshot:n};return i.queue=l,ls(lc.bind(null,r,l,e),[e]),r.flags|=2048,yr(9,ic.bind(null,r,l,t,n),void 0,null),t},useId:function(){var e=rn(),n=de.identifierPrefix;if(Z){var t=fn,r=dn;t=(r&~(1<<32-qe(r)-1)).toString(32)+t,n=":"+n+"R"+t,t=gr++,0<t&&(n+="H"+t.toString(32)),n+=":"}else t=op++,n=":"+n+"r"+t.toString(32)+":";return e.memoizedState=n},unstable_isNewReconciler:!1},dp={readContext:Qe,useCallback:pc,useContext:Qe,useEffect:qo,useImperativeHandle:fc,useInsertionEffect:uc,useLayoutEffect:cc,useMemo:mc,useReducer:ml,useRef:sc,useState:function(){return ml(vr)},useDebugValue:Jo,useDeferredValue:function(e){var n=Ke();return hc(n,oe.memoizedState,e)},useTransition:function(){var e=ml(vr)[0],n=Ke().memoizedState;return[e,n]},useMutableSource:nc,useSyncExternalStore:tc,useId:gc,unstable_isNewReconciler:!1},fp={readContext:Qe,useCallback:pc,useContext:Qe,useEffect:qo,useImperativeHandle:fc,useInsertionEffect:uc,useLayoutEffect:cc,useMemo:mc,useReducer:hl,useRef:sc,useState:function(){return hl(vr)},useDebugValue:Jo,useDeferredValue:function(e){var n=Ke();return oe===null?n.memoizedState=e:hc(n,oe.memoizedState,e)},useTransition:function(){var e=hl(vr)[0],n=Ke().memoizedState;return[e,n]},useMutableSource:nc,useSyncExternalStore:tc,useId:gc,unstable_isNewReconciler:!1};function Ye(e,n){if(e&&e.defaultProps){n=ee({},n),e=e.defaultProps;for(var t in e)n[t]===void 0&&(n[t]=e[t]);return n}return n}function no(e,n,t,r){n=e.memoizedState,t=t(r,n),t=t==null?n:ee({},n,t),e.memoizedState=t,e.lanes===0&&(e.updateQueue.baseState=t)}var Oi={isMounted:function(e){return(e=e._reactInternals)?et(e)===e:!1},enqueueSetState:function(e,n,t){e=e._reactInternals;var r=Ce(),i=jn(e),l=pn(r,i);l.payload=n,t!=null&&(l.callback=t),n=Fn(e,l,i),n!==null&&(Je(n,e,i,r),Zr(n,e,i))},enqueueReplaceState:function(e,n,t){e=e._reactInternals;var r=Ce(),i=jn(e),l=pn(r,i);l.tag=1,l.payload=n,t!=null&&(l.callback=t),n=Fn(e,l,i),n!==null&&(Je(n,e,i,r),Zr(n,e,i))},enqueueForceUpdate:function(e,n){e=e._reactInternals;var t=Ce(),r=jn(e),i=pn(t,r);i.tag=2,n!=null&&(i.callback=n),n=Fn(e,i,r),n!==null&&(Je(n,e,r,t),Zr(n,e,r))}};function os(e,n,t,r,i,l,o){return e=e.stateNode,typeof e.shouldComponentUpdate=="function"?e.shouldComponentUpdate(r,l,o):n.prototype&&n.prototype.isPureReactComponent?!cr(t,r)||!cr(i,l):!0}function wc(e,n,t){var r=!1,i=Mn,l=n.contextType;return typeof l=="object"&&l!==null?l=Qe(l):(i=Fe(n)?Gn:we.current,r=n.contextTypes,l=(r=r!=null)?Et(e,i):Mn),n=new n(t,l),e.memoizedState=n.state!==null&&n.state!==void 0?n.state:null,n.updater=Oi,e.stateNode=n,n._reactInternals=e,r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=i,e.__reactInternalMemoizedMaskedChildContext=l),n}function as(e,n,t,r){e=n.state,typeof n.componentWillReceiveProps=="function"&&n.componentWillReceiveProps(t,r),typeof n.UNSAFE_componentWillReceiveProps=="function"&&n.UNSAFE_componentWillReceiveProps(t,r),n.state!==e&&Oi.enqueueReplaceState(n,n.state,null)}function to(e,n,t,r){var i=e.stateNode;i.props=t,i.state=e.memoizedState,i.refs={},Vo(e);var l=n.contextType;typeof l=="object"&&l!==null?i.context=Qe(l):(l=Fe(n)?Gn:we.current,i.context=Et(e,l)),i.state=e.memoizedState,l=n.getDerivedStateFromProps,typeof l=="function"&&(no(e,n,l,t),i.state=e.memoizedState),typeof n.getDerivedStateFromProps=="function"||typeof i.getSnapshotBeforeUpdate=="function"||typeof i.UNSAFE_componentWillMount!="function"&&typeof i.componentWillMount!="function"||(n=i.state,typeof i.componentWillMount=="function"&&i.componentWillMount(),typeof i.UNSAFE_componentWillMount=="function"&&i.UNSAFE_componentWillMount(),n!==i.state&&Oi.enqueueReplaceState(i,i.state,null),wi(e,t,i,r),i.state=e.memoizedState),typeof i.componentDidMount=="function"&&(e.flags|=4194308)}function Nt(e,n){try{var t="",r=n;do t+=Ad(r),r=r.return;while(r);var i=t}catch(l){i=`
Error generating stack: `+l.message+`
`+l.stack}return{value:e,source:n,stack:i,digest:null}}function gl(e,n,t){return{value:e,source:null,stack:t??null,digest:n??null}}function ro(e,n){try{console.error(n.value)}catch(t){setTimeout(function(){throw t})}}var pp=typeof WeakMap=="function"?WeakMap:Map;function kc(e,n,t){t=pn(-1,t),t.tag=3,t.payload={element:null};var r=n.value;return t.callback=function(){Ei||(Ei=!0,mo=r),ro(e,n)},t}function _c(e,n,t){t=pn(-1,t),t.tag=3;var r=e.type.getDerivedStateFromError;if(typeof r=="function"){var i=n.value;t.payload=function(){return r(i)},t.callback=function(){ro(e,n)}}var l=e.stateNode;return l!==null&&typeof l.componentDidCatch=="function"&&(t.callback=function(){ro(e,n),typeof r!="function"&&(Tn===null?Tn=new Set([this]):Tn.add(this));var o=n.stack;this.componentDidCatch(n.value,{componentStack:o!==null?o:""})}),t}function ss(e,n,t){var r=e.pingCache;if(r===null){r=e.pingCache=new pp;var i=new Set;r.set(n,i)}else i=r.get(n),i===void 0&&(i=new Set,r.set(n,i));i.has(t)||(i.add(t),e=$p.bind(null,e,n,t),n.then(e,e))}function us(e){do{var n;if((n=e.tag===13)&&(n=e.memoizedState,n=n!==null?n.dehydrated!==null:!0),n)return e;e=e.return}while(e!==null);return null}function cs(e,n,t,r,i){return e.mode&1?(e.flags|=65536,e.lanes=i,e):(e===n?e.flags|=65536:(e.flags|=128,t.flags|=131072,t.flags&=-52805,t.tag===1&&(t.alternate===null?t.tag=17:(n=pn(-1,1),n.tag=2,Fn(t,n,1))),t.lanes|=1),e)}var mp=yn.ReactCurrentOwner,Pe=!1;function Se(e,n,t,r){n.child=e===null?Zu(n,null,t,r):$t(n,e.child,t,r)}function ds(e,n,t,r,i){t=t.render;var l=n.ref;return _t(n,i),r=Xo(e,n,t,r,l,i),t=Zo(),e!==null&&!Pe?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,vn(e,n,i)):(Z&&t&&Oo(n),n.flags|=1,Se(e,n,r,i),n.child)}function fs(e,n,t,r,i){if(e===null){var l=t.type;return typeof l=="function"&&!aa(l)&&l.defaultProps===void 0&&t.compare===null&&t.defaultProps===void 0?(n.tag=15,n.type=l,Sc(e,n,l,r,i)):(e=ri(t.type,null,r,n,n.mode,i),e.ref=n.ref,e.return=n,n.child=e)}if(l=e.child,!(e.lanes&i)){var o=l.memoizedProps;if(t=t.compare,t=t!==null?t:cr,t(o,r)&&e.ref===n.ref)return vn(e,n,i)}return n.flags|=1,e=zn(l,r),e.ref=n.ref,e.return=n,n.child=e}function Sc(e,n,t,r,i){if(e!==null){var l=e.memoizedProps;if(cr(l,r)&&e.ref===n.ref)if(Pe=!1,n.pendingProps=r=l,(e.lanes&i)!==0)e.flags&131072&&(Pe=!0);else return n.lanes=e.lanes,vn(e,n,i)}return io(e,n,t,r,i)}function Cc(e,n,t){var r=n.pendingProps,i=r.children,l=e!==null?e.memoizedState:null;if(r.mode==="hidden")if(!(n.mode&1))n.memoizedState={baseLanes:0,cachePool:null,transitions:null},Q(gt,Le),Le|=t;else{if(!(t&1073741824))return e=l!==null?l.baseLanes|t:t,n.lanes=n.childLanes=1073741824,n.memoizedState={baseLanes:e,cachePool:null,transitions:null},n.updateQueue=null,Q(gt,Le),Le|=e,null;n.memoizedState={baseLanes:0,cachePool:null,transitions:null},r=l!==null?l.baseLanes:t,Q(gt,Le),Le|=r}else l!==null?(r=l.baseLanes|t,n.memoizedState=null):r=t,Q(gt,Le),Le|=r;return Se(e,n,i,t),n.child}function Ec(e,n){var t=n.ref;(e===null&&t!==null||e!==null&&e.ref!==t)&&(n.flags|=512,n.flags|=2097152)}function io(e,n,t,r,i){var l=Fe(t)?Gn:we.current;return l=Et(n,l),_t(n,i),t=Xo(e,n,t,r,l,i),r=Zo(),e!==null&&!Pe?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,vn(e,n,i)):(Z&&r&&Oo(n),n.flags|=1,Se(e,n,t,i),n.child)}function ps(e,n,t,r,i){if(Fe(t)){var l=!0;hi(n)}else l=!1;if(_t(n,i),n.stateNode===null)ei(e,n),wc(n,t,r),to(n,t,r,i),r=!0;else if(e===null){var o=n.stateNode,a=n.memoizedProps;o.props=a;var u=o.context,d=t.contextType;typeof d=="object"&&d!==null?d=Qe(d):(d=Fe(t)?Gn:we.current,d=Et(n,d));var v=t.getDerivedStateFromProps,m=typeof v=="function"||typeof o.getSnapshotBeforeUpdate=="function";m||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==r||u!==d)&&as(n,o,r,d),kn=!1;var p=n.memoizedState;o.state=p,wi(n,r,o,i),u=n.memoizedState,a!==r||p!==u||Ne.current||kn?(typeof v=="function"&&(no(n,t,v,r),u=n.memoizedState),(a=kn||os(n,t,a,r,p,u,d))?(m||typeof o.UNSAFE_componentWillMount!="function"&&typeof o.componentWillMount!="function"||(typeof o.componentWillMount=="function"&&o.componentWillMount(),typeof o.UNSAFE_componentWillMount=="function"&&o.UNSAFE_componentWillMount()),typeof o.componentDidMount=="function"&&(n.flags|=4194308)):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),n.memoizedProps=r,n.memoizedState=u),o.props=r,o.state=u,o.context=d,r=a):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),r=!1)}else{o=n.stateNode,Ju(e,n),a=n.memoizedProps,d=n.type===n.elementType?a:Ye(n.type,a),o.props=d,m=n.pendingProps,p=o.context,u=t.contextType,typeof u=="object"&&u!==null?u=Qe(u):(u=Fe(t)?Gn:we.current,u=Et(n,u));var g=t.getDerivedStateFromProps;(v=typeof g=="function"||typeof o.getSnapshotBeforeUpdate=="function")||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==m||p!==u)&&as(n,o,r,u),kn=!1,p=n.memoizedState,o.state=p,wi(n,r,o,i);var x=n.memoizedState;a!==m||p!==x||Ne.current||kn?(typeof g=="function"&&(no(n,t,g,r),x=n.memoizedState),(d=kn||os(n,t,d,r,p,x,u)||!1)?(v||typeof o.UNSAFE_componentWillUpdate!="function"&&typeof o.componentWillUpdate!="function"||(typeof o.componentWillUpdate=="function"&&o.componentWillUpdate(r,x,u),typeof o.UNSAFE_componentWillUpdate=="function"&&o.UNSAFE_componentWillUpdate(r,x,u)),typeof o.componentDidUpdate=="function"&&(n.flags|=4),typeof o.getSnapshotBeforeUpdate=="function"&&(n.flags|=1024)):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),n.memoizedProps=r,n.memoizedState=x),o.props=r,o.state=x,o.context=u,r=d):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),r=!1)}return lo(e,n,t,r,l,i)}function lo(e,n,t,r,i,l){Ec(e,n);var o=(n.flags&128)!==0;if(!r&&!o)return i&&qa(n,t,!1),vn(e,n,l);r=n.stateNode,mp.current=n;var a=o&&typeof t.getDerivedStateFromError!="function"?null:r.render();return n.flags|=1,e!==null&&o?(n.child=$t(n,e.child,null,l),n.child=$t(n,null,a,l)):Se(e,n,a,l),n.memoizedState=r.state,i&&qa(n,t,!0),n.child}function bc(e){var n=e.stateNode;n.pendingContext?Za(e,n.pendingContext,n.pendingContext!==n.context):n.context&&Za(e,n.context,!1),Qo(e,n.containerInfo)}function ms(e,n,t,r,i){return bt(),Io(i),n.flags|=256,Se(e,n,t,r),n.child}var oo={dehydrated:null,treeContext:null,retryLane:0};function ao(e){return{baseLanes:e,cachePool:null,transitions:null}}function $c(e,n,t){var r=n.pendingProps,i=q.current,l=!1,o=(n.flags&128)!==0,a;if((a=o)||(a=e!==null&&e.memoizedState===null?!1:(i&2)!==0),a?(l=!0,n.flags&=-129):(e===null||e.memoizedState!==null)&&(i|=1),Q(q,i&1),e===null)return Jl(n),e=n.memoizedState,e!==null&&(e=e.dehydrated,e!==null)?(n.mode&1?e.data==="$!"?n.lanes=8:n.lanes=1073741824:n.lanes=1,null):(o=r.children,e=r.fallback,l?(r=n.mode,l=n.child,o={mode:"hidden",children:o},!(r&1)&&l!==null?(l.childLanes=0,l.pendingProps=o):l=Ui(o,r,0,null),e=Kn(e,r,t,null),l.return=n,e.return=n,l.sibling=e,n.child=l,n.child.memoizedState=ao(t),n.memoizedState=oo,e):ea(n,o));if(i=e.memoizedState,i!==null&&(a=i.dehydrated,a!==null))return hp(e,n,o,r,a,i,t);if(l){l=r.fallback,o=n.mode,i=e.child,a=i.sibling;var u={mode:"hidden",children:r.children};return!(o&1)&&n.child!==i?(r=n.child,r.childLanes=0,r.pendingProps=u,n.deletions=null):(r=zn(i,u),r.subtreeFlags=i.subtreeFlags&14680064),a!==null?l=zn(a,l):(l=Kn(l,o,t,null),l.flags|=2),l.return=n,r.return=n,r.sibling=l,n.child=r,r=l,l=n.child,o=e.child.memoizedState,o=o===null?ao(t):{baseLanes:o.baseLanes|t,cachePool:null,transitions:o.transitions},l.memoizedState=o,l.childLanes=e.childLanes&~t,n.memoizedState=oo,r}return l=e.child,e=l.sibling,r=zn(l,{mode:"visible",children:r.children}),!(n.mode&1)&&(r.lanes=t),r.return=n,r.sibling=null,e!==null&&(t=n.deletions,t===null?(n.deletions=[e],n.flags|=16):t.push(e)),n.child=r,n.memoizedState=null,r}function ea(e,n){return n=Ui({mode:"visible",children:n},e.mode,0,null),n.return=e,e.child=n}function Ir(e,n,t,r){return r!==null&&Io(r),$t(n,e.child,null,t),e=ea(n,n.pendingProps.children),e.flags|=2,n.memoizedState=null,e}function hp(e,n,t,r,i,l,o){if(t)return n.flags&256?(n.flags&=-257,r=gl(Error(S(422))),Ir(e,n,o,r)):n.memoizedState!==null?(n.child=e.child,n.flags|=128,null):(l=r.fallback,i=n.mode,r=Ui({mode:"visible",children:r.children},i,0,null),l=Kn(l,i,o,null),l.flags|=2,r.return=n,l.return=n,r.sibling=l,n.child=r,n.mode&1&&$t(n,e.child,null,o),n.child.memoizedState=ao(o),n.memoizedState=oo,l);if(!(n.mode&1))return Ir(e,n,o,null);if(i.data==="$!"){if(r=i.nextSibling&&i.nextSibling.dataset,r)var a=r.dgst;return r=a,l=Error(S(419)),r=gl(l,r,void 0),Ir(e,n,o,r)}if(a=(o&e.childLanes)!==0,Pe||a){if(r=de,r!==null){switch(o&-o){case 4:i=2;break;case 16:i=8;break;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:i=32;break;case 536870912:i=268435456;break;default:i=0}i=i&(r.suspendedLanes|o)?0:i,i!==0&&i!==l.retryLane&&(l.retryLane=i,gn(e,i),Je(r,e,i,-1))}return oa(),r=gl(Error(S(421))),Ir(e,n,o,r)}return i.data==="$?"?(n.flags|=128,n.child=e.child,n=Pp.bind(null,e),i._reactRetry=n,null):(e=l.treeContext,Me=Nn(i.nextSibling),De=n,Z=!0,Ze=null,e!==null&&(Be[We++]=dn,Be[We++]=fn,Be[We++]=Yn,dn=e.id,fn=e.overflow,Yn=n),n=ea(n,r.children),n.flags|=4096,n)}function hs(e,n,t){e.lanes|=n;var r=e.alternate;r!==null&&(r.lanes|=n),eo(e.return,n,t)}function vl(e,n,t,r,i){var l=e.memoizedState;l===null?e.memoizedState={isBackwards:n,rendering:null,renderingStartTime:0,last:r,tail:t,tailMode:i}:(l.isBackwards=n,l.rendering=null,l.renderingStartTime=0,l.last=r,l.tail=t,l.tailMode=i)}function Pc(e,n,t){var r=n.pendingProps,i=r.revealOrder,l=r.tail;if(Se(e,n,r.children,t),r=q.current,r&2)r=r&1|2,n.flags|=128;else{if(e!==null&&e.flags&128)e:for(e=n.child;e!==null;){if(e.tag===13)e.memoizedState!==null&&hs(e,t,n);else if(e.tag===19)hs(e,t,n);else if(e.child!==null){e.child.return=e,e=e.child;continue}if(e===n)break e;for(;e.sibling===null;){if(e.return===null||e.return===n)break e;e=e.return}e.sibling.return=e.return,e=e.sibling}r&=1}if(Q(q,r),!(n.mode&1))n.memoizedState=null;else switch(i){case"forwards":for(t=n.child,i=null;t!==null;)e=t.alternate,e!==null&&ki(e)===null&&(i=t),t=t.sibling;t=i,t===null?(i=n.child,n.child=null):(i=t.sibling,t.sibling=null),vl(n,!1,i,t,l);break;case"backwards":for(t=null,i=n.child,n.child=null;i!==null;){if(e=i.alternate,e!==null&&ki(e)===null){n.child=i;break}e=i.sibling,i.sibling=t,t=i,i=e}vl(n,!0,t,null,l);break;case"together":vl(n,!1,null,null,void 0);break;default:n.memoizedState=null}return n.child}function ei(e,n){!(n.mode&1)&&e!==null&&(e.alternate=null,n.alternate=null,n.flags|=2)}function vn(e,n,t){if(e!==null&&(n.dependencies=e.dependencies),Zn|=n.lanes,!(t&n.childLanes))return null;if(e!==null&&n.child!==e.child)throw Error(S(153));if(n.child!==null){for(e=n.child,t=zn(e,e.pendingProps),n.child=t,t.return=n;e.sibling!==null;)e=e.sibling,t=t.sibling=zn(e,e.pendingProps),t.return=n;t.sibling=null}return n.child}function gp(e,n,t){switch(n.tag){case 3:bc(n),bt();break;case 5:ec(n);break;case 1:Fe(n.type)&&hi(n);break;case 4:Qo(n,n.stateNode.containerInfo);break;case 10:var r=n.type._context,i=n.memoizedProps.value;Q(yi,r._currentValue),r._currentValue=i;break;case 13:if(r=n.memoizedState,r!==null)return r.dehydrated!==null?(Q(q,q.current&1),n.flags|=128,null):t&n.child.childLanes?$c(e,n,t):(Q(q,q.current&1),e=vn(e,n,t),e!==null?e.sibling:null);Q(q,q.current&1);break;case 19:if(r=(t&n.childLanes)!==0,e.flags&128){if(r)return Pc(e,n,t);n.flags|=128}if(i=n.memoizedState,i!==null&&(i.rendering=null,i.tail=null,i.lastEffect=null),Q(q,q.current),r)break;return null;case 22:case 23:return n.lanes=0,Cc(e,n,t)}return vn(e,n,t)}var Nc,so,Fc,Tc;Nc=function(e,n){for(var t=n.child;t!==null;){if(t.tag===5||t.tag===6)e.appendChild(t.stateNode);else if(t.tag!==4&&t.child!==null){t.child.return=t,t=t.child;continue}if(t===n)break;for(;t.sibling===null;){if(t.return===null||t.return===n)return;t=t.return}t.sibling.return=t.return,t=t.sibling}};so=function(){};Fc=function(e,n,t,r){var i=e.memoizedProps;if(i!==r){e=n.stateNode,Vn(an.current);var l=null;switch(t){case"input":i=Fl(e,i),r=Fl(e,r),l=[];break;case"select":i=ee({},i,{value:void 0}),r=ee({},r,{value:void 0}),l=[];break;case"textarea":i=zl(e,i),r=zl(e,r),l=[];break;default:typeof i.onClick!="function"&&typeof r.onClick=="function"&&(e.onclick=pi)}Rl(t,r);var o;t=null;for(d in i)if(!r.hasOwnProperty(d)&&i.hasOwnProperty(d)&&i[d]!=null)if(d==="style"){var a=i[d];for(o in a)a.hasOwnProperty(o)&&(t||(t={}),t[o]="")}else d!=="dangerouslySetInnerHTML"&&d!=="children"&&d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&d!=="autoFocus"&&(rr.hasOwnProperty(d)?l||(l=[]):(l=l||[]).push(d,null));for(d in r){var u=r[d];if(a=i!=null?i[d]:void 0,r.hasOwnProperty(d)&&u!==a&&(u!=null||a!=null))if(d==="style")if(a){for(o in a)!a.hasOwnProperty(o)||u&&u.hasOwnProperty(o)||(t||(t={}),t[o]="");for(o in u)u.hasOwnProperty(o)&&a[o]!==u[o]&&(t||(t={}),t[o]=u[o])}else t||(l||(l=[]),l.push(d,t)),t=u;else d==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,a=a?a.__html:void 0,u!=null&&a!==u&&(l=l||[]).push(d,u)):d==="children"?typeof u!="string"&&typeof u!="number"||(l=l||[]).push(d,""+u):d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&(rr.hasOwnProperty(d)?(u!=null&&d==="onScroll"&&G("scroll",e),l||a===u||(l=[])):(l=l||[]).push(d,u))}t&&(l=l||[]).push("style",t);var d=l;(n.updateQueue=d)&&(n.flags|=4)}};Tc=function(e,n,t,r){t!==r&&(n.flags|=4)};function It(e,n){if(!Z)switch(e.tailMode){case"hidden":n=e.tail;for(var t=null;n!==null;)n.alternate!==null&&(t=n),n=n.sibling;t===null?e.tail=null:t.sibling=null;break;case"collapsed":t=e.tail;for(var r=null;t!==null;)t.alternate!==null&&(r=t),t=t.sibling;r===null?n||e.tail===null?e.tail=null:e.tail.sibling=null:r.sibling=null}}function ye(e){var n=e.alternate!==null&&e.alternate.child===e.child,t=0,r=0;if(n)for(var i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags&14680064,r|=i.flags&14680064,i.return=e,i=i.sibling;else for(i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags,r|=i.flags,i.return=e,i=i.sibling;return e.subtreeFlags|=r,e.childLanes=t,n}function vp(e,n,t){var r=n.pendingProps;switch(Ao(n),n.tag){case 2:case 16:case 15:case 0:case 11:case 7:case 8:case 12:case 9:case 14:return ye(n),null;case 1:return Fe(n.type)&&mi(),ye(n),null;case 3:return r=n.stateNode,Pt(),Y(Ne),Y(we),Go(),r.pendingContext&&(r.context=r.pendingContext,r.pendingContext=null),(e===null||e.child===null)&&(Or(n)?n.flags|=4:e===null||e.memoizedState.isDehydrated&&!(n.flags&256)||(n.flags|=1024,Ze!==null&&(vo(Ze),Ze=null))),so(e,n),ye(n),null;case 5:Ko(n);var i=Vn(hr.current);if(t=n.type,e!==null&&n.stateNode!=null)Fc(e,n,t,r,i),e.ref!==n.ref&&(n.flags|=512,n.flags|=2097152);else{if(!r){if(n.stateNode===null)throw Error(S(166));return ye(n),null}if(e=Vn(an.current),Or(n)){r=n.stateNode,t=n.type;var l=n.memoizedProps;switch(r[ln]=n,r[pr]=l,e=(n.mode&1)!==0,t){case"dialog":G("cancel",r),G("close",r);break;case"iframe":case"object":case"embed":G("load",r);break;case"video":case"audio":for(i=0;i<Vt.length;i++)G(Vt[i],r);break;case"source":G("error",r);break;case"img":case"image":case"link":G("error",r),G("load",r);break;case"details":G("toggle",r);break;case"input":Ca(r,l),G("invalid",r);break;case"select":r._wrapperState={wasMultiple:!!l.multiple},G("invalid",r);break;case"textarea":ba(r,l),G("invalid",r)}Rl(t,l),i=null;for(var o in l)if(l.hasOwnProperty(o)){var a=l[o];o==="children"?typeof a=="string"?r.textContent!==a&&(l.suppressHydrationWarning!==!0&&Dr(r.textContent,a,e),i=["children",a]):typeof a=="number"&&r.textContent!==""+a&&(l.suppressHydrationWarning!==!0&&Dr(r.textContent,a,e),i=["children",""+a]):rr.hasOwnProperty(o)&&a!=null&&o==="onScroll"&&G("scroll",r)}switch(t){case"input":Nr(r),Ea(r,l,!0);break;case"textarea":Nr(r),$a(r);break;case"select":case"option":break;default:typeof l.onClick=="function"&&(r.onclick=pi)}r=i,n.updateQueue=r,r!==null&&(n.flags|=4)}else{o=i.nodeType===9?i:i.ownerDocument,e==="http://www.w3.org/1999/xhtml"&&(e=lu(t)),e==="http://www.w3.org/1999/xhtml"?t==="script"?(e=o.createElement("div"),e.innerHTML="<script><\/script>",e=e.removeChild(e.firstChild)):typeof r.is=="string"?e=o.createElement(t,{is:r.is}):(e=o.createElement(t),t==="select"&&(o=e,r.multiple?o.multiple=!0:r.size&&(o.size=r.size))):e=o.createElementNS(e,t),e[ln]=n,e[pr]=r,Nc(e,n,!1,!1),n.stateNode=e;e:{switch(o=Ml(t,r),t){case"dialog":G("cancel",e),G("close",e),i=r;break;case"iframe":case"object":case"embed":G("load",e),i=r;break;case"video":case"audio":for(i=0;i<Vt.length;i++)G(Vt[i],e);i=r;break;case"source":G("error",e),i=r;break;case"img":case"image":case"link":G("error",e),G("load",e),i=r;break;case"details":G("toggle",e),i=r;break;case"input":Ca(e,r),i=Fl(e,r),G("invalid",e);break;case"option":i=r;break;case"select":e._wrapperState={wasMultiple:!!r.multiple},i=ee({},r,{value:void 0}),G("invalid",e);break;case"textarea":ba(e,r),i=zl(e,r),G("invalid",e);break;default:i=r}Rl(t,i),a=i;for(l in a)if(a.hasOwnProperty(l)){var u=a[l];l==="style"?su(e,u):l==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,u!=null&&ou(e,u)):l==="children"?typeof u=="string"?(t!=="textarea"||u!=="")&&ir(e,u):typeof u=="number"&&ir(e,""+u):l!=="suppressContentEditableWarning"&&l!=="suppressHydrationWarning"&&l!=="autoFocus"&&(rr.hasOwnProperty(l)?u!=null&&l==="onScroll"&&G("scroll",e):u!=null&&Co(e,l,u,o))}switch(t){case"input":Nr(e),Ea(e,r,!1);break;case"textarea":Nr(e),$a(e);break;case"option":r.value!=null&&e.setAttribute("value",""+Rn(r.value));break;case"select":e.multiple=!!r.multiple,l=r.value,l!=null?yt(e,!!r.multiple,l,!1):r.defaultValue!=null&&yt(e,!!r.multiple,r.defaultValue,!0);break;default:typeof i.onClick=="function"&&(e.onclick=pi)}switch(t){case"button":case"input":case"select":case"textarea":r=!!r.autoFocus;break e;case"img":r=!0;break e;default:r=!1}}r&&(n.flags|=4)}n.ref!==null&&(n.flags|=512,n.flags|=2097152)}return ye(n),null;case 6:if(e&&n.stateNode!=null)Tc(e,n,e.memoizedProps,r);else{if(typeof r!="string"&&n.stateNode===null)throw Error(S(166));if(t=Vn(hr.current),Vn(an.current),Or(n)){if(r=n.stateNode,t=n.memoizedProps,r[ln]=n,(l=r.nodeValue!==t)&&(e=De,e!==null))switch(e.tag){case 3:Dr(r.nodeValue,t,(e.mode&1)!==0);break;case 5:e.memoizedProps.suppressHydrationWarning!==!0&&Dr(r.nodeValue,t,(e.mode&1)!==0)}l&&(n.flags|=4)}else r=(t.nodeType===9?t:t.ownerDocument).createTextNode(r),r[ln]=n,n.stateNode=r}return ye(n),null;case 13:if(Y(q),r=n.memoizedState,e===null||e.memoizedState!==null&&e.memoizedState.dehydrated!==null){if(Z&&Me!==null&&n.mode&1&&!(n.flags&128))Yu(),bt(),n.flags|=98560,l=!1;else if(l=Or(n),r!==null&&r.dehydrated!==null){if(e===null){if(!l)throw Error(S(318));if(l=n.memoizedState,l=l!==null?l.dehydrated:null,!l)throw Error(S(317));l[ln]=n}else bt(),!(n.flags&128)&&(n.memoizedState=null),n.flags|=4;ye(n),l=!1}else Ze!==null&&(vo(Ze),Ze=null),l=!0;if(!l)return n.flags&65536?n:null}return n.flags&128?(n.lanes=t,n):(r=r!==null,r!==(e!==null&&e.memoizedState!==null)&&r&&(n.child.flags|=8192,n.mode&1&&(e===null||q.current&1?ae===0&&(ae=3):oa())),n.updateQueue!==null&&(n.flags|=4),ye(n),null);case 4:return Pt(),so(e,n),e===null&&dr(n.stateNode.containerInfo),ye(n),null;case 10:return Wo(n.type._context),ye(n),null;case 17:return Fe(n.type)&&mi(),ye(n),null;case 19:if(Y(q),l=n.memoizedState,l===null)return ye(n),null;if(r=(n.flags&128)!==0,o=l.rendering,o===null)if(r)It(l,!1);else{if(ae!==0||e!==null&&e.flags&128)for(e=n.child;e!==null;){if(o=ki(e),o!==null){for(n.flags|=128,It(l,!1),r=o.updateQueue,r!==null&&(n.updateQueue=r,n.flags|=4),n.subtreeFlags=0,r=t,t=n.child;t!==null;)l=t,e=r,l.flags&=14680066,o=l.alternate,o===null?(l.childLanes=0,l.lanes=e,l.child=null,l.subtreeFlags=0,l.memoizedProps=null,l.memoizedState=null,l.updateQueue=null,l.dependencies=null,l.stateNode=null):(l.childLanes=o.childLanes,l.lanes=o.lanes,l.child=o.child,l.subtreeFlags=0,l.deletions=null,l.memoizedProps=o.memoizedProps,l.memoizedState=o.memoizedState,l.updateQueue=o.updateQueue,l.type=o.type,e=o.dependencies,l.dependencies=e===null?null:{lanes:e.lanes,firstContext:e.firstContext}),t=t.sibling;return Q(q,q.current&1|2),n.child}e=e.sibling}l.tail!==null&&te()>Ft&&(n.flags|=128,r=!0,It(l,!1),n.lanes=4194304)}else{if(!r)if(e=ki(o),e!==null){if(n.flags|=128,r=!0,t=e.updateQueue,t!==null&&(n.updateQueue=t,n.flags|=4),It(l,!0),l.tail===null&&l.tailMode==="hidden"&&!o.alternate&&!Z)return ye(n),null}else 2*te()-l.renderingStartTime>Ft&&t!==1073741824&&(n.flags|=128,r=!0,It(l,!1),n.lanes=4194304);l.isBackwards?(o.sibling=n.child,n.child=o):(t=l.last,t!==null?t.sibling=o:n.child=o,l.last=o)}return l.tail!==null?(n=l.tail,l.rendering=n,l.tail=n.sibling,l.renderingStartTime=te(),n.sibling=null,t=q.current,Q(q,r?t&1|2:t&1),n):(ye(n),null);case 22:case 23:return la(),r=n.memoizedState!==null,e!==null&&e.memoizedState!==null!==r&&(n.flags|=8192),r&&n.mode&1?Le&1073741824&&(ye(n),n.subtreeFlags&6&&(n.flags|=8192)):ye(n),null;case 24:return null;case 25:return null}throw Error(S(156,n.tag))}function yp(e,n){switch(Ao(n),n.tag){case 1:return Fe(n.type)&&mi(),e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 3:return Pt(),Y(Ne),Y(we),Go(),e=n.flags,e&65536&&!(e&128)?(n.flags=e&-65537|128,n):null;case 5:return Ko(n),null;case 13:if(Y(q),e=n.memoizedState,e!==null&&e.dehydrated!==null){if(n.alternate===null)throw Error(S(340));bt()}return e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 19:return Y(q),null;case 4:return Pt(),null;case 10:return Wo(n.type._context),null;case 22:case 23:return la(),null;case 24:return null;default:return null}}var Ur=!1,xe=!1,xp=typeof WeakSet=="function"?WeakSet:Set,T=null;function ht(e,n){var t=e.ref;if(t!==null)if(typeof t=="function")try{t(null)}catch(r){ne(e,n,r)}else t.current=null}function uo(e,n,t){try{t()}catch(r){ne(e,n,r)}}var gs=!1;function wp(e,n){if(Ql=ci,e=Mu(),Do(e)){if("selectionStart"in e)var t={start:e.selectionStart,end:e.selectionEnd};else e:{t=(t=e.ownerDocument)&&t.defaultView||window;var r=t.getSelection&&t.getSelection();if(r&&r.rangeCount!==0){t=r.anchorNode;var i=r.anchorOffset,l=r.focusNode;r=r.focusOffset;try{t.nodeType,l.nodeType}catch{t=null;break e}var o=0,a=-1,u=-1,d=0,v=0,m=e,p=null;n:for(;;){for(var g;m!==t||i!==0&&m.nodeType!==3||(a=o+i),m!==l||r!==0&&m.nodeType!==3||(u=o+r),m.nodeType===3&&(o+=m.nodeValue.length),(g=m.firstChild)!==null;)p=m,m=g;for(;;){if(m===e)break n;if(p===t&&++d===i&&(a=o),p===l&&++v===r&&(u=o),(g=m.nextSibling)!==null)break;m=p,p=m.parentNode}m=g}t=a===-1||u===-1?null:{start:a,end:u}}else t=null}t=t||{start:0,end:0}}else t=null;for(Kl={focusedElem:e,selectionRange:t},ci=!1,T=n;T!==null;)if(n=T,e=n.child,(n.subtreeFlags&1028)!==0&&e!==null)e.return=n,T=e;else for(;T!==null;){n=T;try{var x=n.alternate;if(n.flags&1024)switch(n.tag){case 0:case 11:case 15:break;case 1:if(x!==null){var w=x.memoizedProps,z=x.memoizedState,c=n.stateNode,s=c.getSnapshotBeforeUpdate(n.elementType===n.type?w:Ye(n.type,w),z);c.__reactInternalSnapshotBeforeUpdate=s}break;case 3:var f=n.stateNode.containerInfo;f.nodeType===1?f.textContent="":f.nodeType===9&&f.documentElement&&f.removeChild(f.documentElement);break;case 5:case 6:case 4:case 17:break;default:throw Error(S(163))}}catch(h){ne(n,n.return,h)}if(e=n.sibling,e!==null){e.return=n.return,T=e;break}T=n.return}return x=gs,gs=!1,x}function Jt(e,n,t){var r=n.updateQueue;if(r=r!==null?r.lastEffect:null,r!==null){var i=r=r.next;do{if((i.tag&e)===e){var l=i.destroy;i.destroy=void 0,l!==void 0&&uo(n,t,l)}i=i.next}while(i!==r)}}function Ai(e,n){if(n=n.updateQueue,n=n!==null?n.lastEffect:null,n!==null){var t=n=n.next;do{if((t.tag&e)===e){var r=t.create;t.destroy=r()}t=t.next}while(t!==n)}}function co(e){var n=e.ref;if(n!==null){var t=e.stateNode;switch(e.tag){case 5:e=t;break;default:e=t}typeof n=="function"?n(e):n.current=e}}function jc(e){var n=e.alternate;n!==null&&(e.alternate=null,jc(n)),e.child=null,e.deletions=null,e.sibling=null,e.tag===5&&(n=e.stateNode,n!==null&&(delete n[ln],delete n[pr],delete n[Xl],delete n[tp],delete n[rp])),e.stateNode=null,e.return=null,e.dependencies=null,e.memoizedProps=null,e.memoizedState=null,e.pendingProps=null,e.stateNode=null,e.updateQueue=null}function zc(e){return e.tag===5||e.tag===3||e.tag===4}function vs(e){e:for(;;){for(;e.sibling===null;){if(e.return===null||zc(e.return))return null;e=e.return}for(e.sibling.return=e.return,e=e.sibling;e.tag!==5&&e.tag!==6&&e.tag!==18;){if(e.flags&2||e.child===null||e.tag===4)continue e;e.child.return=e,e=e.child}if(!(e.flags&2))return e.stateNode}}function fo(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.nodeType===8?t.parentNode.insertBefore(e,n):t.insertBefore(e,n):(t.nodeType===8?(n=t.parentNode,n.insertBefore(e,t)):(n=t,n.appendChild(e)),t=t._reactRootContainer,t!=null||n.onclick!==null||(n.onclick=pi));else if(r!==4&&(e=e.child,e!==null))for(fo(e,n,t),e=e.sibling;e!==null;)fo(e,n,t),e=e.sibling}function po(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.insertBefore(e,n):t.appendChild(e);else if(r!==4&&(e=e.child,e!==null))for(po(e,n,t),e=e.sibling;e!==null;)po(e,n,t),e=e.sibling}var fe=null,Xe=!1;function xn(e,n,t){for(t=t.child;t!==null;)Lc(e,n,t),t=t.sibling}function Lc(e,n,t){if(on&&typeof on.onCommitFiberUnmount=="function")try{on.onCommitFiberUnmount(Ti,t)}catch{}switch(t.tag){case 5:xe||ht(t,n);case 6:var r=fe,i=Xe;fe=null,xn(e,n,t),fe=r,Xe=i,fe!==null&&(Xe?(e=fe,t=t.stateNode,e.nodeType===8?e.parentNode.removeChild(t):e.removeChild(t)):fe.removeChild(t.stateNode));break;case 18:fe!==null&&(Xe?(e=fe,t=t.stateNode,e.nodeType===8?cl(e.parentNode,t):e.nodeType===1&&cl(e,t),sr(e)):cl(fe,t.stateNode));break;case 4:r=fe,i=Xe,fe=t.stateNode.containerInfo,Xe=!0,xn(e,n,t),fe=r,Xe=i;break;case 0:case 11:case 14:case 15:if(!xe&&(r=t.updateQueue,r!==null&&(r=r.lastEffect,r!==null))){i=r=r.next;do{var l=i,o=l.destroy;l=l.tag,o!==void 0&&(l&2||l&4)&&uo(t,n,o),i=i.next}while(i!==r)}xn(e,n,t);break;case 1:if(!xe&&(ht(t,n),r=t.stateNode,typeof r.componentWillUnmount=="function"))try{r.props=t.memoizedProps,r.state=t.memoizedState,r.componentWillUnmount()}catch(a){ne(t,n,a)}xn(e,n,t);break;case 21:xn(e,n,t);break;case 22:t.mode&1?(xe=(r=xe)||t.memoizedState!==null,xn(e,n,t),xe=r):xn(e,n,t);break;default:xn(e,n,t)}}function ys(e){var n=e.updateQueue;if(n!==null){e.updateQueue=null;var t=e.stateNode;t===null&&(t=e.stateNode=new xp),n.forEach(function(r){var i=Np.bind(null,e,r);t.has(r)||(t.add(r),r.then(i,i))})}}function Ge(e,n){var t=n.deletions;if(t!==null)for(var r=0;r<t.length;r++){var i=t[r];try{var l=e,o=n,a=o;e:for(;a!==null;){switch(a.tag){case 5:fe=a.stateNode,Xe=!1;break e;case 3:fe=a.stateNode.containerInfo,Xe=!0;break e;case 4:fe=a.stateNode.containerInfo,Xe=!0;break e}a=a.return}if(fe===null)throw Error(S(160));Lc(l,o,i),fe=null,Xe=!1;var u=i.alternate;u!==null&&(u.return=null),i.return=null}catch(d){ne(i,n,d)}}if(n.subtreeFlags&12854)for(n=n.child;n!==null;)Rc(n,e),n=n.sibling}function Rc(e,n){var t=e.alternate,r=e.flags;switch(e.tag){case 0:case 11:case 14:case 15:if(Ge(n,e),tn(e),r&4){try{Jt(3,e,e.return),Ai(3,e)}catch(w){ne(e,e.return,w)}try{Jt(5,e,e.return)}catch(w){ne(e,e.return,w)}}break;case 1:Ge(n,e),tn(e),r&512&&t!==null&&ht(t,t.return);break;case 5:if(Ge(n,e),tn(e),r&512&&t!==null&&ht(t,t.return),e.flags&32){var i=e.stateNode;try{ir(i,"")}catch(w){ne(e,e.return,w)}}if(r&4&&(i=e.stateNode,i!=null)){var l=e.memoizedProps,o=t!==null?t.memoizedProps:l,a=e.type,u=e.updateQueue;if(e.updateQueue=null,u!==null)try{a==="input"&&l.type==="radio"&&l.name!=null&&ru(i,l),Ml(a,o);var d=Ml(a,l);for(o=0;o<u.length;o+=2){var v=u[o],m=u[o+1];v==="style"?su(i,m):v==="dangerouslySetInnerHTML"?ou(i,m):v==="children"?ir(i,m):Co(i,v,m,d)}switch(a){case"input":Tl(i,l);break;case"textarea":iu(i,l);break;case"select":var p=i._wrapperState.wasMultiple;i._wrapperState.wasMultiple=!!l.multiple;var g=l.value;g!=null?yt(i,!!l.multiple,g,!1):p!==!!l.multiple&&(l.defaultValue!=null?yt(i,!!l.multiple,l.defaultValue,!0):yt(i,!!l.multiple,l.multiple?[]:"",!1))}i[pr]=l}catch(w){ne(e,e.return,w)}}break;case 6:if(Ge(n,e),tn(e),r&4){if(e.stateNode===null)throw Error(S(162));i=e.stateNode,l=e.memoizedProps;try{i.nodeValue=l}catch(w){ne(e,e.return,w)}}break;case 3:if(Ge(n,e),tn(e),r&4&&t!==null&&t.memoizedState.isDehydrated)try{sr(n.containerInfo)}catch(w){ne(e,e.return,w)}break;case 4:Ge(n,e),tn(e);break;case 13:Ge(n,e),tn(e),i=e.child,i.flags&8192&&(l=i.memoizedState!==null,i.stateNode.isHidden=l,!l||i.alternate!==null&&i.alternate.memoizedState!==null||(ra=te())),r&4&&ys(e);break;case 22:if(v=t!==null&&t.memoizedState!==null,e.mode&1?(xe=(d=xe)||v,Ge(n,e),xe=d):Ge(n,e),tn(e),r&8192){if(d=e.memoizedState!==null,(e.stateNode.isHidden=d)&&!v&&e.mode&1)for(T=e,v=e.child;v!==null;){for(m=T=v;T!==null;){switch(p=T,g=p.child,p.tag){case 0:case 11:case 14:case 15:Jt(4,p,p.return);break;case 1:ht(p,p.return);var x=p.stateNode;if(typeof x.componentWillUnmount=="function"){r=p,t=p.return;try{n=r,x.props=n.memoizedProps,x.state=n.memoizedState,x.componentWillUnmount()}catch(w){ne(r,t,w)}}break;case 5:ht(p,p.return);break;case 22:if(p.memoizedState!==null){ws(m);continue}}g!==null?(g.return=p,T=g):ws(m)}v=v.sibling}e:for(v=null,m=e;;){if(m.tag===5){if(v===null){v=m;try{i=m.stateNode,d?(l=i.style,typeof l.setProperty=="function"?l.setProperty("display","none","important"):l.display="none"):(a=m.stateNode,u=m.memoizedProps.style,o=u!=null&&u.hasOwnProperty("display")?u.display:null,a.style.display=au("display",o))}catch(w){ne(e,e.return,w)}}}else if(m.tag===6){if(v===null)try{m.stateNode.nodeValue=d?"":m.memoizedProps}catch(w){ne(e,e.return,w)}}else if((m.tag!==22&&m.tag!==23||m.memoizedState===null||m===e)&&m.child!==null){m.child.return=m,m=m.child;continue}if(m===e)break e;for(;m.sibling===null;){if(m.return===null||m.return===e)break e;v===m&&(v=null),m=m.return}v===m&&(v=null),m.sibling.return=m.return,m=m.sibling}}break;case 19:Ge(n,e),tn(e),r&4&&ys(e);break;case 21:break;default:Ge(n,e),tn(e)}}function tn(e){var n=e.flags;if(n&2){try{e:{for(var t=e.return;t!==null;){if(zc(t)){var r=t;break e}t=t.return}throw Error(S(160))}switch(r.tag){case 5:var i=r.stateNode;r.flags&32&&(ir(i,""),r.flags&=-33);var l=vs(e);po(e,l,i);break;case 3:case 4:var o=r.stateNode.containerInfo,a=vs(e);fo(e,a,o);break;default:throw Error(S(161))}}catch(u){ne(e,e.return,u)}e.flags&=-3}n&4096&&(e.flags&=-4097)}function kp(e,n,t){T=e,Mc(e)}function Mc(e,n,t){for(var r=(e.mode&1)!==0;T!==null;){var i=T,l=i.child;if(i.tag===22&&r){var o=i.memoizedState!==null||Ur;if(!o){var a=i.alternate,u=a!==null&&a.memoizedState!==null||xe;a=Ur;var d=xe;if(Ur=o,(xe=u)&&!d)for(T=i;T!==null;)o=T,u=o.child,o.tag===22&&o.memoizedState!==null?ks(i):u!==null?(u.return=o,T=u):ks(i);for(;l!==null;)T=l,Mc(l),l=l.sibling;T=i,Ur=a,xe=d}xs(e)}else i.subtreeFlags&8772&&l!==null?(l.return=i,T=l):xs(e)}}function xs(e){for(;T!==null;){var n=T;if(n.flags&8772){var t=n.alternate;try{if(n.flags&8772)switch(n.tag){case 0:case 11:case 15:xe||Ai(5,n);break;case 1:var r=n.stateNode;if(n.flags&4&&!xe)if(t===null)r.componentDidMount();else{var i=n.elementType===n.type?t.memoizedProps:Ye(n.type,t.memoizedProps);r.componentDidUpdate(i,t.memoizedState,r.__reactInternalSnapshotBeforeUpdate)}var l=n.updateQueue;l!==null&&rs(n,l,r);break;case 3:var o=n.updateQueue;if(o!==null){if(t=null,n.child!==null)switch(n.child.tag){case 5:t=n.child.stateNode;break;case 1:t=n.child.stateNode}rs(n,o,t)}break;case 5:var a=n.stateNode;if(t===null&&n.flags&4){t=a;var u=n.memoizedProps;switch(n.type){case"button":case"input":case"select":case"textarea":u.autoFocus&&t.focus();break;case"img":u.src&&(t.src=u.src)}}break;case 6:break;case 4:break;case 12:break;case 13:if(n.memoizedState===null){var d=n.alternate;if(d!==null){var v=d.memoizedState;if(v!==null){var m=v.dehydrated;m!==null&&sr(m)}}}break;case 19:case 17:case 21:case 22:case 23:case 25:break;default:throw Error(S(163))}xe||n.flags&512&&co(n)}catch(p){ne(n,n.return,p)}}if(n===e){T=null;break}if(t=n.sibling,t!==null){t.return=n.return,T=t;break}T=n.return}}function ws(e){for(;T!==null;){var n=T;if(n===e){T=null;break}var t=n.sibling;if(t!==null){t.return=n.return,T=t;break}T=n.return}}function ks(e){for(;T!==null;){var n=T;try{switch(n.tag){case 0:case 11:case 15:var t=n.return;try{Ai(4,n)}catch(u){ne(n,t,u)}break;case 1:var r=n.stateNode;if(typeof r.componentDidMount=="function"){var i=n.return;try{r.componentDidMount()}catch(u){ne(n,i,u)}}var l=n.return;try{co(n)}catch(u){ne(n,l,u)}break;case 5:var o=n.return;try{co(n)}catch(u){ne(n,o,u)}}}catch(u){ne(n,n.return,u)}if(n===e){T=null;break}var a=n.sibling;if(a!==null){a.return=n.return,T=a;break}T=n.return}}var _p=Math.ceil,Ci=yn.ReactCurrentDispatcher,na=yn.ReactCurrentOwner,Ve=yn.ReactCurrentBatchConfig,U=0,de=null,le=null,me=0,Le=0,gt=On(0),ae=0,xr=null,Zn=0,Ii=0,ta=0,er=null,$e=null,ra=0,Ft=1/0,un=null,Ei=!1,mo=null,Tn=null,Br=!1,En=null,bi=0,nr=0,ho=null,ni=-1,ti=0;function Ce(){return U&6?te():ni!==-1?ni:ni=te()}function jn(e){return e.mode&1?U&2&&me!==0?me&-me:lp.transition!==null?(ti===0&&(ti=wu()),ti):(e=V,e!==0||(e=window.event,e=e===void 0?16:$u(e.type)),e):1}function Je(e,n,t,r){if(50<nr)throw nr=0,ho=null,Error(S(185));_r(e,t,r),(!(U&2)||e!==de)&&(e===de&&(!(U&2)&&(Ii|=t),ae===4&&Sn(e,me)),Te(e,r),t===1&&U===0&&!(n.mode&1)&&(Ft=te()+500,Mi&&An()))}function Te(e,n){var t=e.callbackNode;lf(e,n);var r=ui(e,e===de?me:0);if(r===0)t!==null&&Fa(t),e.callbackNode=null,e.callbackPriority=0;else if(n=r&-r,e.callbackPriority!==n){if(t!=null&&Fa(t),n===1)e.tag===0?ip(_s.bind(null,e)):Qu(_s.bind(null,e)),ep(function(){!(U&6)&&An()}),t=null;else{switch(ku(r)){case 1:t=No;break;case 4:t=yu;break;case 16:t=si;break;case 536870912:t=xu;break;default:t=si}t=Hc(t,Dc.bind(null,e))}e.callbackPriority=n,e.callbackNode=t}}function Dc(e,n){if(ni=-1,ti=0,U&6)throw Error(S(327));var t=e.callbackNode;if(St()&&e.callbackNode!==t)return null;var r=ui(e,e===de?me:0);if(r===0)return null;if(r&30||r&e.expiredLanes||n)n=$i(e,r);else{n=r;var i=U;U|=2;var l=Ac();(de!==e||me!==n)&&(un=null,Ft=te()+500,Qn(e,n));do try{Ep();break}catch(a){Oc(e,a)}while(!0);Bo(),Ci.current=l,U=i,le!==null?n=0:(de=null,me=0,n=ae)}if(n!==0){if(n===2&&(i=Ul(e),i!==0&&(r=i,n=go(e,i))),n===1)throw t=xr,Qn(e,0),Sn(e,r),Te(e,te()),t;if(n===6)Sn(e,r);else{if(i=e.current.alternate,!(r&30)&&!Sp(i)&&(n=$i(e,r),n===2&&(l=Ul(e),l!==0&&(r=l,n=go(e,l))),n===1))throw t=xr,Qn(e,0),Sn(e,r),Te(e,te()),t;switch(e.finishedWork=i,e.finishedLanes=r,n){case 0:case 1:throw Error(S(345));case 2:Bn(e,$e,un);break;case 3:if(Sn(e,r),(r&130023424)===r&&(n=ra+500-te(),10<n)){if(ui(e,0)!==0)break;if(i=e.suspendedLanes,(i&r)!==r){Ce(),e.pingedLanes|=e.suspendedLanes&i;break}e.timeoutHandle=Yl(Bn.bind(null,e,$e,un),n);break}Bn(e,$e,un);break;case 4:if(Sn(e,r),(r&4194240)===r)break;for(n=e.eventTimes,i=-1;0<r;){var o=31-qe(r);l=1<<o,o=n[o],o>i&&(i=o),r&=~l}if(r=i,r=te()-r,r=(120>r?120:480>r?480:1080>r?1080:1920>r?1920:3e3>r?3e3:4320>r?4320:1960*_p(r/1960))-r,10<r){e.timeoutHandle=Yl(Bn.bind(null,e,$e,un),r);break}Bn(e,$e,un);break;case 5:Bn(e,$e,un);break;default:throw Error(S(329))}}}return Te(e,te()),e.callbackNode===t?Dc.bind(null,e):null}function go(e,n){var t=er;return e.current.memoizedState.isDehydrated&&(Qn(e,n).flags|=256),e=$i(e,n),e!==2&&(n=$e,$e=t,n!==null&&vo(n)),e}function vo(e){$e===null?$e=e:$e.push.apply($e,e)}function Sp(e){for(var n=e;;){if(n.flags&16384){var t=n.updateQueue;if(t!==null&&(t=t.stores,t!==null))for(var r=0;r<t.length;r++){var i=t[r],l=i.getSnapshot;i=i.value;try{if(!en(l(),i))return!1}catch{return!1}}}if(t=n.child,n.subtreeFlags&16384&&t!==null)t.return=n,n=t;else{if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return!0;n=n.return}n.sibling.return=n.return,n=n.sibling}}return!0}function Sn(e,n){for(n&=~ta,n&=~Ii,e.suspendedLanes|=n,e.pingedLanes&=~n,e=e.expirationTimes;0<n;){var t=31-qe(n),r=1<<t;e[t]=-1,n&=~r}}function _s(e){if(U&6)throw Error(S(327));St();var n=ui(e,0);if(!(n&1))return Te(e,te()),null;var t=$i(e,n);if(e.tag!==0&&t===2){var r=Ul(e);r!==0&&(n=r,t=go(e,r))}if(t===1)throw t=xr,Qn(e,0),Sn(e,n),Te(e,te()),t;if(t===6)throw Error(S(345));return e.finishedWork=e.current.alternate,e.finishedLanes=n,Bn(e,$e,un),Te(e,te()),null}function ia(e,n){var t=U;U|=1;try{return e(n)}finally{U=t,U===0&&(Ft=te()+500,Mi&&An())}}function qn(e){En!==null&&En.tag===0&&!(U&6)&&St();var n=U;U|=1;var t=Ve.transition,r=V;try{if(Ve.transition=null,V=1,e)return e()}finally{V=r,Ve.transition=t,U=n,!(U&6)&&An()}}function la(){Le=gt.current,Y(gt)}function Qn(e,n){e.finishedWork=null,e.finishedLanes=0;var t=e.timeoutHandle;if(t!==-1&&(e.timeoutHandle=-1,Jf(t)),le!==null)for(t=le.return;t!==null;){var r=t;switch(Ao(r),r.tag){case 1:r=r.type.childContextTypes,r!=null&&mi();break;case 3:Pt(),Y(Ne),Y(we),Go();break;case 5:Ko(r);break;case 4:Pt();break;case 13:Y(q);break;case 19:Y(q);break;case 10:Wo(r.type._context);break;case 22:case 23:la()}t=t.return}if(de=e,le=e=zn(e.current,null),me=Le=n,ae=0,xr=null,ta=Ii=Zn=0,$e=er=null,Hn!==null){for(n=0;n<Hn.length;n++)if(t=Hn[n],r=t.interleaved,r!==null){t.interleaved=null;var i=r.next,l=t.pending;if(l!==null){var o=l.next;l.next=i,r.next=o}t.pending=r}Hn=null}return e}function Oc(e,n){do{var t=le;try{if(Bo(),qr.current=Si,_i){for(var r=J.memoizedState;r!==null;){var i=r.queue;i!==null&&(i.pending=null),r=r.next}_i=!1}if(Xn=0,ce=oe=J=null,qt=!1,gr=0,na.current=null,t===null||t.return===null){ae=1,xr=n,le=null;break}e:{var l=e,o=t.return,a=t,u=n;if(n=me,a.flags|=32768,u!==null&&typeof u=="object"&&typeof u.then=="function"){var d=u,v=a,m=v.tag;if(!(v.mode&1)&&(m===0||m===11||m===15)){var p=v.alternate;p?(v.updateQueue=p.updateQueue,v.memoizedState=p.memoizedState,v.lanes=p.lanes):(v.updateQueue=null,v.memoizedState=null)}var g=us(o);if(g!==null){g.flags&=-257,cs(g,o,a,l,n),g.mode&1&&ss(l,d,n),n=g,u=d;var x=n.updateQueue;if(x===null){var w=new Set;w.add(u),n.updateQueue=w}else x.add(u);break e}else{if(!(n&1)){ss(l,d,n),oa();break e}u=Error(S(426))}}else if(Z&&a.mode&1){var z=us(o);if(z!==null){!(z.flags&65536)&&(z.flags|=256),cs(z,o,a,l,n),Io(Nt(u,a));break e}}l=u=Nt(u,a),ae!==4&&(ae=2),er===null?er=[l]:er.push(l),l=o;do{switch(l.tag){case 3:l.flags|=65536,n&=-n,l.lanes|=n;var c=kc(l,u,n);ts(l,c);break e;case 1:a=u;var s=l.type,f=l.stateNode;if(!(l.flags&128)&&(typeof s.getDerivedStateFromError=="function"||f!==null&&typeof f.componentDidCatch=="function"&&(Tn===null||!Tn.has(f)))){l.flags|=65536,n&=-n,l.lanes|=n;var h=_c(l,a,n);ts(l,h);break e}}l=l.return}while(l!==null)}Uc(t)}catch(_){n=_,le===t&&t!==null&&(le=t=t.return);continue}break}while(!0)}function Ac(){var e=Ci.current;return Ci.current=Si,e===null?Si:e}function oa(){(ae===0||ae===3||ae===2)&&(ae=4),de===null||!(Zn&268435455)&&!(Ii&268435455)||Sn(de,me)}function $i(e,n){var t=U;U|=2;var r=Ac();(de!==e||me!==n)&&(un=null,Qn(e,n));do try{Cp();break}catch(i){Oc(e,i)}while(!0);if(Bo(),U=t,Ci.current=r,le!==null)throw Error(S(261));return de=null,me=0,ae}function Cp(){for(;le!==null;)Ic(le)}function Ep(){for(;le!==null&&!Yd();)Ic(le)}function Ic(e){var n=Wc(e.alternate,e,Le);e.memoizedProps=e.pendingProps,n===null?Uc(e):le=n,na.current=null}function Uc(e){var n=e;do{var t=n.alternate;if(e=n.return,n.flags&32768){if(t=yp(t,n),t!==null){t.flags&=32767,le=t;return}if(e!==null)e.flags|=32768,e.subtreeFlags=0,e.deletions=null;else{ae=6,le=null;return}}else if(t=vp(t,n,Le),t!==null){le=t;return}if(n=n.sibling,n!==null){le=n;return}le=n=e}while(n!==null);ae===0&&(ae=5)}function Bn(e,n,t){var r=V,i=Ve.transition;try{Ve.transition=null,V=1,bp(e,n,t,r)}finally{Ve.transition=i,V=r}return null}function bp(e,n,t,r){do St();while(En!==null);if(U&6)throw Error(S(327));t=e.finishedWork;var i=e.finishedLanes;if(t===null)return null;if(e.finishedWork=null,e.finishedLanes=0,t===e.current)throw Error(S(177));e.callbackNode=null,e.callbackPriority=0;var l=t.lanes|t.childLanes;if(of(e,l),e===de&&(le=de=null,me=0),!(t.subtreeFlags&2064)&&!(t.flags&2064)||Br||(Br=!0,Hc(si,function(){return St(),null})),l=(t.flags&15990)!==0,t.subtreeFlags&15990||l){l=Ve.transition,Ve.transition=null;var o=V;V=1;var a=U;U|=4,na.current=null,wp(e,t),Rc(t,e),Qf(Kl),ci=!!Ql,Kl=Ql=null,e.current=t,kp(t),Xd(),U=a,V=o,Ve.transition=l}else e.current=t;if(Br&&(Br=!1,En=e,bi=i),l=e.pendingLanes,l===0&&(Tn=null),Jd(t.stateNode),Te(e,te()),n!==null)for(r=e.onRecoverableError,t=0;t<n.length;t++)i=n[t],r(i.value,{componentStack:i.stack,digest:i.digest});if(Ei)throw Ei=!1,e=mo,mo=null,e;return bi&1&&e.tag!==0&&St(),l=e.pendingLanes,l&1?e===ho?nr++:(nr=0,ho=e):nr=0,An(),null}function St(){if(En!==null){var e=ku(bi),n=Ve.transition,t=V;try{if(Ve.transition=null,V=16>e?16:e,En===null)var r=!1;else{if(e=En,En=null,bi=0,U&6)throw Error(S(331));var i=U;for(U|=4,T=e.current;T!==null;){var l=T,o=l.child;if(T.flags&16){var a=l.deletions;if(a!==null){for(var u=0;u<a.length;u++){var d=a[u];for(T=d;T!==null;){var v=T;switch(v.tag){case 0:case 11:case 15:Jt(8,v,l)}var m=v.child;if(m!==null)m.return=v,T=m;else for(;T!==null;){v=T;var p=v.sibling,g=v.return;if(jc(v),v===d){T=null;break}if(p!==null){p.return=g,T=p;break}T=g}}}var x=l.alternate;if(x!==null){var w=x.child;if(w!==null){x.child=null;do{var z=w.sibling;w.sibling=null,w=z}while(w!==null)}}T=l}}if(l.subtreeFlags&2064&&o!==null)o.return=l,T=o;else e:for(;T!==null;){if(l=T,l.flags&2048)switch(l.tag){case 0:case 11:case 15:Jt(9,l,l.return)}var c=l.sibling;if(c!==null){c.return=l.return,T=c;break e}T=l.return}}var s=e.current;for(T=s;T!==null;){o=T;var f=o.child;if(o.subtreeFlags&2064&&f!==null)f.return=o,T=f;else e:for(o=s;T!==null;){if(a=T,a.flags&2048)try{switch(a.tag){case 0:case 11:case 15:Ai(9,a)}}catch(_){ne(a,a.return,_)}if(a===o){T=null;break e}var h=a.sibling;if(h!==null){h.return=a.return,T=h;break e}T=a.return}}if(U=i,An(),on&&typeof on.onPostCommitFiberRoot=="function")try{on.onPostCommitFiberRoot(Ti,e)}catch{}r=!0}return r}finally{V=t,Ve.transition=n}}return!1}function Ss(e,n,t){n=Nt(t,n),n=kc(e,n,1),e=Fn(e,n,1),n=Ce(),e!==null&&(_r(e,1,n),Te(e,n))}function ne(e,n,t){if(e.tag===3)Ss(e,e,t);else for(;n!==null;){if(n.tag===3){Ss(n,e,t);break}else if(n.tag===1){var r=n.stateNode;if(typeof n.type.getDerivedStateFromError=="function"||typeof r.componentDidCatch=="function"&&(Tn===null||!Tn.has(r))){e=Nt(t,e),e=_c(n,e,1),n=Fn(n,e,1),e=Ce(),n!==null&&(_r(n,1,e),Te(n,e));break}}n=n.return}}function $p(e,n,t){var r=e.pingCache;r!==null&&r.delete(n),n=Ce(),e.pingedLanes|=e.suspendedLanes&t,de===e&&(me&t)===t&&(ae===4||ae===3&&(me&130023424)===me&&500>te()-ra?Qn(e,0):ta|=t),Te(e,n)}function Bc(e,n){n===0&&(e.mode&1?(n=jr,jr<<=1,!(jr&130023424)&&(jr=4194304)):n=1);var t=Ce();e=gn(e,n),e!==null&&(_r(e,n,t),Te(e,t))}function Pp(e){var n=e.memoizedState,t=0;n!==null&&(t=n.retryLane),Bc(e,t)}function Np(e,n){var t=0;switch(e.tag){case 13:var r=e.stateNode,i=e.memoizedState;i!==null&&(t=i.retryLane);break;case 19:r=e.stateNode;break;default:throw Error(S(314))}r!==null&&r.delete(n),Bc(e,t)}var Wc;Wc=function(e,n,t){if(e!==null)if(e.memoizedProps!==n.pendingProps||Ne.current)Pe=!0;else{if(!(e.lanes&t)&&!(n.flags&128))return Pe=!1,gp(e,n,t);Pe=!!(e.flags&131072)}else Pe=!1,Z&&n.flags&1048576&&Ku(n,vi,n.index);switch(n.lanes=0,n.tag){case 2:var r=n.type;ei(e,n),e=n.pendingProps;var i=Et(n,we.current);_t(n,t),i=Xo(null,n,r,e,i,t);var l=Zo();return n.flags|=1,typeof i=="object"&&i!==null&&typeof i.render=="function"&&i.$$typeof===void 0?(n.tag=1,n.memoizedState=null,n.updateQueue=null,Fe(r)?(l=!0,hi(n)):l=!1,n.memoizedState=i.state!==null&&i.state!==void 0?i.state:null,Vo(n),i.updater=Oi,n.stateNode=i,i._reactInternals=n,to(n,r,e,t),n=lo(null,n,r,!0,l,t)):(n.tag=0,Z&&l&&Oo(n),Se(null,n,i,t),n=n.child),n;case 16:r=n.elementType;e:{switch(ei(e,n),e=n.pendingProps,i=r._init,r=i(r._payload),n.type=r,i=n.tag=Tp(r),e=Ye(r,e),i){case 0:n=io(null,n,r,e,t);break e;case 1:n=ps(null,n,r,e,t);break e;case 11:n=ds(null,n,r,e,t);break e;case 14:n=fs(null,n,r,Ye(r.type,e),t);break e}throw Error(S(306,r,""))}return n;case 0:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ye(r,i),io(e,n,r,i,t);case 1:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ye(r,i),ps(e,n,r,i,t);case 3:e:{if(bc(n),e===null)throw Error(S(387));r=n.pendingProps,l=n.memoizedState,i=l.element,Ju(e,n),wi(n,r,null,t);var o=n.memoizedState;if(r=o.element,l.isDehydrated)if(l={element:r,isDehydrated:!1,cache:o.cache,pendingSuspenseBoundaries:o.pendingSuspenseBoundaries,transitions:o.transitions},n.updateQueue.baseState=l,n.memoizedState=l,n.flags&256){i=Nt(Error(S(423)),n),n=ms(e,n,r,t,i);break e}else if(r!==i){i=Nt(Error(S(424)),n),n=ms(e,n,r,t,i);break e}else for(Me=Nn(n.stateNode.containerInfo.firstChild),De=n,Z=!0,Ze=null,t=Zu(n,null,r,t),n.child=t;t;)t.flags=t.flags&-3|4096,t=t.sibling;else{if(bt(),r===i){n=vn(e,n,t);break e}Se(e,n,r,t)}n=n.child}return n;case 5:return ec(n),e===null&&Jl(n),r=n.type,i=n.pendingProps,l=e!==null?e.memoizedProps:null,o=i.children,Gl(r,i)?o=null:l!==null&&Gl(r,l)&&(n.flags|=32),Ec(e,n),Se(e,n,o,t),n.child;case 6:return e===null&&Jl(n),null;case 13:return $c(e,n,t);case 4:return Qo(n,n.stateNode.containerInfo),r=n.pendingProps,e===null?n.child=$t(n,null,r,t):Se(e,n,r,t),n.child;case 11:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ye(r,i),ds(e,n,r,i,t);case 7:return Se(e,n,n.pendingProps,t),n.child;case 8:return Se(e,n,n.pendingProps.children,t),n.child;case 12:return Se(e,n,n.pendingProps.children,t),n.child;case 10:e:{if(r=n.type._context,i=n.pendingProps,l=n.memoizedProps,o=i.value,Q(yi,r._currentValue),r._currentValue=o,l!==null)if(en(l.value,o)){if(l.children===i.children&&!Ne.current){n=vn(e,n,t);break e}}else for(l=n.child,l!==null&&(l.return=n);l!==null;){var a=l.dependencies;if(a!==null){o=l.child;for(var u=a.firstContext;u!==null;){if(u.context===r){if(l.tag===1){u=pn(-1,t&-t),u.tag=2;var d=l.updateQueue;if(d!==null){d=d.shared;var v=d.pending;v===null?u.next=u:(u.next=v.next,v.next=u),d.pending=u}}l.lanes|=t,u=l.alternate,u!==null&&(u.lanes|=t),eo(l.return,t,n),a.lanes|=t;break}u=u.next}}else if(l.tag===10)o=l.type===n.type?null:l.child;else if(l.tag===18){if(o=l.return,o===null)throw Error(S(341));o.lanes|=t,a=o.alternate,a!==null&&(a.lanes|=t),eo(o,t,n),o=l.sibling}else o=l.child;if(o!==null)o.return=l;else for(o=l;o!==null;){if(o===n){o=null;break}if(l=o.sibling,l!==null){l.return=o.return,o=l;break}o=o.return}l=o}Se(e,n,i.children,t),n=n.child}return n;case 9:return i=n.type,r=n.pendingProps.children,_t(n,t),i=Qe(i),r=r(i),n.flags|=1,Se(e,n,r,t),n.child;case 14:return r=n.type,i=Ye(r,n.pendingProps),i=Ye(r.type,i),fs(e,n,r,i,t);case 15:return Sc(e,n,n.type,n.pendingProps,t);case 17:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ye(r,i),ei(e,n),n.tag=1,Fe(r)?(e=!0,hi(n)):e=!1,_t(n,t),wc(n,r,i),to(n,r,i,t),lo(null,n,r,!0,e,t);case 19:return Pc(e,n,t);case 22:return Cc(e,n,t)}throw Error(S(156,n.tag))};function Hc(e,n){return vu(e,n)}function Fp(e,n,t,r){this.tag=e,this.key=t,this.sibling=this.child=this.return=this.stateNode=this.type=this.elementType=null,this.index=0,this.ref=null,this.pendingProps=n,this.dependencies=this.memoizedState=this.updateQueue=this.memoizedProps=null,this.mode=r,this.subtreeFlags=this.flags=0,this.deletions=null,this.childLanes=this.lanes=0,this.alternate=null}function He(e,n,t,r){return new Fp(e,n,t,r)}function aa(e){return e=e.prototype,!(!e||!e.isReactComponent)}function Tp(e){if(typeof e=="function")return aa(e)?1:0;if(e!=null){if(e=e.$$typeof,e===bo)return 11;if(e===$o)return 14}return 2}function zn(e,n){var t=e.alternate;return t===null?(t=He(e.tag,n,e.key,e.mode),t.elementType=e.elementType,t.type=e.type,t.stateNode=e.stateNode,t.alternate=e,e.alternate=t):(t.pendingProps=n,t.type=e.type,t.flags=0,t.subtreeFlags=0,t.deletions=null),t.flags=e.flags&14680064,t.childLanes=e.childLanes,t.lanes=e.lanes,t.child=e.child,t.memoizedProps=e.memoizedProps,t.memoizedState=e.memoizedState,t.updateQueue=e.updateQueue,n=e.dependencies,t.dependencies=n===null?null:{lanes:n.lanes,firstContext:n.firstContext},t.sibling=e.sibling,t.index=e.index,t.ref=e.ref,t}function ri(e,n,t,r,i,l){var o=2;if(r=e,typeof e=="function")aa(e)&&(o=1);else if(typeof e=="string")o=5;else e:switch(e){case ot:return Kn(t.children,i,l,n);case Eo:o=8,i|=8;break;case bl:return e=He(12,t,n,i|2),e.elementType=bl,e.lanes=l,e;case $l:return e=He(13,t,n,i),e.elementType=$l,e.lanes=l,e;case Pl:return e=He(19,t,n,i),e.elementType=Pl,e.lanes=l,e;case eu:return Ui(t,i,l,n);default:if(typeof e=="object"&&e!==null)switch(e.$$typeof){case qs:o=10;break e;case Js:o=9;break e;case bo:o=11;break e;case $o:o=14;break e;case wn:o=16,r=null;break e}throw Error(S(130,e==null?e:typeof e,""))}return n=He(o,t,n,i),n.elementType=e,n.type=r,n.lanes=l,n}function Kn(e,n,t,r){return e=He(7,e,r,n),e.lanes=t,e}function Ui(e,n,t,r){return e=He(22,e,r,n),e.elementType=eu,e.lanes=t,e.stateNode={isHidden:!1},e}function yl(e,n,t){return e=He(6,e,null,n),e.lanes=t,e}function xl(e,n,t){return n=He(4,e.children!==null?e.children:[],e.key,n),n.lanes=t,n.stateNode={containerInfo:e.containerInfo,pendingChildren:null,implementation:e.implementation},n}function jp(e,n,t,r,i){this.tag=n,this.containerInfo=e,this.finishedWork=this.pingCache=this.current=this.pendingChildren=null,this.timeoutHandle=-1,this.callbackNode=this.pendingContext=this.context=null,this.callbackPriority=0,this.eventTimes=Ji(0),this.expirationTimes=Ji(-1),this.entangledLanes=this.finishedLanes=this.mutableReadLanes=this.expiredLanes=this.pingedLanes=this.suspendedLanes=this.pendingLanes=0,this.entanglements=Ji(0),this.identifierPrefix=r,this.onRecoverableError=i,this.mutableSourceEagerHydrationData=null}function sa(e,n,t,r,i,l,o,a,u){return e=new jp(e,n,t,a,u),n===1?(n=1,l===!0&&(n|=8)):n=0,l=He(3,null,null,n),e.current=l,l.stateNode=e,l.memoizedState={element:r,isDehydrated:t,cache:null,transitions:null,pendingSuspenseBoundaries:null},Vo(l),e}function zp(e,n,t){var r=3<arguments.length&&arguments[3]!==void 0?arguments[3]:null;return{$$typeof:lt,key:r==null?null:""+r,children:e,containerInfo:n,implementation:t}}function Vc(e){if(!e)return Mn;e=e._reactInternals;e:{if(et(e)!==e||e.tag!==1)throw Error(S(170));var n=e;do{switch(n.tag){case 3:n=n.stateNode.context;break e;case 1:if(Fe(n.type)){n=n.stateNode.__reactInternalMemoizedMergedChildContext;break e}}n=n.return}while(n!==null);throw Error(S(171))}if(e.tag===1){var t=e.type;if(Fe(t))return Vu(e,t,n)}return n}function Qc(e,n,t,r,i,l,o,a,u){return e=sa(t,r,!0,e,i,l,o,a,u),e.context=Vc(null),t=e.current,r=Ce(),i=jn(t),l=pn(r,i),l.callback=n??null,Fn(t,l,i),e.current.lanes=i,_r(e,i,r),Te(e,r),e}function Bi(e,n,t,r){var i=n.current,l=Ce(),o=jn(i);return t=Vc(t),n.context===null?n.context=t:n.pendingContext=t,n=pn(l,o),n.payload={element:e},r=r===void 0?null:r,r!==null&&(n.callback=r),e=Fn(i,n,o),e!==null&&(Je(e,i,o,l),Zr(e,i,o)),o}function Pi(e){if(e=e.current,!e.child)return null;switch(e.child.tag){case 5:return e.child.stateNode;default:return e.child.stateNode}}function Cs(e,n){if(e=e.memoizedState,e!==null&&e.dehydrated!==null){var t=e.retryLane;e.retryLane=t!==0&&t<n?t:n}}function ua(e,n){Cs(e,n),(e=e.alternate)&&Cs(e,n)}function Lp(){return null}var Kc=typeof reportError=="function"?reportError:function(e){console.error(e)};function ca(e){this._internalRoot=e}Wi.prototype.render=ca.prototype.render=function(e){var n=this._internalRoot;if(n===null)throw Error(S(409));Bi(e,n,null,null)};Wi.prototype.unmount=ca.prototype.unmount=function(){var e=this._internalRoot;if(e!==null){this._internalRoot=null;var n=e.containerInfo;qn(function(){Bi(null,e,null,null)}),n[hn]=null}};function Wi(e){this._internalRoot=e}Wi.prototype.unstable_scheduleHydration=function(e){if(e){var n=Cu();e={blockedOn:null,target:e,priority:n};for(var t=0;t<_n.length&&n!==0&&n<_n[t].priority;t++);_n.splice(t,0,e),t===0&&bu(e)}};function da(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11)}function Hi(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11&&(e.nodeType!==8||e.nodeValue!==" react-mount-point-unstable "))}function Es(){}function Rp(e,n,t,r,i){if(i){if(typeof r=="function"){var l=r;r=function(){var d=Pi(o);l.call(d)}}var o=Qc(n,r,e,0,null,!1,!1,"",Es);return e._reactRootContainer=o,e[hn]=o.current,dr(e.nodeType===8?e.parentNode:e),qn(),o}for(;i=e.lastChild;)e.removeChild(i);if(typeof r=="function"){var a=r;r=function(){var d=Pi(u);a.call(d)}}var u=sa(e,0,!1,null,null,!1,!1,"",Es);return e._reactRootContainer=u,e[hn]=u.current,dr(e.nodeType===8?e.parentNode:e),qn(function(){Bi(n,u,t,r)}),u}function Vi(e,n,t,r,i){var l=t._reactRootContainer;if(l){var o=l;if(typeof i=="function"){var a=i;i=function(){var u=Pi(o);a.call(u)}}Bi(n,o,e,i)}else o=Rp(t,n,e,i,r);return Pi(o)}_u=function(e){switch(e.tag){case 3:var n=e.stateNode;if(n.current.memoizedState.isDehydrated){var t=Ht(n.pendingLanes);t!==0&&(Fo(n,t|1),Te(n,te()),!(U&6)&&(Ft=te()+500,An()))}break;case 13:qn(function(){var r=gn(e,1);if(r!==null){var i=Ce();Je(r,e,1,i)}}),ua(e,1)}};To=function(e){if(e.tag===13){var n=gn(e,134217728);if(n!==null){var t=Ce();Je(n,e,134217728,t)}ua(e,134217728)}};Su=function(e){if(e.tag===13){var n=jn(e),t=gn(e,n);if(t!==null){var r=Ce();Je(t,e,n,r)}ua(e,n)}};Cu=function(){return V};Eu=function(e,n){var t=V;try{return V=e,n()}finally{V=t}};Ol=function(e,n,t){switch(n){case"input":if(Tl(e,t),n=t.name,t.type==="radio"&&n!=null){for(t=e;t.parentNode;)t=t.parentNode;for(t=t.querySelectorAll("input[name="+JSON.stringify(""+n)+'][type="radio"]'),n=0;n<t.length;n++){var r=t[n];if(r!==e&&r.form===e.form){var i=Ri(r);if(!i)throw Error(S(90));tu(r),Tl(r,i)}}}break;case"textarea":iu(e,t);break;case"select":n=t.value,n!=null&&yt(e,!!t.multiple,n,!1)}};du=ia;fu=qn;var Mp={usingClientEntryPoint:!1,Events:[Cr,ct,Ri,uu,cu,ia]},Ut={findFiberByHostInstance:Wn,bundleType:0,version:"18.3.1",rendererPackageName:"react-dom"},Dp={bundleType:Ut.bundleType,version:Ut.version,rendererPackageName:Ut.rendererPackageName,rendererConfig:Ut.rendererConfig,overrideHookState:null,overrideHookStateDeletePath:null,overrideHookStateRenamePath:null,overrideProps:null,overridePropsDeletePath:null,overridePropsRenamePath:null,setErrorHandler:null,setSuspenseHandler:null,scheduleUpdate:null,currentDispatcherRef:yn.ReactCurrentDispatcher,findHostInstanceByFiber:function(e){return e=hu(e),e===null?null:e.stateNode},findFiberByHostInstance:Ut.findFiberByHostInstance||Lp,findHostInstancesForRefresh:null,scheduleRefresh:null,scheduleRoot:null,setRefreshHandler:null,getCurrentFiber:null,reconcilerVersion:"18.3.1-next-f1338f8080-20240426"};if(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__<"u"){var Wr=__REACT_DEVTOOLS_GLOBAL_HOOK__;if(!Wr.isDisabled&&Wr.supportsFiber)try{Ti=Wr.inject(Dp),on=Wr}catch{}}Ae.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Mp;Ae.createPortal=function(e,n){var t=2<arguments.length&&arguments[2]!==void 0?arguments[2]:null;if(!da(n))throw Error(S(200));return zp(e,n,null,t)};Ae.createRoot=function(e,n){if(!da(e))throw Error(S(299));var t=!1,r="",i=Kc;return n!=null&&(n.unstable_strictMode===!0&&(t=!0),n.identifierPrefix!==void 0&&(r=n.identifierPrefix),n.onRecoverableError!==void 0&&(i=n.onRecoverableError)),n=sa(e,1,!1,null,null,t,!1,r,i),e[hn]=n.current,dr(e.nodeType===8?e.parentNode:e),new ca(n)};Ae.findDOMNode=function(e){if(e==null)return null;if(e.nodeType===1)return e;var n=e._reactInternals;if(n===void 0)throw typeof e.render=="function"?Error(S(188)):(e=Object.keys(e).join(","),Error(S(268,e)));return e=hu(n),e=e===null?null:e.stateNode,e};Ae.flushSync=function(e){return qn(e)};Ae.hydrate=function(e,n,t){if(!Hi(n))throw Error(S(200));return Vi(null,e,n,!0,t)};Ae.hydrateRoot=function(e,n,t){if(!da(e))throw Error(S(405));var r=t!=null&&t.hydratedSources||null,i=!1,l="",o=Kc;if(t!=null&&(t.unstable_strictMode===!0&&(i=!0),t.identifierPrefix!==void 0&&(l=t.identifierPrefix),t.onRecoverableError!==void 0&&(o=t.onRecoverableError)),n=Qc(n,null,e,1,t??null,i,!1,l,o),e[hn]=n.current,dr(e),r)for(e=0;e<r.length;e++)t=r[e],i=t._getVersion,i=i(t._source),n.mutableSourceEagerHydrationData==null?n.mutableSourceEagerHydrationData=[t,i]:n.mutableSourceEagerHydrationData.push(t,i);return new Wi(n)};Ae.render=function(e,n,t){if(!Hi(n))throw Error(S(200));return Vi(null,e,n,!1,t)};Ae.unmountComponentAtNode=function(e){if(!Hi(e))throw Error(S(40));return e._reactRootContainer?(qn(function(){Vi(null,null,e,!1,function(){e._reactRootContainer=null,e[hn]=null})}),!0):!1};Ae.unstable_batchedUpdates=ia;Ae.unstable_renderSubtreeIntoContainer=function(e,n,t,r){if(!Hi(t))throw Error(S(200));if(e==null||e._reactInternals===void 0)throw Error(S(38));return Vi(e,n,t,!1,r)};Ae.version="18.3.1-next-f1338f8080-20240426";function Gc(){if(!(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__>"u"||typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE!="function"))try{__REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(Gc)}catch(e){console.error(e)}}Gc(),Gs.exports=Ae;var Op=Gs.exports,bs=Op;Cl.createRoot=bs.createRoot,Cl.hydrateRoot=bs.hydrateRoot;const Ap=`version: 0.1

#atlasGrid programmable(columns:int=8, sheetName="", sheetLength:int, tileWidth:int=120, tileHeight:int=80, indexY:int) {
  // Use "ui" or "fx" for sheetName to see the difference
  @(sheetName=>crew2) repeatable($index, grid($sheetLength, dx:0)) {
          pos: 5, 20

          @alpha(0.9) text(default, "sheet:" + $sheetName + ' yindex \${$indexY}', white, left, 200):10,-20
          bitmap(sheet($sheetName, callback($sheetName, $index))) {
            pos: ($index % $columns)*$tileWidth, ($index div $columns) * $tileHeight
            @alpha(0.9) text(f7x5, callback($sheetName, $index),  white, left, 200):0,40
          }
        }
}

  `,Ip=`version: 0.1


 #button_custom  programmable(status:[hover, pressed,normal], disabled:[true, false], buttonText="Button") {
      //filter:pixelOutline(knockout, blue, 0.3)
      //filter:replacePalette(file, 0, 1)
      
      //bitmap(sheet("crew2", "marine_r_shooting_d")):30,130;
      //filter:glow(red, 0.3, 1, 1, 1, smoothColor)
      //filter:glow(red, 0.3, 1, 1, 1, smoothColor)
      //filter:dropShadow(4, 1.6, #F3F, 0.9, 50, 3.05)
      //filter:pixelOutline(knockout, blue, 0.3)
      //filter:pixelOutline(inlineColor, red, yellow)
      @(status=>normal, disabled=>false) ninepatch("ui", "button-idle", 200, 30):     0,1
      @(status=>hover, disabled=>false) ninepatch("ui", "button-hover", 200, 30):     0,0
      @(status=>pressed, disabled=>false) ninepatch("ui", "button-pressed", 200, 30): 0,0
      @(status=>*, disabled=>true) ninepatch("ui", "button-disabled", 200, 30):       0,0
      
      @(status=>hover, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>pressed, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>normal, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>*, disabled=>true) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
 }


#ui programmable() {
      pos:100,300
      
      #buttonVal(updatable) text(dd, "Click the button!", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 20)), builderParameter("button")) {
            settings(builderName=>button_custom) // override builder name (will use button2 programmable from std)
      }

      placeholder(generated(cross(200, 20)), builderParameter("disableCheckbox")) {
            pos: 10,100
      }
      text(dd, "Disabled Checkbox", #ffffff00): 30,100

      
      
}


 `,Up=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #checkboxVal(updatable) text(dd, "clickCheckbox", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 20)), builderParameter("checkbox")) {
            settings(checkboxBuildName=>checkbox2) // override builder name (will use checkbox2 programmable from std)
      }

      
      
}


 
`,Bp=`version: 0.1

relativeLayouts {
  grid: 21, 31 {
  hexgrid:pointy(2, 3) {
  
  #endpoint point: 600,10

  
    
  #endpoints list {
        point: 250,20
        point: 450,20
        point: 10,20
        point: 10,20
  }

    #mainDropDown sequence($i:0..30) point: 10 + $i * 120, 100
    #buttons sequence($i:0..30) point: 10 + $i * 200, 500
    #checkboxes sequence($i:0..30) point: 300, 200 + 30 * $i
  }
  }
}


#macroTest programmable() {
      pos:600,200
      text(dd, "MacroTest", #ffffff00): 0,0
      placeholder(generated(cross(10, 10)), builderParameter("element")):0,20
      placeholder(generated(cross(10, 10)), builderParameter("factoryElement")):0,40
      placeholder(generated(cross(10, 10)), builderParameter("h2dObject")):0,60
      placeholder(generated(cross(10, 10)), builderParameter("h2dObjectFactory")):0,80
}
   

#testTileGroup3 programmable() {
      pos:600,100
          point {
            text(dd, "tilegroup test", #ffffff00): 0,0
            bitmap(generated(color(20, 20, white)), left, top):0,50
            bitmap(generated(color(20, 20, white)), left, center):40,50
            bitmap(generated(color(20, 20, white)), left, bottom):80,50
          }
}


#testTileGroup2 programmable tileGroup() {
      pos:600,100
      point {
            pos:5,5
            bitmap(generated(color(20, 20, red)), left, top):0,50
            bitmap(generated(color(20, 20, red)), left, center):40,50
            bitmap(generated(color(20, 20, red)), left, bottom):80,50
      }
}

#testTileGroup1 programmable tileGroup() {
      
      point {
            bitmap(generated(color(20, 20, gray)), left, top):610, 160
            bitmap(generated(color(20, 20, gray)), left, center):650, 160
            bitmap(generated(color(20, 20, gray)), left, bottom):690, 160
      }
}

#testTileGroup4 programmable tileGroup() {
      pos:800,100
      repeatable($index, grid(3, dx:40)) {
            bitmap(generated(color(20, 20, white)), left, top);
      }
}


#testTileGroup5 programmable() {
      pos:805,105
            repeatable($index, grid(3, dx:40)) {
            bitmap(generated(color(20, 20, orange)), left, top);
      }
}

#testTileGroup6 programmable tileGroup() {
      repeatable($bugabuga, grid(3, dx:40)) {
            pos:810,110      
            bitmap(generated(color(20, 20, red)), left, top);
      }
}


#ui programmable() {
      pos:100,300
      
      placeholder(generated(cross(200, 20)), builderParameter("checkbox1")) {
            settings(checkboxBuildName=>checkbox2) // override builder name (will use checkbox2 programmable from std)
      }

      placeholder(generated(cross(200, 20)), builderParameter("checkbox2")) {
            pos:30,0
            settings(checkboxBuildName=>radio) 
      }
      placeholder(generated(cross(200, 20)), builderParameter("checkbox3")) {
            pos:60,0
            settings(checkboxBuildName=>radio2) 
      }
      placeholder(generated(cross(200, 20)), builderParameter("checkbox4")) {
            pos:90,0
            settings(checkboxBuildName=>tickbox) 
      }

      placeholder(generated(cross(200, 20)), builderParameter("checkbox5")) {
            pos:120,0
            settings(checkboxBuildName=>toggle) 
      }

      placeholder(generated(cross(200, 20)), builderParameter("scroll1")) {
            pos:400,100 
            settings(height=>200, topClearance=>60)   
      }
      placeholder(generated(cross(200, 20)), builderParameter("scroll2")):550,100;
      placeholder(generated(cross(200, 20)), builderParameter("scroll3")):700,100;
      
      placeholder(generated(cross(200, 20)), builderParameter("scroll4")):850,100;
      
      
      placeholder(generated(cross(200, 20)), builderParameter("checkboxWithLabel")) {
            pos:610,50;
            settings(font=>dd)
      }

      
      
}`,Wp=`version: 0.1


#dialogBase programmable() {
      pos:400,200

      ninepatch("ui", "Droppanel_3x3_idle", 550, 300): 0,0
      point {
        pos: 50,250
        placeholder(generated(cross(20, 20)), builderParameter("button1")) {
          settings(text=>"override specific placeholder")
          
        }
        placeholder(generated(cross(20, 20)), builderParameter("button2")):250,0
      }
}

#yesNoDialog programmable() {
      reference($dialogBase) {
        #dialogText(updatable) text(dd, "This is a text message", #ffffff00, center, 400): 50,50
      }
}



#fileDialog programmable() {
      
      reference($dialogBase){
        placeholder(generated(cross(20, 20)), builderParameter("filelist")):100,30
      }
}

      



    `,Hp=`version: 0.1


#ui programmable() {
      pos:400,200
      
      #selectedFileText(updatable) text(dd, "No file selected", #ffffff00, center, 400): 0,50
      
      point {
      
        placeholder(generated(cross(20, 20)), builderParameter("openDialog1button"));
        placeholder(generated(cross(200, 20)), builderParameter("openDialog2button")):250,0;
        
      }
}


      



    `,Vp=`version: 0.1

#file palette(file:"main-palette.png")

relativeLayouts {
  grid: 21, 31 {
  
  
  #roomCheckboxes sequence($i: 1..6) point: grid(0,$i)	
  #cornerCheckboxes sequence($i: 1..6) point: grid(1,$i)	
  #panelCheckboxes sequence($i: 1..6) point: grid(2,$i)	
  #panelButtons sequence($i: 10..16) point: grid(0,$i)	
  #repeatableTest list {
        point: 10,20
        point: 30,20
        point: 45,35
        point: 70,60
        point: 100,90
        point: 100,110
        point: 80,120
        point: 20,120
  }
  }
}

#arrayDemo programmable(arr:array = [bla, bla, 3, buga], index:int=0) {
  text(pixeled6,  $arr[$index], #F00, right):30,20;
}


#conditionalsDemo1 programmable(param1:[top, middle, bottom]) {
  @(param1=>top) text(pixeled6,  $param1, #FFF, left):0,0
  @(param1=>middle) text(pixeled6,  $param1, #FFF, left):0,10
  @(param1=>bottom) text(pixeled6,  $param1, #FFF, left):0,20
}

#conditionalsDemo2 programmable(param1:[A, B, C]) {
  @(param1=>A) text(pixeled6,  $param1, #FFF, left):0,0
  @(param1=>B) text(pixeled6,  $param1, #FFF, left):0,10
  @(param1=>C) text(pixeled6,  $param1, #FFF, left):0,20
  @(param1=>!C) text(pixeled6,  "!C", #FFF, left):0,30
}

#conditionalsDemo3 programmable(param1:[A, B], param2:[X,Y]) {
  @(param1=>A) text(pixeled6,  $param1+$param2, #FFF, left):0,0
  @(param1=>B) text(pixeled6,  $param1+$param2, #FFF, left):0,10
  @(param2=>X) text(pixeled6,  $param1+$param2, #FFF, left):0,20
  @(param2=>Y) text(pixeled6,  $param1+$param2, #FFF, left):0,30
  @(param1=>A, param2=>X) text(pixeled6,  $param1+$param2, #FFF, left):0,40
  
  
}

#referenceDemo programmable(width:int, height:int, shape:[rect, triangle], c1:color=white) {
  @(shape=>rect) bitmap(generated(color($width, $height, $c1)));
  @(shape=>triangle)  pixels (
            line 0,0, 0, $height, #f00
            line 0,$height, $width, $height, #f00
            line $width,$height, 0, 0, #f00
          );
}

#applyDemo programmable(state:[alpha, filter, scale]) {
  
  @(state=>alpha) apply {
    alpha:0.4
    pos:0,0
    
  }
  @(state=>filter) apply {
    filter:glow(color:white, alpha:0.9, radius:15, smoothColor:true)
    pos:30,30
  }
  @(state=>scale) apply {
    scale:0.7
    pos:60,60
  }
  
  bitmap(generated(color(30, 30, green)));
}


#ui programmable() {
      pos:10,60
      hex:pointy(40, 40)
      grid:250,150

       

      point { // example 1: hex grid + pixels
          pos: grid(0,0);
          
          @alpha(0.7) bitmap(generated(color(function(gridWidth), function(gridHeight), #777)));
          pixels (
            line hexCorner(0, 1.1), hexCorner(1, 1.1), #f00
            line hexCorner(1, 1.1), hexCorner(2, 1.1), #0f0
            line hexCorner(2, 1.1), hexCorner(3, 1.1), #00f
            line hexCorner(3, 1.1), hexCorner(4, 1.1), #ff0
            line hexCorner(4, 1.1), hexCorner(5, 1.1), #f0f
            line hexCorner(5, 1.1), hexCorner(0, 1.1), #fff
          ):100,50
          @alpha(0.9) text(dd, "#1: hex grid + pixels", white, left, 200);
      }

      point { // example 2: text 
          pos: grid(1,0);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),green)));
          @alpha(0.9) text(dd, "#2: text", white, left, 160);

          text(dd, "test left", red, left, 200):0,20;
          text(m3x6, "test center", blue, center, 200):0,20;
          text(pixeled6, "test right", 0xF00, right, 200):0,20;
          text(pixellari, "The quick brown fox jumps over the lazy dog", 0xF00, right, 200):0,40;
      }

      point { // example 3: bitmap
          pos: grid(2,0);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),blue)));
          @alpha(0.9) text(dd, "#3: bitmap", white, left, 160);

          //bitmap(sheet("crew2", "marine_r_shooting_d")):20,30
          bitmap(sheet("crew2", "marine_l_killed",0), center):50,30
          bitmap(sheet("crew2", "marine_l_killed",1), center):80,30
          bitmap(sheet("crew2", "marine_l_killed",2), center):110,30
          bitmap(sheet("crew2", "marine_l_killed",3), center):140,30
          
          point {
            pos: 80,60
            
            scale:2;
            bitmap(sheet("crew2", "marine_r_shooting_d"), center);
            @alpha(0.5) bitmap(sheet("crew2", "marine_r_shooting_d"), center):-5,0;
            @alpha(0.3) bitmap(sheet("crew2", "marine_r_shooting_d"), center):-10,0;
          }
      }      
      point { // example 4: repeatable
          pos: grid(3,0);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),gray)));
          @alpha(0.9) text(dd, "#4: repeatable", white, left, 200);

          repeatable($index, grid(5, dx:5, dy:1)) {
            @alpha(1.0 - $index/5.0) scale(2) bitmap(sheet("crew2", "marine_r_shooting_d")):30,80;
          }
      }
      point { // example 5: stateanim
          pos: grid(4,0);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),yellow)));
          stateanim("files/marine.anim", "idle", "direction"=>"l"):50,50
          @alpha(0.5) stateanim("files/marine.anim", "idle", direction=>"l"):100,50
          stateanim("files/marine.anim", "idle", direction=>r){
            pos: 150, 50
            filter:replacePalette(file, 0, 1)

          }
          @alpha(0.9) text(dd, "#5: stateanim", white, left, 200);
          
      }
      point { // example 6: flow
          pos: grid(0,1);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),orange)));
          flow(maxWidth:200, maxHeight:100, minWidth:200, minHeight:100, layout:vertical, padding:0, debug:1) {
            text(dd, "test left", red, left);
            text(m3x6, "test center", blue, center);
            text(pixeled6, "test right", 0xF00, right);
          }
          @alpha(0.9) text(dd, "#6: flow", white, left, 200);
          @scale(2) text(dd, "WIP", red, center, 200):-100,40
        

          
      }
      point { // example 7: palette
          pos: grid(1,1);
           bitmap(generated(color(function(gridWidth), function(gridHeight),black)));
          
          @alpha(0.9) text(dd, "#7: palette", white, left, 200);

        repeatable($row, grid(3, dy:25)) {
          repeatable($index, grid(16, dx:12)) {
            pos: 5, 20
            bitmap(generated(color(10, 15, palette(file, $index, $row))));
          }
        }
      }
      point { // example 8: layers
          pos: grid(2,1);
          bitmap(generated(color(function(gridWidth), function(gridHeight),gray)));
          @alpha(0.9) text(dd, "#8: layers", white, left, 200);
          
          layers {
            pos:30,30
            @layer(3) bitmap(generated(color(30, 30, palette(file, 10, 0))));
            @layer(2) bitmap(generated(color(30, 30, palette(file, 11, 0)))):10,10;
            @layer(1) bitmap(generated(color(30, 30, palette(file, 12, 0)))):20,20
          }
          layers {
            pos:90, 30
          @layer(1) bitmap(generated(color(30, 30, palette(file, 10, 0))));
          @layer(2) bitmap(generated(color(30, 30, palette(file, 11, 0)))):10,10;
          @layer(3) bitmap(generated(color(30, 30, palette(file, 12, 0)))):20,20
          }

      }
      point { // example 9: 9-patch
          pos: grid(3,1);
          @alpha(0.5) bitmap(generated(color(function(gridWidth), function(gridHeight),blue)));
          @alpha(0.9) text(dd, "#9: 9-patch", white, left, 200);
          
          ninepatch("ui", "Window_3x3_idle", 30, 30): 10,20
          ninepatch("ui", "Window_3x3_idle", 30, 60): 50,20
          ninepatch("ui", "Window_3x3_idle", 60, 60): 100,20

      }
      point { // example 10: reference
          pos: grid(4,1);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),red)));
          @alpha(0.9) text(dd, "#10: reference", white, left, 200);
          
          
          reference($referenceDemo, width=>10, height=>10, shape=>rect): 10,30;
          reference($referenceDemo, width=>30, height=>30, shape=>triangle): 10, 60;
          reference($referenceDemo, width=>50, height=>20, shape=>triangle): 100, 30;
          reference($referenceDemo, width=>30, height=>30, shape=>triangle): 100, 60;
          reference($referenceDemo, width=>15, height=>15, shape=>rect): 150, 60;
          reference($arrayDemo, arr=>["first element","second element","3rd element", "4th element"]):170, 80

          reference($arrayDemo, arr=>["first element","second element","3rd element", "4th element"], index=>2):170, 100

      }
      point { // example 11: bitmap align
          pos: grid(0,2);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),red)));
          
          @alpha(0.9) text(dd, "#11: bitmap align", white, left, 200);
          bitmap(generated(color(100, 1, white)), left, top):0,50

          bitmap(generated(color(20, 20, red)), left, top):0,50
          bitmap(generated(color(20, 20, red)), left, center):40,50
          bitmap(generated(color(20, 20, red)), left, bottom):80,50

          bitmap(generated(color(1, 100, white)), left, top):150,20

          bitmap(generated(color(20, 20, red)), left, top):150,20
          bitmap(generated(color(20, 20, red)), center, top):150,60
          bitmap(generated(color(20, 20, red)), right, top):150,100
      }
      point { // example 12: text & tile are updatable from code
          pos: grid(1,2);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),yellow)));
          @alpha(0.9) text(dd, "#12: updatable from code", white, left, 200);
          
          #textToUpdate(updatable) text(dd, "This is a test text message", #ffffff00): 10,30
          #bitmapToUpdate(updatable) bitmap(generated(color(20, 20, red)), left, top):10,80
          

      }
      point { // example 13: layout iterator
          pos: grid(2,2);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),gray)));
          @alpha(0.9) text(dd, "#13: layout repeatable", white, left, 200);
          repeatable($index, layout("mainScreen", "repeatableTest")) {
            pos: 0, 0
            bitmap(generated(color(10, 15, red)));
          }
      }
      point { // example 14: tileGroup
          pos: grid(3,2);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),black)));
          @alpha(0.9) text(dd, "#14: tileGroup", white, left, 200);
          point {
            pos:1, 1
            bitmap(generated(color(20, 20, white)), left, top):0,50
            bitmap(generated(color(20, 20, white)), left, center):40,50
            bitmap(generated(color(20, 20, white)), left, bottom):80,50
          }

          tileGroup {
            bitmap(generated(color(20, 20, red)), left, top):0,50
            bitmap(generated(color(20, 20, red)), left, center):40,50
            bitmap(generated(color(20, 20, red)), left, bottom):80,50
          }

          tileGroup {
            pos:30,30
            bitmap(generated(color(20, 20, blue)), left, top):0,50
            bitmap(generated(color(20, 20, blue)), left, center):40,50
            bitmap(generated(color(20, 20, blue)), left, bottom):80,50
          }

          bitmap(generated(color(30, 30, white)), left, top):120,120
          tileGroup {
            pos:100,100
                repeatable($index, grid(5, dx:5, dy:1)) {
                  @alpha(1.0 - $index/5.0) scale(0.5) bitmap(generated(color(20, 20, white)), left, bottom):0,0
            }
          }

          tileGroup {
            pos:120,120
                pixels (
                  rect -1,-1, 31,31, red);
            }
          }
        point { // example 15: stateAnim construct
          pos: grid(4,2);
          @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),white)));
          @alpha(0.9) text(dd, "#15: stateAnim construct", white, left, 200);
          stateAnim construct("state1", 
            "state1" => sheet "crew2", marine_r_shooting_u, 10, loop
            "state2" => sheet "crew2", marine_l_dead, 10
          ):50,50
      }

      point { // example 16: div/mod expressions
        pos: grid(0,3);
        @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight),white)));
        @alpha(0.9) text(dd, "#16: div/mod", white, left, 200);
        repeatable($index, grid(25, dx:0)) {
          pos: 5, 20
          bitmap(generated(color(10, 15, red))): ($index %5)*20, ($index div 5) * 25
        }
      }

      point { // example 17: apply
        pos: grid(1,3);
        @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),#F0F)));
        @alpha(0.9) text(dd, "#17: apply", white, left, 200);

        point {
          pos:10,10
          reference($applyDemo, state=>alpha):30,10
          @alpha(0.9) text(dd, "state=>alpha", white, left, 200):80,15
          reference($applyDemo, state=>filter):0,20
          @alpha(0.9) text(dd, "state=>filter", white, left, 200):80,55
          reference($applyDemo, state=>scale):-30,30
          @alpha(0.9) text(dd, "state=>scale", white, left, 200):80,93
        }
      }
    point { // example 18: reference
          pos: grid(2,3);
          @alpha(0.3) bitmap(generated(color(function(gridWidth), function(gridHeight),yellow)));

          @alpha(0.9) text(dd, "#18: conditionals", white, left, 200);


          point {
            pos: 20, 20
            reference($conditionalsDemo1, param1=>top): 0,0
            reference($conditionalsDemo1, param1=>middle): 0,0
            reference($conditionalsDemo1, param1=>bottom): 0,0
          }
 
          point {
            pos: 80, 20
            reference($conditionalsDemo2, param1=>A): 10,0
            reference($conditionalsDemo2, param1=>B): 20,0
            reference($conditionalsDemo2, param1=>C): 30,0
          }
          point {
            pos: 140, 20
            reference($conditionalsDemo3, param1=>A, param2=>X): 10,0
            reference($conditionalsDemo3, param1=>B, param2=>X): 40,0
            reference($conditionalsDemo3, param1=>A, param2=>Y): 70,0
          }
          

      }

      
  }



                

      

      
`,Qp=`version: 0.1

relativeLayouts {
  #fontNames sequence($i: 1..40) point: 100, 20+20 * $i
  #fonts sequence($i: 1..40) point: 200, 20+20 * $i
}


`,Kp=`version: 0.1



#test1 particles {
    count:550
    
    emit: box(100,650, 180, 5)
    maxLife: 3.5
    speedRandom: 0.2
    speed:350
    speedIncrease:1
    tiles: sheet("fx", "missile/particle") 
    loop: true
    size:1
    sizeRandom:0.8
    emitSync: 0.1
    gravity:300
    gravityAngle:70
    blendMode: add
    fadeOut:0.7
    //rotationSpeed:30
    rotateAuto: yes

    
}

#test2 particles {
    count:550
    emit: point(1,150)
    maxLife: 3.5
    speedRandom: 0
    speed:30
    speedIncrease:1
    tiles: sheet("fx", "missile/particle_1") sheet("fx", "missile/particle_1") 
    loop: true
    size:1
    sizeRandom:0
    
    gravity:0
    gravityAngle:0
    blendMode: add
    
}

#test3 particles {
    count:550
    //emit: point(1,150)
    emit: cone(40,10, 90, 30)
    maxLife: 3.5
    speedRandom: 0
    speed:30
    speedIncrease:1
    tiles: sheet("fx", "missile/particle_1") sheet("fx", "missile/particle_1") 
    loop: true
    size:1
    sizeRandom:0
    
    gravity:0
    gravityAngle:0
    blendMode: add
    
}


#ui programmable() {
    text(pixellari, "particles", #ffffff00, center, 100): 300, 30
    #particles1(updatable) point:1200,50;
     
     
     
}
`,Gp=`version: 0.1




paths {
  #line1 path {
    line (30,30) 
    line (30,100) 
    line (100,30) 
    line (400,102) 
    checkpoint(test)
    bezier(200,400, 100, 300)
    bezier(500,200, 600, 600)
    line (1200,600) 
  }
  #line2 path {
    
    turn(10)
    forward(100)
    turn(10)
    forward(100)
    turn(10)
    forward(100)
    turn(90)
    forward(20)
    turn(90)
    forward(20)
    turn(90)
    forward(20)
    
  }

    #line3 path {
    forward(100)
    turn(45)
    forward(30)
    turn(45)
    forward(30)
    turn(45)
    forward(30)
    turn(45)
    forward(30)
    turn(45)
    forward(30)
    turn(45)
    forward(30)
    turn(45)
    forward(300)
    
  }

    #lineX path {
    line ($endX,$startY)  
    line ($endX,$endY)  
    line ($startX,$endY)  
    line ($startX,$startY)  
    line ($endX,$endY)  
    
  }


}


#cross1 pixels (
  line -10,0, 10, 0, green
  line 0,-10, 0, 10, green
  ) {
   
    text(pixellari, "start path", green): 5,5
  
  }

#cross2 pixels (
  line -10,0, 10, 0, #f88
  line 0,-10, 0, 10, #f88
  ) {
    text(pixellari, "end path", #f88): 5,5
  }



#animRect bitmap(generated(color(20, 20, white)), center);


#anim programmable() {
  bitmap(generated(color(20, 20, yellow)), center) {
          particles {
            count:550
            relative: false
            emit: cone(5,5, 90, 30)
            maxLife: 15
            emitSync: 0
            speedRandom: 0
            speed:30
            speedIncrease:0
            tiles:  sheet("fx", "missile/particle") 
            loop: true
            size:1
            sizeRandom:0
            
            gravity:0
            gravityAngle:0
            blendMode: add
          
      }

       particles {
            count:100
            relative: true
            emit: cone(5,5, 270, 5)
            maxLife: 3.5
            speedRandom: 0
            speed:30
            speedIncrease:0
            tiles: sheet("fx", "missile/particle") 
            loop: true
            size:1
            sizeRandom:0
            emitSync: 0.1
            gravity:0
            gravityAngle:0
            blendMode: add
          
      }
  }
}


#ui programmable() {
    text(pixellari, "testing paths", #ffffff00, center, 100): 30, 50
    placeholder(generated(cross(200, 20)), builderParameter("animate")):1050,100
    
    placeholder(generated(cross(200, 20)), builderParameter("path")):600,100
    placeholder(generated(cross(200, 20)), builderParameter("startPoint")):750,100
    placeholder(generated(cross(200, 20)), builderParameter("endPoint")):900,100
    placeholder(generated(cross(200, 20)), builderParameter("positionMode")):900,300
    placeholder(generated(cross(200, 20)), builderParameter("angleSlider")):900,240


    point {
      pos: 640, 320
      #ref1 placeholder(generated(cross(10, 10)), builderParameter("xxx")) {
        text(pixellari, "ref #1", yellow);
        #ref2 placeholder(generated(cross(10, 10)), builderParameter("xxx")) {
          text(pixellari, "ref #2", green);
          scale: 0.5
          pos:100,100
        }
      }
    }
  
}


#panim animatedPath {
  0.1: changeSpeed 100
  0.3: changeSpeed 1000
  0.1: attachParticles("test") {
      count:30
      relative: true
      speed:500
      loop: false
      emit: cone(5,5, $angle+180, 1)
      tiles:  sheet("fx", "particle/smoke-2") 
  }

    0.1: attachParticles("test") {
      count:120
      relative: true
      loop: false
      speed:500
      emit: cone(5,5, $angle+90, 1)
      tiles:  sheet("fx", "particle/smoke-2") 
  }
}`,Yp=`version: 0.1


relativeLayouts {
  grid: 21, 31 {
  offset: 50,50 {
  
  #roomCheckboxes sequence($i: 1..6) point: grid(0,$i)	
  #cornerCheckboxes sequence($i: 1..6) point: grid(1,$i)	
  #panelCheckboxes sequence($i: 1..6) point: grid(2,$i)	

  #panelButtons sequence($i: 10..16) point: grid(0,$i)
  }
  }
}


#ui programmable() {
      pos:600,400
      hex:pointy(197, 180)
      point {
          pixels (
            line hexCorner(0, 1.1), hexCorner(1, 1.1), #fF0000FF
            line hexCorner(1, 1.1), hexCorner(2, 1.1), #fFFF0000
            line hexCorner(2, 1.1), hexCorner(3, 1.1), #fF0000FF
            line hexCorner(3, 1.1), hexCorner(4, 1.1), #fFFF0000
            line hexCorner(4, 1.1), hexCorner(5, 1.1), #fF0000FF
            line hexCorner(5, 1.1), hexCorner(0, 1.1), #fFFF0000
          ):0,-4
      }

      #testNumber(updatable) text(pixellari, "test test test", #ffffff00, center, 100): 300,-200
}
      
#room programmable(wallDirections:flags(6)=31, cornerDirections:flags(6)=31, panelDirections:flags(6)=31) {
    pos:600,400
    bitmap(file("png/Ground_02.png"), center): 0,0
    bitmap(file("png/WallBase_02.png"), center): 0,0
    layers 
    {
      
      @(cornerDirections=>bit [1]) bitmap(file("png/Corner_090.png"), center): 0,0

      @(wallDirections=>bit [1]) bitmap(file("png/Wall_060.png"), center): 0,0
      @(panelDirections=>bit [1]) bitmap(file("png/Panel_060.png"), center): 0,0
      
      @(cornerDirections=>bit [0]) bitmap(file("png/Corner_030.png"), center): 0,0
      
      @(wallDirections=>bit [0]) bitmap(file("png/Wall_000.png"), center): 0,0
      @(panelDirections=>bit [0]) bitmap(file("png/Panel_000.png"), center): 0,0

      @(wallDirections=>bit [2]) bitmap(file("png/Wall_120.png"), center): 0,0
      @(panelDirections=>bit [2]) bitmap(file("png/Panel_120.png"), center): 0,0

      @(cornerDirections=>bit [5]) bitmap(file("png/Corner_330.png"), center): 0,0

      @(wallDirections=>bit [5]) bitmap(file("png/Wall_300.png"), center): 0,0
      @(cornerDirections=>bit [2]) bitmap(file("png/Corner_150.png"), center): 0,0
      
      @(wallDirections=>bit [3]) bitmap(file("png/Wall_180.png"), center): 0,0
      @(panelDirections=>bit [3]) bitmap(file("png/Panel_180.png"), center): 0,0

      @(cornerDirections=>bit [3]) bitmap(file("png/Corner_210.png"), center): 0,0

      @(wallDirections=>bit [4]) bitmap(file("png/Wall_240.png"), center): 0,0

      @(panelDirections=>bit [4]) bitmap(file("png/Panel_240.png"), center): 0,0
      @(panelDirections=>bit [5]) bitmap(file("png/Panel_300.png"), center): 0,0

      @(cornerDirections=>bit [4]) bitmap(file("png/Corner_270.png"), center): 0,0
      
    }

}



    `,Xp=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #listVal(updatable) text(dd, "Select an item from the list!", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 150)), builderParameter("scrollableList")) {
            pos: 10,80
            settings(panelBuilder=>list-panel, itemBuilder=>list-item-120) // use standard list components
      }

      
      
}


`,Zp=`version: 0.1

relativeLayouts {
    
  #resolution list {
        point: 30,120
        point: 30,160
        point: 30,320
        point: 30,420
  }

    #mainDropDown sequence($i:0..30) point: 10 + $i * 120, 100
    #buttons sequence($i:0..30) point: 10 + $i * 200, 500
    #scrollableList sequence($i:1..30) point: 1280 - $i * 150, 100
    #checkboxes sequence($i:0..30) point: 700 , 500 + 30 * $i
  
}


#ui programmable() {
      text(dd, "Fullscreen", #ffffff00): 60,125
      #resolution(updatable) text(dd, "Resolution", #ffffff00): 160,166

}


      



    `,qp=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #sliderVal(updatable) text(dd, "move slider", #ffffff00): 10,50
      
      placeholder(generated(cross(200, 20)), builderParameter("slider")) {
            pos:10,30
      }

      
      
}`,Jp=`version: 0.1


relativeLayouts {
    #statusBar point:3,680
    #smAnimCenter point:600,300
    #checkboxes list {
        point: 3,3
        point: 400,300
        point: 400,400
        point: 10,20
    }
    #statesDropdowns sequence($i:0..30) point: $i*150+350, 52
    #animStates sequence($i:1..30) point: 1070, 720-$i*30 + 5

}


#ui programmable() {
      
      point {
            pos:500, 120
            grid:1,30
            #pauseCheckbox point {
                  pos: grid(0,0)
                  text(dd, "Pause", white): 30, 5
                  placeholder(generated(cross(20, 20)), builderParameter("pause"));
            }
            #boundsCheckbox point {
                  pos: grid(0,1)
                  text(dd, "Show bounds", white): 30, 5
                  placeholder(generated(cross(20, 20)), builderParameter("bounds"));
            }
            #animStatesCheckbox point {
                  pos: grid(0,2)
                  
                  placeholder(generated(cross(20, 20)), builderParameter("animStates"));
                  text(pixellari, "Show states", white);
            }
            #animCommandsCheckbox point {
                  pos: grid(0,3)
                  text(dd, "Show states", #ddd): 30, 5
                  placeholder(generated(cross(20, 20)), builderParameter("animCommands"));
            }

            
      }
      
      placeholder(generated(cross(20, 20)), builderParameter("load")):50,50;
      
      text(dd, "States", #ffffffff, html:true): 290, 58
      

      #spriteText(updatable) text(pixellari, "sprite", #ffffff00, center, 100, html:true): 500,350
      #statusText(updatable) text(pixellari, "status",  #ffa0a080, left, 400, html:true): 10,90
      #commandsText(updatable) text(pixellari, "status",  #ffa0a080, left, 400, html:true): 10,90

      #sprite point:550,300
      placeholder(generated(cross(150, 20)), builderParameter("speedSlider")) {
            pos: 120, 600
            text(dd, "Anim. speed", #ffffffff): -110, 0
      }
      text(pixellari, "R - reload sprinte<br/>1-8 set sprite scaling<br/>CTRL while clicking on state - crate 5 items",  #fffffff0, html:true) {
            pos:  500,470
            alpha:0.5
            scale:1
      }

 }


#mainStatusBar programmable(statusText="status text", error:bool=false) {
      ninepatch("ui", "Window_3x3_idle", 600, 30): 0,0
      @(error=>true) text(dd, $statusText, #ffff0000): 20,8
      @(error=>false) text(dd, $statusText, #ffffff00): 20,8
}


`,em=`version: 0.1



  #slider programmable(status:[hover, pressed, normal]=normal, value:0..100=0, size:[100,200,300], disabled:[true, false]) {
    //@(value=>between 50..70) text(dd, "HEEEEEEEEEEEEEEEEEY", 0xffffff12, center, 200): 0,10

    //@(value=>[between 3..30]) text(dd, "HEEEEEEEEEEEEEEEEEY", 0xffffff12, center, 200): 0,10
    @if(size=>300) point {
      ninepatch("ui", "Sliderbar_H_3x1", 310, 8) {
        grid: 3, 1;
        #start point:grid(0, -1)
        #end point:grid(100, -1)
        #slider @(status=>hover)  bitmap(sheet("ui", "Slider_button_hover")):grid($value,-1)
        #slider @(status=>normal)  bitmap(sheet("ui", "Slider_button_idle")):grid($value,-1)
        #slider @(status=>pressed)  bitmap(sheet("ui", "Slider_button_pressed")):grid($value,-1)
        #slider @(status=>*, disabled=>true)  bitmap(sheet("ui", "Slider_button_disabled")):grid($value,-1)
      }
    
    }
     @(size=>200, value=>*, status=>*) point {
      
      ninepatch("ui", "Sliderbar_H_3x1", 210, 8) {
        grid:2, 1
        #start point:grid(0, -1)
        #end point:grid(100, -1)

        #slider @(status=>hover)  bitmap(sheet("ui", "Slider_button_hover")):grid($value,-1)
        #slider @(status=>normal)  bitmap(sheet("ui", "Slider_button_idle")):grid($value,-1)
        #slider @(status=>pressed)  bitmap(sheet("ui", "Slider_button_pressed")):grid($value,-1)
        #slider @(status=>*, disabled=>true)  bitmap(sheet("ui", "Slider_button_disabled")):grid($value,-1)
        
      
    }
    }
     
     @(size=>100, value=>*) point {
      
      ninepatch("ui", "Sliderbar_H_3x1", 110, 8) {
        grid:1, 1
        #start point:grid(0, -1)
        #end point:grid(100, -1)

        #slider @(status=>hover)  bitmap(sheet("ui", "Slider_button_hover")):grid($value,-1)
        #slider @(status=>normal)  bitmap(sheet("ui", "Slider_button_idle")):grid($value,-1)
        #slider @(status=>pressed)  bitmap(sheet("ui", "Slider_button_pressed")):grid($value,-1)
        #slider @(status=>*, disabled=>true)  bitmap(sheet("ui", "Slider_button_disabled")):grid($value,-1)
      
    }
    }
  }


 #button programmable(status:[hover, pressed,normal], disabled:[true, false], buttonText="Button") {
      //filter:pixelOutline(knockout, blue, 0.3)
      //filter:replacePalette(file, 0, 1)
      
      //bitmap(sheet("crew2", "marine_r_shooting_d")):30,130;
      //filter:glow(red, 0.3, 1, 1, 1, smoothColor)
      //filter:glow(red, 0.3, 1, 1, 1, smoothColor)
      //filter:dropShadow(4, 1.6, #F3F, 0.9, 50, 3.05)
      //filter:pixelOutline(knockout, blue, 0.3)
      //filter:pixelOutline(inlineColor, red, yellow)
      @(status=>normal, disabled=>false) ninepatch("ui", "button-idle", 200, 30):     0,1
      @(status=>hover, disabled=>false) ninepatch("ui", "button-hover", 200, 30):     0,0
      @(status=>pressed, disabled=>false) ninepatch("ui", "button-pressed", 200, 30): 0,0
      @(status=>*, disabled=>true) ninepatch("ui", "button-disabled", 200, 30):       0,0
      
      @(status=>hover, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>pressed, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>normal, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
      @(status=>*, disabled=>true) text(dd, $buttonText, 0xffffff12, center, 200): 0,10
}
    

 #radio programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
      @(status=>normal, checked=>false) bitmap(sheet("ui", "RadioButton_off_idle"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "RadioButton_off_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "RadioButton_off_pressed"));
      @(disabled=>true, checked=>false) bitmap(sheet("ui", "RadioButton_off_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "RadioButton_on_idle"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "RadioButton_on_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "RadioButton_on_pressed"));
      @(disabled=>true, checked=>true) bitmap(sheet("ui", "RadioButton_on_disabled"));
 }

 #tab programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false], width:uint=120, height:uint=30) {
      @(status=>normal, checked=>false) ninepatch("ui", "Tab_off_idle", $width, $height);
      @(status=>hover, checked=>false) ninepatch("ui", "Tab_off_hover", $width, $height);
      @(status=>pressed, checked=>false) ninepatch("ui", "Tab_off_pressed", $width, $height);
      @(disabled=>true, checked=>false) ninepatch("ui", "Tab_off_disabled", $width, $height);
      @(status=>normal, checked=>true) ninepatch("ui", "Tab_on_idle", $width, $height);
      @(status=>hover, checked=>true) ninepatch("ui", "Tab_on_hover", $width, $height);
      @(status=>pressed, checked=>true) ninepatch("ui", "Tab_on_pressed", $width, $height);
      @(disabled=>true, checked=>true) ninepatch("ui", "Tab_on_disabled", $width, $height);
       
}

 #radio2 programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
      @(status=>normal, checked=>false) bitmap(sheet("ui", "RadioButton2_off_idle"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "RadioButton2_off_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "RadioButton2_off_pressed"));
      @(disabled=>true, checked=>false) bitmap(sheet("ui", "RadioButton2_off_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "RadioButton2_on_idle"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "RadioButton2_on_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "RadioButton2_on_pressed"));
      @(disabled=>true, checked=>true) bitmap(sheet("ui", "RadioButton2_on_disabled"));
       
}
 #tickbox programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
      @(status=>normal, checked=>false) bitmap(sheet("ui", "TickBox2_off_idle"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "TickBox2_off_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "TickBox2_off_pressed"));
      @(disabled=>true, checked=>false) bitmap(sheet("ui", "TickBox2_off_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "TickBox2_on_idle"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "TickBox2_on_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "TickBox2_on_pressed"));
      @(disabled=>true, checked=>true) bitmap(sheet("ui", "TickBox2_on_disabled"));
}


 #toggle programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
      @(status=>normal, checked=>false) bitmap(sheet("ui", "Toggle_off_idle"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "Toggle_off_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "Toggle_off_pressed"));
      @(disabled=>true, checked=>false) bitmap(sheet("ui", "Toggle_off_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "Toggle_on_idle"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "Toggle_on_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "Toggle_on_pressed"));
      @(disabled=>true, checked=>true) bitmap(sheet("ui", "Toggle_on_disabled"));
}

 #checkbox programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
      @(status=>normal, checked=>false) bitmap(sheet("ui", "CheckBox_off_idle"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "CheckBox_off_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "CheckBox_off_pressed"));
      @(disabled=>true, checked=>false) bitmap(sheet("ui", "CheckBox_off_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "CheckBox_on_idle"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "CheckBox_on_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "CheckBox_on_pressed"));
      @(disabled=>true, checked=>true) bitmap(sheet("ui", "CheckBox_on_disabled"));
       
}

#checkbox2 programmable(status:[hover, pressed, normal], checked:[true, false], disabled:[true, false]) {
  scale:2
      @(status=>normal, checked=>false) bitmap(sheet("ui", "checkbox_unchecked_normal"));
      @(status=>hover, checked=>false) bitmap(sheet("ui", "checkbox_unchecked_hover"));
      @(status=>pressed, checked=>false) bitmap(sheet("ui", "checkbox_unchecked_pressed"));
      //@(status=>disabled, checked=>false) bitmap(sheet("ui", "checkbox_unchecked_disabled"));
      @(status=>normal, checked=>true) bitmap(sheet("ui", "checkbox_checked_normal"));
      @(status=>hover, checked=>true) bitmap(sheet("ui", "checkbox_checked_hover"));
      @(status=>pressed, checked=>true) bitmap(sheet("ui", "checkbox_checked_pressed"));
      //@(status=>disabled, checked=>true) bitmap(sheet("ui", "checkbox_checked_disabled"));
       
}


#checkboxWithText programmable(textColor:int, title="checkbox label", font="m6x11"){
    point {
     placeholder(generated(cross(15, 15)), builderParameter("checkbox")):0,0
      text($font, $title, white, left): 40,4
    }
}


#radioButtons programmable(count:int){
      repeatable($index, grid($count, dy:20)) {
            placeholder(generated(cross(15, 15)), callback("checkbox", $index)):0,0
            text(m6x11, callback("label", $index), 0xffffff12, left, 120): 24,4
            
      }
}

#radioButtonsHorizontal programmable(count:int){
      repeatable($index, grid($count, dx:120 )) {
            placeholder(generated(cross(15, 15)), callback("checkbox", $index)):0,0
            text(m6x11, callback("label", $index), 0xffffff12, left, 120): 24,4
            
      }
}

#radioButtonsVertical programmable(count:int){
      repeatable($index, grid($count, dy:30 )) {
            placeholder(generated(cross(15, 15)), callback("checkbox", $index)):0,0
            text(m6x11, callback("label", $index), 0xffffff12, left, 120): 24,4
            
      }
}


#dropdown programmable(images:[none,placeholder,tile]=placeholder, status:[hover, pressed, disabled,normal], panel:[open, closed]) {
      
      #panelPoint (updatable) point: 0, 30;
      //placeholder(generated(cross(120, 200)), builderParameter("panel")):5,10
      @(status=>hover) ninepatch("ui", "dropdown-button-hover", 120, 30);
      @(status=>normal) ninepatch("ui", "dropdown-button-idle", 120, 30);
      @(status=>pressed) ninepatch("ui", "dropdown-button-pressed", 120, 30);
      @(status=>disabled) ninepatch("ui", "dropdown-button-disabled", 120, 30);
      @(panel=>closed) bitmap(sheet("ui", "icon_drop_fold_idle")):108,17
      @(panel=>open) bitmap(sheet("ui", "icon_drop_open")):108,17
      #selectedName(updatable) text(m6x11, callback("selectedName"), 0xffffff12, center, 120): -4,6
      // @(images=>placeholder) placeholder(generated(cross(15, 15)), callback("test")):8,5
      settings(transitionTimer=>.2)
}


#list-item-120 programmable(images:[none,placeholder,tile]=placeholder,status:[hover, pressed, normal], selected:[true, false], disabled:[true, false], tile="", itemWidth:uint=114,  index:uint=0, title="title") {
        
        @(status=>normal, selected=>false, disabled=>false) ninepatch("ui", "droppanel-mid-idle", $itemWidth+4, 20): -2,0
        @(status=>normal, selected=>true, disabled=>false) ninepatch("ui", "droppanel-mid-pressed", $itemWidth+4, 20): -2,0
        
        @(status=>pressed, disabled=>false) ninepatch("ui", "droppanel-mid-pressed", $itemWidth+4, 20) {
          pos:-2,0;
          alpha:0.1;
          blendMode: alphaAdd;
        } 
        @(status=>hover, disabled=>false) ninepatch("ui", "droppanel-mid-hover", $itemWidth+4, 20) {
          pos:-2,0;
          alpha:0.1;
          blendMode: alphaAdd;
        } 
        
        @(disabled=>true) ninepatch("ui", "droppanel-mid-disabled", $itemWidth+4, 20): -2,0
        
        text(m6x11, $title, 0xffffff12, left, 120): 24,4
        @(images=>placeholder) placeholder(generated(cross(15, 15)), callback("test")):5,3
        @(images=>tile) bitmap(file($tile), center):5,3
        interactive($itemWidth , 20, $index);
        settings(height=>20)
}

#list-panel programmable(width:uint=200, height:uint=200, topClearance:uint = 0) {
  
  ninepatch("ui", "Window_3x3_idle", $width+4, $height+8+$topClearance): -2,-4-$topClearance
  placeholder(generated(cross($width, $height)), builderParameter("mask")):0,0
  #scrollbar @layer(100) point: $width - 4, 0
}

#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint = 0) {

ninepatch("ui", "scrollbar-1", 4, $panelHeight * $panelHeight / $scrollableHeight): 0, $scrollPosition*$panelHeight/$scrollableHeight
  settings(scrollSpeed=>250)
}


#okCancelDialog programmable(dialogText = "Your text here") {
      pos:400,200

      ninepatch("ui", "Droppanel_3x3_idle", 550, 300): 0,0
       #dialogText(updatable) text(dd, $dialogText, #ffffff00, center, 400): 50,50
      point {
        pos: 50,250
        placeholder(generated(cross(20, 20)), builderParameter("ok")) {

          
        }
        placeholder(generated(cross(20, 20)), builderParameter("cancel")):250,0
      }
}`,nm=`sheet: crew2
allowedExtraPoints: ["point", "text"]
center: 64,64


animation {
    name: dir0
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir0"m
    }
    extrapoints {
        point: 0,0
        text: -60,0
    }
}


animation {
    name: dir1
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir1"
    }
    extrapoints {
        point: 0,0
        text: -24,50
    }
}


animation {
    name: dir2
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir2"
    }
    extrapoints {
        point: 0,0
        text: 24,50
    }
}


animation {
    name: dir3
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir3"
    }
    extrapoints {
        point: 0,0
        text: 64,0
    }
}

animation {
    name: dir4
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir4"
    }
    extrapoints {
        point: 0,0
        text: 25,-60
    }
}

animation {
    name: dir5
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir5"
    }
    extrapoints {
        point: 0,0
        text: -25,-60
    }
}

`,tm=`sheet: crew2
allowedExtraPoints: [fire, targeting,krava]
states: direction(l, r), color(red, green), count(1,2,3)  
center: 0,10


animation {
    name: idle
    fps:4
    loop: yes
    playlist {
        sheet: dice
    }
}


`,rm=`sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48


animation {
    name: idle
    fps:4
    playlist {
        loop untilCommand {
            sheet: "marine_$$direction$$_idle"
        }
    }
    extrapoints  { 
           @(direction=>l) targeting : -1, -12
           @(direction=>r) targeting : 5, -12
    }
}

animation {
    name: fire-up
    fps:20
    loop: 2
     playlist {
        sheet: "marine_r_shooting_u"
    }
    extrapoints { 
        fire: 5, -19
    }
}


animation {
    name: fire-down
    fps:10
    playlist {
        sheet: marine_l_shooting_d
    }
    extrapoints { 
        fire : -2, -2
    }
}

animation {
    name: fire-left
    fps:20
    playlist {
        sheet: marine_l_shooting_u
    }
    extrapoints { 
        fire : -10, -8
    }
}

animation {
    name: fire-right
    fps:20
    playlist {
        sheet: marine_r_shooting_d
    }
    extrapoints { 
        fire: 10, -8
    }
}

animation {
    name: fire-upright
    fps:20
    playlist {
        sheet: marine_r_shooting
    }
    extrapoints { 
        fire : 12, -12
    }
}

animation {
    name: fire-downleft
    fps:20
    playlist {
        sheet: marine_l_shooting
    }
    extrapoints { 
        fire : -7,-3
    }
}

animation {
    name: fire-upleft
    fps:20
    playlist {
        sheet: marine_l_shooting_uu
    }
    extrapoints { 
        fire : -7,-11
    }
}

animation {
    name: fire-downright
    fps:20
    playlist {
        sheet: marine_r_shooting_dd
    }
    extrapoints { 
        fire : 7,-6
    }
}

animation {
    name: hit
    fps:20
    loop: untilCommand
    playlist {
        sheet: marine_$$direction$$_hit
        loop 3 {
            event hit random 0,-10, 10
        }
    }
}


animation {
    name: killed
    fps:20
    playlist {
        sheet: marine_$$direction$$_killed
        goto dead
    }
}

animation {
    name: dead
    fps:1
    loop: untilCommand
    playlist {
    sheet: marine_$$direction$$_dead
    }
}

animation {
    name: stand
    fps:1
    loop
    playlist {
        sheet: marine_$$direction$$_standing
        command
    }
}



animation {
    name: dodge
    fps:4
    playlist {
        sheet: marine_$$direction$$_dodging_$$direction$$ frames: 0..0 duration: 1500 ms
        loop untilCommand {
            sheet: marine_$$direction$$_dodging_$$direction$$ frames:1..2 duration:15ms
        }
        sheet: marine_$$direction$$_dodging_$$direction$$ frames: 3..3
    }
}

`,im=`sheet: crew2
allowedExtraPoints: ["line_TR", "line_BR", "line_TL", "line_BL"]
states: direction(l, r)
center: 32,48


animation {
    name: idle_0
    fps:4
    loop
    playlist {
        loop untilCommand {
            sheet: "shield_$$direction$$_layer0"
        }
    }
    extrapoints {
        line_TR: 8, -16
        line_TL: -8, -16 
        line_BR: 7, -1
        line_BL: -7, -1
    }
}


animation {
    name: impact
    fps:10
    loop
     playlist {
        sheet: "shield_$$direction$$_layer2_impact fast"
    }
}

animation {
    name: idle_1
    fps:10
    loop
     playlist {
        sheet: "shield_$$direction$$_layer1"
    }
}



`,lm=`sheet: crew2
center: 32,48


animation {
    name: explode
    fps:16
    playlist {
        
        sheet: "Turret_Explode_SW"
        goto destoyed
    }
}

animation {
    name: hit
    fps:10
    playlist {
        loop untilCommand {
            sheet: "Turret_Idle_SW_A" frames: 2..6
        }
    }
}

animation {
    name: idle
    fps:14
    playlist {
        loop untilCommand {
            sheet: "Turret_Idle_SW_B"
        }
    }
}

animation {
    name: shoot
    fps:16
    playlist {
        loop untilCommand {
            sheet: "Turret_Shoot_SW"
        }
    }
}

animation {
    name: destoyed
    fps:1
    playlist {
        sheet: "Turret_Destroyed_SW"
    }
}

`,om=Object.assign({"../public/assets/atlas-test.manim":Ap,"../public/assets/button.manim":Ip,"../public/assets/checkbox.manim":Up,"../public/assets/components.manim":Bp,"../public/assets/dialog-base.manim":Wp,"../public/assets/dialog-start.manim":Hp,"../public/assets/examples1.manim":Vp,"../public/assets/fonts.manim":Qp,"../public/assets/particles.manim":Kp,"../public/assets/paths.manim":Gp,"../public/assets/room1.manim":Yp,"../public/assets/scrollable-list.manim":Xp,"../public/assets/settings.manim":Zp,"../public/assets/slider.manim":qp,"../public/assets/stateanim.manim":Jp,"../public/assets/std.manim":em}),am=Object.assign({"../public/assets/arrows.anim":nm,"../public/assets/dice.anim":tm,"../public/assets/marine.anim":rm,"../public/assets/shield.anim":im,"../public/assets/turret.anim":lm}),fa=Object.fromEntries([...Object.entries(om).map(([e,n])=>[e.split("/").pop(),n]),...Object.entries(am).map(([e,n])=>[e.split("/").pop(),n])]),wl=e=>fa[e]||null,ii=(e,n)=>{fa[e]=n},sm=e=>e in fa,um="button";class cm{constructor(){_e(this,"screens",[{name:"scrollableList",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",manimFile:"scrollable-list.manim"},{name:"button",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",manimFile:"button.manim"},{name:"checkbox",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",manimFile:"checkbox.manim"},{name:"slider",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",manimFile:"slider.manim"},{name:"particles",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",manimFile:"particles.manim"},{name:"components",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",manimFile:"components.manim"},{name:"examples1",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",manimFile:"examples1.manim"},{name:"paths",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",manimFile:"paths.manim"},{name:"fonts",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",manimFile:"fonts.manim"},{name:"room1",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",manimFile:"room1.manim"},{name:"stateAnim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",manimFile:"stateanim.manim"},{name:"dialogStart",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",manimFile:"dialog-start.manim"},{name:"settings",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",manimFile:"settings.manim"},{name:"atlasTest",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",manimFile:"atlas-test.manim"}]);_e(this,"manimFiles",[{filename:"scrollable-list.manim",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",content:null},{filename:"button.manim",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",content:null},{filename:"checkbox.manim",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",content:null},{filename:"slider.manim",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",content:null},{filename:"examples1.manim",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",content:null},{filename:"components.manim",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",content:null},{filename:"dialog-base.manim",displayName:"Dialog Base",description:"Dialog system foundation with base dialog layouts, text rendering, and dialog-specific animations and transitions.",content:null},{filename:"dialog-start.manim",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",content:null},{filename:"fonts.manim",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",content:null},{filename:"particles.manim",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",content:null},{filename:"paths.manim",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",content:null},{filename:"room1.manim",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",content:null},{filename:"settings.manim",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",content:null},{filename:"stateanim.manim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",content:null},{filename:"std.manim",displayName:"Standard Library",description:"Standard library components and utilities for hx-multianim including common animations, effects, and helper functions.",content:null},{filename:"atlas-test.manim",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",content:null}]);_e(this,"animFiles",[{filename:"arrows.anim",content:null},{filename:"dice.anim",content:null},{filename:"marine.anim",content:null},{filename:"shield.anim",content:null},{filename:"turret.anim",content:null}]);_e(this,"currentFile",null);_e(this,"currentExample",null);_e(this,"reloadTimeout",null);_e(this,"reloadDelay",1e3);_e(this,"mainApp",null);_e(this,"baseUrl","");this.init()}init(){this.setupFileLoader(),this.loadFilesFromMap(),this.waitForMainApp()}loadFilesFromMap(){this.manimFiles.forEach(n=>{const t=wl(n.filename);t&&(n.content=t)}),this.animFiles.forEach(n=>{const t=wl(n.filename);t&&(n.content=t)})}waitForMainApp(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?this.mainApp=window.PlaygroundMain.instance:setTimeout(()=>this.waitForMainApp(),100)}setupFileLoader(){this.baseUrl=typeof window<"u"&&window.location?window.location.href:"",window.FileLoader={baseUrl:this.baseUrl,resolveUrl:n=>this.resolveUrl(n),load:n=>this.loadFile(n),stringToArrayBuffer:this.stringToArrayBuffer}}resolveUrl(n){if(n.startsWith("http://")||n.startsWith("https://")||n.startsWith("//")||n.startsWith("file://")||!this.baseUrl)return n;try{return new URL(n,this.baseUrl).href}catch{const r=this.baseUrl.endsWith("/")?this.baseUrl:this.baseUrl+"/",i=n.startsWith("/")?n.substring(1):n;return r+i}}stringToArrayBuffer(n){const t=new ArrayBuffer(n.length),r=new Uint8Array(t);for(let i=0,l=n.length;i<l;i++)r[i]=n.charCodeAt(i);return t}loadFile(n){const t=this.extractFilenameFromUrl(n);if(t&&sm(t)){const l=wl(t);if(l)return this.stringToArrayBuffer(l)}if(typeof window.hxd<"u"&&window.hxd.res&&window.hxd.res.load)try{const l=window.hxd.res.load(n);if(l&&l.entry&&l.entry.getBytes){const o=l.entry.getBytes();return this.stringToArrayBuffer(o.toString())}}catch{}const r=this.resolveUrl(n),i=new XMLHttpRequest;return i.open("GET",r,!1),i.send(),i.status===200?this.stringToArrayBuffer(i.response):new ArrayBuffer(0)}extractFilenameFromUrl(n){const r=n.split("?")[0].split("#")[0].split("/"),i=r[r.length-1];return i&&(i.endsWith(".manim")||i.endsWith(".anim")||i.endsWith(".png")||i.endsWith(".atlas2")||i.endsWith(".fnt")||i.endsWith(".tps"))?i:null}onContentChanged(n){if(this.currentFile){const t=this.manimFiles.find(i=>i.filename===this.currentFile);t&&(t.content=n,ii(this.currentFile,n));const r=this.animFiles.find(i=>i.filename===this.currentFile);r&&(r.content=n,ii(this.currentFile,n))}this.reloadTimeout&&clearTimeout(this.reloadTimeout),this.reloadTimeout=setTimeout(()=>{this.reloadPlayground()},this.reloadDelay)}reloadPlayground(n){var r;let t=n;if(!t){const i=document.getElementById("screen-selector");t=i?i.value:"particles"}if((r=window.PlaygroundMain)!=null&&r.instance)try{const i=window.PlaygroundMain.instance.reload(t,!0);return console.log("PlaygroundLoader reload result:",i),console.log("Result type:",typeof i),console.log("Result keys:",i?Object.keys(i):"null"),i&&i.__nativeException&&console.log("Error in reload result:",i.__nativeException),i}catch(i){return console.log("Exception during reload:",i),{__nativeException:i}}return null}getCurrentContent(){const n=document.getElementById("manim-textarea");return n?n.value:""}getCurrentFile(){return this.currentFile}getEditedContent(n){const t=this.manimFiles.find(i=>i.filename===n);if(t)return t.content;const r=this.animFiles.find(i=>i.filename===n);return r?r.content:null}updateContent(n,t){const r=this.manimFiles.find(i=>i.filename===n);r&&(r.content=t,ii(n,t))}dispose(){this.mainApp&&typeof this.mainApp.dispose=="function"&&this.mainApp.dispose()}static getDefaultScreen(){return um}}function dm(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function $s(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Ps(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?$s(Object(t),!0).forEach(function(r){dm(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):$s(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function fm(e,n){if(e==null)return{};var t={},r=Object.keys(e),i,l;for(l=0;l<r.length;l++)i=r[l],!(n.indexOf(i)>=0)&&(t[i]=e[i]);return t}function pm(e,n){if(e==null)return{};var t=fm(e,n),r,i;if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(i=0;i<l.length;i++)r=l[i],!(n.indexOf(r)>=0)&&Object.prototype.propertyIsEnumerable.call(e,r)&&(t[r]=e[r])}return t}function mm(e,n){return hm(e)||gm(e,n)||vm(e,n)||ym()}function hm(e){if(Array.isArray(e))return e}function gm(e,n){if(!(typeof Symbol>"u"||!(Symbol.iterator in Object(e)))){var t=[],r=!0,i=!1,l=void 0;try{for(var o=e[Symbol.iterator](),a;!(r=(a=o.next()).done)&&(t.push(a.value),!(n&&t.length===n));r=!0);}catch(u){i=!0,l=u}finally{try{!r&&o.return!=null&&o.return()}finally{if(i)throw l}}return t}}function vm(e,n){if(e){if(typeof e=="string")return Ns(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);if(t==="Object"&&e.constructor&&(t=e.constructor.name),t==="Map"||t==="Set")return Array.from(e);if(t==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return Ns(e,n)}}function Ns(e,n){(n==null||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function ym(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function xm(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Fs(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Ts(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Fs(Object(t),!0).forEach(function(r){xm(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Fs(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function wm(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];return function(r){return n.reduceRight(function(i,l){return l(i)},r)}}function Qt(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function Ni(e){return{}.toString.call(e).includes("Object")}function km(e){return!Object.keys(e).length}function wr(e){return typeof e=="function"}function _m(e,n){return Object.prototype.hasOwnProperty.call(e,n)}function Sm(e,n){return Ni(n)||Ln("changeType"),Object.keys(n).some(function(t){return!_m(e,t)})&&Ln("changeField"),n}function Cm(e){wr(e)||Ln("selectorType")}function Em(e){wr(e)||Ni(e)||Ln("handlerType"),Ni(e)&&Object.values(e).some(function(n){return!wr(n)})&&Ln("handlersType")}function bm(e){e||Ln("initialIsRequired"),Ni(e)||Ln("initialType"),km(e)&&Ln("initialContent")}function $m(e,n){throw new Error(e[n]||e.default)}var Pm={initialIsRequired:"initial state is required",initialType:"initial state should be an object",initialContent:"initial state shouldn't be an empty object",handlerType:"handler should be an object or a function",handlersType:"all handlers should be a functions",selectorType:"selector should be a function",changeType:"provided value of changes should be an object",changeField:'it seams you want to change a field in the state which is not specified in the "initial" state',default:"an unknown error accured in `state-local` package"},Ln=Qt($m)(Pm),Hr={changes:Sm,selector:Cm,handler:Em,initial:bm};function Nm(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};Hr.initial(e),Hr.handler(n);var t={current:e},r=Qt(jm)(t,n),i=Qt(Tm)(t),l=Qt(Hr.changes)(e),o=Qt(Fm)(t);function a(){var d=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(v){return v};return Hr.selector(d),d(t.current)}function u(d){wm(r,i,l,o)(d)}return[a,u]}function Fm(e,n){return wr(n)?n(e.current):n}function Tm(e,n){return e.current=Ts(Ts({},e.current),n),n}function jm(e,n,t){return wr(n)?n(e.current):Object.keys(t).forEach(function(r){var i;return(i=n[r])===null||i===void 0?void 0:i.call(n,e.current[r])}),t}var zm={create:Nm},Lm={paths:{vs:"https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs"}};function Rm(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function Mm(e){return{}.toString.call(e).includes("Object")}function Dm(e){return e||js("configIsRequired"),Mm(e)||js("configType"),e.urls?(Om(),{paths:{vs:e.urls.monacoBase}}):e}function Om(){console.warn(Yc.deprecation)}function Am(e,n){throw new Error(e[n]||e.default)}var Yc={configIsRequired:"the configuration object is required",configType:"the configuration object should be an object",default:"an unknown error accured in `@monaco-editor/loader` package",deprecation:`Deprecation warning!
    You are using deprecated way of configuration.

    Instead of using
      monaco.config({ urls: { monacoBase: '...' } })
    use
      monaco.config({ paths: { vs: '...' } })

    For more please check the link https://github.com/suren-atoyan/monaco-loader#config
  `},js=Rm(Am)(Yc),Im={config:Dm},Um=function(){for(var n=arguments.length,t=new Array(n),r=0;r<n;r++)t[r]=arguments[r];return function(i){return t.reduceRight(function(l,o){return o(l)},i)}};function Xc(e,n){return Object.keys(n).forEach(function(t){n[t]instanceof Object&&e[t]&&Object.assign(n[t],Xc(e[t],n[t]))}),Ps(Ps({},e),n)}var Bm={type:"cancelation",msg:"operation is manually canceled"};function kl(e){var n=!1,t=new Promise(function(r,i){e.then(function(l){return n?i(Bm):r(l)}),e.catch(i)});return t.cancel=function(){return n=!0},t}var Wm=zm.create({config:Lm,isInitialized:!1,resolve:null,reject:null,monaco:null}),Zc=mm(Wm,2),br=Zc[0],Qi=Zc[1];function Hm(e){var n=Im.config(e),t=n.monaco,r=pm(n,["monaco"]);Qi(function(i){return{config:Xc(i.config,r),monaco:t}})}function Vm(){var e=br(function(n){var t=n.monaco,r=n.isInitialized,i=n.resolve;return{monaco:t,isInitialized:r,resolve:i}});if(!e.isInitialized){if(Qi({isInitialized:!0}),e.monaco)return e.resolve(e.monaco),kl(_l);if(window.monaco&&window.monaco.editor)return qc(window.monaco),e.resolve(window.monaco),kl(_l);Um(Qm,Gm)(Ym)}return kl(_l)}function Qm(e){return document.body.appendChild(e)}function Km(e){var n=document.createElement("script");return e&&(n.src=e),n}function Gm(e){var n=br(function(r){var i=r.config,l=r.reject;return{config:i,reject:l}}),t=Km("".concat(n.config.paths.vs,"/loader.js"));return t.onload=function(){return e()},t.onerror=n.reject,t}function Ym(){var e=br(function(t){var r=t.config,i=t.resolve,l=t.reject;return{config:r,resolve:i,reject:l}}),n=window.require;n.config(e.config),n(["vs/editor/editor.main"],function(t){qc(t),e.resolve(t)},function(t){e.reject(t)})}function qc(e){br().monaco||Qi({monaco:e})}function Xm(){return br(function(e){var n=e.monaco;return n})}var _l=new Promise(function(e,n){return Qi({resolve:e,reject:n})}),Jc={config:Hm,init:Vm,__getMonacoInstance:Xm},Zm={wrapper:{display:"flex",position:"relative",textAlign:"initial"},fullWidth:{width:"100%"},hide:{display:"none"}},Sl=Zm,qm={container:{display:"flex",height:"100%",width:"100%",justifyContent:"center",alignItems:"center"}},Jm=qm;function e0({children:e}){return pe.createElement("div",{style:Jm.container},e)}var n0=e0,t0=n0;function r0({width:e,height:n,isEditorReady:t,loading:r,_ref:i,className:l,wrapperProps:o}){return pe.createElement("section",{style:{...Sl.wrapper,width:e,height:n},...o},!t&&pe.createElement(t0,null,r),pe.createElement("div",{ref:i,style:{...Sl.fullWidth,...!t&&Sl.hide},className:l}))}var i0=r0,ed=$.memo(i0);function l0(e){$.useEffect(e,[])}var nd=l0;function o0(e,n,t=!0){let r=$.useRef(!0);$.useEffect(r.current||!t?()=>{r.current=!1}:e,n)}var Re=o0;function tr(){}function vt(e,n,t,r){return a0(e,r)||s0(e,n,t,r)}function a0(e,n){return e.editor.getModel(td(e,n))}function s0(e,n,t,r){return e.editor.createModel(n,t,r?td(e,r):void 0)}function td(e,n){return e.Uri.parse(n)}function u0({original:e,modified:n,language:t,originalLanguage:r,modifiedLanguage:i,originalModelPath:l,modifiedModelPath:o,keepCurrentOriginalModel:a=!1,keepCurrentModifiedModel:u=!1,theme:d="light",loading:v="Loading...",options:m={},height:p="100%",width:g="100%",className:x,wrapperProps:w={},beforeMount:z=tr,onMount:c=tr}){let[s,f]=$.useState(!1),[h,_]=$.useState(!0),C=$.useRef(null),b=$.useRef(null),E=$.useRef(null),R=$.useRef(c),P=$.useRef(z),X=$.useRef(!1);nd(()=>{let M=Jc.init();return M.then(B=>(b.current=B)&&_(!1)).catch(B=>(B==null?void 0:B.type)!=="cancelation"&&console.error("Monaco initialization: error:",B)),()=>C.current?nn():M.cancel()}),Re(()=>{if(C.current&&b.current){let M=C.current.getOriginalEditor(),B=vt(b.current,e||"",r||t||"text",l||"");B!==M.getModel()&&M.setModel(B)}},[l],s),Re(()=>{if(C.current&&b.current){let M=C.current.getModifiedEditor(),B=vt(b.current,n||"",i||t||"text",o||"");B!==M.getModel()&&M.setModel(B)}},[o],s),Re(()=>{let M=C.current.getModifiedEditor();M.getOption(b.current.editor.EditorOption.readOnly)?M.setValue(n||""):n!==M.getValue()&&(M.executeEdits("",[{range:M.getModel().getFullModelRange(),text:n||"",forceMoveMarkers:!0}]),M.pushUndoStop())},[n],s),Re(()=>{var M,B;(B=(M=C.current)==null?void 0:M.getModel())==null||B.original.setValue(e||"")},[e],s),Re(()=>{let{original:M,modified:B}=C.current.getModel();b.current.editor.setModelLanguage(M,r||t||"text"),b.current.editor.setModelLanguage(B,i||t||"text")},[t,r,i],s),Re(()=>{var M;(M=b.current)==null||M.editor.setTheme(d)},[d],s),Re(()=>{var M;(M=C.current)==null||M.updateOptions(m)},[m],s);let je=$.useCallback(()=>{var se;if(!b.current)return;P.current(b.current);let M=vt(b.current,e||"",r||t||"text",l||""),B=vt(b.current,n||"",i||t||"text",o||"");(se=C.current)==null||se.setModel({original:M,modified:B})},[t,n,i,e,r,l,o]),ke=$.useCallback(()=>{var M;!X.current&&E.current&&(C.current=b.current.editor.createDiffEditor(E.current,{automaticLayout:!0,...m}),je(),(M=b.current)==null||M.editor.setTheme(d),f(!0),X.current=!0)},[m,d,je]);$.useEffect(()=>{s&&R.current(C.current,b.current)},[s]),$.useEffect(()=>{!h&&!s&&ke()},[h,s,ke]);function nn(){var B,se,N,L;let M=(B=C.current)==null?void 0:B.getModel();a||((se=M==null?void 0:M.original)==null||se.dispose()),u||((N=M==null?void 0:M.modified)==null||N.dispose()),(L=C.current)==null||L.dispose()}return pe.createElement(ed,{width:g,height:p,isEditorReady:s,loading:v,_ref:E,className:x,wrapperProps:w})}var c0=u0;$.memo(c0);function d0(e){let n=$.useRef();return $.useEffect(()=>{n.current=e},[e]),n.current}var f0=d0,Vr=new Map;function p0({defaultValue:e,defaultLanguage:n,defaultPath:t,value:r,language:i,path:l,theme:o="light",line:a,loading:u="Loading...",options:d={},overrideServices:v={},saveViewState:m=!0,keepCurrentModel:p=!1,width:g="100%",height:x="100%",className:w,wrapperProps:z={},beforeMount:c=tr,onMount:s=tr,onChange:f,onValidate:h=tr}){let[_,C]=$.useState(!1),[b,E]=$.useState(!0),R=$.useRef(null),P=$.useRef(null),X=$.useRef(null),je=$.useRef(s),ke=$.useRef(c),nn=$.useRef(),M=$.useRef(r),B=f0(l),se=$.useRef(!1),N=$.useRef(!1);nd(()=>{let j=Jc.init();return j.then(D=>(R.current=D)&&E(!1)).catch(D=>(D==null?void 0:D.type)!=="cancelation"&&console.error("Monaco initialization: error:",D)),()=>P.current?O():j.cancel()}),Re(()=>{var D,re,ge,Ue;let j=vt(R.current,e||r||"",n||i||"",l||t||"");j!==((D=P.current)==null?void 0:D.getModel())&&(m&&Vr.set(B,(re=P.current)==null?void 0:re.saveViewState()),(ge=P.current)==null||ge.setModel(j),m&&((Ue=P.current)==null||Ue.restoreViewState(Vr.get(l))))},[l],_),Re(()=>{var j;(j=P.current)==null||j.updateOptions(d)},[d],_),Re(()=>{!P.current||r===void 0||(P.current.getOption(R.current.editor.EditorOption.readOnly)?P.current.setValue(r):r!==P.current.getValue()&&(N.current=!0,P.current.executeEdits("",[{range:P.current.getModel().getFullModelRange(),text:r,forceMoveMarkers:!0}]),P.current.pushUndoStop(),N.current=!1))},[r],_),Re(()=>{var D,re;let j=(D=P.current)==null?void 0:D.getModel();j&&i&&((re=R.current)==null||re.editor.setModelLanguage(j,i))},[i],_),Re(()=>{var j;a!==void 0&&((j=P.current)==null||j.revealLine(a))},[a],_),Re(()=>{var j;(j=R.current)==null||j.editor.setTheme(o)},[o],_);let L=$.useCallback(()=>{var j;if(!(!X.current||!R.current)&&!se.current){ke.current(R.current);let D=l||t,re=vt(R.current,r||e||"",n||i||"",D||"");P.current=(j=R.current)==null?void 0:j.editor.create(X.current,{model:re,automaticLayout:!0,...d},v),m&&P.current.restoreViewState(Vr.get(D)),R.current.editor.setTheme(o),a!==void 0&&P.current.revealLine(a),C(!0),se.current=!0}},[e,n,t,r,i,l,d,v,m,o,a]);$.useEffect(()=>{_&&je.current(P.current,R.current)},[_]),$.useEffect(()=>{!b&&!_&&L()},[b,_,L]),M.current=r,$.useEffect(()=>{var j,D;_&&f&&((j=nn.current)==null||j.dispose(),nn.current=(D=P.current)==null?void 0:D.onDidChangeModelContent(re=>{N.current||f(P.current.getValue(),re)}))},[_,f]),$.useEffect(()=>{if(_){let j=R.current.editor.onDidChangeMarkers(D=>{var ge;let re=(ge=P.current.getModel())==null?void 0:ge.uri;if(re&&D.find(Ue=>Ue.path===re.path)){let Ue=R.current.editor.getModelMarkers({resource:re});h==null||h(Ue)}});return()=>{j==null||j.dispose()}}return()=>{}},[_,h]);function O(){var j,D;(j=nn.current)==null||j.dispose(),p?m&&Vr.set(l,P.current.saveViewState()):(D=P.current.getModel())==null||D.dispose(),P.current.dispose()}return pe.createElement(ed,{width:g,height:x,isEditorReady:_,loading:u,_ref:X,className:w,wrapperProps:z})}var m0=p0,h0=$.memo(m0),g0=h0;const v0=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{include:"#keywords"}],y0={keywords:{patterns:[{name:"entity.name.class",match:"\\b(sheet|allowedExtraPoints|states|center)\\b"},{name:"keyword",match:"\\b(animation)\\b"},{name:"entity.name.type",match:"\\b(name|fps|playlist|sheet|extrapoints|playlist|loop|event|goto|hit|random|trigger|command|frames|untilCommand|duration|file)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},x0={patterns:v0,repository:y0},w0=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{name:"variable.name",match:"\\$[A-Za-z][A-Za-z0-9]*"},{name:"entity.name.tag",match:"#[A-Za-z][A-Za-z0-9\\-]*\\b"},{begin:"(@|@if|@ifstrict)\\(",beginCaptures:{0:{name:"keyword.control.at-sign"}},end:"\\)",endCaptures:{0:{name:"keyword.control.parenthesis"}},name:"meta.condition-block",contentName:"meta.condition-content",patterns:[{match:"\\b([A-Za-z_][A-Za-z0-9_]*)\\s*=>",name:"meta.condition-pair",captures:{0:{name:"keyword.other"},1:{name:"variable.other.key"}}},{match:"([A-Za-z_][A-Za-z0-9_]*)",name:"constant.other.value"},{match:",",name:"punctuation.separator.comma"}]},{name:"entity.name.method",match:"\\b@[A-Za-z][A-Za-z0-9]*\\b"},{include:"#keywords"}],k0={keywords:{patterns:[{name:"entity.name.class",match:"\\b(animatedPath|particles|programmable|stateanim|flow|apply|text|tilegroup|repeatable|ninepatch|layers|placeholder|reference|bitmap|point|interactive|pixels|relativeLayouts|palettes|paths)\\b"},{name:"keyword",match:"\\b(external|path|debug|version|nothing|list|line|flat|pointy|layer|layout|callback|builderParam|tileSource|sheet|file|generated|hex|hexCorner|hexEdge|grid|settings|pos|alpha|blendMode|scale|updatable|cross|function|gridWidth|gridHeight|center|left|right|top|bottom|offset|construct|palette|position|import|filter)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},_0={patterns:w0,repository:k0},zs=e=>{const n={root:[]};return e.patterns&&e.patterns.forEach(t=>{if(t.include){const r=t.include.replace("#","");e.repository&&e.repository[r]&&e.repository[r].patterns.forEach(l=>{l.match&&n.root.push([new RegExp(l.match),l.name||"identifier"])})}else t.match&&n.root.push([new RegExp(t.match),t.name||"identifier"])}),e.repository&&Object.keys(e.repository).forEach(t=>{const r=e.repository[t];r.patterns&&(n[t]=r.patterns.map(i=>i.match?[new RegExp(i.match),i.name||"identifier"]:["",""]).filter(([i])=>i!==""))}),n},rd=$.forwardRef(({value:e,onChange:n,language:t="text",disabled:r=!1,placeholder:i,onSave:l,errorLine:o,errorColumn:a,errorStart:u,errorEnd:d},v)=>{const m=$.useRef(null),p=$.useRef(),g=$.useRef([]);$.useEffect(()=>{p.current=l},[l]),$.useEffect(()=>{if(m.current&&(g.current.length>0&&(m.current.deltaDecorations(g.current,[]),g.current=[]),o)){const c=[];if(c.push({range:{startLineNumber:o,startColumn:1,endLineNumber:o,endColumn:1},options:{isWholeLine:!0,className:"error-line",glyphMarginClassName:"error-glyph",linesDecorationsClassName:"error-line-decoration"}}),u!==void 0&&d!==void 0){const s=m.current.getModel();if(s)try{const f=s.getPositionAt(u),h=s.getPositionAt(d);c.push({range:{startLineNumber:f.lineNumber,startColumn:f.column,endLineNumber:h.lineNumber,endColumn:h.column},options:{className:"error-token",hoverMessage:{value:"Parse error at this position"}}})}catch(f){console.log("Error calculating character position:",f)}}g.current=m.current.deltaDecorations([],c)}},[o,a,u,d]);const x=(c,s)=>{m.current=c,s.languages.register({id:"haxe-anim"}),s.languages.register({id:"haxe-manim"});const f=zs(x0);s.languages.setMonarchTokensProvider("haxe-anim",{tokenizer:f});const h=zs(_0);s.languages.setMonarchTokensProvider("haxe-manim",{tokenizer:h}),c.addAction({id:"save-file",label:"Save File",keybindings:[s.KeyMod.CtrlCmd|s.KeyCode.KeyS],run:()=>{p.current&&p.current()}}),c.focus()},w=c=>{c!==void 0&&n(c)},z=()=>t==="typescript"&&(e.includes("class")||e.includes("function")||e.includes("var"))?"haxe-manim":t;return y.jsxs("div",{ref:v,className:"w-full h-full min-h-[200px] border border-zinc-700 rounded overflow-hidden",style:{minHeight:200},children:[y.jsx("style",{children:`
          .error-line {
            background-color: rgba(239, 68, 68, 0.1) !important;
            border-left: 3px solid #ef4444 !important;
          }
          .error-glyph {
            background-color: #ef4444 !important;
          }
          .error-line-decoration {
            background-color: #ef4444 !important;
          }
          .error-token {
            background-color: rgba(239, 68, 68, 0.4) !important;
            border-bottom: 2px solid #ef4444 !important;
            text-decoration: underline wavy #ef4444 !important;
          }
        `}),y.jsx(g0,{height:"100%",defaultLanguage:z(),value:e,onChange:w,onMount:x,options:{readOnly:r,minimap:{enabled:!1},scrollBeyondLastLine:!1,fontSize:12,fontFamily:'Consolas, Monaco, "Courier New", monospace',lineNumbers:"on",roundedSelection:!1,scrollbar:{vertical:"visible",horizontal:"visible",verticalScrollbarSize:8,horizontalScrollbarSize:8},automaticLayout:!0,wordWrap:"on",theme:"vs-dark",tabSize:2,insertSpaces:!0,detectIndentation:!1,trimAutoWhitespace:!0,largeFileOptimizations:!1,placeholder:i,suggest:{showKeywords:!0,showSnippets:!0,showClasses:!0,showFunctions:!0,showVariables:!0},quickSuggestions:{other:!0,comments:!1,strings:!1}},theme:"vs-dark"})]})});rd.displayName="CodeEditor";const Ls="button";function S0(){var va;const[e,n]=$.useState(Ls),[t,r]=$.useState(""),[i,l]=$.useState(""),[o,a]=$.useState(!1),[u,d]=$.useState(""),[v,m]=$.useState(!1),[p,g]=$.useState(null),[x,w]=$.useState(null),[z,c]=$.useState(!0),[s]=$.useState(()=>new cm),[f,h]=$.useState(250),[_,C]=$.useState(400),[b,E]=$.useState(600),[R,P]=$.useState("playground"),[X,je]=$.useState([]),ke=$.useRef(null),nn=$.useRef(null),M=$.useRef(null),B=$.useRef(!1),se=$.useRef("");$.useEffect(()=>{p&&P("console")},[p]),$.useEffect(()=>{z&&x&&w(null)},[z,x]),$.useEffect(()=>{const k=console.log,F=console.error,W=console.warn,ie=console.info,ze=(K,...tt)=>{const H=tt.map(I=>{var In;if(typeof I=="object")try{return JSON.stringify(I,null,2)}catch{return((In=I.toString)==null?void 0:In.call(I))||"[Circular Object]"}return String(I)}).join(" ");je(I=>[...I,{type:K,message:H,timestamp:new Date}])};return console.log=(...K)=>{k(...K),ze("log",...K)},console.error=(...K)=>{F(...K),ze("error",...K)},console.warn=(...K)=>{W(...K),ze("warn",...K)},console.info=(...K)=>{ie(...K),ze("info",...K)},()=>{console.log=k,console.error=F,console.warn=W,console.info=ie}},[]),$.useEffect(()=>{ke.current&&(ke.current.scrollTop=ke.current.scrollHeight)},[X]);const N=()=>{je([])},L=pe.useMemo(()=>{const k=new Map;return s.screens.forEach(F=>{F.manimFile&&k.set(F.manimFile,F.name)}),k},[s.screens]),O=pe.useCallback(k=>{if(!k.endsWith(".manim")){w(null);return}const F=L.get(k);F&&F!==e?z?(n(F),s.reloadPlayground(F)):w({file:k,screen:F}):w(null)},[L,e,z,s]),j=pe.useMemo(()=>({scrollableList:"ScrollableListTestScreen.hx",button:"ButtonTestScreen.hx",checkbox:"CheckboxTestScreen.hx",slider:"SliderTestScreen.hx",particles:"ParticlesScreen.hx",components:"ComponentsTestScreen.hx",examples1:"Examples1Screen.hx",paths:"PathsScreen.hx",fonts:"FontsScreen.hx",room1:"Room1Screen.hx",stateAnim:"StateAnimScreen.hx",dialogStart:"DialogStartScreen.hx",settings:"SettingsScreen.hx",atlasTest:"AtlasTestScreen.hx"}),[]),D=pe.useCallback(k=>j[k]||`${k.charAt(0).toUpperCase()+k.slice(1)}Screen.hx`,[j]),re=()=>{x&&(n(x.screen),w(null),s.reloadPlayground(x.screen))},ge=()=>{w(null)},Ue=k=>{switch(k){case"error":return"❌";case"warn":return"⚠️";case"info":return"ℹ️";default:return"📋"}},sn=k=>{switch(k){case"error":return"text-red-400";case"warn":return"text-yellow-400";case"info":return"text-blue-400";default:return"text-gray-300"}};$.useEffect(()=>{const k=()=>{var W;(W=window.PlaygroundMain)!=null&&W.defaultScreen&&n(window.PlaygroundMain.defaultScreen)};k();const F=setTimeout(k,100);return()=>clearTimeout(F)},[]),$.useEffect(()=>(window.playgroundLoader=s,window.defaultScreen=Ls,s.onContentChanged=k=>{l(k)},()=>{s.dispose()}),[s]),$.useEffect(()=>{if(s.manimFiles.length>0&&e){const k=s.screens.find(F=>F.name===e);if(k&&k.manimFile){const F=s.manimFiles.find(W=>W.filename===k.manimFile);F&&(r(k.manimFile),l(F.content||""),d(F.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,m(!1))}}},[s.manimFiles,e]),$.useEffect(()=>{const k=s.screens.find(F=>F.name===e);if(k&&k.manimFile){const F=s.manimFiles.find(W=>W.filename===k.manimFile);F&&(r(k.manimFile),l(F.content||""),d(F.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,m(!1))}},[e,s]);const nt=()=>{if(t&&s.manimFiles.find(k=>k.filename===t))return t;if(e&&s.manimFiles.length>0){const k=s.screens.find(W=>W.name===e);if(k&&k.manimFile){const W=s.manimFiles.find(ie=>ie.filename===k.manimFile);if(W)return r(k.manimFile),(!i||i.trim()==="")&&l(W.content||""),d(W.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,k.manimFile}const F=s.manimFiles[0];return r(F.filename),(!i||i.trim()==="")&&l(F.content||""),d(F.description),a(!0),s.currentFile=F.filename,s.currentExample=F.filename,F.filename}if(s.manimFiles.length>0){const k=s.manimFiles[0];return r(k.filename),s.currentFile=k.filename,s.currentExample=k.filename,k.filename}return null},od=k=>{const F=k.target.value;n(F),w(null),s.reloadPlayground(F)},pa=pe.useMemo(()=>{const k=new Map;return s.manimFiles.forEach(F=>{k.set(F.filename,F)}),k},[s.manimFiles]),ma=pe.useMemo(()=>{const k=new Map;return s.animFiles.forEach(F=>{k.set(F.filename,F)}),k},[s.animFiles]),ha=pe.useCallback(k=>{const F=k.target.value;if(r(F),F){if(F.endsWith(".manim")){const W=pa.get(F);W&&(l(W.content||""),d(W.description),a(!0),s.currentFile=F,s.currentExample=F,m(!1),O(F))}else if(F.endsWith(".anim")){const W=ma.get(F);W&&(l(W.content||""),d("Animation file - content loaded and available to playground"),a(!0),s.currentFile=F,s.currentExample=F,m(!1),w(null))}}else l(""),a(!1),s.currentFile=null,s.currentExample=null,m(!1),w(null)},[pa,ma,O,s]),ad=pe.useCallback(k=>{l(k),m(!0)},[]),sd=()=>{var F,W,ie,ze,K,tt;const k=nt();if(k&&(s.updateContent(k,i),ii(k,i),m(!1),e))try{const H=s.reloadPlayground(e);if(H&&H.__nativeException){const I=H.__nativeException,In={message:I.message||((F=I.toString)==null?void 0:F.call(I))||"Unknown error occurred",pos:(W=I.value)==null?void 0:W.pos,token:(ie=I.value)==null?void 0:ie.token};g(In)}else if(H&&H.value&&H.value.__nativeException){const I=H.value.__nativeException,In={message:I.message||((ze=I.toString)==null?void 0:ze.call(I))||"Unknown error occurred",pos:(K=I.value)==null?void 0:K.pos,token:(tt=I.value)==null?void 0:tt.token};g(In)}else if(H&&H.error){const I={message:H.error||"Unknown error occurred",pos:H.pos,token:H.token};g(I)}else if(H&&!H.success){const I={message:H.error||"Operation failed",pos:H.pos,token:H.token};g(I)}else g(null)}catch(H){let I="Unknown error occurred";try{if(H instanceof Error)I=H.message;else if(typeof H=="string")I=H;else if(H&&typeof H=="object"){const rt=H;rt.message?I=rt.message:rt.toString?I=rt.toString():I="Error occurred"}}catch{I="Error occurred (could not serialize)"}g({message:I,pos:void 0,token:void 0})}},ga=pe.useCallback(()=>{sd()},[t,i,e,s]),ue=pe.useMemo(()=>{if(!(p!=null&&p.pos))return null;const{pmin:k,pmax:F}=p.pos,W=i;let ie=1,ze=1;for(let K=0;K<k&&K<W.length;K++)W[K]===`
`?(ie++,ze=1):ze++;return{line:ie,column:ze,start:k,end:F}},[p==null?void 0:p.pos,i]),Ki=k=>F=>{B.current=!0,se.current=k,F.preventDefault()};return $.useEffect(()=>{const k=W=>{if(B.current){if(se.current==="file"){const ie=W.clientX;ie>150&&ie<window.innerWidth-300&&h(ie)}else if(se.current==="editor"){const ie=W.clientX-f;ie>200&&ie<window.innerWidth-f-200&&C(ie)}else if(se.current==="playground"){const ie=window.innerWidth-f-_-2,ze=f+_+2,K=W.clientX-ze,tt=200,H=ie-200;K>tt&&K<H&&E(K)}}},F=()=>{B.current=!1,se.current=""};return document.addEventListener("mousemove",k),document.addEventListener("mouseup",F),()=>{document.removeEventListener("mousemove",k),document.removeEventListener("mouseup",F)}},[f,_]),y.jsxs("div",{className:"flex h-screen w-screen bg-gray-900 text-white",children:[y.jsxs("div",{ref:nn,className:"bg-gray-800 border-r border-gray-700 flex flex-col",style:{width:f},children:[y.jsxs("div",{className:"p-4 border-b border-gray-700",children:[y.jsxs("div",{className:"mb-4",children:[y.jsx("label",{className:"block mb-2 text-xs font-medium text-gray-300",children:"Screen:"}),y.jsx("select",{className:"w-full p-2 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500",value:e,onChange:od,children:s.screens.map(k=>y.jsx("option",{value:k.name,children:k.displayName},k.name))})]}),o&&y.jsxs("div",{className:"p-3 bg-gray-700 border border-gray-600 rounded h-20 overflow-y-auto overflow-x-hidden",children:[y.jsx("p",{className:"text-xs text-gray-300 leading-relaxed mb-2",children:u}),y.jsxs("a",{href:`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${D(e)}`,target:"_blank",rel:"noopener noreferrer",className:"text-xs text-blue-400 hover:text-blue-300 transition-colors",children:["📖 View ",e," Screen on GitHub"]})]})]}),y.jsx("div",{className:"flex-1 p-4",children:y.jsxs("div",{className:"text-xs text-gray-400",children:[y.jsx("div",{className:"mb-2",children:y.jsx("span",{className:"font-medium",children:"📁 Files:"})}),y.jsxs("div",{className:"space-y-1 scrollable",style:{maxHeight:"calc(100vh - 300px)"},children:[s.manimFiles.map(k=>y.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===k.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>ha({target:{value:k.filename}}),children:["📄 ",k.filename]},k.filename)),s.animFiles.map(k=>y.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===k.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>ha({target:{value:k.filename}}),children:["🎬 ",k.filename]},k.filename))]})]})})]}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Ki("file")}),y.jsxs("div",{ref:M,className:"bg-gray-900 flex flex-col",style:{width:_},children:[y.jsxs("div",{className:"p-4 border-b border-gray-700",children:[y.jsxs("div",{className:"flex items-center justify-between mb-2",children:[y.jsxs("div",{className:"flex items-center space-x-4",children:[y.jsx("h2",{className:"text-base font-semibold text-gray-200",children:"Editor"}),y.jsxs("label",{className:"flex items-center space-x-2 text-xs text-gray-300",children:[y.jsx("input",{type:"checkbox",checked:z,onChange:k=>c(k.target.checked),className:"w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"}),y.jsx("span",{children:"Auto sync screen"})]})]}),v&&y.jsx("button",{className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition",onClick:ga,title:"Save changes and reload playground (Ctrl+S)",children:"💾 Apply Changes"})]}),v&&!p&&y.jsx("div",{className:"text-xs text-orange-400 mb-2",children:'⚠️ Unsaved changes - Click "Apply Changes" to save and reload'}),p&&y.jsxs("div",{className:"p-3 bg-red-900/20 border border-red-700 rounded mb-2",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-red-400 text-xs",children:"❌ Parse Error:"}),y.jsx("button",{className:"text-red-300 hover:text-red-100 text-xs",onClick:()=>g(null),title:"Clear error",children:"✕"})]}),y.jsx("div",{className:"text-red-300 text-xs mb-1",children:p.message}),ue&&y.jsxs("div",{className:"text-red-400 text-xs",children:["Line ",ue.line,", Column ",ue.column]})]})]}),y.jsx("div",{className:"flex-1 scrollable",children:y.jsx(rd,{value:i,onChange:ad,language:"haxe-manim",disabled:!t,placeholder:"Select a manim file to load its content here...",onSave:ga,errorLine:ue==null?void 0:ue.line,errorColumn:ue==null?void 0:ue.column,errorStart:ue==null?void 0:ue.start,errorEnd:ue==null?void 0:ue.end})}),x&&y.jsxs("div",{className:"p-3 bg-blue-900/20 border-t border-blue-700",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-blue-400",children:"🔄 Screen Sync:"}),y.jsx("button",{className:"text-blue-300 hover:text-blue-100",onClick:ge,title:"Dismiss",children:"✕"})]}),y.jsxs("div",{className:"text-blue-300 mb-3",children:["Switch to ",y.jsx("strong",{children:((va=s.screens.find(k=>k.name===x.screen))==null?void 0:va.displayName)||x.screen})," screen to match ",y.jsx("strong",{children:x.file}),"?"]}),y.jsxs("div",{className:"flex space-x-2",children:[y.jsx("button",{onClick:re,className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded transition-colors",children:"✅ Switch Screen"}),y.jsx("button",{onClick:ge,className:"px-3 py-1 bg-gray-600 hover:bg-gray-700 text-white text-sm rounded transition-colors",children:"❌ Keep Current"})]})]})]}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Ki("editor")}),y.jsxs("div",{className:"flex-1 bg-gray-900 flex flex-col h-full min-h-0",children:[y.jsx("div",{className:"border-b border-gray-700 flex-shrink-0",children:y.jsxs("div",{className:"flex",children:[y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="playground"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>P("playground"),children:"🎮 Playground"}),y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="console"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>P("console"),children:p?"❌ Console":"📋 Console"}),y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="info"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>P("info"),children:"ℹ️ Info"})]})}),y.jsxs("div",{className:"flex-1 flex min-h-0",children:[y.jsx("div",{className:`${R==="playground"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,style:{width:R==="playground"?b:0},children:y.jsx("div",{className:"w-full h-full flex-1 min-h-0",children:y.jsx("canvas",{id:"webgl",className:"w-full h-full block"})})}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Ki("playground")}),y.jsxs("div",{className:`${R==="console"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:[y.jsxs("div",{className:"p-3 border-b border-gray-700 flex justify-between items-center flex-shrink-0",children:[y.jsx("h3",{className:"text-xs font-medium text-gray-200",children:"Console Output"}),y.jsx("button",{onClick:N,className:"px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded transition-colors",title:"Clear console",children:"🗑️ Clear"})]}),y.jsxs("div",{ref:ke,className:"flex-1 p-3 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0",children:[X.length===0?y.jsxs("div",{className:"text-gray-400 text-center py-8",children:[y.jsx("div",{className:"text-2xl mb-2",children:"📋"}),y.jsx("div",{children:"Console output will appear here."})]}):y.jsx("div",{className:"space-y-1",children:X.map((k,F)=>y.jsxs("div",{className:"flex items-start space-x-2",children:[y.jsx("span",{className:"text-gray-500 text-xs mt-1",children:k.timestamp.toLocaleTimeString()}),y.jsx("span",{className:"text-gray-500",children:Ue(k.type)}),y.jsx("span",{className:`${sn(k.type)} break-all`,children:k.message})]},F))}),p&&y.jsxs("div",{className:"mt-4 p-3 bg-red-900/20 border border-red-700 rounded",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-red-400",children:"❌ Parse Error:"}),y.jsx("button",{className:"text-red-300 hover:text-red-100",onClick:()=>g(null),title:"Clear error",children:"✕"})]}),y.jsx("div",{className:"text-red-300 mb-2",children:p.message}),ue&&y.jsxs("div",{className:"text-red-400 text-sm",children:["Line ",ue.line,", Column ",ue.column]})]})]})]}),y.jsx("div",{className:`${R==="info"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:y.jsxs("div",{className:"p-4 h-full overflow-y-auto",children:[y.jsx("h3",{className:"text-base font-semibold text-gray-200 mb-4",children:"About hx-multianim Playground"}),y.jsxs("div",{className:"space-y-6",children:[y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"📚 Documentation & Resources"}),y.jsxs("div",{className:"space-y-2",children:[y.jsxs("a",{href:"https://github.com/bh213/hx-multianim",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"hx-multianim"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Animation library for Haxe driving this playground"})]}),y.jsxs("a",{href:"https://github.com/HeapsIO/heaps",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"Heaps"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform graphics framework"})]}),y.jsxs("a",{href:"https://haxe.org",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"Haxe"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform programming language"})]})]})]}),y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"🎮 Playground Features"}),y.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[y.jsx("li",{children:"• Real-time code editing and preview"}),y.jsx("li",{children:"• Multiple animation examples and components"}),y.jsx("li",{children:"• File management for manim and anim files"}),y.jsx("li",{children:"• Console output and error display"}),y.jsx("li",{children:"• Resizable panels for optimal workflow"})]})]}),y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"💡 Tips"}),y.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[y.jsx("li",{children:"• Use Ctrl+S to apply changes quickly"}),y.jsx("li",{children:"• Switch between playground and console tabs"}),y.jsx("li",{children:"• Resize panels by dragging the dividers"}),y.jsx("li",{children:"• Select files to edit their content"}),y.jsx("li",{children:"• Check console for errors and output"})]})]})]})]})})]})]})]})}var id={exports:{}};(function(e,n){(function(t,r){e.exports=r()})(dd,function(){var t=function(){},r={},i={},l={};function o(p,g){p=p.push?p:[p];var x=[],w=p.length,z=w,c,s,f,h;for(c=function(_,C){C.length&&x.push(_),z--,z||g(x)};w--;){if(s=p[w],f=i[s],f){c(s,f);continue}h=l[s]=l[s]||[],h.push(c)}}function a(p,g){if(p){var x=l[p];if(i[p]=g,!!x)for(;x.length;)x[0](p,g),x.splice(0,1)}}function u(p,g){p.call&&(p={success:p}),g.length?(p.error||t)(g):(p.success||t)(p)}function d(p,g,x,w){var z=document,c=x.async,s=(x.numRetries||0)+1,f=x.before||t,h=p.replace(/[\?|#].*$/,""),_=p.replace(/^(css|img|module|nomodule)!/,""),C,b,E;if(w=w||0,/(^css!|\.css$)/.test(h))E=z.createElement("link"),E.rel="stylesheet",E.href=_,C="hideFocus"in E,C&&E.relList&&(C=0,E.rel="preload",E.as="style");else if(/(^img!|\.(png|gif|jpg|svg|webp)$)/.test(h))E=z.createElement("img"),E.src=_;else if(E=z.createElement("script"),E.src=_,E.async=c===void 0?!0:c,b="noModule"in E,/^module!/.test(h)){if(!b)return g(p,"l");E.type="module"}else if(/^nomodule!/.test(h)&&b)return g(p,"l");E.onload=E.onerror=E.onbeforeload=function(R){var P=R.type[0];if(C)try{E.sheet.cssText.length||(P="e")}catch(X){X.code!=18&&(P="e")}if(P=="e"){if(w+=1,w<s)return d(p,g,x,w)}else if(E.rel=="preload"&&E.as=="style")return E.rel="stylesheet";g(p,P,R.defaultPrevented)},f(p,E)!==!1&&z.head.appendChild(E)}function v(p,g,x){p=p.push?p:[p];var w=p.length,z=w,c=[],s,f;for(s=function(h,_,C){if(_=="e"&&c.push(h),_=="b")if(C)c.push(h);else return;w--,w||g(c)},f=0;f<z;f++)d(p[f],s,x)}function m(p,g,x){var w,z;if(g&&g.trim&&(w=g),z=(w?x:g)||{},w){if(w in r)throw"LoadJS";r[w]=!0}function c(s,f){v(p,function(h){u(z,h),s&&u({success:s,error:f},h),a(w,h)},z)}if(z.returnPromise)return new Promise(c);c()}return m.ready=function(g,x){return o(g,function(w){u(x,w)}),m},m.done=function(g){a(g,[])},m.reset=function(){r={},i={},l={}},m.isDefined=function(g){return g in r},m})})(id);var C0=id.exports;const Rs=Ms(C0);class E0{constructor(n={}){_e(this,"maxRetries");_e(this,"retryDelay");_e(this,"timeout");_e(this,"retryCount",0);_e(this,"isLoaded",!1);this.maxRetries=n.maxRetries||5,this.retryDelay=n.retryDelay||2e3,this.timeout=n.timeout||1e4}waitForReactApp(){document.getElementById("root")&&window.playgroundLoader?(console.log("React app ready, loading Haxe application..."),this.loadHaxeApp()):setTimeout(()=>this.waitForReactApp(),300)}loadHaxeApp(){console.log(`Attempting to load playground.js (attempt ${this.retryCount+1}/${this.maxRetries+1})`);const n=setTimeout(()=>{console.error("Timeout loading playground.js"),this.handleLoadError()},this.timeout);Rs("playground.js",{success:()=>{clearTimeout(n),console.log("playground.js loaded successfully"),this.isLoaded=!0,this.waitForHaxeApp()},error:t=>{clearTimeout(n),console.error("Failed to load playground.js:",t),this.handleLoadError()}})}handleLoadError(){this.retryCount++,this.retryCount<=this.maxRetries?(console.log(`Retrying in ${this.retryDelay}ms... (${this.retryCount}/${this.maxRetries})`),setTimeout(()=>{this.loadHaxeApp()},this.retryDelay)):(console.error(`Failed to load playground.js after ${this.maxRetries} retries`),this.showErrorUI())}showErrorUI(){const n=document.createElement("div");n.style.cssText=`
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: #dc2626;
      color: white;
      padding: 20px;
      border-radius: 8px;
      font-family: Arial, sans-serif;
      z-index: 10000;
      text-align: center;
      max-width: 400px;
    `,n.innerHTML=`
      <h3>⚠️ Loading Error</h3>
      <p>Failed to load playground.js after ${this.maxRetries} attempts.</p>
      <p>Please check if the Haxe build completed successfully.</p>
      <button onclick="location.reload()" style="
        background: #ef4444;
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 4px;
        cursor: pointer;
        margin-top: 10px;
      ">Retry</button>
    `,document.body.appendChild(n)}waitForHaxeApp(){Rs.ready("playground.js",()=>{console.log("playground.js is ready and executed"),this.waitForPlaygroundMain()})}waitForPlaygroundMain(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?(console.log("Haxe application initialized successfully"),window.playgroundLoader&&window.playgroundLoader.mainApp===null&&(window.playgroundLoader.mainApp=window.PlaygroundMain.instance)):setTimeout(()=>this.waitForPlaygroundMain(),100)}start(){document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>this.waitForReactApp()):this.waitForReactApp()}isScriptLoaded(){return this.isLoaded}getRetryCount(){return this.retryCount}}const ld=new E0({maxRetries:5,retryDelay:2e3,timeout:1e4});ld.start();window.haxeLoader=ld;Cl.createRoot(document.getElementById("root")).render(y.jsx(pe.StrictMode,{children:y.jsx(S0,{})}));
//# sourceMappingURL=index-BFLo_p1I.js.map
