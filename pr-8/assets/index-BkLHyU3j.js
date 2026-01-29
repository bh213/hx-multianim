var gd=Object.defineProperty;var vd=(e,n,t)=>n in e?gd(e,n,{enumerable:!0,configurable:!0,writable:!0,value:t}):e[n]=t;var Ce=(e,n,t)=>vd(e,typeof n!="symbol"?n+"":n,t);(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))r(i);new MutationObserver(i=>{for(const l of i)if(l.type==="childList")for(const o of l.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&r(o)}).observe(document,{childList:!0,subtree:!0});function t(i){const l={};return i.integrity&&(l.integrity=i.integrity),i.referrerPolicy&&(l.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?l.credentials="include":i.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function r(i){if(i.ep)return;i.ep=!0;const l=t(i);fetch(i.href,l)}})();var yd=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};function As(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var Us={exports:{}},Fi={},Bs={exports:{}},W={};/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var _r=Symbol.for("react.element"),xd=Symbol.for("react.portal"),wd=Symbol.for("react.fragment"),kd=Symbol.for("react.strict_mode"),_d=Symbol.for("react.profiler"),Sd=Symbol.for("react.provider"),bd=Symbol.for("react.context"),Cd=Symbol.for("react.forward_ref"),Ed=Symbol.for("react.suspense"),$d=Symbol.for("react.memo"),Pd=Symbol.for("react.lazy"),_a=Symbol.iterator;function Nd(e){return e===null||typeof e!="object"?null:(e=_a&&e[_a]||e["@@iterator"],typeof e=="function"?e:null)}var Ws={isMounted:function(){return!1},enqueueForceUpdate:function(){},enqueueReplaceState:function(){},enqueueSetState:function(){}},Hs=Object.assign,Vs={};function Ft(e,n,t){this.props=e,this.context=n,this.refs=Vs,this.updater=t||Ws}Ft.prototype.isReactComponent={};Ft.prototype.setState=function(e,n){if(typeof e!="object"&&typeof e!="function"&&e!=null)throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");this.updater.enqueueSetState(this,e,n,"setState")};Ft.prototype.forceUpdate=function(e){this.updater.enqueueForceUpdate(this,e,"forceUpdate")};function Qs(){}Qs.prototype=Ft.prototype;function wo(e,n,t){this.props=e,this.context=n,this.refs=Vs,this.updater=t||Ws}var ko=wo.prototype=new Qs;ko.constructor=wo;Hs(ko,Ft.prototype);ko.isPureReactComponent=!0;var Sa=Array.isArray,Ks=Object.prototype.hasOwnProperty,_o={current:null},Gs={key:!0,ref:!0,__self:!0,__source:!0};function Ys(e,n,t){var r,i={},l=null,o=null;if(n!=null)for(r in n.ref!==void 0&&(o=n.ref),n.key!==void 0&&(l=""+n.key),n)Ks.call(n,r)&&!Gs.hasOwnProperty(r)&&(i[r]=n[r]);var a=arguments.length-2;if(a===1)i.children=t;else if(1<a){for(var s=Array(a),d=0;d<a;d++)s[d]=arguments[d+2];i.children=s}if(e&&e.defaultProps)for(r in a=e.defaultProps,a)i[r]===void 0&&(i[r]=a[r]);return{$$typeof:_r,type:e,key:l,ref:o,props:i,_owner:_o.current}}function Td(e,n){return{$$typeof:_r,type:e.type,key:n,ref:e.ref,props:e.props,_owner:e._owner}}function So(e){return typeof e=="object"&&e!==null&&e.$$typeof===_r}function Fd(e){var n={"=":"=0",":":"=2"};return"$"+e.replace(/[=:]/g,function(t){return n[t]})}var ba=/\/+/g;function Xi(e,n){return typeof e=="object"&&e!==null&&e.key!=null?Fd(""+e.key):n.toString(36)}function Kr(e,n,t,r,i){var l=typeof e;(l==="undefined"||l==="boolean")&&(e=null);var o=!1;if(e===null)o=!0;else switch(l){case"string":case"number":o=!0;break;case"object":switch(e.$$typeof){case _r:case xd:o=!0}}if(o)return o=e,i=i(o),e=r===""?"."+Xi(o,0):r,Sa(i)?(t="",e!=null&&(t=e.replace(ba,"$&/")+"/"),Kr(i,n,t,"",function(d){return d})):i!=null&&(So(i)&&(i=Td(i,t+(!i.key||o&&o.key===i.key?"":(""+i.key).replace(ba,"$&/")+"/")+e)),n.push(i)),1;if(o=0,r=r===""?".":r+":",Sa(e))for(var a=0;a<e.length;a++){l=e[a];var s=r+Xi(l,a);o+=Kr(l,n,t,s,i)}else if(s=Nd(e),typeof s=="function")for(e=s.call(e),a=0;!(l=e.next()).done;)l=l.value,s=r+Xi(l,a++),o+=Kr(l,n,t,s,i);else if(l==="object")throw n=String(e),Error("Objects are not valid as a React child (found: "+(n==="[object Object]"?"object with keys {"+Object.keys(e).join(", ")+"}":n)+"). If you meant to render a collection of children, use an array instead.");return o}function Pr(e,n,t){if(e==null)return e;var r=[],i=0;return Kr(e,r,"","",function(l){return n.call(t,l,i++)}),r}function jd(e){if(e._status===-1){var n=e._result;n=n(),n.then(function(t){(e._status===0||e._status===-1)&&(e._status=1,e._result=t)},function(t){(e._status===0||e._status===-1)&&(e._status=2,e._result=t)}),e._status===-1&&(e._status=0,e._result=n)}if(e._status===1)return e._result.default;throw e._result}var Pe={current:null},Gr={transition:null},Rd={ReactCurrentDispatcher:Pe,ReactCurrentBatchConfig:Gr,ReactCurrentOwner:_o};function Xs(){throw Error("act(...) is not supported in production builds of React.")}W.Children={map:Pr,forEach:function(e,n,t){Pr(e,function(){n.apply(this,arguments)},t)},count:function(e){var n=0;return Pr(e,function(){n++}),n},toArray:function(e){return Pr(e,function(n){return n})||[]},only:function(e){if(!So(e))throw Error("React.Children.only expected to receive a single React element child.");return e}};W.Component=Ft;W.Fragment=wd;W.Profiler=_d;W.PureComponent=wo;W.StrictMode=kd;W.Suspense=Ed;W.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Rd;W.act=Xs;W.cloneElement=function(e,n,t){if(e==null)throw Error("React.cloneElement(...): The argument must be a React element, but you passed "+e+".");var r=Hs({},e.props),i=e.key,l=e.ref,o=e._owner;if(n!=null){if(n.ref!==void 0&&(l=n.ref,o=_o.current),n.key!==void 0&&(i=""+n.key),e.type&&e.type.defaultProps)var a=e.type.defaultProps;for(s in n)Ks.call(n,s)&&!Gs.hasOwnProperty(s)&&(r[s]=n[s]===void 0&&a!==void 0?a[s]:n[s])}var s=arguments.length-2;if(s===1)r.children=t;else if(1<s){a=Array(s);for(var d=0;d<s;d++)a[d]=arguments[d+2];r.children=a}return{$$typeof:_r,type:e.type,key:i,ref:l,props:r,_owner:o}};W.createContext=function(e){return e={$$typeof:bd,_currentValue:e,_currentValue2:e,_threadCount:0,Provider:null,Consumer:null,_defaultValue:null,_globalName:null},e.Provider={$$typeof:Sd,_context:e},e.Consumer=e};W.createElement=Ys;W.createFactory=function(e){var n=Ys.bind(null,e);return n.type=e,n};W.createRef=function(){return{current:null}};W.forwardRef=function(e){return{$$typeof:Cd,render:e}};W.isValidElement=So;W.lazy=function(e){return{$$typeof:Pd,_payload:{_status:-1,_result:e},_init:jd}};W.memo=function(e,n){return{$$typeof:$d,type:e,compare:n===void 0?null:n}};W.startTransition=function(e){var n=Gr.transition;Gr.transition={};try{e()}finally{Gr.transition=n}};W.unstable_act=Xs;W.useCallback=function(e,n){return Pe.current.useCallback(e,n)};W.useContext=function(e){return Pe.current.useContext(e)};W.useDebugValue=function(){};W.useDeferredValue=function(e){return Pe.current.useDeferredValue(e)};W.useEffect=function(e,n){return Pe.current.useEffect(e,n)};W.useId=function(){return Pe.current.useId()};W.useImperativeHandle=function(e,n,t){return Pe.current.useImperativeHandle(e,n,t)};W.useInsertionEffect=function(e,n){return Pe.current.useInsertionEffect(e,n)};W.useLayoutEffect=function(e,n){return Pe.current.useLayoutEffect(e,n)};W.useMemo=function(e,n){return Pe.current.useMemo(e,n)};W.useReducer=function(e,n,t){return Pe.current.useReducer(e,n,t)};W.useRef=function(e){return Pe.current.useRef(e)};W.useState=function(e){return Pe.current.useState(e)};W.useSyncExternalStore=function(e,n,t){return Pe.current.useSyncExternalStore(e,n,t)};W.useTransition=function(){return Pe.current.useTransition()};W.version="18.3.1";Bs.exports=W;var $=Bs.exports;const de=As($);/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var zd=$,Ld=Symbol.for("react.element"),Md=Symbol.for("react.fragment"),Dd=Object.prototype.hasOwnProperty,Od=zd.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,Id={key:!0,ref:!0,__self:!0,__source:!0};function Zs(e,n,t){var r,i={},l=null,o=null;t!==void 0&&(l=""+t),n.key!==void 0&&(l=""+n.key),n.ref!==void 0&&(o=n.ref);for(r in n)Dd.call(n,r)&&!Id.hasOwnProperty(r)&&(i[r]=n[r]);if(e&&e.defaultProps)for(r in n=e.defaultProps,n)i[r]===void 0&&(i[r]=n[r]);return{$$typeof:Ld,type:e,key:l,ref:o,props:i,_owner:Od.current}}Fi.Fragment=Md;Fi.jsx=Zs;Fi.jsxs=Zs;Us.exports=Fi;var v=Us.exports,El={},qs={exports:{}},Ue={},Js={exports:{}},eu={};/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */(function(e){function n(N,L){var A=N.length;N.push(L);e:for(;0<A;){var z=A-1>>>1,D=N[z];if(0<i(D,L))N[z]=L,N[A]=D,A=z;else break e}}function t(N){return N.length===0?null:N[0]}function r(N){if(N.length===0)return null;var L=N[0],A=N.pop();if(A!==L){N[0]=A;e:for(var z=0,D=N.length,oe=D>>>1;z<oe;){var ye=2*(z+1)-1,Le=N[ye],ln=ye+1,rt=N[ln];if(0>i(Le,A))ln<D&&0>i(rt,Le)?(N[z]=rt,N[ln]=A,z=ln):(N[z]=Le,N[ye]=A,z=ye);else if(ln<D&&0>i(rt,A))N[z]=rt,N[ln]=A,z=ln;else break e}}return L}function i(N,L){var A=N.sortIndex-L.sortIndex;return A!==0?A:N.id-L.id}if(typeof performance=="object"&&typeof performance.now=="function"){var l=performance;e.unstable_now=function(){return l.now()}}else{var o=Date,a=o.now();e.unstable_now=function(){return o.now()-a}}var s=[],d=[],x=1,h=null,p=3,g=!1,k=!1,_=!1,j=typeof setTimeout=="function"?setTimeout:null,c=typeof clearTimeout=="function"?clearTimeout:null,u=typeof setImmediate<"u"?setImmediate:null;typeof navigator<"u"&&navigator.scheduling!==void 0&&navigator.scheduling.isInputPending!==void 0&&navigator.scheduling.isInputPending.bind(navigator.scheduling);function f(N){for(var L=t(d);L!==null;){if(L.callback===null)r(d);else if(L.startTime<=N)r(d),L.sortIndex=L.expirationTime,n(s,L);else break;L=t(d)}}function y(N){if(_=!1,f(N),!k)if(t(s)!==null)k=!0,K(S);else{var L=t(d);L!==null&&be(y,L.startTime-N)}}function S(N,L){k=!1,_&&(_=!1,c(C),C=-1),g=!0;var A=p;try{for(f(L),h=t(s);h!==null&&(!(h.expirationTime>L)||N&&!te());){var z=h.callback;if(typeof z=="function"){h.callback=null,p=h.priorityLevel;var D=z(h.expirationTime<=L);L=e.unstable_now(),typeof D=="function"?h.callback=D:h===t(s)&&r(s),f(L)}else r(s);h=t(s)}if(h!==null)var oe=!0;else{var ye=t(d);ye!==null&&be(y,ye.startTime-L),oe=!1}return oe}finally{h=null,p=A,g=!1}}var m=!1,E=null,C=-1,O=5,T=-1;function te(){return!(e.unstable_now()-T<O)}function We(){if(E!==null){var N=e.unstable_now();T=N;var L=!0;try{L=E(!0,N)}finally{L?He():(m=!1,E=null)}}else m=!1}var He;if(typeof u=="function")He=function(){u(We)};else if(typeof MessageChannel<"u"){var ve=new MessageChannel,M=ve.port2;ve.port1.onmessage=We,He=function(){M.postMessage(null)}}else He=function(){j(We,0)};function K(N){E=N,m||(m=!0,He())}function be(N,L){C=j(function(){N(e.unstable_now())},L)}e.unstable_IdlePriority=5,e.unstable_ImmediatePriority=1,e.unstable_LowPriority=4,e.unstable_NormalPriority=3,e.unstable_Profiling=null,e.unstable_UserBlockingPriority=2,e.unstable_cancelCallback=function(N){N.callback=null},e.unstable_continueExecution=function(){k||g||(k=!0,K(S))},e.unstable_forceFrameRate=function(N){0>N||125<N?console.error("forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported"):O=0<N?Math.floor(1e3/N):5},e.unstable_getCurrentPriorityLevel=function(){return p},e.unstable_getFirstCallbackNode=function(){return t(s)},e.unstable_next=function(N){switch(p){case 1:case 2:case 3:var L=3;break;default:L=p}var A=p;p=L;try{return N()}finally{p=A}},e.unstable_pauseExecution=function(){},e.unstable_requestPaint=function(){},e.unstable_runWithPriority=function(N,L){switch(N){case 1:case 2:case 3:case 4:case 5:break;default:N=3}var A=p;p=N;try{return L()}finally{p=A}},e.unstable_scheduleCallback=function(N,L,A){var z=e.unstable_now();switch(typeof A=="object"&&A!==null?(A=A.delay,A=typeof A=="number"&&0<A?z+A:z):A=z,N){case 1:var D=-1;break;case 2:D=250;break;case 5:D=1073741823;break;case 4:D=1e4;break;default:D=5e3}return D=A+D,N={id:x++,callback:L,priorityLevel:N,startTime:A,expirationTime:D,sortIndex:-1},A>z?(N.sortIndex=A,n(d,N),t(s)===null&&N===t(d)&&(_?(c(C),C=-1):_=!0,be(y,A-z))):(N.sortIndex=D,n(s,N),k||g||(k=!0,K(S))),N},e.unstable_shouldYield=te,e.unstable_wrapCallback=function(N){var L=p;return function(){var A=p;p=L;try{return N.apply(this,arguments)}finally{p=A}}}})(eu);Js.exports=eu;var Ad=Js.exports;/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Ud=$,Ae=Ad;function b(e){for(var n="https://reactjs.org/docs/error-decoder.html?invariant="+e,t=1;t<arguments.length;t++)n+="&args[]="+encodeURIComponent(arguments[t]);return"Minified React error #"+e+"; visit "+n+" for the full message or use the non-minified dev environment for full errors and additional helpful warnings."}var nu=new Set,ir={};function nt(e,n){bt(e,n),bt(e+"Capture",n)}function bt(e,n){for(ir[e]=n,e=0;e<n.length;e++)nu.add(n[e])}var vn=!(typeof window>"u"||typeof window.document>"u"||typeof window.document.createElement>"u"),$l=Object.prototype.hasOwnProperty,Bd=/^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,Ca={},Ea={};function Wd(e){return $l.call(Ea,e)?!0:$l.call(Ca,e)?!1:Bd.test(e)?Ea[e]=!0:(Ca[e]=!0,!1)}function Hd(e,n,t,r){if(t!==null&&t.type===0)return!1;switch(typeof n){case"function":case"symbol":return!0;case"boolean":return r?!1:t!==null?!t.acceptsBooleans:(e=e.toLowerCase().slice(0,5),e!=="data-"&&e!=="aria-");default:return!1}}function Vd(e,n,t,r){if(n===null||typeof n>"u"||Hd(e,n,t,r))return!0;if(r)return!1;if(t!==null)switch(t.type){case 3:return!n;case 4:return n===!1;case 5:return isNaN(n);case 6:return isNaN(n)||1>n}return!1}function Ne(e,n,t,r,i,l,o){this.acceptsBooleans=n===2||n===3||n===4,this.attributeName=r,this.attributeNamespace=i,this.mustUseProperty=t,this.propertyName=e,this.type=n,this.sanitizeURL=l,this.removeEmptyString=o}var ge={};"children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style".split(" ").forEach(function(e){ge[e]=new Ne(e,0,!1,e,null,!1,!1)});[["acceptCharset","accept-charset"],["className","class"],["htmlFor","for"],["httpEquiv","http-equiv"]].forEach(function(e){var n=e[0];ge[n]=new Ne(n,1,!1,e[1],null,!1,!1)});["contentEditable","draggable","spellCheck","value"].forEach(function(e){ge[e]=new Ne(e,2,!1,e.toLowerCase(),null,!1,!1)});["autoReverse","externalResourcesRequired","focusable","preserveAlpha"].forEach(function(e){ge[e]=new Ne(e,2,!1,e,null,!1,!1)});"allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope".split(" ").forEach(function(e){ge[e]=new Ne(e,3,!1,e.toLowerCase(),null,!1,!1)});["checked","multiple","muted","selected"].forEach(function(e){ge[e]=new Ne(e,3,!0,e,null,!1,!1)});["capture","download"].forEach(function(e){ge[e]=new Ne(e,4,!1,e,null,!1,!1)});["cols","rows","size","span"].forEach(function(e){ge[e]=new Ne(e,6,!1,e,null,!1,!1)});["rowSpan","start"].forEach(function(e){ge[e]=new Ne(e,5,!1,e.toLowerCase(),null,!1,!1)});var bo=/[\-:]([a-z])/g;function Co(e){return e[1].toUpperCase()}"accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height".split(" ").forEach(function(e){var n=e.replace(bo,Co);ge[n]=new Ne(n,1,!1,e,null,!1,!1)});"xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type".split(" ").forEach(function(e){var n=e.replace(bo,Co);ge[n]=new Ne(n,1,!1,e,"http://www.w3.org/1999/xlink",!1,!1)});["xml:base","xml:lang","xml:space"].forEach(function(e){var n=e.replace(bo,Co);ge[n]=new Ne(n,1,!1,e,"http://www.w3.org/XML/1998/namespace",!1,!1)});["tabIndex","crossOrigin"].forEach(function(e){ge[e]=new Ne(e,1,!1,e.toLowerCase(),null,!1,!1)});ge.xlinkHref=new Ne("xlinkHref",1,!1,"xlink:href","http://www.w3.org/1999/xlink",!0,!1);["src","href","action","formAction"].forEach(function(e){ge[e]=new Ne(e,1,!1,e.toLowerCase(),null,!0,!0)});function Eo(e,n,t,r){var i=ge.hasOwnProperty(n)?ge[n]:null;(i!==null?i.type!==0:r||!(2<n.length)||n[0]!=="o"&&n[0]!=="O"||n[1]!=="n"&&n[1]!=="N")&&(Vd(n,t,i,r)&&(t=null),r||i===null?Wd(n)&&(t===null?e.removeAttribute(n):e.setAttribute(n,""+t)):i.mustUseProperty?e[i.propertyName]=t===null?i.type===3?!1:"":t:(n=i.attributeName,r=i.attributeNamespace,t===null?e.removeAttribute(n):(i=i.type,t=i===3||i===4&&t===!0?"":""+t,r?e.setAttributeNS(r,n,t):e.setAttribute(n,t))))}var kn=Ud.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,Nr=Symbol.for("react.element"),lt=Symbol.for("react.portal"),ot=Symbol.for("react.fragment"),$o=Symbol.for("react.strict_mode"),Pl=Symbol.for("react.profiler"),tu=Symbol.for("react.provider"),ru=Symbol.for("react.context"),Po=Symbol.for("react.forward_ref"),Nl=Symbol.for("react.suspense"),Tl=Symbol.for("react.suspense_list"),No=Symbol.for("react.memo"),Sn=Symbol.for("react.lazy"),iu=Symbol.for("react.offscreen"),$a=Symbol.iterator;function zt(e){return e===null||typeof e!="object"?null:(e=$a&&e[$a]||e["@@iterator"],typeof e=="function"?e:null)}var ne=Object.assign,Zi;function Bt(e){if(Zi===void 0)try{throw Error()}catch(t){var n=t.stack.trim().match(/\n( *(at )?)/);Zi=n&&n[1]||""}return`
`+Zi+e}var qi=!1;function Ji(e,n){if(!e||qi)return"";qi=!0;var t=Error.prepareStackTrace;Error.prepareStackTrace=void 0;try{if(n)if(n=function(){throw Error()},Object.defineProperty(n.prototype,"props",{set:function(){throw Error()}}),typeof Reflect=="object"&&Reflect.construct){try{Reflect.construct(n,[])}catch(d){var r=d}Reflect.construct(e,[],n)}else{try{n.call()}catch(d){r=d}e.call(n.prototype)}else{try{throw Error()}catch(d){r=d}e()}}catch(d){if(d&&r&&typeof d.stack=="string"){for(var i=d.stack.split(`
`),l=r.stack.split(`
`),o=i.length-1,a=l.length-1;1<=o&&0<=a&&i[o]!==l[a];)a--;for(;1<=o&&0<=a;o--,a--)if(i[o]!==l[a]){if(o!==1||a!==1)do if(o--,a--,0>a||i[o]!==l[a]){var s=`
`+i[o].replace(" at new "," at ");return e.displayName&&s.includes("<anonymous>")&&(s=s.replace("<anonymous>",e.displayName)),s}while(1<=o&&0<=a);break}}}finally{qi=!1,Error.prepareStackTrace=t}return(e=e?e.displayName||e.name:"")?Bt(e):""}function Qd(e){switch(e.tag){case 5:return Bt(e.type);case 16:return Bt("Lazy");case 13:return Bt("Suspense");case 19:return Bt("SuspenseList");case 0:case 2:case 15:return e=Ji(e.type,!1),e;case 11:return e=Ji(e.type.render,!1),e;case 1:return e=Ji(e.type,!0),e;default:return""}}function Fl(e){if(e==null)return null;if(typeof e=="function")return e.displayName||e.name||null;if(typeof e=="string")return e;switch(e){case ot:return"Fragment";case lt:return"Portal";case Pl:return"Profiler";case $o:return"StrictMode";case Nl:return"Suspense";case Tl:return"SuspenseList"}if(typeof e=="object")switch(e.$$typeof){case ru:return(e.displayName||"Context")+".Consumer";case tu:return(e._context.displayName||"Context")+".Provider";case Po:var n=e.render;return e=e.displayName,e||(e=n.displayName||n.name||"",e=e!==""?"ForwardRef("+e+")":"ForwardRef"),e;case No:return n=e.displayName||null,n!==null?n:Fl(e.type)||"Memo";case Sn:n=e._payload,e=e._init;try{return Fl(e(n))}catch{}}return null}function Kd(e){var n=e.type;switch(e.tag){case 24:return"Cache";case 9:return(n.displayName||"Context")+".Consumer";case 10:return(n._context.displayName||"Context")+".Provider";case 18:return"DehydratedFragment";case 11:return e=n.render,e=e.displayName||e.name||"",n.displayName||(e!==""?"ForwardRef("+e+")":"ForwardRef");case 7:return"Fragment";case 5:return n;case 4:return"Portal";case 3:return"Root";case 6:return"Text";case 16:return Fl(n);case 8:return n===$o?"StrictMode":"Mode";case 22:return"Offscreen";case 12:return"Profiler";case 21:return"Scope";case 13:return"Suspense";case 19:return"SuspenseList";case 25:return"TracingMarker";case 1:case 0:case 17:case 2:case 14:case 15:if(typeof n=="function")return n.displayName||n.name||null;if(typeof n=="string")return n}return null}function On(e){switch(typeof e){case"boolean":case"number":case"string":case"undefined":return e;case"object":return e;default:return""}}function lu(e){var n=e.type;return(e=e.nodeName)&&e.toLowerCase()==="input"&&(n==="checkbox"||n==="radio")}function Gd(e){var n=lu(e)?"checked":"value",t=Object.getOwnPropertyDescriptor(e.constructor.prototype,n),r=""+e[n];if(!e.hasOwnProperty(n)&&typeof t<"u"&&typeof t.get=="function"&&typeof t.set=="function"){var i=t.get,l=t.set;return Object.defineProperty(e,n,{configurable:!0,get:function(){return i.call(this)},set:function(o){r=""+o,l.call(this,o)}}),Object.defineProperty(e,n,{enumerable:t.enumerable}),{getValue:function(){return r},setValue:function(o){r=""+o},stopTracking:function(){e._valueTracker=null,delete e[n]}}}}function Tr(e){e._valueTracker||(e._valueTracker=Gd(e))}function ou(e){if(!e)return!1;var n=e._valueTracker;if(!n)return!0;var t=n.getValue(),r="";return e&&(r=lu(e)?e.checked?"true":"false":e.value),e=r,e!==t?(n.setValue(e),!0):!1}function oi(e){if(e=e||(typeof document<"u"?document:void 0),typeof e>"u")return null;try{return e.activeElement||e.body}catch{return e.body}}function jl(e,n){var t=n.checked;return ne({},n,{defaultChecked:void 0,defaultValue:void 0,value:void 0,checked:t??e._wrapperState.initialChecked})}function Pa(e,n){var t=n.defaultValue==null?"":n.defaultValue,r=n.checked!=null?n.checked:n.defaultChecked;t=On(n.value!=null?n.value:t),e._wrapperState={initialChecked:r,initialValue:t,controlled:n.type==="checkbox"||n.type==="radio"?n.checked!=null:n.value!=null}}function au(e,n){n=n.checked,n!=null&&Eo(e,"checked",n,!1)}function Rl(e,n){au(e,n);var t=On(n.value),r=n.type;if(t!=null)r==="number"?(t===0&&e.value===""||e.value!=t)&&(e.value=""+t):e.value!==""+t&&(e.value=""+t);else if(r==="submit"||r==="reset"){e.removeAttribute("value");return}n.hasOwnProperty("value")?zl(e,n.type,t):n.hasOwnProperty("defaultValue")&&zl(e,n.type,On(n.defaultValue)),n.checked==null&&n.defaultChecked!=null&&(e.defaultChecked=!!n.defaultChecked)}function Na(e,n,t){if(n.hasOwnProperty("value")||n.hasOwnProperty("defaultValue")){var r=n.type;if(!(r!=="submit"&&r!=="reset"||n.value!==void 0&&n.value!==null))return;n=""+e._wrapperState.initialValue,t||n===e.value||(e.value=n),e.defaultValue=n}t=e.name,t!==""&&(e.name=""),e.defaultChecked=!!e._wrapperState.initialChecked,t!==""&&(e.name=t)}function zl(e,n,t){(n!=="number"||oi(e.ownerDocument)!==e)&&(t==null?e.defaultValue=""+e._wrapperState.initialValue:e.defaultValue!==""+t&&(e.defaultValue=""+t))}var Wt=Array.isArray;function yt(e,n,t,r){if(e=e.options,n){n={};for(var i=0;i<t.length;i++)n["$"+t[i]]=!0;for(t=0;t<e.length;t++)i=n.hasOwnProperty("$"+e[t].value),e[t].selected!==i&&(e[t].selected=i),i&&r&&(e[t].defaultSelected=!0)}else{for(t=""+On(t),n=null,i=0;i<e.length;i++){if(e[i].value===t){e[i].selected=!0,r&&(e[i].defaultSelected=!0);return}n!==null||e[i].disabled||(n=e[i])}n!==null&&(n.selected=!0)}}function Ll(e,n){if(n.dangerouslySetInnerHTML!=null)throw Error(b(91));return ne({},n,{value:void 0,defaultValue:void 0,children:""+e._wrapperState.initialValue})}function Ta(e,n){var t=n.value;if(t==null){if(t=n.children,n=n.defaultValue,t!=null){if(n!=null)throw Error(b(92));if(Wt(t)){if(1<t.length)throw Error(b(93));t=t[0]}n=t}n==null&&(n=""),t=n}e._wrapperState={initialValue:On(t)}}function su(e,n){var t=On(n.value),r=On(n.defaultValue);t!=null&&(t=""+t,t!==e.value&&(e.value=t),n.defaultValue==null&&e.defaultValue!==t&&(e.defaultValue=t)),r!=null&&(e.defaultValue=""+r)}function Fa(e){var n=e.textContent;n===e._wrapperState.initialValue&&n!==""&&n!==null&&(e.value=n)}function uu(e){switch(e){case"svg":return"http://www.w3.org/2000/svg";case"math":return"http://www.w3.org/1998/Math/MathML";default:return"http://www.w3.org/1999/xhtml"}}function Ml(e,n){return e==null||e==="http://www.w3.org/1999/xhtml"?uu(n):e==="http://www.w3.org/2000/svg"&&n==="foreignObject"?"http://www.w3.org/1999/xhtml":e}var Fr,cu=function(e){return typeof MSApp<"u"&&MSApp.execUnsafeLocalFunction?function(n,t,r,i){MSApp.execUnsafeLocalFunction(function(){return e(n,t,r,i)})}:e}(function(e,n){if(e.namespaceURI!=="http://www.w3.org/2000/svg"||"innerHTML"in e)e.innerHTML=n;else{for(Fr=Fr||document.createElement("div"),Fr.innerHTML="<svg>"+n.valueOf().toString()+"</svg>",n=Fr.firstChild;e.firstChild;)e.removeChild(e.firstChild);for(;n.firstChild;)e.appendChild(n.firstChild)}});function lr(e,n){if(n){var t=e.firstChild;if(t&&t===e.lastChild&&t.nodeType===3){t.nodeValue=n;return}}e.textContent=n}var Kt={animationIterationCount:!0,aspectRatio:!0,borderImageOutset:!0,borderImageSlice:!0,borderImageWidth:!0,boxFlex:!0,boxFlexGroup:!0,boxOrdinalGroup:!0,columnCount:!0,columns:!0,flex:!0,flexGrow:!0,flexPositive:!0,flexShrink:!0,flexNegative:!0,flexOrder:!0,gridArea:!0,gridRow:!0,gridRowEnd:!0,gridRowSpan:!0,gridRowStart:!0,gridColumn:!0,gridColumnEnd:!0,gridColumnSpan:!0,gridColumnStart:!0,fontWeight:!0,lineClamp:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,tabSize:!0,widows:!0,zIndex:!0,zoom:!0,fillOpacity:!0,floodOpacity:!0,stopOpacity:!0,strokeDasharray:!0,strokeDashoffset:!0,strokeMiterlimit:!0,strokeOpacity:!0,strokeWidth:!0},Yd=["Webkit","ms","Moz","O"];Object.keys(Kt).forEach(function(e){Yd.forEach(function(n){n=n+e.charAt(0).toUpperCase()+e.substring(1),Kt[n]=Kt[e]})});function du(e,n,t){return n==null||typeof n=="boolean"||n===""?"":t||typeof n!="number"||n===0||Kt.hasOwnProperty(e)&&Kt[e]?(""+n).trim():n+"px"}function fu(e,n){e=e.style;for(var t in n)if(n.hasOwnProperty(t)){var r=t.indexOf("--")===0,i=du(t,n[t],r);t==="float"&&(t="cssFloat"),r?e.setProperty(t,i):e[t]=i}}var Xd=ne({menuitem:!0},{area:!0,base:!0,br:!0,col:!0,embed:!0,hr:!0,img:!0,input:!0,keygen:!0,link:!0,meta:!0,param:!0,source:!0,track:!0,wbr:!0});function Dl(e,n){if(n){if(Xd[e]&&(n.children!=null||n.dangerouslySetInnerHTML!=null))throw Error(b(137,e));if(n.dangerouslySetInnerHTML!=null){if(n.children!=null)throw Error(b(60));if(typeof n.dangerouslySetInnerHTML!="object"||!("__html"in n.dangerouslySetInnerHTML))throw Error(b(61))}if(n.style!=null&&typeof n.style!="object")throw Error(b(62))}}function Ol(e,n){if(e.indexOf("-")===-1)return typeof n.is=="string";switch(e){case"annotation-xml":case"color-profile":case"font-face":case"font-face-src":case"font-face-uri":case"font-face-format":case"font-face-name":case"missing-glyph":return!1;default:return!0}}var Il=null;function To(e){return e=e.target||e.srcElement||window,e.correspondingUseElement&&(e=e.correspondingUseElement),e.nodeType===3?e.parentNode:e}var Al=null,xt=null,wt=null;function ja(e){if(e=Cr(e)){if(typeof Al!="function")throw Error(b(280));var n=e.stateNode;n&&(n=Mi(n),Al(e.stateNode,e.type,n))}}function pu(e){xt?wt?wt.push(e):wt=[e]:xt=e}function mu(){if(xt){var e=xt,n=wt;if(wt=xt=null,ja(e),n)for(e=0;e<n.length;e++)ja(n[e])}}function hu(e,n){return e(n)}function gu(){}var el=!1;function vu(e,n,t){if(el)return e(n,t);el=!0;try{return hu(e,n,t)}finally{el=!1,(xt!==null||wt!==null)&&(gu(),mu())}}function or(e,n){var t=e.stateNode;if(t===null)return null;var r=Mi(t);if(r===null)return null;t=r[n];e:switch(n){case"onClick":case"onClickCapture":case"onDoubleClick":case"onDoubleClickCapture":case"onMouseDown":case"onMouseDownCapture":case"onMouseMove":case"onMouseMoveCapture":case"onMouseUp":case"onMouseUpCapture":case"onMouseEnter":(r=!r.disabled)||(e=e.type,r=!(e==="button"||e==="input"||e==="select"||e==="textarea")),e=!r;break e;default:e=!1}if(e)return null;if(t&&typeof t!="function")throw Error(b(231,n,typeof t));return t}var Ul=!1;if(vn)try{var Lt={};Object.defineProperty(Lt,"passive",{get:function(){Ul=!0}}),window.addEventListener("test",Lt,Lt),window.removeEventListener("test",Lt,Lt)}catch{Ul=!1}function Zd(e,n,t,r,i,l,o,a,s){var d=Array.prototype.slice.call(arguments,3);try{n.apply(t,d)}catch(x){this.onError(x)}}var Gt=!1,ai=null,si=!1,Bl=null,qd={onError:function(e){Gt=!0,ai=e}};function Jd(e,n,t,r,i,l,o,a,s){Gt=!1,ai=null,Zd.apply(qd,arguments)}function ef(e,n,t,r,i,l,o,a,s){if(Jd.apply(this,arguments),Gt){if(Gt){var d=ai;Gt=!1,ai=null}else throw Error(b(198));si||(si=!0,Bl=d)}}function tt(e){var n=e,t=e;if(e.alternate)for(;n.return;)n=n.return;else{e=n;do n=e,n.flags&4098&&(t=n.return),e=n.return;while(e)}return n.tag===3?t:null}function yu(e){if(e.tag===13){var n=e.memoizedState;if(n===null&&(e=e.alternate,e!==null&&(n=e.memoizedState)),n!==null)return n.dehydrated}return null}function Ra(e){if(tt(e)!==e)throw Error(b(188))}function nf(e){var n=e.alternate;if(!n){if(n=tt(e),n===null)throw Error(b(188));return n!==e?null:e}for(var t=e,r=n;;){var i=t.return;if(i===null)break;var l=i.alternate;if(l===null){if(r=i.return,r!==null){t=r;continue}break}if(i.child===l.child){for(l=i.child;l;){if(l===t)return Ra(i),e;if(l===r)return Ra(i),n;l=l.sibling}throw Error(b(188))}if(t.return!==r.return)t=i,r=l;else{for(var o=!1,a=i.child;a;){if(a===t){o=!0,t=i,r=l;break}if(a===r){o=!0,r=i,t=l;break}a=a.sibling}if(!o){for(a=l.child;a;){if(a===t){o=!0,t=l,r=i;break}if(a===r){o=!0,r=l,t=i;break}a=a.sibling}if(!o)throw Error(b(189))}}if(t.alternate!==r)throw Error(b(190))}if(t.tag!==3)throw Error(b(188));return t.stateNode.current===t?e:n}function xu(e){return e=nf(e),e!==null?wu(e):null}function wu(e){if(e.tag===5||e.tag===6)return e;for(e=e.child;e!==null;){var n=wu(e);if(n!==null)return n;e=e.sibling}return null}var ku=Ae.unstable_scheduleCallback,za=Ae.unstable_cancelCallback,tf=Ae.unstable_shouldYield,rf=Ae.unstable_requestPaint,le=Ae.unstable_now,lf=Ae.unstable_getCurrentPriorityLevel,Fo=Ae.unstable_ImmediatePriority,_u=Ae.unstable_UserBlockingPriority,ui=Ae.unstable_NormalPriority,of=Ae.unstable_LowPriority,Su=Ae.unstable_IdlePriority,ji=null,cn=null;function af(e){if(cn&&typeof cn.onCommitFiberRoot=="function")try{cn.onCommitFiberRoot(ji,e,void 0,(e.current.flags&128)===128)}catch{}}var nn=Math.clz32?Math.clz32:cf,sf=Math.log,uf=Math.LN2;function cf(e){return e>>>=0,e===0?32:31-(sf(e)/uf|0)|0}var jr=64,Rr=4194304;function Ht(e){switch(e&-e){case 1:return 1;case 2:return 2;case 4:return 4;case 8:return 8;case 16:return 16;case 32:return 32;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return e&4194240;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return e&130023424;case 134217728:return 134217728;case 268435456:return 268435456;case 536870912:return 536870912;case 1073741824:return 1073741824;default:return e}}function ci(e,n){var t=e.pendingLanes;if(t===0)return 0;var r=0,i=e.suspendedLanes,l=e.pingedLanes,o=t&268435455;if(o!==0){var a=o&~i;a!==0?r=Ht(a):(l&=o,l!==0&&(r=Ht(l)))}else o=t&~i,o!==0?r=Ht(o):l!==0&&(r=Ht(l));if(r===0)return 0;if(n!==0&&n!==r&&!(n&i)&&(i=r&-r,l=n&-n,i>=l||i===16&&(l&4194240)!==0))return n;if(r&4&&(r|=t&16),n=e.entangledLanes,n!==0)for(e=e.entanglements,n&=r;0<n;)t=31-nn(n),i=1<<t,r|=e[t],n&=~i;return r}function df(e,n){switch(e){case 1:case 2:case 4:return n+250;case 8:case 16:case 32:case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return n+5e3;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return-1;case 134217728:case 268435456:case 536870912:case 1073741824:return-1;default:return-1}}function ff(e,n){for(var t=e.suspendedLanes,r=e.pingedLanes,i=e.expirationTimes,l=e.pendingLanes;0<l;){var o=31-nn(l),a=1<<o,s=i[o];s===-1?(!(a&t)||a&r)&&(i[o]=df(a,n)):s<=n&&(e.expiredLanes|=a),l&=~a}}function Wl(e){return e=e.pendingLanes&-1073741825,e!==0?e:e&1073741824?1073741824:0}function bu(){var e=jr;return jr<<=1,!(jr&4194240)&&(jr=64),e}function nl(e){for(var n=[],t=0;31>t;t++)n.push(e);return n}function Sr(e,n,t){e.pendingLanes|=n,n!==536870912&&(e.suspendedLanes=0,e.pingedLanes=0),e=e.eventTimes,n=31-nn(n),e[n]=t}function pf(e,n){var t=e.pendingLanes&~n;e.pendingLanes=n,e.suspendedLanes=0,e.pingedLanes=0,e.expiredLanes&=n,e.mutableReadLanes&=n,e.entangledLanes&=n,n=e.entanglements;var r=e.eventTimes;for(e=e.expirationTimes;0<t;){var i=31-nn(t),l=1<<i;n[i]=0,r[i]=-1,e[i]=-1,t&=~l}}function jo(e,n){var t=e.entangledLanes|=n;for(e=e.entanglements;t;){var r=31-nn(t),i=1<<r;i&n|e[r]&n&&(e[r]|=n),t&=~i}}var G=0;function Cu(e){return e&=-e,1<e?4<e?e&268435455?16:536870912:4:1}var Eu,Ro,$u,Pu,Nu,Hl=!1,zr=[],Nn=null,Tn=null,Fn=null,ar=new Map,sr=new Map,Cn=[],mf="mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(" ");function La(e,n){switch(e){case"focusin":case"focusout":Nn=null;break;case"dragenter":case"dragleave":Tn=null;break;case"mouseover":case"mouseout":Fn=null;break;case"pointerover":case"pointerout":ar.delete(n.pointerId);break;case"gotpointercapture":case"lostpointercapture":sr.delete(n.pointerId)}}function Mt(e,n,t,r,i,l){return e===null||e.nativeEvent!==l?(e={blockedOn:n,domEventName:t,eventSystemFlags:r,nativeEvent:l,targetContainers:[i]},n!==null&&(n=Cr(n),n!==null&&Ro(n)),e):(e.eventSystemFlags|=r,n=e.targetContainers,i!==null&&n.indexOf(i)===-1&&n.push(i),e)}function hf(e,n,t,r,i){switch(n){case"focusin":return Nn=Mt(Nn,e,n,t,r,i),!0;case"dragenter":return Tn=Mt(Tn,e,n,t,r,i),!0;case"mouseover":return Fn=Mt(Fn,e,n,t,r,i),!0;case"pointerover":var l=i.pointerId;return ar.set(l,Mt(ar.get(l)||null,e,n,t,r,i)),!0;case"gotpointercapture":return l=i.pointerId,sr.set(l,Mt(sr.get(l)||null,e,n,t,r,i)),!0}return!1}function Tu(e){var n=Vn(e.target);if(n!==null){var t=tt(n);if(t!==null){if(n=t.tag,n===13){if(n=yu(t),n!==null){e.blockedOn=n,Nu(e.priority,function(){$u(t)});return}}else if(n===3&&t.stateNode.current.memoizedState.isDehydrated){e.blockedOn=t.tag===3?t.stateNode.containerInfo:null;return}}}e.blockedOn=null}function Yr(e){if(e.blockedOn!==null)return!1;for(var n=e.targetContainers;0<n.length;){var t=Vl(e.domEventName,e.eventSystemFlags,n[0],e.nativeEvent);if(t===null){t=e.nativeEvent;var r=new t.constructor(t.type,t);Il=r,t.target.dispatchEvent(r),Il=null}else return n=Cr(t),n!==null&&Ro(n),e.blockedOn=t,!1;n.shift()}return!0}function Ma(e,n,t){Yr(e)&&t.delete(n)}function gf(){Hl=!1,Nn!==null&&Yr(Nn)&&(Nn=null),Tn!==null&&Yr(Tn)&&(Tn=null),Fn!==null&&Yr(Fn)&&(Fn=null),ar.forEach(Ma),sr.forEach(Ma)}function Dt(e,n){e.blockedOn===n&&(e.blockedOn=null,Hl||(Hl=!0,Ae.unstable_scheduleCallback(Ae.unstable_NormalPriority,gf)))}function ur(e){function n(i){return Dt(i,e)}if(0<zr.length){Dt(zr[0],e);for(var t=1;t<zr.length;t++){var r=zr[t];r.blockedOn===e&&(r.blockedOn=null)}}for(Nn!==null&&Dt(Nn,e),Tn!==null&&Dt(Tn,e),Fn!==null&&Dt(Fn,e),ar.forEach(n),sr.forEach(n),t=0;t<Cn.length;t++)r=Cn[t],r.blockedOn===e&&(r.blockedOn=null);for(;0<Cn.length&&(t=Cn[0],t.blockedOn===null);)Tu(t),t.blockedOn===null&&Cn.shift()}var kt=kn.ReactCurrentBatchConfig,di=!0;function vf(e,n,t,r){var i=G,l=kt.transition;kt.transition=null;try{G=1,zo(e,n,t,r)}finally{G=i,kt.transition=l}}function yf(e,n,t,r){var i=G,l=kt.transition;kt.transition=null;try{G=4,zo(e,n,t,r)}finally{G=i,kt.transition=l}}function zo(e,n,t,r){if(di){var i=Vl(e,n,t,r);if(i===null)dl(e,n,r,fi,t),La(e,r);else if(hf(i,e,n,t,r))r.stopPropagation();else if(La(e,r),n&4&&-1<mf.indexOf(e)){for(;i!==null;){var l=Cr(i);if(l!==null&&Eu(l),l=Vl(e,n,t,r),l===null&&dl(e,n,r,fi,t),l===i)break;i=l}i!==null&&r.stopPropagation()}else dl(e,n,r,null,t)}}var fi=null;function Vl(e,n,t,r){if(fi=null,e=To(r),e=Vn(e),e!==null)if(n=tt(e),n===null)e=null;else if(t=n.tag,t===13){if(e=yu(n),e!==null)return e;e=null}else if(t===3){if(n.stateNode.current.memoizedState.isDehydrated)return n.tag===3?n.stateNode.containerInfo:null;e=null}else n!==e&&(e=null);return fi=e,null}function Fu(e){switch(e){case"cancel":case"click":case"close":case"contextmenu":case"copy":case"cut":case"auxclick":case"dblclick":case"dragend":case"dragstart":case"drop":case"focusin":case"focusout":case"input":case"invalid":case"keydown":case"keypress":case"keyup":case"mousedown":case"mouseup":case"paste":case"pause":case"play":case"pointercancel":case"pointerdown":case"pointerup":case"ratechange":case"reset":case"resize":case"seeked":case"submit":case"touchcancel":case"touchend":case"touchstart":case"volumechange":case"change":case"selectionchange":case"textInput":case"compositionstart":case"compositionend":case"compositionupdate":case"beforeblur":case"afterblur":case"beforeinput":case"blur":case"fullscreenchange":case"focus":case"hashchange":case"popstate":case"select":case"selectstart":return 1;case"drag":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"mousemove":case"mouseout":case"mouseover":case"pointermove":case"pointerout":case"pointerover":case"scroll":case"toggle":case"touchmove":case"wheel":case"mouseenter":case"mouseleave":case"pointerenter":case"pointerleave":return 4;case"message":switch(lf()){case Fo:return 1;case _u:return 4;case ui:case of:return 16;case Su:return 536870912;default:return 16}default:return 16}}var $n=null,Lo=null,Xr=null;function ju(){if(Xr)return Xr;var e,n=Lo,t=n.length,r,i="value"in $n?$n.value:$n.textContent,l=i.length;for(e=0;e<t&&n[e]===i[e];e++);var o=t-e;for(r=1;r<=o&&n[t-r]===i[l-r];r++);return Xr=i.slice(e,1<r?1-r:void 0)}function Zr(e){var n=e.keyCode;return"charCode"in e?(e=e.charCode,e===0&&n===13&&(e=13)):e=n,e===10&&(e=13),32<=e||e===13?e:0}function Lr(){return!0}function Da(){return!1}function Be(e){function n(t,r,i,l,o){this._reactName=t,this._targetInst=i,this.type=r,this.nativeEvent=l,this.target=o,this.currentTarget=null;for(var a in e)e.hasOwnProperty(a)&&(t=e[a],this[a]=t?t(l):l[a]);return this.isDefaultPrevented=(l.defaultPrevented!=null?l.defaultPrevented:l.returnValue===!1)?Lr:Da,this.isPropagationStopped=Da,this}return ne(n.prototype,{preventDefault:function(){this.defaultPrevented=!0;var t=this.nativeEvent;t&&(t.preventDefault?t.preventDefault():typeof t.returnValue!="unknown"&&(t.returnValue=!1),this.isDefaultPrevented=Lr)},stopPropagation:function(){var t=this.nativeEvent;t&&(t.stopPropagation?t.stopPropagation():typeof t.cancelBubble!="unknown"&&(t.cancelBubble=!0),this.isPropagationStopped=Lr)},persist:function(){},isPersistent:Lr}),n}var jt={eventPhase:0,bubbles:0,cancelable:0,timeStamp:function(e){return e.timeStamp||Date.now()},defaultPrevented:0,isTrusted:0},Mo=Be(jt),br=ne({},jt,{view:0,detail:0}),xf=Be(br),tl,rl,Ot,Ri=ne({},br,{screenX:0,screenY:0,clientX:0,clientY:0,pageX:0,pageY:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,getModifierState:Do,button:0,buttons:0,relatedTarget:function(e){return e.relatedTarget===void 0?e.fromElement===e.srcElement?e.toElement:e.fromElement:e.relatedTarget},movementX:function(e){return"movementX"in e?e.movementX:(e!==Ot&&(Ot&&e.type==="mousemove"?(tl=e.screenX-Ot.screenX,rl=e.screenY-Ot.screenY):rl=tl=0,Ot=e),tl)},movementY:function(e){return"movementY"in e?e.movementY:rl}}),Oa=Be(Ri),wf=ne({},Ri,{dataTransfer:0}),kf=Be(wf),_f=ne({},br,{relatedTarget:0}),il=Be(_f),Sf=ne({},jt,{animationName:0,elapsedTime:0,pseudoElement:0}),bf=Be(Sf),Cf=ne({},jt,{clipboardData:function(e){return"clipboardData"in e?e.clipboardData:window.clipboardData}}),Ef=Be(Cf),$f=ne({},jt,{data:0}),Ia=Be($f),Pf={Esc:"Escape",Spacebar:" ",Left:"ArrowLeft",Up:"ArrowUp",Right:"ArrowRight",Down:"ArrowDown",Del:"Delete",Win:"OS",Menu:"ContextMenu",Apps:"ContextMenu",Scroll:"ScrollLock",MozPrintableKey:"Unidentified"},Nf={8:"Backspace",9:"Tab",12:"Clear",13:"Enter",16:"Shift",17:"Control",18:"Alt",19:"Pause",20:"CapsLock",27:"Escape",32:" ",33:"PageUp",34:"PageDown",35:"End",36:"Home",37:"ArrowLeft",38:"ArrowUp",39:"ArrowRight",40:"ArrowDown",45:"Insert",46:"Delete",112:"F1",113:"F2",114:"F3",115:"F4",116:"F5",117:"F6",118:"F7",119:"F8",120:"F9",121:"F10",122:"F11",123:"F12",144:"NumLock",145:"ScrollLock",224:"Meta"},Tf={Alt:"altKey",Control:"ctrlKey",Meta:"metaKey",Shift:"shiftKey"};function Ff(e){var n=this.nativeEvent;return n.getModifierState?n.getModifierState(e):(e=Tf[e])?!!n[e]:!1}function Do(){return Ff}var jf=ne({},br,{key:function(e){if(e.key){var n=Pf[e.key]||e.key;if(n!=="Unidentified")return n}return e.type==="keypress"?(e=Zr(e),e===13?"Enter":String.fromCharCode(e)):e.type==="keydown"||e.type==="keyup"?Nf[e.keyCode]||"Unidentified":""},code:0,location:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,repeat:0,locale:0,getModifierState:Do,charCode:function(e){return e.type==="keypress"?Zr(e):0},keyCode:function(e){return e.type==="keydown"||e.type==="keyup"?e.keyCode:0},which:function(e){return e.type==="keypress"?Zr(e):e.type==="keydown"||e.type==="keyup"?e.keyCode:0}}),Rf=Be(jf),zf=ne({},Ri,{pointerId:0,width:0,height:0,pressure:0,tangentialPressure:0,tiltX:0,tiltY:0,twist:0,pointerType:0,isPrimary:0}),Aa=Be(zf),Lf=ne({},br,{touches:0,targetTouches:0,changedTouches:0,altKey:0,metaKey:0,ctrlKey:0,shiftKey:0,getModifierState:Do}),Mf=Be(Lf),Df=ne({},jt,{propertyName:0,elapsedTime:0,pseudoElement:0}),Of=Be(Df),If=ne({},Ri,{deltaX:function(e){return"deltaX"in e?e.deltaX:"wheelDeltaX"in e?-e.wheelDeltaX:0},deltaY:function(e){return"deltaY"in e?e.deltaY:"wheelDeltaY"in e?-e.wheelDeltaY:"wheelDelta"in e?-e.wheelDelta:0},deltaZ:0,deltaMode:0}),Af=Be(If),Uf=[9,13,27,32],Oo=vn&&"CompositionEvent"in window,Yt=null;vn&&"documentMode"in document&&(Yt=document.documentMode);var Bf=vn&&"TextEvent"in window&&!Yt,Ru=vn&&(!Oo||Yt&&8<Yt&&11>=Yt),Ua=" ",Ba=!1;function zu(e,n){switch(e){case"keyup":return Uf.indexOf(n.keyCode)!==-1;case"keydown":return n.keyCode!==229;case"keypress":case"mousedown":case"focusout":return!0;default:return!1}}function Lu(e){return e=e.detail,typeof e=="object"&&"data"in e?e.data:null}var at=!1;function Wf(e,n){switch(e){case"compositionend":return Lu(n);case"keypress":return n.which!==32?null:(Ba=!0,Ua);case"textInput":return e=n.data,e===Ua&&Ba?null:e;default:return null}}function Hf(e,n){if(at)return e==="compositionend"||!Oo&&zu(e,n)?(e=ju(),Xr=Lo=$n=null,at=!1,e):null;switch(e){case"paste":return null;case"keypress":if(!(n.ctrlKey||n.altKey||n.metaKey)||n.ctrlKey&&n.altKey){if(n.char&&1<n.char.length)return n.char;if(n.which)return String.fromCharCode(n.which)}return null;case"compositionend":return Ru&&n.locale!=="ko"?null:n.data;default:return null}}var Vf={color:!0,date:!0,datetime:!0,"datetime-local":!0,email:!0,month:!0,number:!0,password:!0,range:!0,search:!0,tel:!0,text:!0,time:!0,url:!0,week:!0};function Wa(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n==="input"?!!Vf[e.type]:n==="textarea"}function Mu(e,n,t,r){pu(r),n=pi(n,"onChange"),0<n.length&&(t=new Mo("onChange","change",null,t,r),e.push({event:t,listeners:n}))}var Xt=null,cr=null;function Qf(e){Ku(e,0)}function zi(e){var n=ct(e);if(ou(n))return e}function Kf(e,n){if(e==="change")return n}var Du=!1;if(vn){var ll;if(vn){var ol="oninput"in document;if(!ol){var Ha=document.createElement("div");Ha.setAttribute("oninput","return;"),ol=typeof Ha.oninput=="function"}ll=ol}else ll=!1;Du=ll&&(!document.documentMode||9<document.documentMode)}function Va(){Xt&&(Xt.detachEvent("onpropertychange",Ou),cr=Xt=null)}function Ou(e){if(e.propertyName==="value"&&zi(cr)){var n=[];Mu(n,cr,e,To(e)),vu(Qf,n)}}function Gf(e,n,t){e==="focusin"?(Va(),Xt=n,cr=t,Xt.attachEvent("onpropertychange",Ou)):e==="focusout"&&Va()}function Yf(e){if(e==="selectionchange"||e==="keyup"||e==="keydown")return zi(cr)}function Xf(e,n){if(e==="click")return zi(n)}function Zf(e,n){if(e==="input"||e==="change")return zi(n)}function qf(e,n){return e===n&&(e!==0||1/e===1/n)||e!==e&&n!==n}var rn=typeof Object.is=="function"?Object.is:qf;function dr(e,n){if(rn(e,n))return!0;if(typeof e!="object"||e===null||typeof n!="object"||n===null)return!1;var t=Object.keys(e),r=Object.keys(n);if(t.length!==r.length)return!1;for(r=0;r<t.length;r++){var i=t[r];if(!$l.call(n,i)||!rn(e[i],n[i]))return!1}return!0}function Qa(e){for(;e&&e.firstChild;)e=e.firstChild;return e}function Ka(e,n){var t=Qa(e);e=0;for(var r;t;){if(t.nodeType===3){if(r=e+t.textContent.length,e<=n&&r>=n)return{node:t,offset:n-e};e=r}e:{for(;t;){if(t.nextSibling){t=t.nextSibling;break e}t=t.parentNode}t=void 0}t=Qa(t)}}function Iu(e,n){return e&&n?e===n?!0:e&&e.nodeType===3?!1:n&&n.nodeType===3?Iu(e,n.parentNode):"contains"in e?e.contains(n):e.compareDocumentPosition?!!(e.compareDocumentPosition(n)&16):!1:!1}function Au(){for(var e=window,n=oi();n instanceof e.HTMLIFrameElement;){try{var t=typeof n.contentWindow.location.href=="string"}catch{t=!1}if(t)e=n.contentWindow;else break;n=oi(e.document)}return n}function Io(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n&&(n==="input"&&(e.type==="text"||e.type==="search"||e.type==="tel"||e.type==="url"||e.type==="password")||n==="textarea"||e.contentEditable==="true")}function Jf(e){var n=Au(),t=e.focusedElem,r=e.selectionRange;if(n!==t&&t&&t.ownerDocument&&Iu(t.ownerDocument.documentElement,t)){if(r!==null&&Io(t)){if(n=r.start,e=r.end,e===void 0&&(e=n),"selectionStart"in t)t.selectionStart=n,t.selectionEnd=Math.min(e,t.value.length);else if(e=(n=t.ownerDocument||document)&&n.defaultView||window,e.getSelection){e=e.getSelection();var i=t.textContent.length,l=Math.min(r.start,i);r=r.end===void 0?l:Math.min(r.end,i),!e.extend&&l>r&&(i=r,r=l,l=i),i=Ka(t,l);var o=Ka(t,r);i&&o&&(e.rangeCount!==1||e.anchorNode!==i.node||e.anchorOffset!==i.offset||e.focusNode!==o.node||e.focusOffset!==o.offset)&&(n=n.createRange(),n.setStart(i.node,i.offset),e.removeAllRanges(),l>r?(e.addRange(n),e.extend(o.node,o.offset)):(n.setEnd(o.node,o.offset),e.addRange(n)))}}for(n=[],e=t;e=e.parentNode;)e.nodeType===1&&n.push({element:e,left:e.scrollLeft,top:e.scrollTop});for(typeof t.focus=="function"&&t.focus(),t=0;t<n.length;t++)e=n[t],e.element.scrollLeft=e.left,e.element.scrollTop=e.top}}var ep=vn&&"documentMode"in document&&11>=document.documentMode,st=null,Ql=null,Zt=null,Kl=!1;function Ga(e,n,t){var r=t.window===t?t.document:t.nodeType===9?t:t.ownerDocument;Kl||st==null||st!==oi(r)||(r=st,"selectionStart"in r&&Io(r)?r={start:r.selectionStart,end:r.selectionEnd}:(r=(r.ownerDocument&&r.ownerDocument.defaultView||window).getSelection(),r={anchorNode:r.anchorNode,anchorOffset:r.anchorOffset,focusNode:r.focusNode,focusOffset:r.focusOffset}),Zt&&dr(Zt,r)||(Zt=r,r=pi(Ql,"onSelect"),0<r.length&&(n=new Mo("onSelect","select",null,n,t),e.push({event:n,listeners:r}),n.target=st)))}function Mr(e,n){var t={};return t[e.toLowerCase()]=n.toLowerCase(),t["Webkit"+e]="webkit"+n,t["Moz"+e]="moz"+n,t}var ut={animationend:Mr("Animation","AnimationEnd"),animationiteration:Mr("Animation","AnimationIteration"),animationstart:Mr("Animation","AnimationStart"),transitionend:Mr("Transition","TransitionEnd")},al={},Uu={};vn&&(Uu=document.createElement("div").style,"AnimationEvent"in window||(delete ut.animationend.animation,delete ut.animationiteration.animation,delete ut.animationstart.animation),"TransitionEvent"in window||delete ut.transitionend.transition);function Li(e){if(al[e])return al[e];if(!ut[e])return e;var n=ut[e],t;for(t in n)if(n.hasOwnProperty(t)&&t in Uu)return al[e]=n[t];return e}var Bu=Li("animationend"),Wu=Li("animationiteration"),Hu=Li("animationstart"),Vu=Li("transitionend"),Qu=new Map,Ya="abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(" ");function An(e,n){Qu.set(e,n),nt(n,[e])}for(var sl=0;sl<Ya.length;sl++){var ul=Ya[sl],np=ul.toLowerCase(),tp=ul[0].toUpperCase()+ul.slice(1);An(np,"on"+tp)}An(Bu,"onAnimationEnd");An(Wu,"onAnimationIteration");An(Hu,"onAnimationStart");An("dblclick","onDoubleClick");An("focusin","onFocus");An("focusout","onBlur");An(Vu,"onTransitionEnd");bt("onMouseEnter",["mouseout","mouseover"]);bt("onMouseLeave",["mouseout","mouseover"]);bt("onPointerEnter",["pointerout","pointerover"]);bt("onPointerLeave",["pointerout","pointerover"]);nt("onChange","change click focusin focusout input keydown keyup selectionchange".split(" "));nt("onSelect","focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(" "));nt("onBeforeInput",["compositionend","keypress","textInput","paste"]);nt("onCompositionEnd","compositionend focusout keydown keypress keyup mousedown".split(" "));nt("onCompositionStart","compositionstart focusout keydown keypress keyup mousedown".split(" "));nt("onCompositionUpdate","compositionupdate focusout keydown keypress keyup mousedown".split(" "));var Vt="abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(" "),rp=new Set("cancel close invalid load scroll toggle".split(" ").concat(Vt));function Xa(e,n,t){var r=e.type||"unknown-event";e.currentTarget=t,ef(r,n,void 0,e),e.currentTarget=null}function Ku(e,n){n=(n&4)!==0;for(var t=0;t<e.length;t++){var r=e[t],i=r.event;r=r.listeners;e:{var l=void 0;if(n)for(var o=r.length-1;0<=o;o--){var a=r[o],s=a.instance,d=a.currentTarget;if(a=a.listener,s!==l&&i.isPropagationStopped())break e;Xa(i,a,d),l=s}else for(o=0;o<r.length;o++){if(a=r[o],s=a.instance,d=a.currentTarget,a=a.listener,s!==l&&i.isPropagationStopped())break e;Xa(i,a,d),l=s}}}if(si)throw e=Bl,si=!1,Bl=null,e}function X(e,n){var t=n[ql];t===void 0&&(t=n[ql]=new Set);var r=e+"__bubble";t.has(r)||(Gu(n,e,2,!1),t.add(r))}function cl(e,n,t){var r=0;n&&(r|=4),Gu(t,e,r,n)}var Dr="_reactListening"+Math.random().toString(36).slice(2);function fr(e){if(!e[Dr]){e[Dr]=!0,nu.forEach(function(t){t!=="selectionchange"&&(rp.has(t)||cl(t,!1,e),cl(t,!0,e))});var n=e.nodeType===9?e:e.ownerDocument;n===null||n[Dr]||(n[Dr]=!0,cl("selectionchange",!1,n))}}function Gu(e,n,t,r){switch(Fu(n)){case 1:var i=vf;break;case 4:i=yf;break;default:i=zo}t=i.bind(null,n,t,e),i=void 0,!Ul||n!=="touchstart"&&n!=="touchmove"&&n!=="wheel"||(i=!0),r?i!==void 0?e.addEventListener(n,t,{capture:!0,passive:i}):e.addEventListener(n,t,!0):i!==void 0?e.addEventListener(n,t,{passive:i}):e.addEventListener(n,t,!1)}function dl(e,n,t,r,i){var l=r;if(!(n&1)&&!(n&2)&&r!==null)e:for(;;){if(r===null)return;var o=r.tag;if(o===3||o===4){var a=r.stateNode.containerInfo;if(a===i||a.nodeType===8&&a.parentNode===i)break;if(o===4)for(o=r.return;o!==null;){var s=o.tag;if((s===3||s===4)&&(s=o.stateNode.containerInfo,s===i||s.nodeType===8&&s.parentNode===i))return;o=o.return}for(;a!==null;){if(o=Vn(a),o===null)return;if(s=o.tag,s===5||s===6){r=l=o;continue e}a=a.parentNode}}r=r.return}vu(function(){var d=l,x=To(t),h=[];e:{var p=Qu.get(e);if(p!==void 0){var g=Mo,k=e;switch(e){case"keypress":if(Zr(t)===0)break e;case"keydown":case"keyup":g=Rf;break;case"focusin":k="focus",g=il;break;case"focusout":k="blur",g=il;break;case"beforeblur":case"afterblur":g=il;break;case"click":if(t.button===2)break e;case"auxclick":case"dblclick":case"mousedown":case"mousemove":case"mouseup":case"mouseout":case"mouseover":case"contextmenu":g=Oa;break;case"drag":case"dragend":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"dragstart":case"drop":g=kf;break;case"touchcancel":case"touchend":case"touchmove":case"touchstart":g=Mf;break;case Bu:case Wu:case Hu:g=bf;break;case Vu:g=Of;break;case"scroll":g=xf;break;case"wheel":g=Af;break;case"copy":case"cut":case"paste":g=Ef;break;case"gotpointercapture":case"lostpointercapture":case"pointercancel":case"pointerdown":case"pointermove":case"pointerout":case"pointerover":case"pointerup":g=Aa}var _=(n&4)!==0,j=!_&&e==="scroll",c=_?p!==null?p+"Capture":null:p;_=[];for(var u=d,f;u!==null;){f=u;var y=f.stateNode;if(f.tag===5&&y!==null&&(f=y,c!==null&&(y=or(u,c),y!=null&&_.push(pr(u,y,f)))),j)break;u=u.return}0<_.length&&(p=new g(p,k,null,t,x),h.push({event:p,listeners:_}))}}if(!(n&7)){e:{if(p=e==="mouseover"||e==="pointerover",g=e==="mouseout"||e==="pointerout",p&&t!==Il&&(k=t.relatedTarget||t.fromElement)&&(Vn(k)||k[yn]))break e;if((g||p)&&(p=x.window===x?x:(p=x.ownerDocument)?p.defaultView||p.parentWindow:window,g?(k=t.relatedTarget||t.toElement,g=d,k=k?Vn(k):null,k!==null&&(j=tt(k),k!==j||k.tag!==5&&k.tag!==6)&&(k=null)):(g=null,k=d),g!==k)){if(_=Oa,y="onMouseLeave",c="onMouseEnter",u="mouse",(e==="pointerout"||e==="pointerover")&&(_=Aa,y="onPointerLeave",c="onPointerEnter",u="pointer"),j=g==null?p:ct(g),f=k==null?p:ct(k),p=new _(y,u+"leave",g,t,x),p.target=j,p.relatedTarget=f,y=null,Vn(x)===d&&(_=new _(c,u+"enter",k,t,x),_.target=f,_.relatedTarget=j,y=_),j=y,g&&k)n:{for(_=g,c=k,u=0,f=_;f;f=it(f))u++;for(f=0,y=c;y;y=it(y))f++;for(;0<u-f;)_=it(_),u--;for(;0<f-u;)c=it(c),f--;for(;u--;){if(_===c||c!==null&&_===c.alternate)break n;_=it(_),c=it(c)}_=null}else _=null;g!==null&&Za(h,p,g,_,!1),k!==null&&j!==null&&Za(h,j,k,_,!0)}}e:{if(p=d?ct(d):window,g=p.nodeName&&p.nodeName.toLowerCase(),g==="select"||g==="input"&&p.type==="file")var S=Kf;else if(Wa(p))if(Du)S=Zf;else{S=Yf;var m=Gf}else(g=p.nodeName)&&g.toLowerCase()==="input"&&(p.type==="checkbox"||p.type==="radio")&&(S=Xf);if(S&&(S=S(e,d))){Mu(h,S,t,x);break e}m&&m(e,p,d),e==="focusout"&&(m=p._wrapperState)&&m.controlled&&p.type==="number"&&zl(p,"number",p.value)}switch(m=d?ct(d):window,e){case"focusin":(Wa(m)||m.contentEditable==="true")&&(st=m,Ql=d,Zt=null);break;case"focusout":Zt=Ql=st=null;break;case"mousedown":Kl=!0;break;case"contextmenu":case"mouseup":case"dragend":Kl=!1,Ga(h,t,x);break;case"selectionchange":if(ep)break;case"keydown":case"keyup":Ga(h,t,x)}var E;if(Oo)e:{switch(e){case"compositionstart":var C="onCompositionStart";break e;case"compositionend":C="onCompositionEnd";break e;case"compositionupdate":C="onCompositionUpdate";break e}C=void 0}else at?zu(e,t)&&(C="onCompositionEnd"):e==="keydown"&&t.keyCode===229&&(C="onCompositionStart");C&&(Ru&&t.locale!=="ko"&&(at||C!=="onCompositionStart"?C==="onCompositionEnd"&&at&&(E=ju()):($n=x,Lo="value"in $n?$n.value:$n.textContent,at=!0)),m=pi(d,C),0<m.length&&(C=new Ia(C,e,null,t,x),h.push({event:C,listeners:m}),E?C.data=E:(E=Lu(t),E!==null&&(C.data=E)))),(E=Bf?Wf(e,t):Hf(e,t))&&(d=pi(d,"onBeforeInput"),0<d.length&&(x=new Ia("onBeforeInput","beforeinput",null,t,x),h.push({event:x,listeners:d}),x.data=E))}Ku(h,n)})}function pr(e,n,t){return{instance:e,listener:n,currentTarget:t}}function pi(e,n){for(var t=n+"Capture",r=[];e!==null;){var i=e,l=i.stateNode;i.tag===5&&l!==null&&(i=l,l=or(e,t),l!=null&&r.unshift(pr(e,l,i)),l=or(e,n),l!=null&&r.push(pr(e,l,i))),e=e.return}return r}function it(e){if(e===null)return null;do e=e.return;while(e&&e.tag!==5);return e||null}function Za(e,n,t,r,i){for(var l=n._reactName,o=[];t!==null&&t!==r;){var a=t,s=a.alternate,d=a.stateNode;if(s!==null&&s===r)break;a.tag===5&&d!==null&&(a=d,i?(s=or(t,l),s!=null&&o.unshift(pr(t,s,a))):i||(s=or(t,l),s!=null&&o.push(pr(t,s,a)))),t=t.return}o.length!==0&&e.push({event:n,listeners:o})}var ip=/\r\n?/g,lp=/\u0000|\uFFFD/g;function qa(e){return(typeof e=="string"?e:""+e).replace(ip,`
`).replace(lp,"")}function Or(e,n,t){if(n=qa(n),qa(e)!==n&&t)throw Error(b(425))}function mi(){}var Gl=null,Yl=null;function Xl(e,n){return e==="textarea"||e==="noscript"||typeof n.children=="string"||typeof n.children=="number"||typeof n.dangerouslySetInnerHTML=="object"&&n.dangerouslySetInnerHTML!==null&&n.dangerouslySetInnerHTML.__html!=null}var Zl=typeof setTimeout=="function"?setTimeout:void 0,op=typeof clearTimeout=="function"?clearTimeout:void 0,Ja=typeof Promise=="function"?Promise:void 0,ap=typeof queueMicrotask=="function"?queueMicrotask:typeof Ja<"u"?function(e){return Ja.resolve(null).then(e).catch(sp)}:Zl;function sp(e){setTimeout(function(){throw e})}function fl(e,n){var t=n,r=0;do{var i=t.nextSibling;if(e.removeChild(t),i&&i.nodeType===8)if(t=i.data,t==="/$"){if(r===0){e.removeChild(i),ur(n);return}r--}else t!=="$"&&t!=="$?"&&t!=="$!"||r++;t=i}while(t);ur(n)}function jn(e){for(;e!=null;e=e.nextSibling){var n=e.nodeType;if(n===1||n===3)break;if(n===8){if(n=e.data,n==="$"||n==="$!"||n==="$?")break;if(n==="/$")return null}}return e}function es(e){e=e.previousSibling;for(var n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="$"||t==="$!"||t==="$?"){if(n===0)return e;n--}else t==="/$"&&n++}e=e.previousSibling}return null}var Rt=Math.random().toString(36).slice(2),un="__reactFiber$"+Rt,mr="__reactProps$"+Rt,yn="__reactContainer$"+Rt,ql="__reactEvents$"+Rt,up="__reactListeners$"+Rt,cp="__reactHandles$"+Rt;function Vn(e){var n=e[un];if(n)return n;for(var t=e.parentNode;t;){if(n=t[yn]||t[un]){if(t=n.alternate,n.child!==null||t!==null&&t.child!==null)for(e=es(e);e!==null;){if(t=e[un])return t;e=es(e)}return n}e=t,t=e.parentNode}return null}function Cr(e){return e=e[un]||e[yn],!e||e.tag!==5&&e.tag!==6&&e.tag!==13&&e.tag!==3?null:e}function ct(e){if(e.tag===5||e.tag===6)return e.stateNode;throw Error(b(33))}function Mi(e){return e[mr]||null}var Jl=[],dt=-1;function Un(e){return{current:e}}function Z(e){0>dt||(e.current=Jl[dt],Jl[dt]=null,dt--)}function Y(e,n){dt++,Jl[dt]=e.current,e.current=n}var In={},Se=Un(In),je=Un(!1),Xn=In;function Ct(e,n){var t=e.type.contextTypes;if(!t)return In;var r=e.stateNode;if(r&&r.__reactInternalMemoizedUnmaskedChildContext===n)return r.__reactInternalMemoizedMaskedChildContext;var i={},l;for(l in t)i[l]=n[l];return r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=n,e.__reactInternalMemoizedMaskedChildContext=i),i}function Re(e){return e=e.childContextTypes,e!=null}function hi(){Z(je),Z(Se)}function ns(e,n,t){if(Se.current!==In)throw Error(b(168));Y(Se,n),Y(je,t)}function Yu(e,n,t){var r=e.stateNode;if(n=n.childContextTypes,typeof r.getChildContext!="function")return t;r=r.getChildContext();for(var i in r)if(!(i in n))throw Error(b(108,Kd(e)||"Unknown",i));return ne({},t,r)}function gi(e){return e=(e=e.stateNode)&&e.__reactInternalMemoizedMergedChildContext||In,Xn=Se.current,Y(Se,e),Y(je,je.current),!0}function ts(e,n,t){var r=e.stateNode;if(!r)throw Error(b(169));t?(e=Yu(e,n,Xn),r.__reactInternalMemoizedMergedChildContext=e,Z(je),Z(Se),Y(Se,e)):Z(je),Y(je,t)}var pn=null,Di=!1,pl=!1;function Xu(e){pn===null?pn=[e]:pn.push(e)}function dp(e){Di=!0,Xu(e)}function Bn(){if(!pl&&pn!==null){pl=!0;var e=0,n=G;try{var t=pn;for(G=1;e<t.length;e++){var r=t[e];do r=r(!0);while(r!==null)}pn=null,Di=!1}catch(i){throw pn!==null&&(pn=pn.slice(e+1)),ku(Fo,Bn),i}finally{G=n,pl=!1}}return null}var ft=[],pt=0,vi=null,yi=0,Ve=[],Qe=0,Zn=null,mn=1,hn="";function Wn(e,n){ft[pt++]=yi,ft[pt++]=vi,vi=e,yi=n}function Zu(e,n,t){Ve[Qe++]=mn,Ve[Qe++]=hn,Ve[Qe++]=Zn,Zn=e;var r=mn;e=hn;var i=32-nn(r)-1;r&=~(1<<i),t+=1;var l=32-nn(n)+i;if(30<l){var o=i-i%5;l=(r&(1<<o)-1).toString(32),r>>=o,i-=o,mn=1<<32-nn(n)+i|t<<i|r,hn=l+e}else mn=1<<l|t<<i|r,hn=e}function Ao(e){e.return!==null&&(Wn(e,1),Zu(e,1,0))}function Uo(e){for(;e===vi;)vi=ft[--pt],ft[pt]=null,yi=ft[--pt],ft[pt]=null;for(;e===Zn;)Zn=Ve[--Qe],Ve[Qe]=null,hn=Ve[--Qe],Ve[Qe]=null,mn=Ve[--Qe],Ve[Qe]=null}var Ie=null,Oe=null,q=!1,en=null;function qu(e,n){var t=Ke(5,null,null,0);t.elementType="DELETED",t.stateNode=n,t.return=e,n=e.deletions,n===null?(e.deletions=[t],e.flags|=16):n.push(t)}function rs(e,n){switch(e.tag){case 5:var t=e.type;return n=n.nodeType!==1||t.toLowerCase()!==n.nodeName.toLowerCase()?null:n,n!==null?(e.stateNode=n,Ie=e,Oe=jn(n.firstChild),!0):!1;case 6:return n=e.pendingProps===""||n.nodeType!==3?null:n,n!==null?(e.stateNode=n,Ie=e,Oe=null,!0):!1;case 13:return n=n.nodeType!==8?null:n,n!==null?(t=Zn!==null?{id:mn,overflow:hn}:null,e.memoizedState={dehydrated:n,treeContext:t,retryLane:1073741824},t=Ke(18,null,null,0),t.stateNode=n,t.return=e,e.child=t,Ie=e,Oe=null,!0):!1;default:return!1}}function eo(e){return(e.mode&1)!==0&&(e.flags&128)===0}function no(e){if(q){var n=Oe;if(n){var t=n;if(!rs(e,n)){if(eo(e))throw Error(b(418));n=jn(t.nextSibling);var r=Ie;n&&rs(e,n)?qu(r,t):(e.flags=e.flags&-4097|2,q=!1,Ie=e)}}else{if(eo(e))throw Error(b(418));e.flags=e.flags&-4097|2,q=!1,Ie=e}}}function is(e){for(e=e.return;e!==null&&e.tag!==5&&e.tag!==3&&e.tag!==13;)e=e.return;Ie=e}function Ir(e){if(e!==Ie)return!1;if(!q)return is(e),q=!0,!1;var n;if((n=e.tag!==3)&&!(n=e.tag!==5)&&(n=e.type,n=n!=="head"&&n!=="body"&&!Xl(e.type,e.memoizedProps)),n&&(n=Oe)){if(eo(e))throw Ju(),Error(b(418));for(;n;)qu(e,n),n=jn(n.nextSibling)}if(is(e),e.tag===13){if(e=e.memoizedState,e=e!==null?e.dehydrated:null,!e)throw Error(b(317));e:{for(e=e.nextSibling,n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="/$"){if(n===0){Oe=jn(e.nextSibling);break e}n--}else t!=="$"&&t!=="$!"&&t!=="$?"||n++}e=e.nextSibling}Oe=null}}else Oe=Ie?jn(e.stateNode.nextSibling):null;return!0}function Ju(){for(var e=Oe;e;)e=jn(e.nextSibling)}function Et(){Oe=Ie=null,q=!1}function Bo(e){en===null?en=[e]:en.push(e)}var fp=kn.ReactCurrentBatchConfig;function It(e,n,t){if(e=t.ref,e!==null&&typeof e!="function"&&typeof e!="object"){if(t._owner){if(t=t._owner,t){if(t.tag!==1)throw Error(b(309));var r=t.stateNode}if(!r)throw Error(b(147,e));var i=r,l=""+e;return n!==null&&n.ref!==null&&typeof n.ref=="function"&&n.ref._stringRef===l?n.ref:(n=function(o){var a=i.refs;o===null?delete a[l]:a[l]=o},n._stringRef=l,n)}if(typeof e!="string")throw Error(b(284));if(!t._owner)throw Error(b(290,e))}return e}function Ar(e,n){throw e=Object.prototype.toString.call(n),Error(b(31,e==="[object Object]"?"object with keys {"+Object.keys(n).join(", ")+"}":e))}function ls(e){var n=e._init;return n(e._payload)}function ec(e){function n(c,u){if(e){var f=c.deletions;f===null?(c.deletions=[u],c.flags|=16):f.push(u)}}function t(c,u){if(!e)return null;for(;u!==null;)n(c,u),u=u.sibling;return null}function r(c,u){for(c=new Map;u!==null;)u.key!==null?c.set(u.key,u):c.set(u.index,u),u=u.sibling;return c}function i(c,u){return c=Mn(c,u),c.index=0,c.sibling=null,c}function l(c,u,f){return c.index=f,e?(f=c.alternate,f!==null?(f=f.index,f<u?(c.flags|=2,u):f):(c.flags|=2,u)):(c.flags|=1048576,u)}function o(c){return e&&c.alternate===null&&(c.flags|=2),c}function a(c,u,f,y){return u===null||u.tag!==6?(u=wl(f,c.mode,y),u.return=c,u):(u=i(u,f),u.return=c,u)}function s(c,u,f,y){var S=f.type;return S===ot?x(c,u,f.props.children,y,f.key):u!==null&&(u.elementType===S||typeof S=="object"&&S!==null&&S.$$typeof===Sn&&ls(S)===u.type)?(y=i(u,f.props),y.ref=It(c,u,f),y.return=c,y):(y=ii(f.type,f.key,f.props,null,c.mode,y),y.ref=It(c,u,f),y.return=c,y)}function d(c,u,f,y){return u===null||u.tag!==4||u.stateNode.containerInfo!==f.containerInfo||u.stateNode.implementation!==f.implementation?(u=kl(f,c.mode,y),u.return=c,u):(u=i(u,f.children||[]),u.return=c,u)}function x(c,u,f,y,S){return u===null||u.tag!==7?(u=Yn(f,c.mode,y,S),u.return=c,u):(u=i(u,f),u.return=c,u)}function h(c,u,f){if(typeof u=="string"&&u!==""||typeof u=="number")return u=wl(""+u,c.mode,f),u.return=c,u;if(typeof u=="object"&&u!==null){switch(u.$$typeof){case Nr:return f=ii(u.type,u.key,u.props,null,c.mode,f),f.ref=It(c,null,u),f.return=c,f;case lt:return u=kl(u,c.mode,f),u.return=c,u;case Sn:var y=u._init;return h(c,y(u._payload),f)}if(Wt(u)||zt(u))return u=Yn(u,c.mode,f,null),u.return=c,u;Ar(c,u)}return null}function p(c,u,f,y){var S=u!==null?u.key:null;if(typeof f=="string"&&f!==""||typeof f=="number")return S!==null?null:a(c,u,""+f,y);if(typeof f=="object"&&f!==null){switch(f.$$typeof){case Nr:return f.key===S?s(c,u,f,y):null;case lt:return f.key===S?d(c,u,f,y):null;case Sn:return S=f._init,p(c,u,S(f._payload),y)}if(Wt(f)||zt(f))return S!==null?null:x(c,u,f,y,null);Ar(c,f)}return null}function g(c,u,f,y,S){if(typeof y=="string"&&y!==""||typeof y=="number")return c=c.get(f)||null,a(u,c,""+y,S);if(typeof y=="object"&&y!==null){switch(y.$$typeof){case Nr:return c=c.get(y.key===null?f:y.key)||null,s(u,c,y,S);case lt:return c=c.get(y.key===null?f:y.key)||null,d(u,c,y,S);case Sn:var m=y._init;return g(c,u,f,m(y._payload),S)}if(Wt(y)||zt(y))return c=c.get(f)||null,x(u,c,y,S,null);Ar(u,y)}return null}function k(c,u,f,y){for(var S=null,m=null,E=u,C=u=0,O=null;E!==null&&C<f.length;C++){E.index>C?(O=E,E=null):O=E.sibling;var T=p(c,E,f[C],y);if(T===null){E===null&&(E=O);break}e&&E&&T.alternate===null&&n(c,E),u=l(T,u,C),m===null?S=T:m.sibling=T,m=T,E=O}if(C===f.length)return t(c,E),q&&Wn(c,C),S;if(E===null){for(;C<f.length;C++)E=h(c,f[C],y),E!==null&&(u=l(E,u,C),m===null?S=E:m.sibling=E,m=E);return q&&Wn(c,C),S}for(E=r(c,E);C<f.length;C++)O=g(E,c,C,f[C],y),O!==null&&(e&&O.alternate!==null&&E.delete(O.key===null?C:O.key),u=l(O,u,C),m===null?S=O:m.sibling=O,m=O);return e&&E.forEach(function(te){return n(c,te)}),q&&Wn(c,C),S}function _(c,u,f,y){var S=zt(f);if(typeof S!="function")throw Error(b(150));if(f=S.call(f),f==null)throw Error(b(151));for(var m=S=null,E=u,C=u=0,O=null,T=f.next();E!==null&&!T.done;C++,T=f.next()){E.index>C?(O=E,E=null):O=E.sibling;var te=p(c,E,T.value,y);if(te===null){E===null&&(E=O);break}e&&E&&te.alternate===null&&n(c,E),u=l(te,u,C),m===null?S=te:m.sibling=te,m=te,E=O}if(T.done)return t(c,E),q&&Wn(c,C),S;if(E===null){for(;!T.done;C++,T=f.next())T=h(c,T.value,y),T!==null&&(u=l(T,u,C),m===null?S=T:m.sibling=T,m=T);return q&&Wn(c,C),S}for(E=r(c,E);!T.done;C++,T=f.next())T=g(E,c,C,T.value,y),T!==null&&(e&&T.alternate!==null&&E.delete(T.key===null?C:T.key),u=l(T,u,C),m===null?S=T:m.sibling=T,m=T);return e&&E.forEach(function(We){return n(c,We)}),q&&Wn(c,C),S}function j(c,u,f,y){if(typeof f=="object"&&f!==null&&f.type===ot&&f.key===null&&(f=f.props.children),typeof f=="object"&&f!==null){switch(f.$$typeof){case Nr:e:{for(var S=f.key,m=u;m!==null;){if(m.key===S){if(S=f.type,S===ot){if(m.tag===7){t(c,m.sibling),u=i(m,f.props.children),u.return=c,c=u;break e}}else if(m.elementType===S||typeof S=="object"&&S!==null&&S.$$typeof===Sn&&ls(S)===m.type){t(c,m.sibling),u=i(m,f.props),u.ref=It(c,m,f),u.return=c,c=u;break e}t(c,m);break}else n(c,m);m=m.sibling}f.type===ot?(u=Yn(f.props.children,c.mode,y,f.key),u.return=c,c=u):(y=ii(f.type,f.key,f.props,null,c.mode,y),y.ref=It(c,u,f),y.return=c,c=y)}return o(c);case lt:e:{for(m=f.key;u!==null;){if(u.key===m)if(u.tag===4&&u.stateNode.containerInfo===f.containerInfo&&u.stateNode.implementation===f.implementation){t(c,u.sibling),u=i(u,f.children||[]),u.return=c,c=u;break e}else{t(c,u);break}else n(c,u);u=u.sibling}u=kl(f,c.mode,y),u.return=c,c=u}return o(c);case Sn:return m=f._init,j(c,u,m(f._payload),y)}if(Wt(f))return k(c,u,f,y);if(zt(f))return _(c,u,f,y);Ar(c,f)}return typeof f=="string"&&f!==""||typeof f=="number"?(f=""+f,u!==null&&u.tag===6?(t(c,u.sibling),u=i(u,f),u.return=c,c=u):(t(c,u),u=wl(f,c.mode,y),u.return=c,c=u),o(c)):t(c,u)}return j}var $t=ec(!0),nc=ec(!1),xi=Un(null),wi=null,mt=null,Wo=null;function Ho(){Wo=mt=wi=null}function Vo(e){var n=xi.current;Z(xi),e._currentValue=n}function to(e,n,t){for(;e!==null;){var r=e.alternate;if((e.childLanes&n)!==n?(e.childLanes|=n,r!==null&&(r.childLanes|=n)):r!==null&&(r.childLanes&n)!==n&&(r.childLanes|=n),e===t)break;e=e.return}}function _t(e,n){wi=e,Wo=mt=null,e=e.dependencies,e!==null&&e.firstContext!==null&&(e.lanes&n&&(Fe=!0),e.firstContext=null)}function Ye(e){var n=e._currentValue;if(Wo!==e)if(e={context:e,memoizedValue:n,next:null},mt===null){if(wi===null)throw Error(b(308));mt=e,wi.dependencies={lanes:0,firstContext:e}}else mt=mt.next=e;return n}var Qn=null;function Qo(e){Qn===null?Qn=[e]:Qn.push(e)}function tc(e,n,t,r){var i=n.interleaved;return i===null?(t.next=t,Qo(n)):(t.next=i.next,i.next=t),n.interleaved=t,xn(e,r)}function xn(e,n){e.lanes|=n;var t=e.alternate;for(t!==null&&(t.lanes|=n),t=e,e=e.return;e!==null;)e.childLanes|=n,t=e.alternate,t!==null&&(t.childLanes|=n),t=e,e=e.return;return t.tag===3?t.stateNode:null}var bn=!1;function Ko(e){e.updateQueue={baseState:e.memoizedState,firstBaseUpdate:null,lastBaseUpdate:null,shared:{pending:null,interleaved:null,lanes:0},effects:null}}function rc(e,n){e=e.updateQueue,n.updateQueue===e&&(n.updateQueue={baseState:e.baseState,firstBaseUpdate:e.firstBaseUpdate,lastBaseUpdate:e.lastBaseUpdate,shared:e.shared,effects:e.effects})}function gn(e,n){return{eventTime:e,lane:n,tag:0,payload:null,callback:null,next:null}}function Rn(e,n,t){var r=e.updateQueue;if(r===null)return null;if(r=r.shared,Q&2){var i=r.pending;return i===null?n.next=n:(n.next=i.next,i.next=n),r.pending=n,xn(e,t)}return i=r.interleaved,i===null?(n.next=n,Qo(r)):(n.next=i.next,i.next=n),r.interleaved=n,xn(e,t)}function qr(e,n,t){if(n=n.updateQueue,n!==null&&(n=n.shared,(t&4194240)!==0)){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,jo(e,t)}}function os(e,n){var t=e.updateQueue,r=e.alternate;if(r!==null&&(r=r.updateQueue,t===r)){var i=null,l=null;if(t=t.firstBaseUpdate,t!==null){do{var o={eventTime:t.eventTime,lane:t.lane,tag:t.tag,payload:t.payload,callback:t.callback,next:null};l===null?i=l=o:l=l.next=o,t=t.next}while(t!==null);l===null?i=l=n:l=l.next=n}else i=l=n;t={baseState:r.baseState,firstBaseUpdate:i,lastBaseUpdate:l,shared:r.shared,effects:r.effects},e.updateQueue=t;return}e=t.lastBaseUpdate,e===null?t.firstBaseUpdate=n:e.next=n,t.lastBaseUpdate=n}function ki(e,n,t,r){var i=e.updateQueue;bn=!1;var l=i.firstBaseUpdate,o=i.lastBaseUpdate,a=i.shared.pending;if(a!==null){i.shared.pending=null;var s=a,d=s.next;s.next=null,o===null?l=d:o.next=d,o=s;var x=e.alternate;x!==null&&(x=x.updateQueue,a=x.lastBaseUpdate,a!==o&&(a===null?x.firstBaseUpdate=d:a.next=d,x.lastBaseUpdate=s))}if(l!==null){var h=i.baseState;o=0,x=d=s=null,a=l;do{var p=a.lane,g=a.eventTime;if((r&p)===p){x!==null&&(x=x.next={eventTime:g,lane:0,tag:a.tag,payload:a.payload,callback:a.callback,next:null});e:{var k=e,_=a;switch(p=n,g=t,_.tag){case 1:if(k=_.payload,typeof k=="function"){h=k.call(g,h,p);break e}h=k;break e;case 3:k.flags=k.flags&-65537|128;case 0:if(k=_.payload,p=typeof k=="function"?k.call(g,h,p):k,p==null)break e;h=ne({},h,p);break e;case 2:bn=!0}}a.callback!==null&&a.lane!==0&&(e.flags|=64,p=i.effects,p===null?i.effects=[a]:p.push(a))}else g={eventTime:g,lane:p,tag:a.tag,payload:a.payload,callback:a.callback,next:null},x===null?(d=x=g,s=h):x=x.next=g,o|=p;if(a=a.next,a===null){if(a=i.shared.pending,a===null)break;p=a,a=p.next,p.next=null,i.lastBaseUpdate=p,i.shared.pending=null}}while(!0);if(x===null&&(s=h),i.baseState=s,i.firstBaseUpdate=d,i.lastBaseUpdate=x,n=i.shared.interleaved,n!==null){i=n;do o|=i.lane,i=i.next;while(i!==n)}else l===null&&(i.shared.lanes=0);Jn|=o,e.lanes=o,e.memoizedState=h}}function as(e,n,t){if(e=n.effects,n.effects=null,e!==null)for(n=0;n<e.length;n++){var r=e[n],i=r.callback;if(i!==null){if(r.callback=null,r=t,typeof i!="function")throw Error(b(191,i));i.call(r)}}}var Er={},dn=Un(Er),hr=Un(Er),gr=Un(Er);function Kn(e){if(e===Er)throw Error(b(174));return e}function Go(e,n){switch(Y(gr,n),Y(hr,e),Y(dn,Er),e=n.nodeType,e){case 9:case 11:n=(n=n.documentElement)?n.namespaceURI:Ml(null,"");break;default:e=e===8?n.parentNode:n,n=e.namespaceURI||null,e=e.tagName,n=Ml(n,e)}Z(dn),Y(dn,n)}function Pt(){Z(dn),Z(hr),Z(gr)}function ic(e){Kn(gr.current);var n=Kn(dn.current),t=Ml(n,e.type);n!==t&&(Y(hr,e),Y(dn,t))}function Yo(e){hr.current===e&&(Z(dn),Z(hr))}var J=Un(0);function _i(e){for(var n=e;n!==null;){if(n.tag===13){var t=n.memoizedState;if(t!==null&&(t=t.dehydrated,t===null||t.data==="$?"||t.data==="$!"))return n}else if(n.tag===19&&n.memoizedProps.revealOrder!==void 0){if(n.flags&128)return n}else if(n.child!==null){n.child.return=n,n=n.child;continue}if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return null;n=n.return}n.sibling.return=n.return,n=n.sibling}return null}var ml=[];function Xo(){for(var e=0;e<ml.length;e++)ml[e]._workInProgressVersionPrimary=null;ml.length=0}var Jr=kn.ReactCurrentDispatcher,hl=kn.ReactCurrentBatchConfig,qn=0,ee=null,se=null,fe=null,Si=!1,qt=!1,vr=0,pp=0;function we(){throw Error(b(321))}function Zo(e,n){if(n===null)return!1;for(var t=0;t<n.length&&t<e.length;t++)if(!rn(e[t],n[t]))return!1;return!0}function qo(e,n,t,r,i,l){if(qn=l,ee=n,n.memoizedState=null,n.updateQueue=null,n.lanes=0,Jr.current=e===null||e.memoizedState===null?vp:yp,e=t(r,i),qt){l=0;do{if(qt=!1,vr=0,25<=l)throw Error(b(301));l+=1,fe=se=null,n.updateQueue=null,Jr.current=xp,e=t(r,i)}while(qt)}if(Jr.current=bi,n=se!==null&&se.next!==null,qn=0,fe=se=ee=null,Si=!1,n)throw Error(b(300));return e}function Jo(){var e=vr!==0;return vr=0,e}function sn(){var e={memoizedState:null,baseState:null,baseQueue:null,queue:null,next:null};return fe===null?ee.memoizedState=fe=e:fe=fe.next=e,fe}function Xe(){if(se===null){var e=ee.alternate;e=e!==null?e.memoizedState:null}else e=se.next;var n=fe===null?ee.memoizedState:fe.next;if(n!==null)fe=n,se=e;else{if(e===null)throw Error(b(310));se=e,e={memoizedState:se.memoizedState,baseState:se.baseState,baseQueue:se.baseQueue,queue:se.queue,next:null},fe===null?ee.memoizedState=fe=e:fe=fe.next=e}return fe}function yr(e,n){return typeof n=="function"?n(e):n}function gl(e){var n=Xe(),t=n.queue;if(t===null)throw Error(b(311));t.lastRenderedReducer=e;var r=se,i=r.baseQueue,l=t.pending;if(l!==null){if(i!==null){var o=i.next;i.next=l.next,l.next=o}r.baseQueue=i=l,t.pending=null}if(i!==null){l=i.next,r=r.baseState;var a=o=null,s=null,d=l;do{var x=d.lane;if((qn&x)===x)s!==null&&(s=s.next={lane:0,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null}),r=d.hasEagerState?d.eagerState:e(r,d.action);else{var h={lane:x,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null};s===null?(a=s=h,o=r):s=s.next=h,ee.lanes|=x,Jn|=x}d=d.next}while(d!==null&&d!==l);s===null?o=r:s.next=a,rn(r,n.memoizedState)||(Fe=!0),n.memoizedState=r,n.baseState=o,n.baseQueue=s,t.lastRenderedState=r}if(e=t.interleaved,e!==null){i=e;do l=i.lane,ee.lanes|=l,Jn|=l,i=i.next;while(i!==e)}else i===null&&(t.lanes=0);return[n.memoizedState,t.dispatch]}function vl(e){var n=Xe(),t=n.queue;if(t===null)throw Error(b(311));t.lastRenderedReducer=e;var r=t.dispatch,i=t.pending,l=n.memoizedState;if(i!==null){t.pending=null;var o=i=i.next;do l=e(l,o.action),o=o.next;while(o!==i);rn(l,n.memoizedState)||(Fe=!0),n.memoizedState=l,n.baseQueue===null&&(n.baseState=l),t.lastRenderedState=l}return[l,r]}function lc(){}function oc(e,n){var t=ee,r=Xe(),i=n(),l=!rn(r.memoizedState,i);if(l&&(r.memoizedState=i,Fe=!0),r=r.queue,ea(uc.bind(null,t,r,e),[e]),r.getSnapshot!==n||l||fe!==null&&fe.memoizedState.tag&1){if(t.flags|=2048,xr(9,sc.bind(null,t,r,i,n),void 0,null),pe===null)throw Error(b(349));qn&30||ac(t,n,i)}return i}function ac(e,n,t){e.flags|=16384,e={getSnapshot:n,value:t},n=ee.updateQueue,n===null?(n={lastEffect:null,stores:null},ee.updateQueue=n,n.stores=[e]):(t=n.stores,t===null?n.stores=[e]:t.push(e))}function sc(e,n,t,r){n.value=t,n.getSnapshot=r,cc(n)&&dc(e)}function uc(e,n,t){return t(function(){cc(n)&&dc(e)})}function cc(e){var n=e.getSnapshot;e=e.value;try{var t=n();return!rn(e,t)}catch{return!0}}function dc(e){var n=xn(e,1);n!==null&&tn(n,e,1,-1)}function ss(e){var n=sn();return typeof e=="function"&&(e=e()),n.memoizedState=n.baseState=e,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:yr,lastRenderedState:e},n.queue=e,e=e.dispatch=gp.bind(null,ee,e),[n.memoizedState,e]}function xr(e,n,t,r){return e={tag:e,create:n,destroy:t,deps:r,next:null},n=ee.updateQueue,n===null?(n={lastEffect:null,stores:null},ee.updateQueue=n,n.lastEffect=e.next=e):(t=n.lastEffect,t===null?n.lastEffect=e.next=e:(r=t.next,t.next=e,e.next=r,n.lastEffect=e)),e}function fc(){return Xe().memoizedState}function ei(e,n,t,r){var i=sn();ee.flags|=e,i.memoizedState=xr(1|n,t,void 0,r===void 0?null:r)}function Oi(e,n,t,r){var i=Xe();r=r===void 0?null:r;var l=void 0;if(se!==null){var o=se.memoizedState;if(l=o.destroy,r!==null&&Zo(r,o.deps)){i.memoizedState=xr(n,t,l,r);return}}ee.flags|=e,i.memoizedState=xr(1|n,t,l,r)}function us(e,n){return ei(8390656,8,e,n)}function ea(e,n){return Oi(2048,8,e,n)}function pc(e,n){return Oi(4,2,e,n)}function mc(e,n){return Oi(4,4,e,n)}function hc(e,n){if(typeof n=="function")return e=e(),n(e),function(){n(null)};if(n!=null)return e=e(),n.current=e,function(){n.current=null}}function gc(e,n,t){return t=t!=null?t.concat([e]):null,Oi(4,4,hc.bind(null,n,e),t)}function na(){}function vc(e,n){var t=Xe();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Zo(n,r[1])?r[0]:(t.memoizedState=[e,n],e)}function yc(e,n){var t=Xe();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Zo(n,r[1])?r[0]:(e=e(),t.memoizedState=[e,n],e)}function xc(e,n,t){return qn&21?(rn(t,n)||(t=bu(),ee.lanes|=t,Jn|=t,e.baseState=!0),n):(e.baseState&&(e.baseState=!1,Fe=!0),e.memoizedState=t)}function mp(e,n){var t=G;G=t!==0&&4>t?t:4,e(!0);var r=hl.transition;hl.transition={};try{e(!1),n()}finally{G=t,hl.transition=r}}function wc(){return Xe().memoizedState}function hp(e,n,t){var r=Ln(e);if(t={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null},kc(e))_c(n,t);else if(t=tc(e,n,t,r),t!==null){var i=$e();tn(t,e,r,i),Sc(t,n,r)}}function gp(e,n,t){var r=Ln(e),i={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null};if(kc(e))_c(n,i);else{var l=e.alternate;if(e.lanes===0&&(l===null||l.lanes===0)&&(l=n.lastRenderedReducer,l!==null))try{var o=n.lastRenderedState,a=l(o,t);if(i.hasEagerState=!0,i.eagerState=a,rn(a,o)){var s=n.interleaved;s===null?(i.next=i,Qo(n)):(i.next=s.next,s.next=i),n.interleaved=i;return}}catch{}finally{}t=tc(e,n,i,r),t!==null&&(i=$e(),tn(t,e,r,i),Sc(t,n,r))}}function kc(e){var n=e.alternate;return e===ee||n!==null&&n===ee}function _c(e,n){qt=Si=!0;var t=e.pending;t===null?n.next=n:(n.next=t.next,t.next=n),e.pending=n}function Sc(e,n,t){if(t&4194240){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,jo(e,t)}}var bi={readContext:Ye,useCallback:we,useContext:we,useEffect:we,useImperativeHandle:we,useInsertionEffect:we,useLayoutEffect:we,useMemo:we,useReducer:we,useRef:we,useState:we,useDebugValue:we,useDeferredValue:we,useTransition:we,useMutableSource:we,useSyncExternalStore:we,useId:we,unstable_isNewReconciler:!1},vp={readContext:Ye,useCallback:function(e,n){return sn().memoizedState=[e,n===void 0?null:n],e},useContext:Ye,useEffect:us,useImperativeHandle:function(e,n,t){return t=t!=null?t.concat([e]):null,ei(4194308,4,hc.bind(null,n,e),t)},useLayoutEffect:function(e,n){return ei(4194308,4,e,n)},useInsertionEffect:function(e,n){return ei(4,2,e,n)},useMemo:function(e,n){var t=sn();return n=n===void 0?null:n,e=e(),t.memoizedState=[e,n],e},useReducer:function(e,n,t){var r=sn();return n=t!==void 0?t(n):n,r.memoizedState=r.baseState=n,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:e,lastRenderedState:n},r.queue=e,e=e.dispatch=hp.bind(null,ee,e),[r.memoizedState,e]},useRef:function(e){var n=sn();return e={current:e},n.memoizedState=e},useState:ss,useDebugValue:na,useDeferredValue:function(e){return sn().memoizedState=e},useTransition:function(){var e=ss(!1),n=e[0];return e=mp.bind(null,e[1]),sn().memoizedState=e,[n,e]},useMutableSource:function(){},useSyncExternalStore:function(e,n,t){var r=ee,i=sn();if(q){if(t===void 0)throw Error(b(407));t=t()}else{if(t=n(),pe===null)throw Error(b(349));qn&30||ac(r,n,t)}i.memoizedState=t;var l={value:t,getSnapshot:n};return i.queue=l,us(uc.bind(null,r,l,e),[e]),r.flags|=2048,xr(9,sc.bind(null,r,l,t,n),void 0,null),t},useId:function(){var e=sn(),n=pe.identifierPrefix;if(q){var t=hn,r=mn;t=(r&~(1<<32-nn(r)-1)).toString(32)+t,n=":"+n+"R"+t,t=vr++,0<t&&(n+="H"+t.toString(32)),n+=":"}else t=pp++,n=":"+n+"r"+t.toString(32)+":";return e.memoizedState=n},unstable_isNewReconciler:!1},yp={readContext:Ye,useCallback:vc,useContext:Ye,useEffect:ea,useImperativeHandle:gc,useInsertionEffect:pc,useLayoutEffect:mc,useMemo:yc,useReducer:gl,useRef:fc,useState:function(){return gl(yr)},useDebugValue:na,useDeferredValue:function(e){var n=Xe();return xc(n,se.memoizedState,e)},useTransition:function(){var e=gl(yr)[0],n=Xe().memoizedState;return[e,n]},useMutableSource:lc,useSyncExternalStore:oc,useId:wc,unstable_isNewReconciler:!1},xp={readContext:Ye,useCallback:vc,useContext:Ye,useEffect:ea,useImperativeHandle:gc,useInsertionEffect:pc,useLayoutEffect:mc,useMemo:yc,useReducer:vl,useRef:fc,useState:function(){return vl(yr)},useDebugValue:na,useDeferredValue:function(e){var n=Xe();return se===null?n.memoizedState=e:xc(n,se.memoizedState,e)},useTransition:function(){var e=vl(yr)[0],n=Xe().memoizedState;return[e,n]},useMutableSource:lc,useSyncExternalStore:oc,useId:wc,unstable_isNewReconciler:!1};function qe(e,n){if(e&&e.defaultProps){n=ne({},n),e=e.defaultProps;for(var t in e)n[t]===void 0&&(n[t]=e[t]);return n}return n}function ro(e,n,t,r){n=e.memoizedState,t=t(r,n),t=t==null?n:ne({},n,t),e.memoizedState=t,e.lanes===0&&(e.updateQueue.baseState=t)}var Ii={isMounted:function(e){return(e=e._reactInternals)?tt(e)===e:!1},enqueueSetState:function(e,n,t){e=e._reactInternals;var r=$e(),i=Ln(e),l=gn(r,i);l.payload=n,t!=null&&(l.callback=t),n=Rn(e,l,i),n!==null&&(tn(n,e,i,r),qr(n,e,i))},enqueueReplaceState:function(e,n,t){e=e._reactInternals;var r=$e(),i=Ln(e),l=gn(r,i);l.tag=1,l.payload=n,t!=null&&(l.callback=t),n=Rn(e,l,i),n!==null&&(tn(n,e,i,r),qr(n,e,i))},enqueueForceUpdate:function(e,n){e=e._reactInternals;var t=$e(),r=Ln(e),i=gn(t,r);i.tag=2,n!=null&&(i.callback=n),n=Rn(e,i,r),n!==null&&(tn(n,e,r,t),qr(n,e,r))}};function cs(e,n,t,r,i,l,o){return e=e.stateNode,typeof e.shouldComponentUpdate=="function"?e.shouldComponentUpdate(r,l,o):n.prototype&&n.prototype.isPureReactComponent?!dr(t,r)||!dr(i,l):!0}function bc(e,n,t){var r=!1,i=In,l=n.contextType;return typeof l=="object"&&l!==null?l=Ye(l):(i=Re(n)?Xn:Se.current,r=n.contextTypes,l=(r=r!=null)?Ct(e,i):In),n=new n(t,l),e.memoizedState=n.state!==null&&n.state!==void 0?n.state:null,n.updater=Ii,e.stateNode=n,n._reactInternals=e,r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=i,e.__reactInternalMemoizedMaskedChildContext=l),n}function ds(e,n,t,r){e=n.state,typeof n.componentWillReceiveProps=="function"&&n.componentWillReceiveProps(t,r),typeof n.UNSAFE_componentWillReceiveProps=="function"&&n.UNSAFE_componentWillReceiveProps(t,r),n.state!==e&&Ii.enqueueReplaceState(n,n.state,null)}function io(e,n,t,r){var i=e.stateNode;i.props=t,i.state=e.memoizedState,i.refs={},Ko(e);var l=n.contextType;typeof l=="object"&&l!==null?i.context=Ye(l):(l=Re(n)?Xn:Se.current,i.context=Ct(e,l)),i.state=e.memoizedState,l=n.getDerivedStateFromProps,typeof l=="function"&&(ro(e,n,l,t),i.state=e.memoizedState),typeof n.getDerivedStateFromProps=="function"||typeof i.getSnapshotBeforeUpdate=="function"||typeof i.UNSAFE_componentWillMount!="function"&&typeof i.componentWillMount!="function"||(n=i.state,typeof i.componentWillMount=="function"&&i.componentWillMount(),typeof i.UNSAFE_componentWillMount=="function"&&i.UNSAFE_componentWillMount(),n!==i.state&&Ii.enqueueReplaceState(i,i.state,null),ki(e,t,i,r),i.state=e.memoizedState),typeof i.componentDidMount=="function"&&(e.flags|=4194308)}function Nt(e,n){try{var t="",r=n;do t+=Qd(r),r=r.return;while(r);var i=t}catch(l){i=`
Error generating stack: `+l.message+`
`+l.stack}return{value:e,source:n,stack:i,digest:null}}function yl(e,n,t){return{value:e,source:null,stack:t??null,digest:n??null}}function lo(e,n){try{console.error(n.value)}catch(t){setTimeout(function(){throw t})}}var wp=typeof WeakMap=="function"?WeakMap:Map;function Cc(e,n,t){t=gn(-1,t),t.tag=3,t.payload={element:null};var r=n.value;return t.callback=function(){Ei||(Ei=!0,go=r),lo(e,n)},t}function Ec(e,n,t){t=gn(-1,t),t.tag=3;var r=e.type.getDerivedStateFromError;if(typeof r=="function"){var i=n.value;t.payload=function(){return r(i)},t.callback=function(){lo(e,n)}}var l=e.stateNode;return l!==null&&typeof l.componentDidCatch=="function"&&(t.callback=function(){lo(e,n),typeof r!="function"&&(zn===null?zn=new Set([this]):zn.add(this));var o=n.stack;this.componentDidCatch(n.value,{componentStack:o!==null?o:""})}),t}function fs(e,n,t){var r=e.pingCache;if(r===null){r=e.pingCache=new wp;var i=new Set;r.set(n,i)}else i=r.get(n),i===void 0&&(i=new Set,r.set(n,i));i.has(t)||(i.add(t),e=zp.bind(null,e,n,t),n.then(e,e))}function ps(e){do{var n;if((n=e.tag===13)&&(n=e.memoizedState,n=n!==null?n.dehydrated!==null:!0),n)return e;e=e.return}while(e!==null);return null}function ms(e,n,t,r,i){return e.mode&1?(e.flags|=65536,e.lanes=i,e):(e===n?e.flags|=65536:(e.flags|=128,t.flags|=131072,t.flags&=-52805,t.tag===1&&(t.alternate===null?t.tag=17:(n=gn(-1,1),n.tag=2,Rn(t,n,1))),t.lanes|=1),e)}var kp=kn.ReactCurrentOwner,Fe=!1;function Ee(e,n,t,r){n.child=e===null?nc(n,null,t,r):$t(n,e.child,t,r)}function hs(e,n,t,r,i){t=t.render;var l=n.ref;return _t(n,i),r=qo(e,n,t,r,l,i),t=Jo(),e!==null&&!Fe?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,wn(e,n,i)):(q&&t&&Ao(n),n.flags|=1,Ee(e,n,r,i),n.child)}function gs(e,n,t,r,i){if(e===null){var l=t.type;return typeof l=="function"&&!ua(l)&&l.defaultProps===void 0&&t.compare===null&&t.defaultProps===void 0?(n.tag=15,n.type=l,$c(e,n,l,r,i)):(e=ii(t.type,null,r,n,n.mode,i),e.ref=n.ref,e.return=n,n.child=e)}if(l=e.child,!(e.lanes&i)){var o=l.memoizedProps;if(t=t.compare,t=t!==null?t:dr,t(o,r)&&e.ref===n.ref)return wn(e,n,i)}return n.flags|=1,e=Mn(l,r),e.ref=n.ref,e.return=n,n.child=e}function $c(e,n,t,r,i){if(e!==null){var l=e.memoizedProps;if(dr(l,r)&&e.ref===n.ref)if(Fe=!1,n.pendingProps=r=l,(e.lanes&i)!==0)e.flags&131072&&(Fe=!0);else return n.lanes=e.lanes,wn(e,n,i)}return oo(e,n,t,r,i)}function Pc(e,n,t){var r=n.pendingProps,i=r.children,l=e!==null?e.memoizedState:null;if(r.mode==="hidden")if(!(n.mode&1))n.memoizedState={baseLanes:0,cachePool:null,transitions:null},Y(gt,Me),Me|=t;else{if(!(t&1073741824))return e=l!==null?l.baseLanes|t:t,n.lanes=n.childLanes=1073741824,n.memoizedState={baseLanes:e,cachePool:null,transitions:null},n.updateQueue=null,Y(gt,Me),Me|=e,null;n.memoizedState={baseLanes:0,cachePool:null,transitions:null},r=l!==null?l.baseLanes:t,Y(gt,Me),Me|=r}else l!==null?(r=l.baseLanes|t,n.memoizedState=null):r=t,Y(gt,Me),Me|=r;return Ee(e,n,i,t),n.child}function Nc(e,n){var t=n.ref;(e===null&&t!==null||e!==null&&e.ref!==t)&&(n.flags|=512,n.flags|=2097152)}function oo(e,n,t,r,i){var l=Re(t)?Xn:Se.current;return l=Ct(n,l),_t(n,i),t=qo(e,n,t,r,l,i),r=Jo(),e!==null&&!Fe?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,wn(e,n,i)):(q&&r&&Ao(n),n.flags|=1,Ee(e,n,t,i),n.child)}function vs(e,n,t,r,i){if(Re(t)){var l=!0;gi(n)}else l=!1;if(_t(n,i),n.stateNode===null)ni(e,n),bc(n,t,r),io(n,t,r,i),r=!0;else if(e===null){var o=n.stateNode,a=n.memoizedProps;o.props=a;var s=o.context,d=t.contextType;typeof d=="object"&&d!==null?d=Ye(d):(d=Re(t)?Xn:Se.current,d=Ct(n,d));var x=t.getDerivedStateFromProps,h=typeof x=="function"||typeof o.getSnapshotBeforeUpdate=="function";h||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==r||s!==d)&&ds(n,o,r,d),bn=!1;var p=n.memoizedState;o.state=p,ki(n,r,o,i),s=n.memoizedState,a!==r||p!==s||je.current||bn?(typeof x=="function"&&(ro(n,t,x,r),s=n.memoizedState),(a=bn||cs(n,t,a,r,p,s,d))?(h||typeof o.UNSAFE_componentWillMount!="function"&&typeof o.componentWillMount!="function"||(typeof o.componentWillMount=="function"&&o.componentWillMount(),typeof o.UNSAFE_componentWillMount=="function"&&o.UNSAFE_componentWillMount()),typeof o.componentDidMount=="function"&&(n.flags|=4194308)):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),n.memoizedProps=r,n.memoizedState=s),o.props=r,o.state=s,o.context=d,r=a):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),r=!1)}else{o=n.stateNode,rc(e,n),a=n.memoizedProps,d=n.type===n.elementType?a:qe(n.type,a),o.props=d,h=n.pendingProps,p=o.context,s=t.contextType,typeof s=="object"&&s!==null?s=Ye(s):(s=Re(t)?Xn:Se.current,s=Ct(n,s));var g=t.getDerivedStateFromProps;(x=typeof g=="function"||typeof o.getSnapshotBeforeUpdate=="function")||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==h||p!==s)&&ds(n,o,r,s),bn=!1,p=n.memoizedState,o.state=p,ki(n,r,o,i);var k=n.memoizedState;a!==h||p!==k||je.current||bn?(typeof g=="function"&&(ro(n,t,g,r),k=n.memoizedState),(d=bn||cs(n,t,d,r,p,k,s)||!1)?(x||typeof o.UNSAFE_componentWillUpdate!="function"&&typeof o.componentWillUpdate!="function"||(typeof o.componentWillUpdate=="function"&&o.componentWillUpdate(r,k,s),typeof o.UNSAFE_componentWillUpdate=="function"&&o.UNSAFE_componentWillUpdate(r,k,s)),typeof o.componentDidUpdate=="function"&&(n.flags|=4),typeof o.getSnapshotBeforeUpdate=="function"&&(n.flags|=1024)):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),n.memoizedProps=r,n.memoizedState=k),o.props=r,o.state=k,o.context=s,r=d):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),r=!1)}return ao(e,n,t,r,l,i)}function ao(e,n,t,r,i,l){Nc(e,n);var o=(n.flags&128)!==0;if(!r&&!o)return i&&ts(n,t,!1),wn(e,n,l);r=n.stateNode,kp.current=n;var a=o&&typeof t.getDerivedStateFromError!="function"?null:r.render();return n.flags|=1,e!==null&&o?(n.child=$t(n,e.child,null,l),n.child=$t(n,null,a,l)):Ee(e,n,a,l),n.memoizedState=r.state,i&&ts(n,t,!0),n.child}function Tc(e){var n=e.stateNode;n.pendingContext?ns(e,n.pendingContext,n.pendingContext!==n.context):n.context&&ns(e,n.context,!1),Go(e,n.containerInfo)}function ys(e,n,t,r,i){return Et(),Bo(i),n.flags|=256,Ee(e,n,t,r),n.child}var so={dehydrated:null,treeContext:null,retryLane:0};function uo(e){return{baseLanes:e,cachePool:null,transitions:null}}function Fc(e,n,t){var r=n.pendingProps,i=J.current,l=!1,o=(n.flags&128)!==0,a;if((a=o)||(a=e!==null&&e.memoizedState===null?!1:(i&2)!==0),a?(l=!0,n.flags&=-129):(e===null||e.memoizedState!==null)&&(i|=1),Y(J,i&1),e===null)return no(n),e=n.memoizedState,e!==null&&(e=e.dehydrated,e!==null)?(n.mode&1?e.data==="$!"?n.lanes=8:n.lanes=1073741824:n.lanes=1,null):(o=r.children,e=r.fallback,l?(r=n.mode,l=n.child,o={mode:"hidden",children:o},!(r&1)&&l!==null?(l.childLanes=0,l.pendingProps=o):l=Bi(o,r,0,null),e=Yn(e,r,t,null),l.return=n,e.return=n,l.sibling=e,n.child=l,n.child.memoizedState=uo(t),n.memoizedState=so,e):ta(n,o));if(i=e.memoizedState,i!==null&&(a=i.dehydrated,a!==null))return _p(e,n,o,r,a,i,t);if(l){l=r.fallback,o=n.mode,i=e.child,a=i.sibling;var s={mode:"hidden",children:r.children};return!(o&1)&&n.child!==i?(r=n.child,r.childLanes=0,r.pendingProps=s,n.deletions=null):(r=Mn(i,s),r.subtreeFlags=i.subtreeFlags&14680064),a!==null?l=Mn(a,l):(l=Yn(l,o,t,null),l.flags|=2),l.return=n,r.return=n,r.sibling=l,n.child=r,r=l,l=n.child,o=e.child.memoizedState,o=o===null?uo(t):{baseLanes:o.baseLanes|t,cachePool:null,transitions:o.transitions},l.memoizedState=o,l.childLanes=e.childLanes&~t,n.memoizedState=so,r}return l=e.child,e=l.sibling,r=Mn(l,{mode:"visible",children:r.children}),!(n.mode&1)&&(r.lanes=t),r.return=n,r.sibling=null,e!==null&&(t=n.deletions,t===null?(n.deletions=[e],n.flags|=16):t.push(e)),n.child=r,n.memoizedState=null,r}function ta(e,n){return n=Bi({mode:"visible",children:n},e.mode,0,null),n.return=e,e.child=n}function Ur(e,n,t,r){return r!==null&&Bo(r),$t(n,e.child,null,t),e=ta(n,n.pendingProps.children),e.flags|=2,n.memoizedState=null,e}function _p(e,n,t,r,i,l,o){if(t)return n.flags&256?(n.flags&=-257,r=yl(Error(b(422))),Ur(e,n,o,r)):n.memoizedState!==null?(n.child=e.child,n.flags|=128,null):(l=r.fallback,i=n.mode,r=Bi({mode:"visible",children:r.children},i,0,null),l=Yn(l,i,o,null),l.flags|=2,r.return=n,l.return=n,r.sibling=l,n.child=r,n.mode&1&&$t(n,e.child,null,o),n.child.memoizedState=uo(o),n.memoizedState=so,l);if(!(n.mode&1))return Ur(e,n,o,null);if(i.data==="$!"){if(r=i.nextSibling&&i.nextSibling.dataset,r)var a=r.dgst;return r=a,l=Error(b(419)),r=yl(l,r,void 0),Ur(e,n,o,r)}if(a=(o&e.childLanes)!==0,Fe||a){if(r=pe,r!==null){switch(o&-o){case 4:i=2;break;case 16:i=8;break;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:i=32;break;case 536870912:i=268435456;break;default:i=0}i=i&(r.suspendedLanes|o)?0:i,i!==0&&i!==l.retryLane&&(l.retryLane=i,xn(e,i),tn(r,e,i,-1))}return sa(),r=yl(Error(b(421))),Ur(e,n,o,r)}return i.data==="$?"?(n.flags|=128,n.child=e.child,n=Lp.bind(null,e),i._reactRetry=n,null):(e=l.treeContext,Oe=jn(i.nextSibling),Ie=n,q=!0,en=null,e!==null&&(Ve[Qe++]=mn,Ve[Qe++]=hn,Ve[Qe++]=Zn,mn=e.id,hn=e.overflow,Zn=n),n=ta(n,r.children),n.flags|=4096,n)}function xs(e,n,t){e.lanes|=n;var r=e.alternate;r!==null&&(r.lanes|=n),to(e.return,n,t)}function xl(e,n,t,r,i){var l=e.memoizedState;l===null?e.memoizedState={isBackwards:n,rendering:null,renderingStartTime:0,last:r,tail:t,tailMode:i}:(l.isBackwards=n,l.rendering=null,l.renderingStartTime=0,l.last=r,l.tail=t,l.tailMode=i)}function jc(e,n,t){var r=n.pendingProps,i=r.revealOrder,l=r.tail;if(Ee(e,n,r.children,t),r=J.current,r&2)r=r&1|2,n.flags|=128;else{if(e!==null&&e.flags&128)e:for(e=n.child;e!==null;){if(e.tag===13)e.memoizedState!==null&&xs(e,t,n);else if(e.tag===19)xs(e,t,n);else if(e.child!==null){e.child.return=e,e=e.child;continue}if(e===n)break e;for(;e.sibling===null;){if(e.return===null||e.return===n)break e;e=e.return}e.sibling.return=e.return,e=e.sibling}r&=1}if(Y(J,r),!(n.mode&1))n.memoizedState=null;else switch(i){case"forwards":for(t=n.child,i=null;t!==null;)e=t.alternate,e!==null&&_i(e)===null&&(i=t),t=t.sibling;t=i,t===null?(i=n.child,n.child=null):(i=t.sibling,t.sibling=null),xl(n,!1,i,t,l);break;case"backwards":for(t=null,i=n.child,n.child=null;i!==null;){if(e=i.alternate,e!==null&&_i(e)===null){n.child=i;break}e=i.sibling,i.sibling=t,t=i,i=e}xl(n,!0,t,null,l);break;case"together":xl(n,!1,null,null,void 0);break;default:n.memoizedState=null}return n.child}function ni(e,n){!(n.mode&1)&&e!==null&&(e.alternate=null,n.alternate=null,n.flags|=2)}function wn(e,n,t){if(e!==null&&(n.dependencies=e.dependencies),Jn|=n.lanes,!(t&n.childLanes))return null;if(e!==null&&n.child!==e.child)throw Error(b(153));if(n.child!==null){for(e=n.child,t=Mn(e,e.pendingProps),n.child=t,t.return=n;e.sibling!==null;)e=e.sibling,t=t.sibling=Mn(e,e.pendingProps),t.return=n;t.sibling=null}return n.child}function Sp(e,n,t){switch(n.tag){case 3:Tc(n),Et();break;case 5:ic(n);break;case 1:Re(n.type)&&gi(n);break;case 4:Go(n,n.stateNode.containerInfo);break;case 10:var r=n.type._context,i=n.memoizedProps.value;Y(xi,r._currentValue),r._currentValue=i;break;case 13:if(r=n.memoizedState,r!==null)return r.dehydrated!==null?(Y(J,J.current&1),n.flags|=128,null):t&n.child.childLanes?Fc(e,n,t):(Y(J,J.current&1),e=wn(e,n,t),e!==null?e.sibling:null);Y(J,J.current&1);break;case 19:if(r=(t&n.childLanes)!==0,e.flags&128){if(r)return jc(e,n,t);n.flags|=128}if(i=n.memoizedState,i!==null&&(i.rendering=null,i.tail=null,i.lastEffect=null),Y(J,J.current),r)break;return null;case 22:case 23:return n.lanes=0,Pc(e,n,t)}return wn(e,n,t)}var Rc,co,zc,Lc;Rc=function(e,n){for(var t=n.child;t!==null;){if(t.tag===5||t.tag===6)e.appendChild(t.stateNode);else if(t.tag!==4&&t.child!==null){t.child.return=t,t=t.child;continue}if(t===n)break;for(;t.sibling===null;){if(t.return===null||t.return===n)return;t=t.return}t.sibling.return=t.return,t=t.sibling}};co=function(){};zc=function(e,n,t,r){var i=e.memoizedProps;if(i!==r){e=n.stateNode,Kn(dn.current);var l=null;switch(t){case"input":i=jl(e,i),r=jl(e,r),l=[];break;case"select":i=ne({},i,{value:void 0}),r=ne({},r,{value:void 0}),l=[];break;case"textarea":i=Ll(e,i),r=Ll(e,r),l=[];break;default:typeof i.onClick!="function"&&typeof r.onClick=="function"&&(e.onclick=mi)}Dl(t,r);var o;t=null;for(d in i)if(!r.hasOwnProperty(d)&&i.hasOwnProperty(d)&&i[d]!=null)if(d==="style"){var a=i[d];for(o in a)a.hasOwnProperty(o)&&(t||(t={}),t[o]="")}else d!=="dangerouslySetInnerHTML"&&d!=="children"&&d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&d!=="autoFocus"&&(ir.hasOwnProperty(d)?l||(l=[]):(l=l||[]).push(d,null));for(d in r){var s=r[d];if(a=i!=null?i[d]:void 0,r.hasOwnProperty(d)&&s!==a&&(s!=null||a!=null))if(d==="style")if(a){for(o in a)!a.hasOwnProperty(o)||s&&s.hasOwnProperty(o)||(t||(t={}),t[o]="");for(o in s)s.hasOwnProperty(o)&&a[o]!==s[o]&&(t||(t={}),t[o]=s[o])}else t||(l||(l=[]),l.push(d,t)),t=s;else d==="dangerouslySetInnerHTML"?(s=s?s.__html:void 0,a=a?a.__html:void 0,s!=null&&a!==s&&(l=l||[]).push(d,s)):d==="children"?typeof s!="string"&&typeof s!="number"||(l=l||[]).push(d,""+s):d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&(ir.hasOwnProperty(d)?(s!=null&&d==="onScroll"&&X("scroll",e),l||a===s||(l=[])):(l=l||[]).push(d,s))}t&&(l=l||[]).push("style",t);var d=l;(n.updateQueue=d)&&(n.flags|=4)}};Lc=function(e,n,t,r){t!==r&&(n.flags|=4)};function At(e,n){if(!q)switch(e.tailMode){case"hidden":n=e.tail;for(var t=null;n!==null;)n.alternate!==null&&(t=n),n=n.sibling;t===null?e.tail=null:t.sibling=null;break;case"collapsed":t=e.tail;for(var r=null;t!==null;)t.alternate!==null&&(r=t),t=t.sibling;r===null?n||e.tail===null?e.tail=null:e.tail.sibling=null:r.sibling=null}}function ke(e){var n=e.alternate!==null&&e.alternate.child===e.child,t=0,r=0;if(n)for(var i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags&14680064,r|=i.flags&14680064,i.return=e,i=i.sibling;else for(i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags,r|=i.flags,i.return=e,i=i.sibling;return e.subtreeFlags|=r,e.childLanes=t,n}function bp(e,n,t){var r=n.pendingProps;switch(Uo(n),n.tag){case 2:case 16:case 15:case 0:case 11:case 7:case 8:case 12:case 9:case 14:return ke(n),null;case 1:return Re(n.type)&&hi(),ke(n),null;case 3:return r=n.stateNode,Pt(),Z(je),Z(Se),Xo(),r.pendingContext&&(r.context=r.pendingContext,r.pendingContext=null),(e===null||e.child===null)&&(Ir(n)?n.flags|=4:e===null||e.memoizedState.isDehydrated&&!(n.flags&256)||(n.flags|=1024,en!==null&&(xo(en),en=null))),co(e,n),ke(n),null;case 5:Yo(n);var i=Kn(gr.current);if(t=n.type,e!==null&&n.stateNode!=null)zc(e,n,t,r,i),e.ref!==n.ref&&(n.flags|=512,n.flags|=2097152);else{if(!r){if(n.stateNode===null)throw Error(b(166));return ke(n),null}if(e=Kn(dn.current),Ir(n)){r=n.stateNode,t=n.type;var l=n.memoizedProps;switch(r[un]=n,r[mr]=l,e=(n.mode&1)!==0,t){case"dialog":X("cancel",r),X("close",r);break;case"iframe":case"object":case"embed":X("load",r);break;case"video":case"audio":for(i=0;i<Vt.length;i++)X(Vt[i],r);break;case"source":X("error",r);break;case"img":case"image":case"link":X("error",r),X("load",r);break;case"details":X("toggle",r);break;case"input":Pa(r,l),X("invalid",r);break;case"select":r._wrapperState={wasMultiple:!!l.multiple},X("invalid",r);break;case"textarea":Ta(r,l),X("invalid",r)}Dl(t,l),i=null;for(var o in l)if(l.hasOwnProperty(o)){var a=l[o];o==="children"?typeof a=="string"?r.textContent!==a&&(l.suppressHydrationWarning!==!0&&Or(r.textContent,a,e),i=["children",a]):typeof a=="number"&&r.textContent!==""+a&&(l.suppressHydrationWarning!==!0&&Or(r.textContent,a,e),i=["children",""+a]):ir.hasOwnProperty(o)&&a!=null&&o==="onScroll"&&X("scroll",r)}switch(t){case"input":Tr(r),Na(r,l,!0);break;case"textarea":Tr(r),Fa(r);break;case"select":case"option":break;default:typeof l.onClick=="function"&&(r.onclick=mi)}r=i,n.updateQueue=r,r!==null&&(n.flags|=4)}else{o=i.nodeType===9?i:i.ownerDocument,e==="http://www.w3.org/1999/xhtml"&&(e=uu(t)),e==="http://www.w3.org/1999/xhtml"?t==="script"?(e=o.createElement("div"),e.innerHTML="<script><\/script>",e=e.removeChild(e.firstChild)):typeof r.is=="string"?e=o.createElement(t,{is:r.is}):(e=o.createElement(t),t==="select"&&(o=e,r.multiple?o.multiple=!0:r.size&&(o.size=r.size))):e=o.createElementNS(e,t),e[un]=n,e[mr]=r,Rc(e,n,!1,!1),n.stateNode=e;e:{switch(o=Ol(t,r),t){case"dialog":X("cancel",e),X("close",e),i=r;break;case"iframe":case"object":case"embed":X("load",e),i=r;break;case"video":case"audio":for(i=0;i<Vt.length;i++)X(Vt[i],e);i=r;break;case"source":X("error",e),i=r;break;case"img":case"image":case"link":X("error",e),X("load",e),i=r;break;case"details":X("toggle",e),i=r;break;case"input":Pa(e,r),i=jl(e,r),X("invalid",e);break;case"option":i=r;break;case"select":e._wrapperState={wasMultiple:!!r.multiple},i=ne({},r,{value:void 0}),X("invalid",e);break;case"textarea":Ta(e,r),i=Ll(e,r),X("invalid",e);break;default:i=r}Dl(t,i),a=i;for(l in a)if(a.hasOwnProperty(l)){var s=a[l];l==="style"?fu(e,s):l==="dangerouslySetInnerHTML"?(s=s?s.__html:void 0,s!=null&&cu(e,s)):l==="children"?typeof s=="string"?(t!=="textarea"||s!=="")&&lr(e,s):typeof s=="number"&&lr(e,""+s):l!=="suppressContentEditableWarning"&&l!=="suppressHydrationWarning"&&l!=="autoFocus"&&(ir.hasOwnProperty(l)?s!=null&&l==="onScroll"&&X("scroll",e):s!=null&&Eo(e,l,s,o))}switch(t){case"input":Tr(e),Na(e,r,!1);break;case"textarea":Tr(e),Fa(e);break;case"option":r.value!=null&&e.setAttribute("value",""+On(r.value));break;case"select":e.multiple=!!r.multiple,l=r.value,l!=null?yt(e,!!r.multiple,l,!1):r.defaultValue!=null&&yt(e,!!r.multiple,r.defaultValue,!0);break;default:typeof i.onClick=="function"&&(e.onclick=mi)}switch(t){case"button":case"input":case"select":case"textarea":r=!!r.autoFocus;break e;case"img":r=!0;break e;default:r=!1}}r&&(n.flags|=4)}n.ref!==null&&(n.flags|=512,n.flags|=2097152)}return ke(n),null;case 6:if(e&&n.stateNode!=null)Lc(e,n,e.memoizedProps,r);else{if(typeof r!="string"&&n.stateNode===null)throw Error(b(166));if(t=Kn(gr.current),Kn(dn.current),Ir(n)){if(r=n.stateNode,t=n.memoizedProps,r[un]=n,(l=r.nodeValue!==t)&&(e=Ie,e!==null))switch(e.tag){case 3:Or(r.nodeValue,t,(e.mode&1)!==0);break;case 5:e.memoizedProps.suppressHydrationWarning!==!0&&Or(r.nodeValue,t,(e.mode&1)!==0)}l&&(n.flags|=4)}else r=(t.nodeType===9?t:t.ownerDocument).createTextNode(r),r[un]=n,n.stateNode=r}return ke(n),null;case 13:if(Z(J),r=n.memoizedState,e===null||e.memoizedState!==null&&e.memoizedState.dehydrated!==null){if(q&&Oe!==null&&n.mode&1&&!(n.flags&128))Ju(),Et(),n.flags|=98560,l=!1;else if(l=Ir(n),r!==null&&r.dehydrated!==null){if(e===null){if(!l)throw Error(b(318));if(l=n.memoizedState,l=l!==null?l.dehydrated:null,!l)throw Error(b(317));l[un]=n}else Et(),!(n.flags&128)&&(n.memoizedState=null),n.flags|=4;ke(n),l=!1}else en!==null&&(xo(en),en=null),l=!0;if(!l)return n.flags&65536?n:null}return n.flags&128?(n.lanes=t,n):(r=r!==null,r!==(e!==null&&e.memoizedState!==null)&&r&&(n.child.flags|=8192,n.mode&1&&(e===null||J.current&1?ue===0&&(ue=3):sa())),n.updateQueue!==null&&(n.flags|=4),ke(n),null);case 4:return Pt(),co(e,n),e===null&&fr(n.stateNode.containerInfo),ke(n),null;case 10:return Vo(n.type._context),ke(n),null;case 17:return Re(n.type)&&hi(),ke(n),null;case 19:if(Z(J),l=n.memoizedState,l===null)return ke(n),null;if(r=(n.flags&128)!==0,o=l.rendering,o===null)if(r)At(l,!1);else{if(ue!==0||e!==null&&e.flags&128)for(e=n.child;e!==null;){if(o=_i(e),o!==null){for(n.flags|=128,At(l,!1),r=o.updateQueue,r!==null&&(n.updateQueue=r,n.flags|=4),n.subtreeFlags=0,r=t,t=n.child;t!==null;)l=t,e=r,l.flags&=14680066,o=l.alternate,o===null?(l.childLanes=0,l.lanes=e,l.child=null,l.subtreeFlags=0,l.memoizedProps=null,l.memoizedState=null,l.updateQueue=null,l.dependencies=null,l.stateNode=null):(l.childLanes=o.childLanes,l.lanes=o.lanes,l.child=o.child,l.subtreeFlags=0,l.deletions=null,l.memoizedProps=o.memoizedProps,l.memoizedState=o.memoizedState,l.updateQueue=o.updateQueue,l.type=o.type,e=o.dependencies,l.dependencies=e===null?null:{lanes:e.lanes,firstContext:e.firstContext}),t=t.sibling;return Y(J,J.current&1|2),n.child}e=e.sibling}l.tail!==null&&le()>Tt&&(n.flags|=128,r=!0,At(l,!1),n.lanes=4194304)}else{if(!r)if(e=_i(o),e!==null){if(n.flags|=128,r=!0,t=e.updateQueue,t!==null&&(n.updateQueue=t,n.flags|=4),At(l,!0),l.tail===null&&l.tailMode==="hidden"&&!o.alternate&&!q)return ke(n),null}else 2*le()-l.renderingStartTime>Tt&&t!==1073741824&&(n.flags|=128,r=!0,At(l,!1),n.lanes=4194304);l.isBackwards?(o.sibling=n.child,n.child=o):(t=l.last,t!==null?t.sibling=o:n.child=o,l.last=o)}return l.tail!==null?(n=l.tail,l.rendering=n,l.tail=n.sibling,l.renderingStartTime=le(),n.sibling=null,t=J.current,Y(J,r?t&1|2:t&1),n):(ke(n),null);case 22:case 23:return aa(),r=n.memoizedState!==null,e!==null&&e.memoizedState!==null!==r&&(n.flags|=8192),r&&n.mode&1?Me&1073741824&&(ke(n),n.subtreeFlags&6&&(n.flags|=8192)):ke(n),null;case 24:return null;case 25:return null}throw Error(b(156,n.tag))}function Cp(e,n){switch(Uo(n),n.tag){case 1:return Re(n.type)&&hi(),e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 3:return Pt(),Z(je),Z(Se),Xo(),e=n.flags,e&65536&&!(e&128)?(n.flags=e&-65537|128,n):null;case 5:return Yo(n),null;case 13:if(Z(J),e=n.memoizedState,e!==null&&e.dehydrated!==null){if(n.alternate===null)throw Error(b(340));Et()}return e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 19:return Z(J),null;case 4:return Pt(),null;case 10:return Vo(n.type._context),null;case 22:case 23:return aa(),null;case 24:return null;default:return null}}var Br=!1,_e=!1,Ep=typeof WeakSet=="function"?WeakSet:Set,F=null;function ht(e,n){var t=e.ref;if(t!==null)if(typeof t=="function")try{t(null)}catch(r){re(e,n,r)}else t.current=null}function fo(e,n,t){try{t()}catch(r){re(e,n,r)}}var ws=!1;function $p(e,n){if(Gl=di,e=Au(),Io(e)){if("selectionStart"in e)var t={start:e.selectionStart,end:e.selectionEnd};else e:{t=(t=e.ownerDocument)&&t.defaultView||window;var r=t.getSelection&&t.getSelection();if(r&&r.rangeCount!==0){t=r.anchorNode;var i=r.anchorOffset,l=r.focusNode;r=r.focusOffset;try{t.nodeType,l.nodeType}catch{t=null;break e}var o=0,a=-1,s=-1,d=0,x=0,h=e,p=null;n:for(;;){for(var g;h!==t||i!==0&&h.nodeType!==3||(a=o+i),h!==l||r!==0&&h.nodeType!==3||(s=o+r),h.nodeType===3&&(o+=h.nodeValue.length),(g=h.firstChild)!==null;)p=h,h=g;for(;;){if(h===e)break n;if(p===t&&++d===i&&(a=o),p===l&&++x===r&&(s=o),(g=h.nextSibling)!==null)break;h=p,p=h.parentNode}h=g}t=a===-1||s===-1?null:{start:a,end:s}}else t=null}t=t||{start:0,end:0}}else t=null;for(Yl={focusedElem:e,selectionRange:t},di=!1,F=n;F!==null;)if(n=F,e=n.child,(n.subtreeFlags&1028)!==0&&e!==null)e.return=n,F=e;else for(;F!==null;){n=F;try{var k=n.alternate;if(n.flags&1024)switch(n.tag){case 0:case 11:case 15:break;case 1:if(k!==null){var _=k.memoizedProps,j=k.memoizedState,c=n.stateNode,u=c.getSnapshotBeforeUpdate(n.elementType===n.type?_:qe(n.type,_),j);c.__reactInternalSnapshotBeforeUpdate=u}break;case 3:var f=n.stateNode.containerInfo;f.nodeType===1?f.textContent="":f.nodeType===9&&f.documentElement&&f.removeChild(f.documentElement);break;case 5:case 6:case 4:case 17:break;default:throw Error(b(163))}}catch(y){re(n,n.return,y)}if(e=n.sibling,e!==null){e.return=n.return,F=e;break}F=n.return}return k=ws,ws=!1,k}function Jt(e,n,t){var r=n.updateQueue;if(r=r!==null?r.lastEffect:null,r!==null){var i=r=r.next;do{if((i.tag&e)===e){var l=i.destroy;i.destroy=void 0,l!==void 0&&fo(n,t,l)}i=i.next}while(i!==r)}}function Ai(e,n){if(n=n.updateQueue,n=n!==null?n.lastEffect:null,n!==null){var t=n=n.next;do{if((t.tag&e)===e){var r=t.create;t.destroy=r()}t=t.next}while(t!==n)}}function po(e){var n=e.ref;if(n!==null){var t=e.stateNode;switch(e.tag){case 5:e=t;break;default:e=t}typeof n=="function"?n(e):n.current=e}}function Mc(e){var n=e.alternate;n!==null&&(e.alternate=null,Mc(n)),e.child=null,e.deletions=null,e.sibling=null,e.tag===5&&(n=e.stateNode,n!==null&&(delete n[un],delete n[mr],delete n[ql],delete n[up],delete n[cp])),e.stateNode=null,e.return=null,e.dependencies=null,e.memoizedProps=null,e.memoizedState=null,e.pendingProps=null,e.stateNode=null,e.updateQueue=null}function Dc(e){return e.tag===5||e.tag===3||e.tag===4}function ks(e){e:for(;;){for(;e.sibling===null;){if(e.return===null||Dc(e.return))return null;e=e.return}for(e.sibling.return=e.return,e=e.sibling;e.tag!==5&&e.tag!==6&&e.tag!==18;){if(e.flags&2||e.child===null||e.tag===4)continue e;e.child.return=e,e=e.child}if(!(e.flags&2))return e.stateNode}}function mo(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.nodeType===8?t.parentNode.insertBefore(e,n):t.insertBefore(e,n):(t.nodeType===8?(n=t.parentNode,n.insertBefore(e,t)):(n=t,n.appendChild(e)),t=t._reactRootContainer,t!=null||n.onclick!==null||(n.onclick=mi));else if(r!==4&&(e=e.child,e!==null))for(mo(e,n,t),e=e.sibling;e!==null;)mo(e,n,t),e=e.sibling}function ho(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.insertBefore(e,n):t.appendChild(e);else if(r!==4&&(e=e.child,e!==null))for(ho(e,n,t),e=e.sibling;e!==null;)ho(e,n,t),e=e.sibling}var me=null,Je=!1;function _n(e,n,t){for(t=t.child;t!==null;)Oc(e,n,t),t=t.sibling}function Oc(e,n,t){if(cn&&typeof cn.onCommitFiberUnmount=="function")try{cn.onCommitFiberUnmount(ji,t)}catch{}switch(t.tag){case 5:_e||ht(t,n);case 6:var r=me,i=Je;me=null,_n(e,n,t),me=r,Je=i,me!==null&&(Je?(e=me,t=t.stateNode,e.nodeType===8?e.parentNode.removeChild(t):e.removeChild(t)):me.removeChild(t.stateNode));break;case 18:me!==null&&(Je?(e=me,t=t.stateNode,e.nodeType===8?fl(e.parentNode,t):e.nodeType===1&&fl(e,t),ur(e)):fl(me,t.stateNode));break;case 4:r=me,i=Je,me=t.stateNode.containerInfo,Je=!0,_n(e,n,t),me=r,Je=i;break;case 0:case 11:case 14:case 15:if(!_e&&(r=t.updateQueue,r!==null&&(r=r.lastEffect,r!==null))){i=r=r.next;do{var l=i,o=l.destroy;l=l.tag,o!==void 0&&(l&2||l&4)&&fo(t,n,o),i=i.next}while(i!==r)}_n(e,n,t);break;case 1:if(!_e&&(ht(t,n),r=t.stateNode,typeof r.componentWillUnmount=="function"))try{r.props=t.memoizedProps,r.state=t.memoizedState,r.componentWillUnmount()}catch(a){re(t,n,a)}_n(e,n,t);break;case 21:_n(e,n,t);break;case 22:t.mode&1?(_e=(r=_e)||t.memoizedState!==null,_n(e,n,t),_e=r):_n(e,n,t);break;default:_n(e,n,t)}}function _s(e){var n=e.updateQueue;if(n!==null){e.updateQueue=null;var t=e.stateNode;t===null&&(t=e.stateNode=new Ep),n.forEach(function(r){var i=Mp.bind(null,e,r);t.has(r)||(t.add(r),r.then(i,i))})}}function Ze(e,n){var t=n.deletions;if(t!==null)for(var r=0;r<t.length;r++){var i=t[r];try{var l=e,o=n,a=o;e:for(;a!==null;){switch(a.tag){case 5:me=a.stateNode,Je=!1;break e;case 3:me=a.stateNode.containerInfo,Je=!0;break e;case 4:me=a.stateNode.containerInfo,Je=!0;break e}a=a.return}if(me===null)throw Error(b(160));Oc(l,o,i),me=null,Je=!1;var s=i.alternate;s!==null&&(s.return=null),i.return=null}catch(d){re(i,n,d)}}if(n.subtreeFlags&12854)for(n=n.child;n!==null;)Ic(n,e),n=n.sibling}function Ic(e,n){var t=e.alternate,r=e.flags;switch(e.tag){case 0:case 11:case 14:case 15:if(Ze(n,e),an(e),r&4){try{Jt(3,e,e.return),Ai(3,e)}catch(_){re(e,e.return,_)}try{Jt(5,e,e.return)}catch(_){re(e,e.return,_)}}break;case 1:Ze(n,e),an(e),r&512&&t!==null&&ht(t,t.return);break;case 5:if(Ze(n,e),an(e),r&512&&t!==null&&ht(t,t.return),e.flags&32){var i=e.stateNode;try{lr(i,"")}catch(_){re(e,e.return,_)}}if(r&4&&(i=e.stateNode,i!=null)){var l=e.memoizedProps,o=t!==null?t.memoizedProps:l,a=e.type,s=e.updateQueue;if(e.updateQueue=null,s!==null)try{a==="input"&&l.type==="radio"&&l.name!=null&&au(i,l),Ol(a,o);var d=Ol(a,l);for(o=0;o<s.length;o+=2){var x=s[o],h=s[o+1];x==="style"?fu(i,h):x==="dangerouslySetInnerHTML"?cu(i,h):x==="children"?lr(i,h):Eo(i,x,h,d)}switch(a){case"input":Rl(i,l);break;case"textarea":su(i,l);break;case"select":var p=i._wrapperState.wasMultiple;i._wrapperState.wasMultiple=!!l.multiple;var g=l.value;g!=null?yt(i,!!l.multiple,g,!1):p!==!!l.multiple&&(l.defaultValue!=null?yt(i,!!l.multiple,l.defaultValue,!0):yt(i,!!l.multiple,l.multiple?[]:"",!1))}i[mr]=l}catch(_){re(e,e.return,_)}}break;case 6:if(Ze(n,e),an(e),r&4){if(e.stateNode===null)throw Error(b(162));i=e.stateNode,l=e.memoizedProps;try{i.nodeValue=l}catch(_){re(e,e.return,_)}}break;case 3:if(Ze(n,e),an(e),r&4&&t!==null&&t.memoizedState.isDehydrated)try{ur(n.containerInfo)}catch(_){re(e,e.return,_)}break;case 4:Ze(n,e),an(e);break;case 13:Ze(n,e),an(e),i=e.child,i.flags&8192&&(l=i.memoizedState!==null,i.stateNode.isHidden=l,!l||i.alternate!==null&&i.alternate.memoizedState!==null||(la=le())),r&4&&_s(e);break;case 22:if(x=t!==null&&t.memoizedState!==null,e.mode&1?(_e=(d=_e)||x,Ze(n,e),_e=d):Ze(n,e),an(e),r&8192){if(d=e.memoizedState!==null,(e.stateNode.isHidden=d)&&!x&&e.mode&1)for(F=e,x=e.child;x!==null;){for(h=F=x;F!==null;){switch(p=F,g=p.child,p.tag){case 0:case 11:case 14:case 15:Jt(4,p,p.return);break;case 1:ht(p,p.return);var k=p.stateNode;if(typeof k.componentWillUnmount=="function"){r=p,t=p.return;try{n=r,k.props=n.memoizedProps,k.state=n.memoizedState,k.componentWillUnmount()}catch(_){re(r,t,_)}}break;case 5:ht(p,p.return);break;case 22:if(p.memoizedState!==null){bs(h);continue}}g!==null?(g.return=p,F=g):bs(h)}x=x.sibling}e:for(x=null,h=e;;){if(h.tag===5){if(x===null){x=h;try{i=h.stateNode,d?(l=i.style,typeof l.setProperty=="function"?l.setProperty("display","none","important"):l.display="none"):(a=h.stateNode,s=h.memoizedProps.style,o=s!=null&&s.hasOwnProperty("display")?s.display:null,a.style.display=du("display",o))}catch(_){re(e,e.return,_)}}}else if(h.tag===6){if(x===null)try{h.stateNode.nodeValue=d?"":h.memoizedProps}catch(_){re(e,e.return,_)}}else if((h.tag!==22&&h.tag!==23||h.memoizedState===null||h===e)&&h.child!==null){h.child.return=h,h=h.child;continue}if(h===e)break e;for(;h.sibling===null;){if(h.return===null||h.return===e)break e;x===h&&(x=null),h=h.return}x===h&&(x=null),h.sibling.return=h.return,h=h.sibling}}break;case 19:Ze(n,e),an(e),r&4&&_s(e);break;case 21:break;default:Ze(n,e),an(e)}}function an(e){var n=e.flags;if(n&2){try{e:{for(var t=e.return;t!==null;){if(Dc(t)){var r=t;break e}t=t.return}throw Error(b(160))}switch(r.tag){case 5:var i=r.stateNode;r.flags&32&&(lr(i,""),r.flags&=-33);var l=ks(e);ho(e,l,i);break;case 3:case 4:var o=r.stateNode.containerInfo,a=ks(e);mo(e,a,o);break;default:throw Error(b(161))}}catch(s){re(e,e.return,s)}e.flags&=-3}n&4096&&(e.flags&=-4097)}function Pp(e,n,t){F=e,Ac(e)}function Ac(e,n,t){for(var r=(e.mode&1)!==0;F!==null;){var i=F,l=i.child;if(i.tag===22&&r){var o=i.memoizedState!==null||Br;if(!o){var a=i.alternate,s=a!==null&&a.memoizedState!==null||_e;a=Br;var d=_e;if(Br=o,(_e=s)&&!d)for(F=i;F!==null;)o=F,s=o.child,o.tag===22&&o.memoizedState!==null?Cs(i):s!==null?(s.return=o,F=s):Cs(i);for(;l!==null;)F=l,Ac(l),l=l.sibling;F=i,Br=a,_e=d}Ss(e)}else i.subtreeFlags&8772&&l!==null?(l.return=i,F=l):Ss(e)}}function Ss(e){for(;F!==null;){var n=F;if(n.flags&8772){var t=n.alternate;try{if(n.flags&8772)switch(n.tag){case 0:case 11:case 15:_e||Ai(5,n);break;case 1:var r=n.stateNode;if(n.flags&4&&!_e)if(t===null)r.componentDidMount();else{var i=n.elementType===n.type?t.memoizedProps:qe(n.type,t.memoizedProps);r.componentDidUpdate(i,t.memoizedState,r.__reactInternalSnapshotBeforeUpdate)}var l=n.updateQueue;l!==null&&as(n,l,r);break;case 3:var o=n.updateQueue;if(o!==null){if(t=null,n.child!==null)switch(n.child.tag){case 5:t=n.child.stateNode;break;case 1:t=n.child.stateNode}as(n,o,t)}break;case 5:var a=n.stateNode;if(t===null&&n.flags&4){t=a;var s=n.memoizedProps;switch(n.type){case"button":case"input":case"select":case"textarea":s.autoFocus&&t.focus();break;case"img":s.src&&(t.src=s.src)}}break;case 6:break;case 4:break;case 12:break;case 13:if(n.memoizedState===null){var d=n.alternate;if(d!==null){var x=d.memoizedState;if(x!==null){var h=x.dehydrated;h!==null&&ur(h)}}}break;case 19:case 17:case 21:case 22:case 23:case 25:break;default:throw Error(b(163))}_e||n.flags&512&&po(n)}catch(p){re(n,n.return,p)}}if(n===e){F=null;break}if(t=n.sibling,t!==null){t.return=n.return,F=t;break}F=n.return}}function bs(e){for(;F!==null;){var n=F;if(n===e){F=null;break}var t=n.sibling;if(t!==null){t.return=n.return,F=t;break}F=n.return}}function Cs(e){for(;F!==null;){var n=F;try{switch(n.tag){case 0:case 11:case 15:var t=n.return;try{Ai(4,n)}catch(s){re(n,t,s)}break;case 1:var r=n.stateNode;if(typeof r.componentDidMount=="function"){var i=n.return;try{r.componentDidMount()}catch(s){re(n,i,s)}}var l=n.return;try{po(n)}catch(s){re(n,l,s)}break;case 5:var o=n.return;try{po(n)}catch(s){re(n,o,s)}}}catch(s){re(n,n.return,s)}if(n===e){F=null;break}var a=n.sibling;if(a!==null){a.return=n.return,F=a;break}F=n.return}}var Np=Math.ceil,Ci=kn.ReactCurrentDispatcher,ra=kn.ReactCurrentOwner,Ge=kn.ReactCurrentBatchConfig,Q=0,pe=null,ae=null,he=0,Me=0,gt=Un(0),ue=0,wr=null,Jn=0,Ui=0,ia=0,er=null,Te=null,la=0,Tt=1/0,fn=null,Ei=!1,go=null,zn=null,Wr=!1,Pn=null,$i=0,nr=0,vo=null,ti=-1,ri=0;function $e(){return Q&6?le():ti!==-1?ti:ti=le()}function Ln(e){return e.mode&1?Q&2&&he!==0?he&-he:fp.transition!==null?(ri===0&&(ri=bu()),ri):(e=G,e!==0||(e=window.event,e=e===void 0?16:Fu(e.type)),e):1}function tn(e,n,t,r){if(50<nr)throw nr=0,vo=null,Error(b(185));Sr(e,t,r),(!(Q&2)||e!==pe)&&(e===pe&&(!(Q&2)&&(Ui|=t),ue===4&&En(e,he)),ze(e,r),t===1&&Q===0&&!(n.mode&1)&&(Tt=le()+500,Di&&Bn()))}function ze(e,n){var t=e.callbackNode;ff(e,n);var r=ci(e,e===pe?he:0);if(r===0)t!==null&&za(t),e.callbackNode=null,e.callbackPriority=0;else if(n=r&-r,e.callbackPriority!==n){if(t!=null&&za(t),n===1)e.tag===0?dp(Es.bind(null,e)):Xu(Es.bind(null,e)),ap(function(){!(Q&6)&&Bn()}),t=null;else{switch(Cu(r)){case 1:t=Fo;break;case 4:t=_u;break;case 16:t=ui;break;case 536870912:t=Su;break;default:t=ui}t=Gc(t,Uc.bind(null,e))}e.callbackPriority=n,e.callbackNode=t}}function Uc(e,n){if(ti=-1,ri=0,Q&6)throw Error(b(327));var t=e.callbackNode;if(St()&&e.callbackNode!==t)return null;var r=ci(e,e===pe?he:0);if(r===0)return null;if(r&30||r&e.expiredLanes||n)n=Pi(e,r);else{n=r;var i=Q;Q|=2;var l=Wc();(pe!==e||he!==n)&&(fn=null,Tt=le()+500,Gn(e,n));do try{jp();break}catch(a){Bc(e,a)}while(!0);Ho(),Ci.current=l,Q=i,ae!==null?n=0:(pe=null,he=0,n=ue)}if(n!==0){if(n===2&&(i=Wl(e),i!==0&&(r=i,n=yo(e,i))),n===1)throw t=wr,Gn(e,0),En(e,r),ze(e,le()),t;if(n===6)En(e,r);else{if(i=e.current.alternate,!(r&30)&&!Tp(i)&&(n=Pi(e,r),n===2&&(l=Wl(e),l!==0&&(r=l,n=yo(e,l))),n===1))throw t=wr,Gn(e,0),En(e,r),ze(e,le()),t;switch(e.finishedWork=i,e.finishedLanes=r,n){case 0:case 1:throw Error(b(345));case 2:Hn(e,Te,fn);break;case 3:if(En(e,r),(r&130023424)===r&&(n=la+500-le(),10<n)){if(ci(e,0)!==0)break;if(i=e.suspendedLanes,(i&r)!==r){$e(),e.pingedLanes|=e.suspendedLanes&i;break}e.timeoutHandle=Zl(Hn.bind(null,e,Te,fn),n);break}Hn(e,Te,fn);break;case 4:if(En(e,r),(r&4194240)===r)break;for(n=e.eventTimes,i=-1;0<r;){var o=31-nn(r);l=1<<o,o=n[o],o>i&&(i=o),r&=~l}if(r=i,r=le()-r,r=(120>r?120:480>r?480:1080>r?1080:1920>r?1920:3e3>r?3e3:4320>r?4320:1960*Np(r/1960))-r,10<r){e.timeoutHandle=Zl(Hn.bind(null,e,Te,fn),r);break}Hn(e,Te,fn);break;case 5:Hn(e,Te,fn);break;default:throw Error(b(329))}}}return ze(e,le()),e.callbackNode===t?Uc.bind(null,e):null}function yo(e,n){var t=er;return e.current.memoizedState.isDehydrated&&(Gn(e,n).flags|=256),e=Pi(e,n),e!==2&&(n=Te,Te=t,n!==null&&xo(n)),e}function xo(e){Te===null?Te=e:Te.push.apply(Te,e)}function Tp(e){for(var n=e;;){if(n.flags&16384){var t=n.updateQueue;if(t!==null&&(t=t.stores,t!==null))for(var r=0;r<t.length;r++){var i=t[r],l=i.getSnapshot;i=i.value;try{if(!rn(l(),i))return!1}catch{return!1}}}if(t=n.child,n.subtreeFlags&16384&&t!==null)t.return=n,n=t;else{if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return!0;n=n.return}n.sibling.return=n.return,n=n.sibling}}return!0}function En(e,n){for(n&=~ia,n&=~Ui,e.suspendedLanes|=n,e.pingedLanes&=~n,e=e.expirationTimes;0<n;){var t=31-nn(n),r=1<<t;e[t]=-1,n&=~r}}function Es(e){if(Q&6)throw Error(b(327));St();var n=ci(e,0);if(!(n&1))return ze(e,le()),null;var t=Pi(e,n);if(e.tag!==0&&t===2){var r=Wl(e);r!==0&&(n=r,t=yo(e,r))}if(t===1)throw t=wr,Gn(e,0),En(e,n),ze(e,le()),t;if(t===6)throw Error(b(345));return e.finishedWork=e.current.alternate,e.finishedLanes=n,Hn(e,Te,fn),ze(e,le()),null}function oa(e,n){var t=Q;Q|=1;try{return e(n)}finally{Q=t,Q===0&&(Tt=le()+500,Di&&Bn())}}function et(e){Pn!==null&&Pn.tag===0&&!(Q&6)&&St();var n=Q;Q|=1;var t=Ge.transition,r=G;try{if(Ge.transition=null,G=1,e)return e()}finally{G=r,Ge.transition=t,Q=n,!(Q&6)&&Bn()}}function aa(){Me=gt.current,Z(gt)}function Gn(e,n){e.finishedWork=null,e.finishedLanes=0;var t=e.timeoutHandle;if(t!==-1&&(e.timeoutHandle=-1,op(t)),ae!==null)for(t=ae.return;t!==null;){var r=t;switch(Uo(r),r.tag){case 1:r=r.type.childContextTypes,r!=null&&hi();break;case 3:Pt(),Z(je),Z(Se),Xo();break;case 5:Yo(r);break;case 4:Pt();break;case 13:Z(J);break;case 19:Z(J);break;case 10:Vo(r.type._context);break;case 22:case 23:aa()}t=t.return}if(pe=e,ae=e=Mn(e.current,null),he=Me=n,ue=0,wr=null,ia=Ui=Jn=0,Te=er=null,Qn!==null){for(n=0;n<Qn.length;n++)if(t=Qn[n],r=t.interleaved,r!==null){t.interleaved=null;var i=r.next,l=t.pending;if(l!==null){var o=l.next;l.next=i,r.next=o}t.pending=r}Qn=null}return e}function Bc(e,n){do{var t=ae;try{if(Ho(),Jr.current=bi,Si){for(var r=ee.memoizedState;r!==null;){var i=r.queue;i!==null&&(i.pending=null),r=r.next}Si=!1}if(qn=0,fe=se=ee=null,qt=!1,vr=0,ra.current=null,t===null||t.return===null){ue=1,wr=n,ae=null;break}e:{var l=e,o=t.return,a=t,s=n;if(n=he,a.flags|=32768,s!==null&&typeof s=="object"&&typeof s.then=="function"){var d=s,x=a,h=x.tag;if(!(x.mode&1)&&(h===0||h===11||h===15)){var p=x.alternate;p?(x.updateQueue=p.updateQueue,x.memoizedState=p.memoizedState,x.lanes=p.lanes):(x.updateQueue=null,x.memoizedState=null)}var g=ps(o);if(g!==null){g.flags&=-257,ms(g,o,a,l,n),g.mode&1&&fs(l,d,n),n=g,s=d;var k=n.updateQueue;if(k===null){var _=new Set;_.add(s),n.updateQueue=_}else k.add(s);break e}else{if(!(n&1)){fs(l,d,n),sa();break e}s=Error(b(426))}}else if(q&&a.mode&1){var j=ps(o);if(j!==null){!(j.flags&65536)&&(j.flags|=256),ms(j,o,a,l,n),Bo(Nt(s,a));break e}}l=s=Nt(s,a),ue!==4&&(ue=2),er===null?er=[l]:er.push(l),l=o;do{switch(l.tag){case 3:l.flags|=65536,n&=-n,l.lanes|=n;var c=Cc(l,s,n);os(l,c);break e;case 1:a=s;var u=l.type,f=l.stateNode;if(!(l.flags&128)&&(typeof u.getDerivedStateFromError=="function"||f!==null&&typeof f.componentDidCatch=="function"&&(zn===null||!zn.has(f)))){l.flags|=65536,n&=-n,l.lanes|=n;var y=Ec(l,a,n);os(l,y);break e}}l=l.return}while(l!==null)}Vc(t)}catch(S){n=S,ae===t&&t!==null&&(ae=t=t.return);continue}break}while(!0)}function Wc(){var e=Ci.current;return Ci.current=bi,e===null?bi:e}function sa(){(ue===0||ue===3||ue===2)&&(ue=4),pe===null||!(Jn&268435455)&&!(Ui&268435455)||En(pe,he)}function Pi(e,n){var t=Q;Q|=2;var r=Wc();(pe!==e||he!==n)&&(fn=null,Gn(e,n));do try{Fp();break}catch(i){Bc(e,i)}while(!0);if(Ho(),Q=t,Ci.current=r,ae!==null)throw Error(b(261));return pe=null,he=0,ue}function Fp(){for(;ae!==null;)Hc(ae)}function jp(){for(;ae!==null&&!tf();)Hc(ae)}function Hc(e){var n=Kc(e.alternate,e,Me);e.memoizedProps=e.pendingProps,n===null?Vc(e):ae=n,ra.current=null}function Vc(e){var n=e;do{var t=n.alternate;if(e=n.return,n.flags&32768){if(t=Cp(t,n),t!==null){t.flags&=32767,ae=t;return}if(e!==null)e.flags|=32768,e.subtreeFlags=0,e.deletions=null;else{ue=6,ae=null;return}}else if(t=bp(t,n,Me),t!==null){ae=t;return}if(n=n.sibling,n!==null){ae=n;return}ae=n=e}while(n!==null);ue===0&&(ue=5)}function Hn(e,n,t){var r=G,i=Ge.transition;try{Ge.transition=null,G=1,Rp(e,n,t,r)}finally{Ge.transition=i,G=r}return null}function Rp(e,n,t,r){do St();while(Pn!==null);if(Q&6)throw Error(b(327));t=e.finishedWork;var i=e.finishedLanes;if(t===null)return null;if(e.finishedWork=null,e.finishedLanes=0,t===e.current)throw Error(b(177));e.callbackNode=null,e.callbackPriority=0;var l=t.lanes|t.childLanes;if(pf(e,l),e===pe&&(ae=pe=null,he=0),!(t.subtreeFlags&2064)&&!(t.flags&2064)||Wr||(Wr=!0,Gc(ui,function(){return St(),null})),l=(t.flags&15990)!==0,t.subtreeFlags&15990||l){l=Ge.transition,Ge.transition=null;var o=G;G=1;var a=Q;Q|=4,ra.current=null,$p(e,t),Ic(t,e),Jf(Yl),di=!!Gl,Yl=Gl=null,e.current=t,Pp(t),rf(),Q=a,G=o,Ge.transition=l}else e.current=t;if(Wr&&(Wr=!1,Pn=e,$i=i),l=e.pendingLanes,l===0&&(zn=null),af(t.stateNode),ze(e,le()),n!==null)for(r=e.onRecoverableError,t=0;t<n.length;t++)i=n[t],r(i.value,{componentStack:i.stack,digest:i.digest});if(Ei)throw Ei=!1,e=go,go=null,e;return $i&1&&e.tag!==0&&St(),l=e.pendingLanes,l&1?e===vo?nr++:(nr=0,vo=e):nr=0,Bn(),null}function St(){if(Pn!==null){var e=Cu($i),n=Ge.transition,t=G;try{if(Ge.transition=null,G=16>e?16:e,Pn===null)var r=!1;else{if(e=Pn,Pn=null,$i=0,Q&6)throw Error(b(331));var i=Q;for(Q|=4,F=e.current;F!==null;){var l=F,o=l.child;if(F.flags&16){var a=l.deletions;if(a!==null){for(var s=0;s<a.length;s++){var d=a[s];for(F=d;F!==null;){var x=F;switch(x.tag){case 0:case 11:case 15:Jt(8,x,l)}var h=x.child;if(h!==null)h.return=x,F=h;else for(;F!==null;){x=F;var p=x.sibling,g=x.return;if(Mc(x),x===d){F=null;break}if(p!==null){p.return=g,F=p;break}F=g}}}var k=l.alternate;if(k!==null){var _=k.child;if(_!==null){k.child=null;do{var j=_.sibling;_.sibling=null,_=j}while(_!==null)}}F=l}}if(l.subtreeFlags&2064&&o!==null)o.return=l,F=o;else e:for(;F!==null;){if(l=F,l.flags&2048)switch(l.tag){case 0:case 11:case 15:Jt(9,l,l.return)}var c=l.sibling;if(c!==null){c.return=l.return,F=c;break e}F=l.return}}var u=e.current;for(F=u;F!==null;){o=F;var f=o.child;if(o.subtreeFlags&2064&&f!==null)f.return=o,F=f;else e:for(o=u;F!==null;){if(a=F,a.flags&2048)try{switch(a.tag){case 0:case 11:case 15:Ai(9,a)}}catch(S){re(a,a.return,S)}if(a===o){F=null;break e}var y=a.sibling;if(y!==null){y.return=a.return,F=y;break e}F=a.return}}if(Q=i,Bn(),cn&&typeof cn.onPostCommitFiberRoot=="function")try{cn.onPostCommitFiberRoot(ji,e)}catch{}r=!0}return r}finally{G=t,Ge.transition=n}}return!1}function $s(e,n,t){n=Nt(t,n),n=Cc(e,n,1),e=Rn(e,n,1),n=$e(),e!==null&&(Sr(e,1,n),ze(e,n))}function re(e,n,t){if(e.tag===3)$s(e,e,t);else for(;n!==null;){if(n.tag===3){$s(n,e,t);break}else if(n.tag===1){var r=n.stateNode;if(typeof n.type.getDerivedStateFromError=="function"||typeof r.componentDidCatch=="function"&&(zn===null||!zn.has(r))){e=Nt(t,e),e=Ec(n,e,1),n=Rn(n,e,1),e=$e(),n!==null&&(Sr(n,1,e),ze(n,e));break}}n=n.return}}function zp(e,n,t){var r=e.pingCache;r!==null&&r.delete(n),n=$e(),e.pingedLanes|=e.suspendedLanes&t,pe===e&&(he&t)===t&&(ue===4||ue===3&&(he&130023424)===he&&500>le()-la?Gn(e,0):ia|=t),ze(e,n)}function Qc(e,n){n===0&&(e.mode&1?(n=Rr,Rr<<=1,!(Rr&130023424)&&(Rr=4194304)):n=1);var t=$e();e=xn(e,n),e!==null&&(Sr(e,n,t),ze(e,t))}function Lp(e){var n=e.memoizedState,t=0;n!==null&&(t=n.retryLane),Qc(e,t)}function Mp(e,n){var t=0;switch(e.tag){case 13:var r=e.stateNode,i=e.memoizedState;i!==null&&(t=i.retryLane);break;case 19:r=e.stateNode;break;default:throw Error(b(314))}r!==null&&r.delete(n),Qc(e,t)}var Kc;Kc=function(e,n,t){if(e!==null)if(e.memoizedProps!==n.pendingProps||je.current)Fe=!0;else{if(!(e.lanes&t)&&!(n.flags&128))return Fe=!1,Sp(e,n,t);Fe=!!(e.flags&131072)}else Fe=!1,q&&n.flags&1048576&&Zu(n,yi,n.index);switch(n.lanes=0,n.tag){case 2:var r=n.type;ni(e,n),e=n.pendingProps;var i=Ct(n,Se.current);_t(n,t),i=qo(null,n,r,e,i,t);var l=Jo();return n.flags|=1,typeof i=="object"&&i!==null&&typeof i.render=="function"&&i.$$typeof===void 0?(n.tag=1,n.memoizedState=null,n.updateQueue=null,Re(r)?(l=!0,gi(n)):l=!1,n.memoizedState=i.state!==null&&i.state!==void 0?i.state:null,Ko(n),i.updater=Ii,n.stateNode=i,i._reactInternals=n,io(n,r,e,t),n=ao(null,n,r,!0,l,t)):(n.tag=0,q&&l&&Ao(n),Ee(null,n,i,t),n=n.child),n;case 16:r=n.elementType;e:{switch(ni(e,n),e=n.pendingProps,i=r._init,r=i(r._payload),n.type=r,i=n.tag=Op(r),e=qe(r,e),i){case 0:n=oo(null,n,r,e,t);break e;case 1:n=vs(null,n,r,e,t);break e;case 11:n=hs(null,n,r,e,t);break e;case 14:n=gs(null,n,r,qe(r.type,e),t);break e}throw Error(b(306,r,""))}return n;case 0:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:qe(r,i),oo(e,n,r,i,t);case 1:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:qe(r,i),vs(e,n,r,i,t);case 3:e:{if(Tc(n),e===null)throw Error(b(387));r=n.pendingProps,l=n.memoizedState,i=l.element,rc(e,n),ki(n,r,null,t);var o=n.memoizedState;if(r=o.element,l.isDehydrated)if(l={element:r,isDehydrated:!1,cache:o.cache,pendingSuspenseBoundaries:o.pendingSuspenseBoundaries,transitions:o.transitions},n.updateQueue.baseState=l,n.memoizedState=l,n.flags&256){i=Nt(Error(b(423)),n),n=ys(e,n,r,t,i);break e}else if(r!==i){i=Nt(Error(b(424)),n),n=ys(e,n,r,t,i);break e}else for(Oe=jn(n.stateNode.containerInfo.firstChild),Ie=n,q=!0,en=null,t=nc(n,null,r,t),n.child=t;t;)t.flags=t.flags&-3|4096,t=t.sibling;else{if(Et(),r===i){n=wn(e,n,t);break e}Ee(e,n,r,t)}n=n.child}return n;case 5:return ic(n),e===null&&no(n),r=n.type,i=n.pendingProps,l=e!==null?e.memoizedProps:null,o=i.children,Xl(r,i)?o=null:l!==null&&Xl(r,l)&&(n.flags|=32),Nc(e,n),Ee(e,n,o,t),n.child;case 6:return e===null&&no(n),null;case 13:return Fc(e,n,t);case 4:return Go(n,n.stateNode.containerInfo),r=n.pendingProps,e===null?n.child=$t(n,null,r,t):Ee(e,n,r,t),n.child;case 11:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:qe(r,i),hs(e,n,r,i,t);case 7:return Ee(e,n,n.pendingProps,t),n.child;case 8:return Ee(e,n,n.pendingProps.children,t),n.child;case 12:return Ee(e,n,n.pendingProps.children,t),n.child;case 10:e:{if(r=n.type._context,i=n.pendingProps,l=n.memoizedProps,o=i.value,Y(xi,r._currentValue),r._currentValue=o,l!==null)if(rn(l.value,o)){if(l.children===i.children&&!je.current){n=wn(e,n,t);break e}}else for(l=n.child,l!==null&&(l.return=n);l!==null;){var a=l.dependencies;if(a!==null){o=l.child;for(var s=a.firstContext;s!==null;){if(s.context===r){if(l.tag===1){s=gn(-1,t&-t),s.tag=2;var d=l.updateQueue;if(d!==null){d=d.shared;var x=d.pending;x===null?s.next=s:(s.next=x.next,x.next=s),d.pending=s}}l.lanes|=t,s=l.alternate,s!==null&&(s.lanes|=t),to(l.return,t,n),a.lanes|=t;break}s=s.next}}else if(l.tag===10)o=l.type===n.type?null:l.child;else if(l.tag===18){if(o=l.return,o===null)throw Error(b(341));o.lanes|=t,a=o.alternate,a!==null&&(a.lanes|=t),to(o,t,n),o=l.sibling}else o=l.child;if(o!==null)o.return=l;else for(o=l;o!==null;){if(o===n){o=null;break}if(l=o.sibling,l!==null){l.return=o.return,o=l;break}o=o.return}l=o}Ee(e,n,i.children,t),n=n.child}return n;case 9:return i=n.type,r=n.pendingProps.children,_t(n,t),i=Ye(i),r=r(i),n.flags|=1,Ee(e,n,r,t),n.child;case 14:return r=n.type,i=qe(r,n.pendingProps),i=qe(r.type,i),gs(e,n,r,i,t);case 15:return $c(e,n,n.type,n.pendingProps,t);case 17:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:qe(r,i),ni(e,n),n.tag=1,Re(r)?(e=!0,gi(n)):e=!1,_t(n,t),bc(n,r,i),io(n,r,i,t),ao(null,n,r,!0,e,t);case 19:return jc(e,n,t);case 22:return Pc(e,n,t)}throw Error(b(156,n.tag))};function Gc(e,n){return ku(e,n)}function Dp(e,n,t,r){this.tag=e,this.key=t,this.sibling=this.child=this.return=this.stateNode=this.type=this.elementType=null,this.index=0,this.ref=null,this.pendingProps=n,this.dependencies=this.memoizedState=this.updateQueue=this.memoizedProps=null,this.mode=r,this.subtreeFlags=this.flags=0,this.deletions=null,this.childLanes=this.lanes=0,this.alternate=null}function Ke(e,n,t,r){return new Dp(e,n,t,r)}function ua(e){return e=e.prototype,!(!e||!e.isReactComponent)}function Op(e){if(typeof e=="function")return ua(e)?1:0;if(e!=null){if(e=e.$$typeof,e===Po)return 11;if(e===No)return 14}return 2}function Mn(e,n){var t=e.alternate;return t===null?(t=Ke(e.tag,n,e.key,e.mode),t.elementType=e.elementType,t.type=e.type,t.stateNode=e.stateNode,t.alternate=e,e.alternate=t):(t.pendingProps=n,t.type=e.type,t.flags=0,t.subtreeFlags=0,t.deletions=null),t.flags=e.flags&14680064,t.childLanes=e.childLanes,t.lanes=e.lanes,t.child=e.child,t.memoizedProps=e.memoizedProps,t.memoizedState=e.memoizedState,t.updateQueue=e.updateQueue,n=e.dependencies,t.dependencies=n===null?null:{lanes:n.lanes,firstContext:n.firstContext},t.sibling=e.sibling,t.index=e.index,t.ref=e.ref,t}function ii(e,n,t,r,i,l){var o=2;if(r=e,typeof e=="function")ua(e)&&(o=1);else if(typeof e=="string")o=5;else e:switch(e){case ot:return Yn(t.children,i,l,n);case $o:o=8,i|=8;break;case Pl:return e=Ke(12,t,n,i|2),e.elementType=Pl,e.lanes=l,e;case Nl:return e=Ke(13,t,n,i),e.elementType=Nl,e.lanes=l,e;case Tl:return e=Ke(19,t,n,i),e.elementType=Tl,e.lanes=l,e;case iu:return Bi(t,i,l,n);default:if(typeof e=="object"&&e!==null)switch(e.$$typeof){case tu:o=10;break e;case ru:o=9;break e;case Po:o=11;break e;case No:o=14;break e;case Sn:o=16,r=null;break e}throw Error(b(130,e==null?e:typeof e,""))}return n=Ke(o,t,n,i),n.elementType=e,n.type=r,n.lanes=l,n}function Yn(e,n,t,r){return e=Ke(7,e,r,n),e.lanes=t,e}function Bi(e,n,t,r){return e=Ke(22,e,r,n),e.elementType=iu,e.lanes=t,e.stateNode={isHidden:!1},e}function wl(e,n,t){return e=Ke(6,e,null,n),e.lanes=t,e}function kl(e,n,t){return n=Ke(4,e.children!==null?e.children:[],e.key,n),n.lanes=t,n.stateNode={containerInfo:e.containerInfo,pendingChildren:null,implementation:e.implementation},n}function Ip(e,n,t,r,i){this.tag=n,this.containerInfo=e,this.finishedWork=this.pingCache=this.current=this.pendingChildren=null,this.timeoutHandle=-1,this.callbackNode=this.pendingContext=this.context=null,this.callbackPriority=0,this.eventTimes=nl(0),this.expirationTimes=nl(-1),this.entangledLanes=this.finishedLanes=this.mutableReadLanes=this.expiredLanes=this.pingedLanes=this.suspendedLanes=this.pendingLanes=0,this.entanglements=nl(0),this.identifierPrefix=r,this.onRecoverableError=i,this.mutableSourceEagerHydrationData=null}function ca(e,n,t,r,i,l,o,a,s){return e=new Ip(e,n,t,a,s),n===1?(n=1,l===!0&&(n|=8)):n=0,l=Ke(3,null,null,n),e.current=l,l.stateNode=e,l.memoizedState={element:r,isDehydrated:t,cache:null,transitions:null,pendingSuspenseBoundaries:null},Ko(l),e}function Ap(e,n,t){var r=3<arguments.length&&arguments[3]!==void 0?arguments[3]:null;return{$$typeof:lt,key:r==null?null:""+r,children:e,containerInfo:n,implementation:t}}function Yc(e){if(!e)return In;e=e._reactInternals;e:{if(tt(e)!==e||e.tag!==1)throw Error(b(170));var n=e;do{switch(n.tag){case 3:n=n.stateNode.context;break e;case 1:if(Re(n.type)){n=n.stateNode.__reactInternalMemoizedMergedChildContext;break e}}n=n.return}while(n!==null);throw Error(b(171))}if(e.tag===1){var t=e.type;if(Re(t))return Yu(e,t,n)}return n}function Xc(e,n,t,r,i,l,o,a,s){return e=ca(t,r,!0,e,i,l,o,a,s),e.context=Yc(null),t=e.current,r=$e(),i=Ln(t),l=gn(r,i),l.callback=n??null,Rn(t,l,i),e.current.lanes=i,Sr(e,i,r),ze(e,r),e}function Wi(e,n,t,r){var i=n.current,l=$e(),o=Ln(i);return t=Yc(t),n.context===null?n.context=t:n.pendingContext=t,n=gn(l,o),n.payload={element:e},r=r===void 0?null:r,r!==null&&(n.callback=r),e=Rn(i,n,o),e!==null&&(tn(e,i,o,l),qr(e,i,o)),o}function Ni(e){if(e=e.current,!e.child)return null;switch(e.child.tag){case 5:return e.child.stateNode;default:return e.child.stateNode}}function Ps(e,n){if(e=e.memoizedState,e!==null&&e.dehydrated!==null){var t=e.retryLane;e.retryLane=t!==0&&t<n?t:n}}function da(e,n){Ps(e,n),(e=e.alternate)&&Ps(e,n)}function Up(){return null}var Zc=typeof reportError=="function"?reportError:function(e){console.error(e)};function fa(e){this._internalRoot=e}Hi.prototype.render=fa.prototype.render=function(e){var n=this._internalRoot;if(n===null)throw Error(b(409));Wi(e,n,null,null)};Hi.prototype.unmount=fa.prototype.unmount=function(){var e=this._internalRoot;if(e!==null){this._internalRoot=null;var n=e.containerInfo;et(function(){Wi(null,e,null,null)}),n[yn]=null}};function Hi(e){this._internalRoot=e}Hi.prototype.unstable_scheduleHydration=function(e){if(e){var n=Pu();e={blockedOn:null,target:e,priority:n};for(var t=0;t<Cn.length&&n!==0&&n<Cn[t].priority;t++);Cn.splice(t,0,e),t===0&&Tu(e)}};function pa(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11)}function Vi(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11&&(e.nodeType!==8||e.nodeValue!==" react-mount-point-unstable "))}function Ns(){}function Bp(e,n,t,r,i){if(i){if(typeof r=="function"){var l=r;r=function(){var d=Ni(o);l.call(d)}}var o=Xc(n,r,e,0,null,!1,!1,"",Ns);return e._reactRootContainer=o,e[yn]=o.current,fr(e.nodeType===8?e.parentNode:e),et(),o}for(;i=e.lastChild;)e.removeChild(i);if(typeof r=="function"){var a=r;r=function(){var d=Ni(s);a.call(d)}}var s=ca(e,0,!1,null,null,!1,!1,"",Ns);return e._reactRootContainer=s,e[yn]=s.current,fr(e.nodeType===8?e.parentNode:e),et(function(){Wi(n,s,t,r)}),s}function Qi(e,n,t,r,i){var l=t._reactRootContainer;if(l){var o=l;if(typeof i=="function"){var a=i;i=function(){var s=Ni(o);a.call(s)}}Wi(n,o,e,i)}else o=Bp(t,n,e,i,r);return Ni(o)}Eu=function(e){switch(e.tag){case 3:var n=e.stateNode;if(n.current.memoizedState.isDehydrated){var t=Ht(n.pendingLanes);t!==0&&(jo(n,t|1),ze(n,le()),!(Q&6)&&(Tt=le()+500,Bn()))}break;case 13:et(function(){var r=xn(e,1);if(r!==null){var i=$e();tn(r,e,1,i)}}),da(e,1)}};Ro=function(e){if(e.tag===13){var n=xn(e,134217728);if(n!==null){var t=$e();tn(n,e,134217728,t)}da(e,134217728)}};$u=function(e){if(e.tag===13){var n=Ln(e),t=xn(e,n);if(t!==null){var r=$e();tn(t,e,n,r)}da(e,n)}};Pu=function(){return G};Nu=function(e,n){var t=G;try{return G=e,n()}finally{G=t}};Al=function(e,n,t){switch(n){case"input":if(Rl(e,t),n=t.name,t.type==="radio"&&n!=null){for(t=e;t.parentNode;)t=t.parentNode;for(t=t.querySelectorAll("input[name="+JSON.stringify(""+n)+'][type="radio"]'),n=0;n<t.length;n++){var r=t[n];if(r!==e&&r.form===e.form){var i=Mi(r);if(!i)throw Error(b(90));ou(r),Rl(r,i)}}}break;case"textarea":su(e,t);break;case"select":n=t.value,n!=null&&yt(e,!!t.multiple,n,!1)}};hu=oa;gu=et;var Wp={usingClientEntryPoint:!1,Events:[Cr,ct,Mi,pu,mu,oa]},Ut={findFiberByHostInstance:Vn,bundleType:0,version:"18.3.1",rendererPackageName:"react-dom"},Hp={bundleType:Ut.bundleType,version:Ut.version,rendererPackageName:Ut.rendererPackageName,rendererConfig:Ut.rendererConfig,overrideHookState:null,overrideHookStateDeletePath:null,overrideHookStateRenamePath:null,overrideProps:null,overridePropsDeletePath:null,overridePropsRenamePath:null,setErrorHandler:null,setSuspenseHandler:null,scheduleUpdate:null,currentDispatcherRef:kn.ReactCurrentDispatcher,findHostInstanceByFiber:function(e){return e=xu(e),e===null?null:e.stateNode},findFiberByHostInstance:Ut.findFiberByHostInstance||Up,findHostInstancesForRefresh:null,scheduleRefresh:null,scheduleRoot:null,setRefreshHandler:null,getCurrentFiber:null,reconcilerVersion:"18.3.1-next-f1338f8080-20240426"};if(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__<"u"){var Hr=__REACT_DEVTOOLS_GLOBAL_HOOK__;if(!Hr.isDisabled&&Hr.supportsFiber)try{ji=Hr.inject(Hp),cn=Hr}catch{}}Ue.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Wp;Ue.createPortal=function(e,n){var t=2<arguments.length&&arguments[2]!==void 0?arguments[2]:null;if(!pa(n))throw Error(b(200));return Ap(e,n,null,t)};Ue.createRoot=function(e,n){if(!pa(e))throw Error(b(299));var t=!1,r="",i=Zc;return n!=null&&(n.unstable_strictMode===!0&&(t=!0),n.identifierPrefix!==void 0&&(r=n.identifierPrefix),n.onRecoverableError!==void 0&&(i=n.onRecoverableError)),n=ca(e,1,!1,null,null,t,!1,r,i),e[yn]=n.current,fr(e.nodeType===8?e.parentNode:e),new fa(n)};Ue.findDOMNode=function(e){if(e==null)return null;if(e.nodeType===1)return e;var n=e._reactInternals;if(n===void 0)throw typeof e.render=="function"?Error(b(188)):(e=Object.keys(e).join(","),Error(b(268,e)));return e=xu(n),e=e===null?null:e.stateNode,e};Ue.flushSync=function(e){return et(e)};Ue.hydrate=function(e,n,t){if(!Vi(n))throw Error(b(200));return Qi(null,e,n,!0,t)};Ue.hydrateRoot=function(e,n,t){if(!pa(e))throw Error(b(405));var r=t!=null&&t.hydratedSources||null,i=!1,l="",o=Zc;if(t!=null&&(t.unstable_strictMode===!0&&(i=!0),t.identifierPrefix!==void 0&&(l=t.identifierPrefix),t.onRecoverableError!==void 0&&(o=t.onRecoverableError)),n=Xc(n,null,e,1,t??null,i,!1,l,o),e[yn]=n.current,fr(e),r)for(e=0;e<r.length;e++)t=r[e],i=t._getVersion,i=i(t._source),n.mutableSourceEagerHydrationData==null?n.mutableSourceEagerHydrationData=[t,i]:n.mutableSourceEagerHydrationData.push(t,i);return new Hi(n)};Ue.render=function(e,n,t){if(!Vi(n))throw Error(b(200));return Qi(null,e,n,!1,t)};Ue.unmountComponentAtNode=function(e){if(!Vi(e))throw Error(b(40));return e._reactRootContainer?(et(function(){Qi(null,null,e,!1,function(){e._reactRootContainer=null,e[yn]=null})}),!0):!1};Ue.unstable_batchedUpdates=oa;Ue.unstable_renderSubtreeIntoContainer=function(e,n,t,r){if(!Vi(t))throw Error(b(200));if(e==null||e._reactInternals===void 0)throw Error(b(38));return Qi(e,n,t,!1,r)};Ue.version="18.3.1-next-f1338f8080-20240426";function qc(){if(!(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__>"u"||typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE!="function"))try{__REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(qc)}catch(e){console.error(e)}}qc(),qs.exports=Ue;var Vp=qs.exports,Ts=Vp;El.createRoot=Ts.createRoot,El.hydrateRoot=Ts.hydrateRoot;const Qp=`version: 0.3

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

  `,Kp=`version: 0.3


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
            settings{builderName=>button_custom} // override builder name (will use button2 programmable from std)
      }

      placeholder(generated(cross(200, 20)), builderParameter("disableCheckbox")) {
            pos: 10,100
      }
      text(dd, "Disabled Checkbox", #ffffff00): 30,100

      
      
}


 `,Gp=`version: 0.3


#ui programmable() {
      pos:100,300
      
      #checkboxVal(updatable) text(dd, "clickCheckbox", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 20)), builderParameter("checkbox")) {
            settings{checkboxBuildName=>checkbox2} // override builder name (will use checkbox2 programmable from std)
      }

      
      
}


 
`,Yp=`version: 0.3

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
            settings{checkboxBuildName=>checkbox2} // override builder name (will use checkbox2 programmable from std)
      }

      placeholder(generated(cross(200, 20)), builderParameter("checkbox2")) {
            pos:30,0
            settings{checkboxBuildName=>radio} 
      }
      placeholder(generated(cross(200, 20)), builderParameter("checkbox3")) {
            pos:60,0
            settings{checkboxBuildName=>radio2} 
      }
      placeholder(generated(cross(200, 20)), builderParameter("checkbox4")) {
            pos:90,0
            settings{checkboxBuildName=>tickbox} 
      }

      placeholder(generated(cross(200, 20)), builderParameter("checkbox5")) {
            pos:120,0
            settings{checkboxBuildName=>toggle} 
      }

      placeholder(generated(cross(200, 20)), builderParameter("scroll1")) {
            pos:400,100 
            settings{height=>200, topClearance=>60}   
      }
      placeholder(generated(cross(200, 20)), builderParameter("scroll2")):550,100;
      placeholder(generated(cross(200, 20)), builderParameter("scroll3")):700,100;
      
      placeholder(generated(cross(200, 20)), builderParameter("scroll4")):850,100;
      
      
      placeholder(generated(cross(200, 20)), builderParameter("checkboxWithLabel")) {
            pos:610,50;
            settings{font=>dd}
      }

      
      
}`,Xp=`version: 0.3


#dialogBase programmable() {
      pos:400,200

      ninepatch("ui", "Droppanel_3x3_idle", 550, 300): 0,0
      point {
        pos: 50,250
        placeholder(generated(cross(20, 20)), builderParameter("button1")) {
          settings{text=>"override specific placeholder"}
          
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

      



    `,Zp=`version: 0.3


#ui programmable() {
      pos:400,200
      
      #selectedFileText(updatable) text(dd, "No file selected", #ffffff00, center, 400): 0,50
      
      point {
      
        placeholder(generated(cross(20, 20)), builderParameter("openDialog1button"));
        placeholder(generated(cross(200, 20)), builderParameter("openDialog2button")):250,0;
        
      }
}


      



    `,qp=`version: 0.3





#ui programmable() {
    // Title
    text(dd, "Draggable Test Screen", #ffffff, center, 800): 0, 30
    
    // Drop zones
    rect(180, 180, #ffffff): 300, 300
    text(dd, "Drop Zone", #000000, center, 80): 400, 185
    
    rect(100, 60, red): 100, 100
    text(dd, "Zone 2", #ffffff, center, 100): 500, 185
} `,Jp=`version: 0.3

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



                

      

      
`,e0=`version: 0.3

relativeLayouts {
  #fontNames sequence($i: 1..40) point: 100, 20+20 * $i
  #fonts sequence($i: 1..40) point: 200, 20+20 * $i
}


`,n0=`version: 0.3



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
`,t0=`version: 0.3




paths {
  #line1 path {
    
    
    line(relative, 100,100)
    
    arc(100, -90)
    forward(20)
    arc(100, 180) 
    bezier(relative, -100,0, 50,200, smoothing:auto)
    
    arc(100, -180)
    arc(100, 180)
  }
  #line2 path {
turn(0)
forward(80)
turn(144)
forward(80)
turn(144)
forward(80)
turn(144)
forward(80)
turn(144)
forward(80)
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
    line(absolute, 100,100)
    line(absolute, 500,0)
    line(absolute, 0,500)
    line(absolute, 0,0)
    
  }
  #testModes path {
    line(relative, 100, 50)
    line(absolute, 200, 100)
    line(300, 150) // default relative
    bezier(relative, 100, 50, 75, 25)
    bezier(absolute, 200, 100, 150, 50)
    bezier(100, 50, 75, 25) // default relative
    bezier(absolute, 300, 150, 250, 75, smoothing: auto)
    bezier(relative, 100, 50, 75, 25, smoothing: none)
    bezier(100, 50, 75, 25, smoothing: 20)
    bezier(absolute, 400, 200, 350, 100, 300, 150)
    bezier(relative, 100, 50, 75, 25, 50, 75)
    bezier(100, 50, 75, 25, 50, 75)
    bezier(absolute, 500, 250, 450, 125, 400, 200, smoothing: auto)
    bezier(relative, 100, 50, 75, 25, 50, 75, smoothing: none)
    bezier(100, 50, 75, 25, 50, 75, smoothing: 30)
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
  
  0.05: accelerate (200, 5000)
  0.1: attachParticles("test") {
      count:30
      relative: true
      speed:500
      loop: false
      emit: cone(5,5, $angle+180, 1)
      tiles:  sheet("fx", "missile/particle") 
  }

    0.1: attachParticles("test") {
      count:120
      relative: true
      loop: false
      speed:500
      emit: cone(5,5, $angle+90, 1)
      tiles:  sheet("fx", "missile/particle") 
  }
}`,r0=`version: 0.3

#ui programmable() {
    // 0,0 -> 10,10 rect
    pixels (
            rect 0,0, 10,10, #fff
        ):-30, 150

    grid: 200, 250
    pos:30,-150
    hex:pointy(10, 10)

    // Squares (20x20)
    point {
        pos: grid(0, 1)
        pixels (
            rect 0,0, 20,20, #00f
            rect 1,1, 9,9, #f0f
            rect 10,1, 9,9, #0f0
            rect 1,10, 9,9, #0ff
            rect 10,10, 9,9, #fff
        ) {
            scale: 5
            pos: 0, 0
        }
        text(pixellari, "Squares (20x20), scale 5", #00f, left, grid): 0, -40
    }

    // Single pixels (red, green, blue)
    point {
        pos: grid(1, 1)
        pixels (
            pixel 0,0, #f00
            pixel 1,1, #0f0
            pixel 2,2, #00f
        ) {
            scale: 8
            pos: 0, 0
        }
        text(pixellari, "3 pixels, scale 8", #fff, left, grid): 0, -40
    }

    // Hexagon using hexCorner
    point {
        pos: grid(2, 1)
        pixels (
            line hexCorner(0, 1.1), hexCorner(1, 1.1), #f00
            line hexCorner(1, 1.1), hexCorner(2, 1.1), #0f0
            line hexCorner(2, 1.1), hexCorner(3, 1.1), #00f
            line hexCorner(3, 1.1), hexCorner(4, 1.1), #ff0
            line hexCorner(4, 1.1), hexCorner(5, 1.1), #f0f
            line hexCorner(5, 1.1), hexCorner(0, 1.1), #fff
        ) {
            scale: 4
            pos: 0, 0
        }
        text(pixellari, "Hexagon using hexCorner, scale 4", #0f0, left, grid): 0, -40
    }

    // Cross (20x20)
    point {
        pos: grid(3, 1)
        pixels (
            line -10,0, 10,0, #f00
            line 0,-10, 0,10, #f00
            pixel 0,0, #fff
        ) {
            scale: 4
            pos: 20, 20
        }
        text(pixellari, "Cross (20x20) with white center pixel, scale 4", #f00, left, grid): 0, -40
    }

    // Single yellow pixel
    point {
        pos: grid(4, 1)
        pixels (
            pixel 0,0, #ff0
        ) {
            scale: 16
            pos: 0, 0
        }
        text(pixellari, "Single yellow pixel, scale 16", #ff0, left, grid): 0, -40
    }

    // Diagonal lines (1px)
    point {
        pos: grid(0, 2)
        pixels (
            line 0,0, 20,20, #f00
            line 1,0, 21,20, #ff0
        ) {
            scale: 4
            pos: 0, 0
        }
        text(pixellari, "2 diagonal lines (1px), scale 4", #ff0, left, grid): 0, -40
    }

    
    point {
        pos: grid(1, 2)
        pixels (
            rect 0,0, 1,40, #fff
            rect 0,0, 40,1, #fff
            rect 39,0, 1,40, #fff
            rect 0,39, 40,1, #fff
        ) {
            scale: 4
            pos: 0, 0
        }
        text(pixellari, "1px border at edges (40x40)", #fff, left, grid): 0, -40
    }

    
    point {
        pos: grid(2, 2)
        repeatable($i, grid(10, dx:10, dy:10)) {
            pixels (
                rect 0,0, 5,5, #fff
            ) {
                scale: 2
                pos:0,20
                
            }
        }
        text(pixellari, "Pixel grid: 10 white squares, 5x5 spaced 10px diagonally", #fff, left, grid): 0, -40
    }

    // Checkerboard 4x4 (1px)
    point {
        pos: grid(3, 2)
        // White squares
        repeatable($y, range(1, 10)) {
            repeatable($x, range(1,10)) {
                pixels (
                    rect 0,0, 5,5, #fff
                ) {
                    scale: 3
                    pos: $x*15, $y*15
                }
            }
        }
        
        text(pixellari, "10x10 checkerboard, 5x5 squares, scale 3", #fff, left, grid): 0, -40
    }

    
    point {
        pos: grid(4, 2)
        
        point {
        pixels (
            pixel 0,0, red
        ) {
            scale: 1
            pos: 0, 0
        }
        pixels (
            pixel 2,1, green
        ) {
            scale: 1
            pos: -1, -1
        }

        pixels (
            rect -10,-10, 1,1, blue
        ) {
            scale: 1
            pos: 12, 10
        }

        pixels (
            pixel 11,1, orange
        ) {
            scale: 1
            pos: -11+3, -1
        }



            scale:16
        }

        text(pixellari, "positioning pixels, scale 16", white, left, grid): 0, -40
    }

    
    point {
        pos: grid(5, 2)
        // "/" direction (bottom-left to top-right)
        repeatable($i, range(0, 9)) {
            pixels (
                line 0, $i*10, 100, $i*10+100, #0ff
            ) {
                scale: 1
                pos: 0, 0
            }
        }
        // "\\" direction (top-left to bottom-right)
        repeatable($i, range(0, 9)) {
            pixels (
                line 0, $i*10+100, 100, $i*10, #0ff
            ) {
                scale: 1
                pos: 0, 0
            }
        }
        text(pixellari, "Criss-crossed lines at 45deg, 10 in each direction", #0ff, left, grid): 0, -40
    }

    // Pixel staircase (1x1 px, offset 10px)
    point {
        pos: grid(0, 3)
        repeatable($i, grid(10, dx:10, dy:10)) {
            pixels (
                pixel 0,0, #ff0
            ) {
                scale: 10
                pos: $i, $i
            }
        }
        text(pixellari, "Pixel staircase (1x1 px, offset 10px)", #ff0, left, grid): 0, -40
    }
} `,i0=`version: 0.3


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



    `,l0=`version: 0.3


#ui programmable() {
      pos:100,300
      
      #listVal(updatable) text(dd, "Select an item from the list!", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 150)), builderParameter("scrollableList")) {
            pos: 10,80
            settings{panelBuilder=>list-panel, itemBuilder=>list-item-120} // use standard list components
      }

      
      
}


`,o0=`version: 0.3

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


      



    `,a0=`version: 0.3


#ui programmable() {
      pos:100,300
      
      #sliderVal(updatable) text(dd, "move slider", #ffffff00): 10,50
      
      placeholder(generated(cross(200, 20)), builderParameter("slider")) {
            pos:10,30
      }

      
      
}`,s0=`version: 0.3


relativeLayouts {
    #statusBar point:1000,2
    
    #checkboxes list {
        point: 3,3
        point: 400,300
        point: 400,400
        point: 10,20
    }
    #statesDropdowns sequence($i:0..30) point: $i*150+60, 2
    #animStates sequence($i:0..30) point: 10+(($i % 6)*200), 700 - 30*($i div 6)

}


#ui programmable() {
      
      point {
            pos:10, 40
            grid:1,20
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
                  text(pixellari, "Show states", white):30,5;
            }
            #animCommandsCheckbox point {
                  pos: grid(0,3)
                  text(dd, "Show commands", #ddd): 30, 5
                  placeholder(generated(cross(20, 20)), builderParameter("animCommands"));
            }

            
      }
      
      placeholder(generated(cross(20, 20)), builderParameter("load")):780,0;
      
      text(dd, "States", #ffffffff, html:true): 2, 10
      

      #spriteText(updatable) text(pixellari, "sprite", #ffffff00, center, 100, html:true): 1280/2,720/2

      text(m6x11, "Current frames",  white, left, 400, html:true): 10,140
      #currentStatesText(updatable) text(pixellari, "status",  #ffa0a080, left, 400, html:true): 10,160
      text(m6x11, "Commands",  white, left, 400): 1000,40
      #commandsText(updatable) text(pixellari, "status",  #ffa0a080, left, 400, html:true): 1000,60

      #sprite point:1280/2,720/2
      placeholder(generated(cross(150, 20)), builderParameter("speedSlider")) {
            pos: 300, 60
            text(dd, "Anim. speed", #ffffffff): 0, -20
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


`,u0=`version: 0.3

      #main palette {
      0x1a1a1a  0x2c5f7c  0x4a90a4  0x7fdbda  0xff7f50  0xff4444  0x4caf50  0xffeb3b  0xffffff  0x666666  0xb0b0b0  0x000000
      }

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
      settings{transitionTimer=>.2}
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
        settings{height=>20}
}

#list-panel programmable(width:uint=200, height:uint=200, topClearance:uint = 0) {
  
  ninepatch("ui", "Window_3x3_idle", $width+4, $height+8+$topClearance): -2,-4-$topClearance
  placeholder(generated(cross($width, $height)), builderParameter("mask")):0,0
  #scrollbar @layer(100) point: $width - 4, 0
}

#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint = 0) {

ninepatch("ui", "scrollbar-1", 4, $panelHeight * $panelHeight / $scrollableHeight): 0, $scrollPosition*$panelHeight/$scrollableHeight
  settings{scrollSpeed=>250}
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
}`,c0=`sheet: crew2
allowedExtraPoints: ["point", "text"]
center: 64,64


animation {
    name: dir0
    fps:10
    loop
    playlist {
            sheet: "Arrow_dir0"
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

`,d0=`sheet: crew2
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


`,f0=`sheet: crew2
allowedExtraPoints: [fire, targeting]
states: direction(l, r)
center: 32,48


animation {
    name: idle
    fps:4
    loop: yes
    playlist {
        sheet: "marine_$$direction$$_idle"
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
    loop: yes
    playlist {
        sheet: marine_$$direction$$_hit
        event hit random 0,-10, 10
    }
}


animation {
    name: killed
    fps:20
    playlist {
        sheet: marine_$$direction$$_killed
    }
}

animation {
    name: dead
    fps:1
    loop: yes
    playlist {
        sheet: marine_$$direction$$_dead
    }
}

animation {
    name: stand
    fps:1
    loop: yes
    playlist {
        sheet: marine_$$direction$$_standing
    }
}



animation {
    name: dodge
    fps:4
    playlist {
        sheet: marine_$$direction$$_dodging_$$direction$$ frames: 0..3
    }
}

`,p0=`sheet: crew2
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



`,m0=`sheet: crew2
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

`,h0=Object.assign({"../public/assets/atlas-test.manim":Qp,"../public/assets/button.manim":Kp,"../public/assets/checkbox.manim":Gp,"../public/assets/components.manim":Yp,"../public/assets/dialog-base.manim":Xp,"../public/assets/dialog-start.manim":Zp,"../public/assets/draggable.manim":qp,"../public/assets/examples1.manim":Jp,"../public/assets/fonts.manim":e0,"../public/assets/particles.manim":n0,"../public/assets/paths.manim":t0,"../public/assets/pixels.manim":r0,"../public/assets/room1.manim":i0,"../public/assets/scrollable-list.manim":l0,"../public/assets/settings.manim":o0,"../public/assets/slider.manim":a0,"../public/assets/stateanim.manim":s0,"../public/assets/std.manim":u0}),g0=Object.assign({"../public/assets/arrows.anim":c0,"../public/assets/dice.anim":d0,"../public/assets/marine.anim":f0,"../public/assets/shield.anim":p0,"../public/assets/turret.anim":m0}),ma=Object.fromEntries([...Object.entries(h0).map(([e,n])=>[e.split("/").pop(),n]),...Object.entries(g0).map(([e,n])=>[e.split("/").pop(),n])]),_l=e=>ma[e]||null,tr=(e,n)=>{ma[e]=n},v0=e=>e in ma;class y0{constructor(){Ce(this,"screens",[{name:"scrollableList",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",manimFile:"scrollable-list.manim"},{name:"button",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",manimFile:"button.manim"},{name:"checkbox",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",manimFile:"checkbox.manim"},{name:"slider",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",manimFile:"slider.manim"},{name:"particles",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",manimFile:"particles.manim"},{name:"pixels",displayName:"Pixels",description:"Pixel art and static pixel demo screen.",manimFile:"pixels.manim"},{name:"components",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",manimFile:"components.manim"},{name:"examples1",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",manimFile:"examples1.manim"},{name:"paths",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",manimFile:"paths.manim"},{name:"fonts",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",manimFile:"fonts.manim"},{name:"room1",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",manimFile:"room1.manim"},{name:"stateAnim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",manimFile:"stateanim.manim"},{name:"dialogStart",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",manimFile:"dialog-start.manim"},{name:"settings",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",manimFile:"settings.manim"},{name:"atlasTest",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",manimFile:"atlas-test.manim"},{name:"draggable",displayName:"Draggable Test",description:"Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.",manimFile:"draggable.manim"}]);Ce(this,"manimFiles",[{filename:"scrollable-list.manim",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",content:null},{filename:"button.manim",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",content:null},{filename:"checkbox.manim",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",content:null},{filename:"slider.manim",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",content:null},{filename:"examples1.manim",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",content:null},{filename:"components.manim",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",content:null},{filename:"dialog-base.manim",displayName:"Dialog Base",description:"Dialog system foundation with base dialog layouts, text rendering, and dialog-specific animations and transitions.",content:null},{filename:"dialog-start.manim",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",content:null},{filename:"fonts.manim",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",content:null},{filename:"particles.manim",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",content:null},{filename:"pixels.manim",displayName:"Pixels",description:"Pixel art and static pixel demo screen.",content:null},{filename:"paths.manim",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",content:null},{filename:"room1.manim",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",content:null},{filename:"settings.manim",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",content:null},{filename:"stateanim.manim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",content:null},{filename:"std.manim",displayName:"Standard Library",description:"Standard library components and utilities for hx-multianim including common animations, effects, and helper functions.",content:null},{filename:"draggable.manim",displayName:"Draggable Test",description:"Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.",content:null},{filename:"atlas-test.manim",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",content:null}]);Ce(this,"animFiles",[{filename:"arrows.anim",content:null},{filename:"dice.anim",content:null},{filename:"marine.anim",content:null},{filename:"shield.anim",content:null},{filename:"turret.anim",content:null}]);Ce(this,"currentFile",null);Ce(this,"currentExample",null);Ce(this,"reloadTimeout",null);Ce(this,"reloadDelay",1e3);Ce(this,"mainApp",null);Ce(this,"baseUrl","");this.init()}init(){this.setupFileLoader(),this.loadFilesFromMap(),this.waitForMainApp()}loadFilesFromMap(){this.manimFiles.forEach(n=>{const t=_l(n.filename);t&&(n.content=t)}),this.animFiles.forEach(n=>{const t=_l(n.filename);t&&(n.content=t)})}waitForMainApp(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?this.mainApp=window.PlaygroundMain.instance:setTimeout(()=>this.waitForMainApp(),100)}setupFileLoader(){this.baseUrl=typeof window<"u"&&window.location?window.location.href:"",window.FileLoader={baseUrl:this.baseUrl,resolveUrl:n=>this.resolveUrl(n),load:n=>this.loadFile(n),stringToArrayBuffer:this.stringToArrayBuffer}}resolveUrl(n){if(n.startsWith("http://")||n.startsWith("https://")||n.startsWith("//")||n.startsWith("file://")||!this.baseUrl)return n;try{return new URL(n,this.baseUrl).href}catch{const r=this.baseUrl.endsWith("/")?this.baseUrl:this.baseUrl+"/",i=n.startsWith("/")?n.substring(1):n;return r+i}}stringToArrayBuffer(n){const t=new ArrayBuffer(n.length),r=new Uint8Array(t);for(let i=0,l=n.length;i<l;i++)r[i]=n.charCodeAt(i);return t}loadFile(n){const t=this.extractFilenameFromUrl(n);if(t&&v0(t)){const l=_l(t);if(l)return this.stringToArrayBuffer(l)}if(typeof window.hxd<"u"&&window.hxd.res&&window.hxd.res.load)try{const l=window.hxd.res.load(n);if(l&&l.entry&&l.entry.getBytes){const o=l.entry.getBytes();return this.stringToArrayBuffer(o.toString())}}catch{}const r=this.resolveUrl(n),i=new XMLHttpRequest;return i.open("GET",r,!1),i.send(),i.status===200?this.stringToArrayBuffer(i.response):new ArrayBuffer(0)}extractFilenameFromUrl(n){const r=n.split("?")[0].split("#")[0].split("/"),i=r[r.length-1];return i&&(i.endsWith(".manim")||i.endsWith(".anim")||i.endsWith(".png")||i.endsWith(".atlas2")||i.endsWith(".fnt")||i.endsWith(".tps"))?i:null}onContentChanged(n){if(this.currentFile){const t=this.manimFiles.find(i=>i.filename===this.currentFile);t&&(t.content=n,tr(this.currentFile,n));const r=this.animFiles.find(i=>i.filename===this.currentFile);r&&(r.content=n,tr(this.currentFile,n))}this.reloadTimeout&&clearTimeout(this.reloadTimeout),this.reloadTimeout=setTimeout(()=>{this.reloadPlayground()},this.reloadDelay)}reloadPlayground(n){var r;let t=n;if(!t){const i=document.getElementById("screen-selector");t=i?i.value:"particles"}if((r=window.PlaygroundMain)!=null&&r.instance)try{const i=window.PlaygroundMain.instance.reload(t,!0);return console.log("PlaygroundLoader reload result:",i),console.log("Result type:",typeof i),console.log("Result keys:",i?Object.keys(i):"null"),i&&i.__nativeException&&console.log("Error in reload result:",i.__nativeException),i}catch(i){return console.log("Exception during reload:",i),{__nativeException:i}}return null}getCurrentContent(){const n=document.getElementById("manim-textarea");return n?n.value:""}getCurrentFile(){return this.currentFile}getEditedContent(n){const t=this.manimFiles.find(i=>i.filename===n);if(t)return t.content;const r=this.animFiles.find(i=>i.filename===n);return r?r.content:null}updateContent(n,t){const r=this.manimFiles.find(l=>l.filename===n);r&&(r.content=t);const i=this.animFiles.find(l=>l.filename===n);i&&(i.content=t),tr(n,t)}dispose(){this.mainApp&&typeof this.mainApp.dispose=="function"&&this.mainApp.dispose()}static getDefaultScreen(){return li}}function x0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Fs(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function js(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Fs(Object(t),!0).forEach(function(r){x0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Fs(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function w0(e,n){if(e==null)return{};var t={},r=Object.keys(e),i,l;for(l=0;l<r.length;l++)i=r[l],!(n.indexOf(i)>=0)&&(t[i]=e[i]);return t}function k0(e,n){if(e==null)return{};var t=w0(e,n),r,i;if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(i=0;i<l.length;i++)r=l[i],!(n.indexOf(r)>=0)&&Object.prototype.propertyIsEnumerable.call(e,r)&&(t[r]=e[r])}return t}function _0(e,n){return S0(e)||b0(e,n)||C0(e,n)||E0()}function S0(e){if(Array.isArray(e))return e}function b0(e,n){if(!(typeof Symbol>"u"||!(Symbol.iterator in Object(e)))){var t=[],r=!0,i=!1,l=void 0;try{for(var o=e[Symbol.iterator](),a;!(r=(a=o.next()).done)&&(t.push(a.value),!(n&&t.length===n));r=!0);}catch(s){i=!0,l=s}finally{try{!r&&o.return!=null&&o.return()}finally{if(i)throw l}}return t}}function C0(e,n){if(e){if(typeof e=="string")return Rs(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);if(t==="Object"&&e.constructor&&(t=e.constructor.name),t==="Map"||t==="Set")return Array.from(e);if(t==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return Rs(e,n)}}function Rs(e,n){(n==null||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function E0(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function $0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function zs(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Ls(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?zs(Object(t),!0).forEach(function(r){$0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):zs(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function P0(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];return function(r){return n.reduceRight(function(i,l){return l(i)},r)}}function Qt(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),s=0;s<o;s++)a[s]=arguments[s];return n.apply(t,[].concat(i,a))}}}function Ti(e){return{}.toString.call(e).includes("Object")}function N0(e){return!Object.keys(e).length}function kr(e){return typeof e=="function"}function T0(e,n){return Object.prototype.hasOwnProperty.call(e,n)}function F0(e,n){return Ti(n)||Dn("changeType"),Object.keys(n).some(function(t){return!T0(e,t)})&&Dn("changeField"),n}function j0(e){kr(e)||Dn("selectorType")}function R0(e){kr(e)||Ti(e)||Dn("handlerType"),Ti(e)&&Object.values(e).some(function(n){return!kr(n)})&&Dn("handlersType")}function z0(e){e||Dn("initialIsRequired"),Ti(e)||Dn("initialType"),N0(e)&&Dn("initialContent")}function L0(e,n){throw new Error(e[n]||e.default)}var M0={initialIsRequired:"initial state is required",initialType:"initial state should be an object",initialContent:"initial state shouldn't be an empty object",handlerType:"handler should be an object or a function",handlersType:"all handlers should be a functions",selectorType:"selector should be a function",changeType:"provided value of changes should be an object",changeField:'it seams you want to change a field in the state which is not specified in the "initial" state',default:"an unknown error accured in `state-local` package"},Dn=Qt(L0)(M0),Vr={changes:F0,selector:j0,handler:R0,initial:z0};function D0(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};Vr.initial(e),Vr.handler(n);var t={current:e},r=Qt(A0)(t,n),i=Qt(I0)(t),l=Qt(Vr.changes)(e),o=Qt(O0)(t);function a(){var d=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(x){return x};return Vr.selector(d),d(t.current)}function s(d){P0(r,i,l,o)(d)}return[a,s]}function O0(e,n){return kr(n)?n(e.current):n}function I0(e,n){return e.current=Ls(Ls({},e.current),n),n}function A0(e,n,t){return kr(n)?n(e.current):Object.keys(t).forEach(function(r){var i;return(i=n[r])===null||i===void 0?void 0:i.call(n,e.current[r])}),t}var U0={create:D0},B0={paths:{vs:"https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs"}};function W0(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),s=0;s<o;s++)a[s]=arguments[s];return n.apply(t,[].concat(i,a))}}}function H0(e){return{}.toString.call(e).includes("Object")}function V0(e){return e||Ms("configIsRequired"),H0(e)||Ms("configType"),e.urls?(Q0(),{paths:{vs:e.urls.monacoBase}}):e}function Q0(){console.warn(Jc.deprecation)}function K0(e,n){throw new Error(e[n]||e.default)}var Jc={configIsRequired:"the configuration object is required",configType:"the configuration object should be an object",default:"an unknown error accured in `@monaco-editor/loader` package",deprecation:`Deprecation warning!
    You are using deprecated way of configuration.

    Instead of using
      monaco.config({ urls: { monacoBase: '...' } })
    use
      monaco.config({ paths: { vs: '...' } })

    For more please check the link https://github.com/suren-atoyan/monaco-loader#config
  `},Ms=W0(K0)(Jc),G0={config:V0},Y0=function(){for(var n=arguments.length,t=new Array(n),r=0;r<n;r++)t[r]=arguments[r];return function(i){return t.reduceRight(function(l,o){return o(l)},i)}};function ed(e,n){return Object.keys(n).forEach(function(t){n[t]instanceof Object&&e[t]&&Object.assign(n[t],ed(e[t],n[t]))}),js(js({},e),n)}var X0={type:"cancelation",msg:"operation is manually canceled"};function Sl(e){var n=!1,t=new Promise(function(r,i){e.then(function(l){return n?i(X0):r(l)}),e.catch(i)});return t.cancel=function(){return n=!0},t}var Z0=U0.create({config:B0,isInitialized:!1,resolve:null,reject:null,monaco:null}),nd=_0(Z0,2),$r=nd[0],Ki=nd[1];function q0(e){var n=G0.config(e),t=n.monaco,r=k0(n,["monaco"]);Ki(function(i){return{config:ed(i.config,r),monaco:t}})}function J0(){var e=$r(function(n){var t=n.monaco,r=n.isInitialized,i=n.resolve;return{monaco:t,isInitialized:r,resolve:i}});if(!e.isInitialized){if(Ki({isInitialized:!0}),e.monaco)return e.resolve(e.monaco),Sl(bl);if(window.monaco&&window.monaco.editor)return td(window.monaco),e.resolve(window.monaco),Sl(bl);Y0(em,tm)(rm)}return Sl(bl)}function em(e){return document.body.appendChild(e)}function nm(e){var n=document.createElement("script");return e&&(n.src=e),n}function tm(e){var n=$r(function(r){var i=r.config,l=r.reject;return{config:i,reject:l}}),t=nm("".concat(n.config.paths.vs,"/loader.js"));return t.onload=function(){return e()},t.onerror=n.reject,t}function rm(){var e=$r(function(t){var r=t.config,i=t.resolve,l=t.reject;return{config:r,resolve:i,reject:l}}),n=window.require;n.config(e.config),n(["vs/editor/editor.main"],function(t){td(t),e.resolve(t)},function(t){e.reject(t)})}function td(e){$r().monaco||Ki({monaco:e})}function im(){return $r(function(e){var n=e.monaco;return n})}var bl=new Promise(function(e,n){return Ki({resolve:e,reject:n})}),rd={config:q0,init:J0,__getMonacoInstance:im},lm={wrapper:{display:"flex",position:"relative",textAlign:"initial"},fullWidth:{width:"100%"},hide:{display:"none"}},Cl=lm,om={container:{display:"flex",height:"100%",width:"100%",justifyContent:"center",alignItems:"center"}},am=om;function sm({children:e}){return de.createElement("div",{style:am.container},e)}var um=sm,cm=um;function dm({width:e,height:n,isEditorReady:t,loading:r,_ref:i,className:l,wrapperProps:o}){return de.createElement("section",{style:{...Cl.wrapper,width:e,height:n},...o},!t&&de.createElement(cm,null,r),de.createElement("div",{ref:i,style:{...Cl.fullWidth,...!t&&Cl.hide},className:l}))}var fm=dm,id=$.memo(fm);function pm(e){$.useEffect(e,[])}var ld=pm;function mm(e,n,t=!0){let r=$.useRef(!0);$.useEffect(r.current||!t?()=>{r.current=!1}:e,n)}var De=mm;function rr(){}function vt(e,n,t,r){return hm(e,r)||gm(e,n,t,r)}function hm(e,n){return e.editor.getModel(od(e,n))}function gm(e,n,t,r){return e.editor.createModel(n,t,r?od(e,r):void 0)}function od(e,n){return e.Uri.parse(n)}function vm({original:e,modified:n,language:t,originalLanguage:r,modifiedLanguage:i,originalModelPath:l,modifiedModelPath:o,keepCurrentOriginalModel:a=!1,keepCurrentModifiedModel:s=!1,theme:d="light",loading:x="Loading...",options:h={},height:p="100%",width:g="100%",className:k,wrapperProps:_={},beforeMount:j=rr,onMount:c=rr}){let[u,f]=$.useState(!1),[y,S]=$.useState(!0),m=$.useRef(null),E=$.useRef(null),C=$.useRef(null),O=$.useRef(c),T=$.useRef(j),te=$.useRef(!1);ld(()=>{let M=rd.init();return M.then(K=>(E.current=K)&&S(!1)).catch(K=>(K==null?void 0:K.type)!=="cancelation"&&console.error("Monaco initialization: error:",K)),()=>m.current?ve():M.cancel()}),De(()=>{if(m.current&&E.current){let M=m.current.getOriginalEditor(),K=vt(E.current,e||"",r||t||"text",l||"");K!==M.getModel()&&M.setModel(K)}},[l],u),De(()=>{if(m.current&&E.current){let M=m.current.getModifiedEditor(),K=vt(E.current,n||"",i||t||"text",o||"");K!==M.getModel()&&M.setModel(K)}},[o],u),De(()=>{let M=m.current.getModifiedEditor();M.getOption(E.current.editor.EditorOption.readOnly)?M.setValue(n||""):n!==M.getValue()&&(M.executeEdits("",[{range:M.getModel().getFullModelRange(),text:n||"",forceMoveMarkers:!0}]),M.pushUndoStop())},[n],u),De(()=>{var M,K;(K=(M=m.current)==null?void 0:M.getModel())==null||K.original.setValue(e||"")},[e],u),De(()=>{let{original:M,modified:K}=m.current.getModel();E.current.editor.setModelLanguage(M,r||t||"text"),E.current.editor.setModelLanguage(K,i||t||"text")},[t,r,i],u),De(()=>{var M;(M=E.current)==null||M.editor.setTheme(d)},[d],u),De(()=>{var M;(M=m.current)==null||M.updateOptions(h)},[h],u);let We=$.useCallback(()=>{var be;if(!E.current)return;T.current(E.current);let M=vt(E.current,e||"",r||t||"text",l||""),K=vt(E.current,n||"",i||t||"text",o||"");(be=m.current)==null||be.setModel({original:M,modified:K})},[t,n,i,e,r,l,o]),He=$.useCallback(()=>{var M;!te.current&&C.current&&(m.current=E.current.editor.createDiffEditor(C.current,{automaticLayout:!0,...h}),We(),(M=E.current)==null||M.editor.setTheme(d),f(!0),te.current=!0)},[h,d,We]);$.useEffect(()=>{u&&O.current(m.current,E.current)},[u]),$.useEffect(()=>{!y&&!u&&He()},[y,u,He]);function ve(){var K,be,N,L;let M=(K=m.current)==null?void 0:K.getModel();a||((be=M==null?void 0:M.original)==null||be.dispose()),s||((N=M==null?void 0:M.modified)==null||N.dispose()),(L=m.current)==null||L.dispose()}return de.createElement(id,{width:g,height:p,isEditorReady:u,loading:x,_ref:C,className:k,wrapperProps:_})}var ym=vm;$.memo(ym);function xm(e){let n=$.useRef();return $.useEffect(()=>{n.current=e},[e]),n.current}var wm=xm,Qr=new Map;function km({defaultValue:e,defaultLanguage:n,defaultPath:t,value:r,language:i,path:l,theme:o="light",line:a,loading:s="Loading...",options:d={},overrideServices:x={},saveViewState:h=!0,keepCurrentModel:p=!1,width:g="100%",height:k="100%",className:_,wrapperProps:j={},beforeMount:c=rr,onMount:u=rr,onChange:f,onValidate:y=rr}){let[S,m]=$.useState(!1),[E,C]=$.useState(!0),O=$.useRef(null),T=$.useRef(null),te=$.useRef(null),We=$.useRef(u),He=$.useRef(c),ve=$.useRef(),M=$.useRef(r),K=wm(l),be=$.useRef(!1),N=$.useRef(!1);ld(()=>{let z=rd.init();return z.then(D=>(O.current=D)&&C(!1)).catch(D=>(D==null?void 0:D.type)!=="cancelation"&&console.error("Monaco initialization: error:",D)),()=>T.current?A():z.cancel()}),De(()=>{var D,oe,ye,Le;let z=vt(O.current,e||r||"",n||i||"",l||t||"");z!==((D=T.current)==null?void 0:D.getModel())&&(h&&Qr.set(K,(oe=T.current)==null?void 0:oe.saveViewState()),(ye=T.current)==null||ye.setModel(z),h&&((Le=T.current)==null||Le.restoreViewState(Qr.get(l))))},[l],S),De(()=>{var z;(z=T.current)==null||z.updateOptions(d)},[d],S),De(()=>{!T.current||r===void 0||(T.current.getOption(O.current.editor.EditorOption.readOnly)?T.current.setValue(r):r!==T.current.getValue()&&(N.current=!0,T.current.executeEdits("",[{range:T.current.getModel().getFullModelRange(),text:r,forceMoveMarkers:!0}]),T.current.pushUndoStop(),N.current=!1))},[r],S),De(()=>{var D,oe;let z=(D=T.current)==null?void 0:D.getModel();z&&i&&((oe=O.current)==null||oe.editor.setModelLanguage(z,i))},[i],S),De(()=>{var z;a!==void 0&&((z=T.current)==null||z.revealLine(a))},[a],S),De(()=>{var z;(z=O.current)==null||z.editor.setTheme(o)},[o],S);let L=$.useCallback(()=>{var z;if(!(!te.current||!O.current)&&!be.current){He.current(O.current);let D=l||t,oe=vt(O.current,r||e||"",n||i||"",D||"");T.current=(z=O.current)==null?void 0:z.editor.create(te.current,{model:oe,automaticLayout:!0,...d},x),h&&T.current.restoreViewState(Qr.get(D)),O.current.editor.setTheme(o),a!==void 0&&T.current.revealLine(a),m(!0),be.current=!0}},[e,n,t,r,i,l,d,x,h,o,a]);$.useEffect(()=>{S&&We.current(T.current,O.current)},[S]),$.useEffect(()=>{!E&&!S&&L()},[E,S,L]),M.current=r,$.useEffect(()=>{var z,D;S&&f&&((z=ve.current)==null||z.dispose(),ve.current=(D=T.current)==null?void 0:D.onDidChangeModelContent(oe=>{N.current||f(T.current.getValue(),oe)}))},[S,f]),$.useEffect(()=>{if(S){let z=O.current.editor.onDidChangeMarkers(D=>{var ye;let oe=(ye=T.current.getModel())==null?void 0:ye.uri;if(oe&&D.find(Le=>Le.path===oe.path)){let Le=O.current.editor.getModelMarkers({resource:oe});y==null||y(Le)}});return()=>{z==null||z.dispose()}}return()=>{}},[S,y]);function A(){var z,D;(z=ve.current)==null||z.dispose(),p?h&&Qr.set(l,T.current.saveViewState()):(D=T.current.getModel())==null||D.dispose(),T.current.dispose()}return de.createElement(id,{width:g,height:k,isEditorReady:S,loading:s,_ref:te,className:_,wrapperProps:j})}var _m=km,Sm=$.memo(_m),bm=Sm;const Cm=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{include:"#keywords"}],Em={keywords:{patterns:[{name:"entity.name.class",match:"\\b(sheet|allowedExtraPoints|states|center)\\b"},{name:"keyword",match:"\\b(animation)\\b"},{name:"entity.name.type",match:"\\b(name|fps|playlist|sheet|extrapoints|playlist|loop|event|goto|hit|random|trigger|command|frames|untilCommand|duration|file)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},$m={patterns:Cm,repository:Em},Pm=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{name:"variable.name",match:"\\$[A-Za-z][A-Za-z0-9]*"},{name:"entity.name.tag",match:"#[A-Za-z][A-Za-z0-9\\-]*\\b"},{begin:"(@|@if|@ifstrict)\\(",beginCaptures:{0:{name:"keyword.control.at-sign"}},end:"\\)",endCaptures:{0:{name:"keyword.control.parenthesis"}},name:"meta.condition-block",contentName:"meta.condition-content",patterns:[{match:"\\b([A-Za-z_][A-Za-z0-9_]*)\\s*=>",name:"meta.condition-pair",captures:{0:{name:"keyword.other"},1:{name:"variable.other.key"}}},{match:"([A-Za-z_][A-Za-z0-9_]*)",name:"constant.other.value"},{match:",",name:"punctuation.separator.comma"}]},{name:"entity.name.method",match:"\\b@[A-Za-z][A-Za-z0-9]*\\b"},{include:"#keywords"}],Nm={keywords:{patterns:[{name:"entity.name.class",match:"\\b(animatedPath|particles|programmable|stateanim|flow|apply|text|tilegroup|repeatable|ninepatch|layers|placeholder|reference|bitmap|point|interactive|pixels|relativeLayouts|palettes|paths)\\b"},{name:"keyword",match:"\\b(external|path|debug|version|nothing|list|line|flat|pointy|layer|layout|callback|builderParam|tileSource|sheet|file|generated|hex|hexCorner|hexEdge|grid|settings|pos|alpha|blendMode|scale|updatable|cross|function|gridWidth|gridHeight|center|left|right|top|bottom|offset|construct|palette|position|import|filter)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},Tm={patterns:Pm,repository:Nm},Ds=e=>{const n={root:[]};return e.patterns&&e.patterns.forEach(t=>{if(t.include){const r=t.include.replace("#","");e.repository&&e.repository[r]&&e.repository[r].patterns.forEach(l=>{l.match&&n.root.push([new RegExp(l.match),l.name||"identifier"])})}else t.match&&n.root.push([new RegExp(t.match),t.name||"identifier"])}),e.repository&&Object.keys(e.repository).forEach(t=>{const r=e.repository[t];r.patterns&&(n[t]=r.patterns.map(i=>i.match?[new RegExp(i.match),i.name||"identifier"]:["",""]).filter(([i])=>i!==""))}),n},ad=$.forwardRef(({value:e,onChange:n,language:t="haxe-manim",disabled:r=!1,placeholder:i,onSave:l,errorLine:o,errorColumn:a,errorStart:s,errorEnd:d},x)=>{const h=$.useRef(null),p=$.useRef(),g=$.useRef([]);$.useEffect(()=>{p.current=l},[l]),$.useEffect(()=>{if(h.current&&(g.current.length>0&&(h.current.deltaDecorations(g.current,[]),g.current=[]),o)){const j=[];if(j.push({range:{startLineNumber:o,startColumn:1,endLineNumber:o,endColumn:1},options:{isWholeLine:!0,className:"error-line",glyphMarginClassName:"error-glyph",linesDecorationsClassName:"error-line-decoration"}}),s!==void 0&&d!==void 0){const c=h.current.getModel();if(c)try{const u=c.getPositionAt(s),f=c.getPositionAt(d);j.push({range:{startLineNumber:u.lineNumber,startColumn:u.column,endLineNumber:f.lineNumber,endColumn:f.column},options:{className:"error-token",hoverMessage:{value:"Parse error at this position"}}})}catch(u){console.log("Error calculating character position:",u)}}g.current=h.current.deltaDecorations([],j)}},[o,a,s,d]);const k=(j,c)=>{h.current=j,c.languages.register({id:"haxe-anim"}),c.languages.register({id:"haxe-manim"});const u=Ds($m);c.languages.setMonarchTokensProvider("haxe-anim",{tokenizer:u});const f=Ds(Tm);c.languages.setMonarchTokensProvider("haxe-manim",{tokenizer:f}),c.languages.registerCompletionItemProvider("haxe-manim",{provideCompletionItems:(y,S)=>{const m=y.getWordUntilPosition(S),E={startLineNumber:S.lineNumber,endLineNumber:S.lineNumber,startColumn:m.startColumn,endColumn:m.endColumn};return{suggestions:[{label:"programmable",kind:c.languages.CompletionItemKind.Snippet,insertText:"#${1:name} programmable(${2:param}:${3:type}=${4:default}) {\n  ${5:element}(${6:params}): ${7:0,0}\n}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Create a new programmable element",detail:"Programmable template"},{label:"bitmap",kind:c.languages.CompletionItemKind.Snippet,insertText:"bitmap(${1:source}): ${2:0,0}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Display an image",detail:"Bitmap element"},{label:"text",kind:c.languages.CompletionItemKind.Snippet,insertText:'text(${1:font}, "${2:text}", ${3:0xFFFFFF}): ${4:0,0}',insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Display text with font and color",detail:"Text element"},{label:"ninepatch",kind:c.languages.CompletionItemKind.Snippet,insertText:"ninepatch(${1:sheet}, ${2:tile}, ${3:width}, ${4:height}): ${5:0,0}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"9-patch scalable element",detail:"Ninepatch element"},{label:"button",kind:c.languages.CompletionItemKind.Snippet,insertText:"#${1:buttonName} programmable(state:[normal,hover,pressed]=normal) {\n  @(state=>normal) bitmap(${2:normalSprite}): 0,0\n  @(state=>hover) bitmap(${3:hoverSprite}): 0,0\n  @(state=>pressed) bitmap(${4:pressedSprite}): 0,0\n}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Create a button with hover/pressed states",detail:"Button pattern"},{label:"checkbox",kind:c.languages.CompletionItemKind.Snippet,insertText:"#${1:checkboxName} programmable(checked:bool=false) {\n  @(checked=>false) bitmap(${2:uncheckedSprite}): 0,0\n  @(checked=>true) bitmap(${3:checkedSprite}): 0,0\n}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Create a checkbox component",detail:"Checkbox pattern"},{label:"slider",kind:c.languages.CompletionItemKind.Snippet,insertText:"#${1:sliderName} programmable(value:int=50, min:int=0, max:int=100) {\n  ninepatch(${2:sheet}, ${3:trackTile}, 200, 10): 0,0\n  bitmap(${4:handleSprite}): $value*2,0\n}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Create a slider component",detail:"Slider pattern"},{label:"placeholder",kind:c.languages.CompletionItemKind.Snippet,insertText:"placeholder(${1:32,32}, ${2:source}): ${3:0,0}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Dynamic placeholder element",detail:"Placeholder element"},{label:"reference",kind:c.languages.CompletionItemKind.Snippet,insertText:"reference($${1:ref}): ${2:0,0}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Reference another programmable",detail:"Reference element"},{label:"layers",kind:c.languages.CompletionItemKind.Snippet,insertText:`layers() {
  \${1:element}: 0,0
}`,insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Z-ordering container",detail:"Layers container"},{label:"repeatable",kind:c.languages.CompletionItemKind.Snippet,insertText:"repeatable($${1:var}, ${2:iterator}) {\n  ${3:element}: grid($${1:var}, 0)\n}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Loop elements",detail:"Repeatable element"},{label:"conditional",kind:c.languages.CompletionItemKind.Snippet,insertText:"@(${1:param}=>${2:value}) ${3:element}: ${4:0,0}",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Conditional element display",detail:"Conditional"},{label:"outline",kind:c.languages.CompletionItemKind.Snippet,insertText:"outline(${1:color}, ${2:size})",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Add outline filter",detail:"Outline filter"},{label:"glow",kind:c.languages.CompletionItemKind.Snippet,insertText:"glow(${1:color}, ${2:size}, ${3:strength})",insertTextRules:c.languages.CompletionItemInsertTextRule.InsertAsSnippet,documentation:"Add glow filter",detail:"Glow filter"}].map(O=>({...O,range:E}))}}}),j.addAction({id:"save-file",label:"Save File",keybindings:[c.KeyMod.CtrlCmd|c.KeyCode.KeyS],run:()=>{p.current&&p.current()}}),j.focus()},_=j=>{j!==void 0&&n(j)};return v.jsxs("div",{ref:x,className:"w-full h-full min-h-[200px] border border-zinc-700 rounded overflow-hidden",style:{minHeight:200},children:[v.jsx("style",{children:`
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
        `}),v.jsx(bm,{height:"100%",language:t,value:e,onChange:_,onMount:k,options:{readOnly:r,minimap:{enabled:!1},scrollBeyondLastLine:!1,fontSize:12,fontFamily:'Consolas, Monaco, "Courier New", monospace',lineNumbers:"on",roundedSelection:!1,scrollbar:{vertical:"visible",horizontal:"visible",verticalScrollbarSize:8,horizontalScrollbarSize:8},automaticLayout:!0,wordWrap:"on",theme:"vs-dark",tabSize:2,insertSpaces:!0,detectIndentation:!1,trimAutoWhitespace:!0,largeFileOptimizations:!1,placeholder:i,suggest:{showKeywords:!0,showSnippets:!0,showClasses:!0,showFunctions:!0,showVariables:!0},quickSuggestions:{other:!0,comments:!1,strings:!1}},theme:"vs-dark"})]})});ad.displayName="CodeEditor";const li="draggable",Fm=1500,ha="playground_",jm=e=>{try{return localStorage.getItem(`${ha}${e}`)}catch(n){return console.warn("Failed to read from localStorage:",n),null}},Rm=(e,n)=>{try{localStorage.setItem(`${ha}${e}`,n)}catch(t){console.warn("Failed to write to localStorage:",t)}},Os=e=>{try{localStorage.removeItem(`${ha}${e}`)}catch(n){console.warn("Failed to remove from localStorage:",n)}};function zm(){var ka;const[e,n]=$.useState(li),[t,r]=$.useState(""),[i,l]=$.useState(""),[o,a]=$.useState(!1),[s,d]=$.useState(""),[x,h]=$.useState(!1),[p,g]=$.useState(null),[k,_]=$.useState(null),[j,c]=$.useState(!0),[u,f]=$.useState(!1),[y,S]=$.useState(!1),[m]=$.useState(()=>new y0),E=$.useRef(null),[C,O]=$.useState(250),[T,te]=$.useState(400),[We,He]=$.useState(600),[ve,M]=$.useState("playground"),[K,be]=$.useState([]),N=$.useRef(null),L=$.useRef(null),A=$.useRef(null),z=$.useRef(!1),D=$.useRef("");$.useEffect(()=>{p&&M("console")},[p]),$.useEffect(()=>{j&&k&&_(null)},[j,k]),$.useEffect(()=>{const w=console.log,P=console.error,U=console.warn,H=console.info,ie=(V,...B)=>{const R=B.map(I=>{var xe;if(typeof I=="object")try{return JSON.stringify(I,null,2)}catch{return((xe=I.toString)==null?void 0:xe.call(I))||"[Circular Object]"}return String(I)}).join(" ");be(I=>[...I,{type:V,message:R,timestamp:new Date}].slice(-1e3))};return console.log=(...V)=>{w(...V),ie("log",...V)},console.error=(...V)=>{P(...V),ie("error",...V)},console.warn=(...V)=>{U(...V),ie("warn",...V)},console.info=(...V)=>{H(...V),ie("info",...V)},()=>{console.log=w,console.error=P,console.warn=U,console.info=H}},[]),$.useEffect(()=>{N.current&&(N.current.scrollTop=N.current.scrollHeight)},[K]);const oe=()=>{be([])},ye=de.useMemo(()=>{const w=new Map;return m.screens.forEach(P=>{P.manimFile&&w.set(P.manimFile,P.name)}),w},[m.screens]),Le=de.useCallback(w=>{if(!w.endsWith(".manim")){_(null);return}const P=ye.get(w);P&&P!==e?j?(n(P),m.reloadPlayground(P)):_({file:w,screen:P}):_(null)},[ye,e,j,m]),ln=de.useMemo(()=>({scrollableList:"ScrollableListTestScreen.hx",button:"ButtonTestScreen.hx",checkbox:"CheckboxTestScreen.hx",slider:"SliderTestScreen.hx",particles:"ParticlesScreen.hx",components:"ComponentsTestScreen.hx",examples1:"Examples1Screen.hx",paths:"PathsScreen.hx",fonts:"FontsScreen.hx",room1:"Room1Screen.hx",stateAnim:"StateAnimScreen.hx",dialogStart:"DialogStartScreen.hx",settings:"SettingsScreen.hx",atlasTest:"AtlasTestScreen.hx",draggable:"DraggableTestScreen.hx"}),[]),rt=de.useCallback(w=>ln[w]||`${w.charAt(0).toUpperCase()+w.slice(1)}Screen.hx`,[ln]),cd=()=>{k&&(n(k.screen),_(null),m.reloadPlayground(k.screen))},ga=()=>{_(null)},dd=w=>{switch(w){case"error":return"❌";case"warn":return"⚠️";case"info":return"ℹ️";default:return"📋"}},fd=w=>{switch(w){case"error":return"text-red-400";case"warn":return"text-yellow-400";case"info":return"text-blue-400";default:return"text-gray-300"}};$.useEffect(()=>{const w=()=>{var U;(U=window.PlaygroundMain)!=null&&U.defaultScreen&&n(window.PlaygroundMain.defaultScreen)};w();const P=setTimeout(w,100);return()=>clearTimeout(P)},[]),$.useEffect(()=>(window.playgroundLoader=m,window.defaultScreen=li,m.onContentChanged=w=>{l(w)},()=>{m.dispose()}),[m]);const Gi=de.useCallback(()=>{var w,P,U,H,ie,V;if(e)try{const B=m.reloadPlayground(e);if(B&&B.__nativeException){const R=B.__nativeException,I={message:R.message||((w=R.toString)==null?void 0:w.call(R))||"Unknown error occurred",pos:(P=R.value)==null?void 0:P.pos,token:(U=R.value)==null?void 0:U.token};g(I)}else if(B&&B.value&&B.value.__nativeException){const R=B.value.__nativeException,I={message:R.message||((H=R.toString)==null?void 0:H.call(R))||"Unknown error occurred",pos:(ie=R.value)==null?void 0:ie.pos,token:(V=R.value)==null?void 0:V.token};g(I)}else if(B&&B.error){const R={message:B.error||"Unknown error occurred",pos:B.pos,token:B.token};g(R)}else if(B&&!B.success){const R={message:B.error||"Operation failed",pos:B.pos,token:B.token};g(R)}else g(null)}catch(B){let R="Unknown error occurred";try{if(B instanceof Error)R=B.message;else if(typeof B=="string")R=B;else if(B&&typeof B=="object"){const xe=B;xe.message?R=xe.message:xe.toString?R=xe.toString():R="Error occurred"}}catch{R="Error occurred (could not serialize)"}g({message:R,pos:void 0,token:void 0})}},[e,m]);$.useEffect(()=>{if(m.manimFiles.length>0&&e){const w=m.screens.find(P=>P.name===e);if(w&&w.manimFile){const P=m.manimFiles.find(U=>U.filename===w.manimFile);P&&(r(w.manimFile),l(P.content||""),d(P.description),a(!0),m.currentFile=w.manimFile,m.currentExample=w.manimFile,h(!1),Gi())}}},[m.manimFiles,e]),$.useEffect(()=>{const w=m.screens.find(P=>P.name===e);if(w&&w.manimFile){const P=m.manimFiles.find(U=>U.filename===w.manimFile);P&&(r(w.manimFile),l(P.content||""),d(P.description),a(!0),m.currentFile=w.manimFile,m.currentExample=w.manimFile,h(!1),Gi())}},[e,m]);const pd=()=>{if(t&&m.manimFiles.find(w=>w.filename===t))return t;if(e&&m.manimFiles.length>0){const w=m.screens.find(U=>U.name===e);if(w&&w.manimFile){const U=m.manimFiles.find(H=>H.filename===w.manimFile);if(U)return r(w.manimFile),(!i||i.trim()==="")&&l(U.content||""),d(U.description),a(!0),m.currentFile=w.manimFile,m.currentExample=w.manimFile,w.manimFile}const P=m.manimFiles[0];return r(P.filename),(!i||i.trim()==="")&&l(P.content||""),d(P.description),a(!0),m.currentFile=P.filename,m.currentExample=P.filename,P.filename}if(m.manimFiles.length>0){const w=m.manimFiles[0];return r(w.filename),m.currentFile=w.filename,m.currentExample=w.filename,w.filename}return null},md=w=>{const P=w.target.value;n(P),_(null),S(!0);try{m.reloadPlayground(P)}finally{setTimeout(()=>S(!1),100)}},va=de.useMemo(()=>{const w=new Map;return m.manimFiles.forEach(P=>{w.set(P.filename,P)}),w},[m.manimFiles]),ya=de.useMemo(()=>{const w=new Map;return m.animFiles.forEach(P=>{w.set(P.filename,P)}),w},[m.animFiles]),xa=de.useCallback(w=>{const P=w.target.value;if(r(P),P){const U=jm(P);if(P.endsWith(".manim")){const H=va.get(P);if(H){const ie=U||H.content||"",V=U!==null&&U!==H.content;l(ie),d(H.description),a(!0),m.currentFile=P,m.currentExample=P,h(V),Le(P)}}else if(P.endsWith(".anim")){const H=ya.get(P);if(H){const ie=U||H.content||"",V=U!==null&&U!==H.content;l(ie),d("Animation file - content loaded and available to playground"),a(!0),m.currentFile=P,m.currentExample=P,h(V),_(null)}}}else l(""),a(!1),m.currentFile=null,m.currentExample=null,h(!1),_(null)},[va,ya,Le,m]),hd=de.useCallback(w=>{l(w),h(!0),t&&Rm(t,w)},[t]);$.useEffect(()=>{if(!(!u||!x||!t))return E.current&&clearTimeout(E.current),E.current=setTimeout(()=>{t&&i&&(m.updateContent(t,i),tr(t,i),h(!1),Os(t),e&&m.reloadPlayground(e))},Fm),()=>{E.current&&clearTimeout(E.current)}},[u,x,i,t,e,m]);const wa=de.useCallback(()=>{var P,U,H,ie,V,B;const w=pd();if(w&&(m.updateContent(w,i),tr(w,i),h(!1),Os(w),e))try{const R=m.reloadPlayground(e);if(R&&R.__nativeException){const I=R.__nativeException,xe={message:I.message||((P=I.toString)==null?void 0:P.call(I))||"Unknown error occurred",pos:(U=I.value)==null?void 0:U.pos,token:(H=I.value)==null?void 0:H.token};g(xe)}else if(R&&R.value&&R.value.__nativeException){const I=R.value.__nativeException,xe={message:I.message||((ie=I.toString)==null?void 0:ie.call(I))||"Unknown error occurred",pos:(V=I.value)==null?void 0:V.pos,token:(B=I.value)==null?void 0:B.token};g(xe)}else if(R&&R.error){const I={message:R.error||"Unknown error occurred",pos:R.pos,token:R.token};g(I)}else if(R&&!R.success){const I={message:R.error||"Operation failed",pos:R.pos,token:R.token};g(I)}else g(null)}catch(R){let I="Unknown error occurred";try{if(R instanceof Error)I=R.message;else if(typeof R=="string")I=R;else if(R&&typeof R=="object"){const on=R;on.message?I=on.message:on.toString?I=on.toString():I="Error occurred"}}catch{I="Error occurred (could not serialize)"}g({message:I,pos:void 0,token:void 0})}},[t,i,e,m]),ce=de.useMemo(()=>{if(!(p!=null&&p.pos))return null;const{pmin:w,pmax:P}=p.pos,U=i;if(w<0||U.length===0)return{line:1,column:1,start:0,end:Math.max(0,P)};const H=Math.min(w,U.length);let ie=1,V=1;for(let B=0;B<H;B++)U[B]===`
`?(ie++,V=1):V++;return{line:ie,column:V,start:w,end:P}},[p==null?void 0:p.pos,i]),Yi=w=>P=>{z.current=!0,D.current=w,P.preventDefault()};return $.useEffect(()=>{const w=U=>{if(z.current){if(D.current==="file"){const H=U.clientX;H>150&&H<window.innerWidth-300&&O(H)}else if(D.current==="editor"){const H=U.clientX-C;H>200&&H<window.innerWidth-C-200&&te(H)}else if(D.current==="playground"){const H=window.innerWidth-C-T-2,ie=C+T+2,V=U.clientX-ie,B=200,R=H-200;V>B&&V<R&&He(V)}}},P=()=>{z.current=!1,D.current=""};return document.addEventListener("mousemove",w),document.addEventListener("mouseup",P),()=>{document.removeEventListener("mousemove",w),document.removeEventListener("mouseup",P)}},[C,T]),$.useEffect(()=>{window.PlaygroundMain||(window.PlaygroundMain={}),window.PlaygroundMain.defaultScreen=li},[]),$.useEffect(()=>{i&&e&&Gi()},[i,e]),$.useEffect(()=>{function w(P){if(P.error&&P.error.message&&P.error.message.includes("unexpected MP")){const U=P.error.message.match(/at ([^:]+):(\d+): characters (\d+)-(\d+)/);let H;if(U){const ie=parseInt(U[2],10),V=parseInt(U[3],10),B=parseInt(U[4],10),R=i.split(`
`);let I=0;for(let on=0;on<ie-1;on++)I+=R[on].length+1;I+=V;let xe=I+(B-V);H={psource:"",pmin:I,pmax:xe}}g({message:P.error.message,pos:H,token:void 0}),M("console")}}return window.addEventListener("error",w),()=>window.removeEventListener("error",w)},[i]),v.jsxs("div",{className:"flex h-screen w-screen bg-gray-900 text-white",children:[v.jsxs("div",{ref:L,className:"bg-gray-800 border-r border-gray-700 flex flex-col",style:{width:C},children:[v.jsxs("div",{className:"p-4 border-b border-gray-700",children:[v.jsxs("div",{className:"mb-4",children:[v.jsx("label",{className:"block mb-2 text-xs font-medium text-gray-300",children:"Screen:"}),v.jsx("select",{id:"screen-selector",className:"w-full p-2 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500",value:e,onChange:md,children:m.screens.map(w=>v.jsx("option",{value:w.name,children:w.displayName},w.name))})]}),o&&v.jsxs("div",{className:"p-3 bg-gray-700 border border-gray-600 rounded h-20 overflow-y-auto overflow-x-hidden",children:[v.jsx("p",{className:"text-xs text-gray-300 leading-relaxed mb-2",children:s}),v.jsxs("a",{href:`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${rt(e)}`,target:"_blank",rel:"noopener noreferrer",className:"text-xs text-blue-400 hover:text-blue-300 transition-colors",children:["📖 View ",e," Screen on GitHub"]})]})]}),v.jsx("div",{className:"flex-1 p-4",children:v.jsxs("div",{className:"text-xs text-gray-400",children:[v.jsx("div",{className:"mb-2",children:v.jsx("span",{className:"font-medium",children:"📁 Files:"})}),v.jsxs("div",{className:"space-y-1 scrollable",style:{maxHeight:"calc(100vh - 300px)"},children:[m.manimFiles.map(w=>v.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===w.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>xa({target:{value:w.filename}}),children:["📄 ",w.filename]},w.filename)),m.animFiles.map(w=>v.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===w.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>xa({target:{value:w.filename}}),children:["🎬 ",w.filename]},w.filename))]})]})})]}),v.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Yi("file")}),v.jsxs("div",{ref:A,className:"bg-gray-900 flex flex-col",style:{width:T},children:[v.jsxs("div",{className:"p-4 border-b border-gray-700",children:[v.jsxs("div",{className:"flex items-center justify-between mb-2",children:[v.jsxs("div",{className:"flex items-center space-x-4",children:[v.jsx("h2",{className:"text-base font-semibold text-gray-200",children:"Editor"}),v.jsxs("label",{className:"flex items-center space-x-2 text-xs text-gray-300",children:[v.jsx("input",{type:"checkbox",checked:j,onChange:w=>c(w.target.checked),className:"w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"}),v.jsx("span",{children:"Auto sync screen"})]}),v.jsxs("label",{className:"flex items-center space-x-2 text-xs text-gray-300",children:[v.jsx("input",{type:"checkbox",checked:u,onChange:w=>f(w.target.checked),className:"w-3 h-3 text-green-600 bg-gray-700 border-gray-600 rounded focus:ring-green-500 focus:ring-1"}),v.jsx("span",{children:"Auto-save"})]})]}),x&&v.jsx("button",{className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition",onClick:wa,title:"Save changes and reload playground (Ctrl+S)",children:"💾 Apply Changes"})]}),x&&!p&&v.jsx("div",{className:"text-xs text-orange-400 mb-2",children:'⚠️ Unsaved changes - Click "Apply Changes" to save and reload'}),p&&v.jsxs("div",{className:"p-3 bg-red-900/20 border border-red-700 rounded mb-2",children:[v.jsxs("div",{className:"flex justify-between items-start mb-2",children:[v.jsx("div",{className:"font-bold text-red-400 text-xs",children:"❌ Parse Error:"}),v.jsx("button",{className:"text-red-300 hover:text-red-100 text-xs",onClick:()=>g(null),title:"Clear error",children:"✕"})]}),v.jsx("div",{className:"text-red-300 text-xs mb-1",children:p.message}),ce&&v.jsxs("div",{className:"text-red-400 text-xs",children:["Line ",ce.line,", Column ",ce.column]})]})]}),v.jsx("div",{className:"flex-1 scrollable",children:v.jsx(ad,{value:i,onChange:hd,language:t!=null&&t.endsWith(".anim")?"haxe-anim":"haxe-manim",disabled:!t,placeholder:"Select a manim file to load its content here...",onSave:wa,errorLine:ce==null?void 0:ce.line,errorColumn:ce==null?void 0:ce.column,errorStart:ce==null?void 0:ce.start,errorEnd:ce==null?void 0:ce.end})}),k&&v.jsxs("div",{className:"p-3 bg-blue-900/20 border-t border-blue-700",children:[v.jsxs("div",{className:"flex justify-between items-start mb-2",children:[v.jsx("div",{className:"font-bold text-blue-400",children:"🔄 Screen Sync:"}),v.jsx("button",{className:"text-blue-300 hover:text-blue-100",onClick:ga,title:"Dismiss",children:"✕"})]}),v.jsxs("div",{className:"text-blue-300 mb-3",children:["Switch to ",v.jsx("strong",{children:((ka=m.screens.find(w=>w.name===k.screen))==null?void 0:ka.displayName)||k.screen})," screen to match ",v.jsx("strong",{children:k.file}),"?"]}),v.jsxs("div",{className:"flex space-x-2",children:[v.jsx("button",{onClick:cd,className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded transition-colors",children:"✅ Switch Screen"}),v.jsx("button",{onClick:ga,className:"px-3 py-1 bg-gray-600 hover:bg-gray-700 text-white text-sm rounded transition-colors",children:"❌ Keep Current"})]})]})]}),v.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Yi("editor")}),v.jsxs("div",{className:"flex-1 bg-gray-900 flex flex-col h-full min-h-0",children:[v.jsx("div",{className:"border-b border-gray-700 flex-shrink-0",children:v.jsxs("div",{className:"flex",children:[v.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${ve==="playground"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>M("playground"),children:"🎮 Playground"}),v.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${ve==="console"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>M("console"),children:p?"❌ Console":"📋 Console"}),v.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${ve==="info"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>M("info"),children:"ℹ️ Info"})]})}),v.jsxs("div",{className:"flex-1 flex min-h-0",children:[v.jsxs("div",{className:`${ve==="playground"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full relative`,style:{width:ve==="playground"?We:0},children:[v.jsx("div",{className:"w-full h-full flex-1 min-h-0",children:v.jsx("canvas",{id:"webgl",className:"w-full h-full block"})}),y&&v.jsx("div",{className:"absolute inset-0 bg-gray-900/70 flex items-center justify-center z-10",children:v.jsxs("div",{className:"flex flex-col items-center",children:[v.jsx("div",{className:"w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-2"}),v.jsx("span",{className:"text-gray-300 text-sm",children:"Loading..."})]})})]}),v.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Yi("playground")}),v.jsxs("div",{className:`${ve==="console"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:[v.jsxs("div",{className:"p-3 border-b border-gray-700 flex justify-between items-center flex-shrink-0",children:[v.jsx("h3",{className:"text-xs font-medium text-gray-200",children:"Console Output"}),v.jsx("button",{onClick:oe,className:"px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded transition-colors",title:"Clear console",children:"🗑️ Clear"})]}),v.jsxs("div",{ref:N,className:"flex-1 p-3 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0",children:[K.length===0?v.jsxs("div",{className:"text-gray-400 text-center py-8",children:[v.jsx("div",{className:"text-2xl mb-2",children:"📋"}),v.jsx("div",{children:"Console output will appear here."})]}):v.jsx("div",{className:"space-y-1",children:K.map((w,P)=>v.jsxs("div",{className:"flex items-start space-x-2",children:[v.jsx("span",{className:"text-gray-500 text-xs mt-1",children:w.timestamp.toLocaleTimeString()}),v.jsx("span",{className:"text-gray-500",children:dd(w.type)}),v.jsx("span",{className:`${fd(w.type)} break-all`,children:w.message})]},P))}),p&&v.jsxs("div",{className:"mt-4 p-3 bg-red-900/20 border border-red-700 rounded",children:[v.jsxs("div",{className:"flex justify-between items-start mb-2",children:[v.jsx("div",{className:"font-bold text-red-400",children:"❌ Parse Error:"}),v.jsx("button",{className:"text-red-300 hover:text-red-100",onClick:()=>g(null),title:"Clear error",children:"✕"})]}),v.jsx("div",{className:"text-red-300 mb-2",children:p.message}),ce&&v.jsxs("div",{className:"text-red-400 text-sm",children:["Line ",ce.line,", Column ",ce.column]})]})]})]}),v.jsx("div",{className:`${ve==="info"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:v.jsxs("div",{className:"p-4 h-full overflow-y-auto",children:[v.jsx("h3",{className:"text-base font-semibold text-gray-200 mb-4",children:"About hx-multianim Playground"}),v.jsxs("div",{className:"space-y-6",children:[v.jsxs("div",{children:[v.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"📚 Documentation & Resources"}),v.jsxs("div",{className:"space-y-2",children:[v.jsxs("a",{href:"https://github.com/bh213/hx-multianim",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[v.jsx("div",{className:"font-medium text-blue-400",children:"hx-multianim"}),v.jsx("div",{className:"text-xs text-gray-400",children:"Animation library for Haxe driving this playground"})]}),v.jsxs("a",{href:"https://github.com/HeapsIO/heaps",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[v.jsx("div",{className:"font-medium text-blue-400",children:"Heaps"}),v.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform graphics framework"})]}),v.jsxs("a",{href:"https://haxe.org",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[v.jsx("div",{className:"font-medium text-blue-400",children:"Haxe"}),v.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform programming language"})]})]})]}),v.jsxs("div",{children:[v.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"🎮 Playground Features"}),v.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[v.jsx("li",{children:"• Real-time code editing and preview"}),v.jsx("li",{children:"• Multiple animation examples and components"}),v.jsx("li",{children:"• File management for manim and anim files"}),v.jsx("li",{children:"• Console output and error display"}),v.jsx("li",{children:"• Resizable panels for optimal workflow"})]})]}),v.jsxs("div",{children:[v.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"💡 Tips"}),v.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[v.jsx("li",{children:"• Use Ctrl+S to apply changes quickly"}),v.jsx("li",{children:"• Switch between playground and console tabs"}),v.jsx("li",{children:"• Resize panels by dragging the dividers"}),v.jsx("li",{children:"• Select files to edit their content"}),v.jsx("li",{children:"• Check console for errors and output"})]})]})]})]})})]})]})]})}var sd={exports:{}};(function(e,n){(function(t,r){e.exports=r()})(yd,function(){var t=function(){},r={},i={},l={};function o(p,g){p=p.push?p:[p];var k=[],_=p.length,j=_,c,u,f,y;for(c=function(S,m){m.length&&k.push(S),j--,j||g(k)};_--;){if(u=p[_],f=i[u],f){c(u,f);continue}y=l[u]=l[u]||[],y.push(c)}}function a(p,g){if(p){var k=l[p];if(i[p]=g,!!k)for(;k.length;)k[0](p,g),k.splice(0,1)}}function s(p,g){p.call&&(p={success:p}),g.length?(p.error||t)(g):(p.success||t)(p)}function d(p,g,k,_){var j=document,c=k.async,u=(k.numRetries||0)+1,f=k.before||t,y=p.replace(/[\?|#].*$/,""),S=p.replace(/^(css|img|module|nomodule)!/,""),m,E,C;if(_=_||0,/(^css!|\.css$)/.test(y))C=j.createElement("link"),C.rel="stylesheet",C.href=S,m="hideFocus"in C,m&&C.relList&&(m=0,C.rel="preload",C.as="style");else if(/(^img!|\.(png|gif|jpg|svg|webp)$)/.test(y))C=j.createElement("img"),C.src=S;else if(C=j.createElement("script"),C.src=S,C.async=c===void 0?!0:c,E="noModule"in C,/^module!/.test(y)){if(!E)return g(p,"l");C.type="module"}else if(/^nomodule!/.test(y)&&E)return g(p,"l");C.onload=C.onerror=C.onbeforeload=function(O){var T=O.type[0];if(m)try{C.sheet.cssText.length||(T="e")}catch(te){te.code!=18&&(T="e")}if(T=="e"){if(_+=1,_<u)return d(p,g,k,_)}else if(C.rel=="preload"&&C.as=="style")return C.rel="stylesheet";g(p,T,O.defaultPrevented)},f(p,C)!==!1&&j.head.appendChild(C)}function x(p,g,k){p=p.push?p:[p];var _=p.length,j=_,c=[],u,f;for(u=function(y,S,m){if(S=="e"&&c.push(y),S=="b")if(m)c.push(y);else return;_--,_||g(c)},f=0;f<j;f++)d(p[f],u,k)}function h(p,g,k){var _,j;if(g&&g.trim&&(_=g),j=(_?k:g)||{},_){if(_ in r)throw"LoadJS";r[_]=!0}function c(u,f){x(p,function(y){s(j,y),u&&s({success:u,error:f},y),a(_,y)},j)}if(j.returnPromise)return new Promise(c);c()}return h.ready=function(g,k){return o(g,function(_){s(k,_)}),h},h.done=function(g){a(g,[])},h.reset=function(){r={},i={},l={}},h.isDefined=function(g){return g in r},h})})(sd);var Lm=sd.exports;const Is=As(Lm);class Mm{constructor(n={}){Ce(this,"maxRetries");Ce(this,"retryDelay");Ce(this,"timeout");Ce(this,"retryCount",0);Ce(this,"isLoaded",!1);this.maxRetries=n.maxRetries||5,this.retryDelay=n.retryDelay||2e3,this.timeout=n.timeout||1e4}waitForReactApp(){document.getElementById("root")&&window.playgroundLoader?(console.log("React app ready, loading Haxe application..."),this.loadHaxeApp()):setTimeout(()=>this.waitForReactApp(),300)}loadHaxeApp(){console.log(`Attempting to load playground.js (attempt ${this.retryCount+1}/${this.maxRetries+1})`);const n=setTimeout(()=>{console.error("Timeout loading playground.js"),this.handleLoadError()},this.timeout);Is("playground.js",{success:()=>{clearTimeout(n),console.log("playground.js loaded successfully"),this.isLoaded=!0,this.waitForHaxeApp()},error:t=>{clearTimeout(n),console.error("Failed to load playground.js:",t),this.handleLoadError()}})}handleLoadError(){this.retryCount++,this.retryCount<=this.maxRetries?(console.log(`Retrying in ${this.retryDelay}ms... (${this.retryCount}/${this.maxRetries})`),setTimeout(()=>{this.loadHaxeApp()},this.retryDelay)):(console.error(`Failed to load playground.js after ${this.maxRetries} retries`),this.showErrorUI())}showErrorUI(){const n=document.createElement("div");n.style.cssText=`
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
    `,document.body.appendChild(n)}waitForHaxeApp(){Is.ready("playground.js",()=>{console.log("playground.js is ready and executed"),this.waitForPlaygroundMain()})}waitForPlaygroundMain(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?(console.log("Haxe application initialized successfully"),window.playgroundLoader&&window.playgroundLoader.mainApp===null&&(window.playgroundLoader.mainApp=window.PlaygroundMain.instance)):setTimeout(()=>this.waitForPlaygroundMain(),100)}start(){document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>this.waitForReactApp()):this.waitForReactApp()}isScriptLoaded(){return this.isLoaded}getRetryCount(){return this.retryCount}}const ud=new Mm({maxRetries:5,retryDelay:2e3,timeout:1e4});ud.start();window.haxeLoader=ud;El.createRoot(document.getElementById("root")).render(v.jsx(de.StrictMode,{children:v.jsx(zm,{})}));
//# sourceMappingURL=index-BkLHyU3j.js.map
