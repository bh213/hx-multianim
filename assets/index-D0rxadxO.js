var cd=Object.defineProperty;var dd=(e,n,t)=>n in e?cd(e,n,{enumerable:!0,configurable:!0,writable:!0,value:t}):e[n]=t;var Ce=(e,n,t)=>dd(e,typeof n!="symbol"?n+"":n,t);(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))r(i);new MutationObserver(i=>{for(const l of i)if(l.type==="childList")for(const o of l.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&r(o)}).observe(document,{childList:!0,subtree:!0});function t(i){const l={};return i.integrity&&(l.integrity=i.integrity),i.referrerPolicy&&(l.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?l.credentials="include":i.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function r(i){if(i.ep)return;i.ep=!0;const l=t(i);fetch(i.href,l)}})();var fd=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};function Rs(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var Ds={exports:{}},Ti={},Os={exports:{}},B={};/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var kr=Symbol.for("react.element"),pd=Symbol.for("react.portal"),md=Symbol.for("react.fragment"),hd=Symbol.for("react.strict_mode"),gd=Symbol.for("react.profiler"),vd=Symbol.for("react.provider"),yd=Symbol.for("react.context"),xd=Symbol.for("react.forward_ref"),wd=Symbol.for("react.suspense"),kd=Symbol.for("react.memo"),_d=Symbol.for("react.lazy"),xa=Symbol.iterator;function Sd(e){return e===null||typeof e!="object"?null:(e=xa&&e[xa]||e["@@iterator"],typeof e=="function"?e:null)}var Is={isMounted:function(){return!1},enqueueForceUpdate:function(){},enqueueReplaceState:function(){},enqueueSetState:function(){}},As=Object.assign,Us={};function Tt(e,n,t){this.props=e,this.context=n,this.refs=Us,this.updater=t||Is}Tt.prototype.isReactComponent={};Tt.prototype.setState=function(e,n){if(typeof e!="object"&&typeof e!="function"&&e!=null)throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");this.updater.enqueueSetState(this,e,n,"setState")};Tt.prototype.forceUpdate=function(e){this.updater.enqueueForceUpdate(this,e,"forceUpdate")};function Bs(){}Bs.prototype=Tt.prototype;function xo(e,n,t){this.props=e,this.context=n,this.refs=Us,this.updater=t||Is}var wo=xo.prototype=new Bs;wo.constructor=xo;As(wo,Tt.prototype);wo.isPureReactComponent=!0;var wa=Array.isArray,Ws=Object.prototype.hasOwnProperty,ko={current:null},Hs={key:!0,ref:!0,__self:!0,__source:!0};function Vs(e,n,t){var r,i={},l=null,o=null;if(n!=null)for(r in n.ref!==void 0&&(o=n.ref),n.key!==void 0&&(l=""+n.key),n)Ws.call(n,r)&&!Hs.hasOwnProperty(r)&&(i[r]=n[r]);var a=arguments.length-2;if(a===1)i.children=t;else if(1<a){for(var u=Array(a),d=0;d<a;d++)u[d]=arguments[d+2];i.children=u}if(e&&e.defaultProps)for(r in a=e.defaultProps,a)i[r]===void 0&&(i[r]=a[r]);return{$$typeof:kr,type:e,key:l,ref:o,props:i,_owner:ko.current}}function bd(e,n){return{$$typeof:kr,type:e.type,key:n,ref:e.ref,props:e.props,_owner:e._owner}}function _o(e){return typeof e=="object"&&e!==null&&e.$$typeof===kr}function Cd(e){var n={"=":"=0",":":"=2"};return"$"+e.replace(/[=:]/g,function(t){return n[t]})}var ka=/\/+/g;function Yi(e,n){return typeof e=="object"&&e!==null&&e.key!=null?Cd(""+e.key):n.toString(36)}function Qr(e,n,t,r,i){var l=typeof e;(l==="undefined"||l==="boolean")&&(e=null);var o=!1;if(e===null)o=!0;else switch(l){case"string":case"number":o=!0;break;case"object":switch(e.$$typeof){case kr:case pd:o=!0}}if(o)return o=e,i=i(o),e=r===""?"."+Yi(o,0):r,wa(i)?(t="",e!=null&&(t=e.replace(ka,"$&/")+"/"),Qr(i,n,t,"",function(d){return d})):i!=null&&(_o(i)&&(i=bd(i,t+(!i.key||o&&o.key===i.key?"":(""+i.key).replace(ka,"$&/")+"/")+e)),n.push(i)),1;if(o=0,r=r===""?".":r+":",wa(e))for(var a=0;a<e.length;a++){l=e[a];var u=r+Yi(l,a);o+=Qr(l,n,t,u,i)}else if(u=Sd(e),typeof u=="function")for(e=u.call(e),a=0;!(l=e.next()).done;)l=l.value,u=r+Yi(l,a++),o+=Qr(l,n,t,u,i);else if(l==="object")throw n=String(e),Error("Objects are not valid as a React child (found: "+(n==="[object Object]"?"object with keys {"+Object.keys(e).join(", ")+"}":n)+"). If you meant to render a collection of children, use an array instead.");return o}function $r(e,n,t){if(e==null)return e;var r=[],i=0;return Qr(e,r,"","",function(l){return n.call(t,l,i++)}),r}function Ed(e){if(e._status===-1){var n=e._result;n=n(),n.then(function(t){(e._status===0||e._status===-1)&&(e._status=1,e._result=t)},function(t){(e._status===0||e._status===-1)&&(e._status=2,e._result=t)}),e._status===-1&&(e._status=0,e._result=n)}if(e._status===1)return e._result.default;throw e._result}var Pe={current:null},Kr={transition:null},$d={ReactCurrentDispatcher:Pe,ReactCurrentBatchConfig:Kr,ReactCurrentOwner:ko};function Qs(){throw Error("act(...) is not supported in production builds of React.")}B.Children={map:$r,forEach:function(e,n,t){$r(e,function(){n.apply(this,arguments)},t)},count:function(e){var n=0;return $r(e,function(){n++}),n},toArray:function(e){return $r(e,function(n){return n})||[]},only:function(e){if(!_o(e))throw Error("React.Children.only expected to receive a single React element child.");return e}};B.Component=Tt;B.Fragment=md;B.Profiler=gd;B.PureComponent=xo;B.StrictMode=hd;B.Suspense=wd;B.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=$d;B.act=Qs;B.cloneElement=function(e,n,t){if(e==null)throw Error("React.cloneElement(...): The argument must be a React element, but you passed "+e+".");var r=As({},e.props),i=e.key,l=e.ref,o=e._owner;if(n!=null){if(n.ref!==void 0&&(l=n.ref,o=ko.current),n.key!==void 0&&(i=""+n.key),e.type&&e.type.defaultProps)var a=e.type.defaultProps;for(u in n)Ws.call(n,u)&&!Hs.hasOwnProperty(u)&&(r[u]=n[u]===void 0&&a!==void 0?a[u]:n[u])}var u=arguments.length-2;if(u===1)r.children=t;else if(1<u){a=Array(u);for(var d=0;d<u;d++)a[d]=arguments[d+2];r.children=a}return{$$typeof:kr,type:e.type,key:i,ref:l,props:r,_owner:o}};B.createContext=function(e){return e={$$typeof:yd,_currentValue:e,_currentValue2:e,_threadCount:0,Provider:null,Consumer:null,_defaultValue:null,_globalName:null},e.Provider={$$typeof:vd,_context:e},e.Consumer=e};B.createElement=Vs;B.createFactory=function(e){var n=Vs.bind(null,e);return n.type=e,n};B.createRef=function(){return{current:null}};B.forwardRef=function(e){return{$$typeof:xd,render:e}};B.isValidElement=_o;B.lazy=function(e){return{$$typeof:_d,_payload:{_status:-1,_result:e},_init:Ed}};B.memo=function(e,n){return{$$typeof:kd,type:e,compare:n===void 0?null:n}};B.startTransition=function(e){var n=Kr.transition;Kr.transition={};try{e()}finally{Kr.transition=n}};B.unstable_act=Qs;B.useCallback=function(e,n){return Pe.current.useCallback(e,n)};B.useContext=function(e){return Pe.current.useContext(e)};B.useDebugValue=function(){};B.useDeferredValue=function(e){return Pe.current.useDeferredValue(e)};B.useEffect=function(e,n){return Pe.current.useEffect(e,n)};B.useId=function(){return Pe.current.useId()};B.useImperativeHandle=function(e,n,t){return Pe.current.useImperativeHandle(e,n,t)};B.useInsertionEffect=function(e,n){return Pe.current.useInsertionEffect(e,n)};B.useLayoutEffect=function(e,n){return Pe.current.useLayoutEffect(e,n)};B.useMemo=function(e,n){return Pe.current.useMemo(e,n)};B.useReducer=function(e,n,t){return Pe.current.useReducer(e,n,t)};B.useRef=function(e){return Pe.current.useRef(e)};B.useState=function(e){return Pe.current.useState(e)};B.useSyncExternalStore=function(e,n,t){return Pe.current.useSyncExternalStore(e,n,t)};B.useTransition=function(){return Pe.current.useTransition()};B.version="18.3.1";Os.exports=B;var $=Os.exports;const he=Rs($);/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Pd=$,Nd=Symbol.for("react.element"),Fd=Symbol.for("react.fragment"),Td=Object.prototype.hasOwnProperty,jd=Pd.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,zd={key:!0,ref:!0,__self:!0,__source:!0};function Ks(e,n,t){var r,i={},l=null,o=null;t!==void 0&&(l=""+t),n.key!==void 0&&(l=""+n.key),n.ref!==void 0&&(o=n.ref);for(r in n)Td.call(n,r)&&!zd.hasOwnProperty(r)&&(i[r]=n[r]);if(e&&e.defaultProps)for(r in n=e.defaultProps,n)i[r]===void 0&&(i[r]=n[r]);return{$$typeof:Nd,type:e,key:l,ref:o,props:i,_owner:jd.current}}Ti.Fragment=Fd;Ti.jsx=Ks;Ti.jsxs=Ks;Ds.exports=Ti;var y=Ds.exports,Cl={},Gs={exports:{}},Ue={},Ys={exports:{}},Xs={};/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */(function(e){function n(F,M){var A=F.length;F.push(M);e:for(;0<A;){var z=A-1>>>1,O=F[z];if(0<i(O,M))F[z]=M,F[A]=O,A=z;else break e}}function t(F){return F.length===0?null:F[0]}function r(F){if(F.length===0)return null;var M=F[0],A=F.pop();if(A!==M){F[0]=A;e:for(var z=0,O=F.length,le=O>>>1;z<le;){var ye=2*(z+1)-1,We=F[ye],dn=ye+1,_n=F[dn];if(0>i(We,A))dn<O&&0>i(_n,We)?(F[z]=_n,F[dn]=A,z=dn):(F[z]=We,F[ye]=A,z=ye);else if(dn<O&&0>i(_n,A))F[z]=_n,F[dn]=A,z=dn;else break e}}return M}function i(F,M){var A=F.sortIndex-M.sortIndex;return A!==0?A:F.id-M.id}if(typeof performance=="object"&&typeof performance.now=="function"){var l=performance;e.unstable_now=function(){return l.now()}}else{var o=Date,a=o.now();e.unstable_now=function(){return o.now()-a}}var u=[],d=[],v=1,m=null,p=3,h=!1,x=!1,w=!1,L=typeof setTimeout=="function"?setTimeout:null,c=typeof clearTimeout=="function"?clearTimeout:null,s=typeof setImmediate<"u"?setImmediate:null;typeof navigator<"u"&&navigator.scheduling!==void 0&&navigator.scheduling.isInputPending!==void 0&&navigator.scheduling.isInputPending.bind(navigator.scheduling);function f(F){for(var M=t(d);M!==null;){if(M.callback===null)r(d);else if(M.startTime<=F)r(d),M.sortIndex=M.expirationTime,n(u,M);else break;M=t(d)}}function g(F){if(w=!1,f(F),!x)if(t(u)!==null)x=!0,V(_);else{var M=t(d);M!==null&&ue(g,M.startTime-F)}}function _(F,M){x=!1,w&&(w=!1,c(C),C=-1),h=!0;var A=p;try{for(f(M),m=t(u);m!==null&&(!(m.expirationTime>M)||F&&!q());){var z=m.callback;if(typeof z=="function"){m.callback=null,p=m.priorityLevel;var O=z(m.expirationTime<=M);M=e.unstable_now(),typeof O=="function"?m.callback=O:m===t(u)&&r(u),f(M)}else r(u);m=t(u)}if(m!==null)var le=!0;else{var ye=t(d);ye!==null&&ue(g,ye.startTime-M),le=!1}return le}finally{m=null,p=A,h=!1}}var b=!1,E=null,C=-1,R=5,N=-1;function q(){return!(e.unstable_now()-N<R)}function Me(){if(E!==null){var F=e.unstable_now();N=F;var M=!0;try{M=E(!0,F)}finally{M?Se():(b=!1,E=null)}}else b=!1}var Se;if(typeof s=="function")Se=function(){s(Me)};else if(typeof MessageChannel<"u"){var rn=new MessageChannel,D=rn.port2;rn.port1.onmessage=Me,Se=function(){D.postMessage(null)}}else Se=function(){L(Me,0)};function V(F){E=F,b||(b=!0,Se())}function ue(F,M){C=L(function(){F(e.unstable_now())},M)}e.unstable_IdlePriority=5,e.unstable_ImmediatePriority=1,e.unstable_LowPriority=4,e.unstable_NormalPriority=3,e.unstable_Profiling=null,e.unstable_UserBlockingPriority=2,e.unstable_cancelCallback=function(F){F.callback=null},e.unstable_continueExecution=function(){x||h||(x=!0,V(_))},e.unstable_forceFrameRate=function(F){0>F||125<F?console.error("forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported"):R=0<F?Math.floor(1e3/F):5},e.unstable_getCurrentPriorityLevel=function(){return p},e.unstable_getFirstCallbackNode=function(){return t(u)},e.unstable_next=function(F){switch(p){case 1:case 2:case 3:var M=3;break;default:M=p}var A=p;p=M;try{return F()}finally{p=A}},e.unstable_pauseExecution=function(){},e.unstable_requestPaint=function(){},e.unstable_runWithPriority=function(F,M){switch(F){case 1:case 2:case 3:case 4:case 5:break;default:F=3}var A=p;p=F;try{return M()}finally{p=A}},e.unstable_scheduleCallback=function(F,M,A){var z=e.unstable_now();switch(typeof A=="object"&&A!==null?(A=A.delay,A=typeof A=="number"&&0<A?z+A:z):A=z,F){case 1:var O=-1;break;case 2:O=250;break;case 5:O=1073741823;break;case 4:O=1e4;break;default:O=5e3}return O=A+O,F={id:v++,callback:M,priorityLevel:F,startTime:A,expirationTime:O,sortIndex:-1},A>z?(F.sortIndex=A,n(d,F),t(u)===null&&F===t(d)&&(w?(c(C),C=-1):w=!0,ue(g,A-z))):(F.sortIndex=O,n(u,F),x||h||(x=!0,V(_))),F},e.unstable_shouldYield=q,e.unstable_wrapCallback=function(F){var M=p;return function(){var A=p;p=M;try{return F.apply(this,arguments)}finally{p=A}}}})(Xs);Ys.exports=Xs;var Ld=Ys.exports;/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Md=$,Ae=Ld;function S(e){for(var n="https://reactjs.org/docs/error-decoder.html?invariant="+e,t=1;t<arguments.length;t++)n+="&args[]="+encodeURIComponent(arguments[t]);return"Minified React error #"+e+"; visit "+n+" for the full message or use the non-minified dev environment for full errors and additional helpful warnings."}var Zs=new Set,rr={};function tt(e,n){bt(e,n),bt(e+"Capture",n)}function bt(e,n){for(rr[e]=n,e=0;e<n.length;e++)Zs.add(n[e])}var vn=!(typeof window>"u"||typeof window.document>"u"||typeof window.document.createElement>"u"),El=Object.prototype.hasOwnProperty,Rd=/^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,_a={},Sa={};function Dd(e){return El.call(Sa,e)?!0:El.call(_a,e)?!1:Rd.test(e)?Sa[e]=!0:(_a[e]=!0,!1)}function Od(e,n,t,r){if(t!==null&&t.type===0)return!1;switch(typeof n){case"function":case"symbol":return!0;case"boolean":return r?!1:t!==null?!t.acceptsBooleans:(e=e.toLowerCase().slice(0,5),e!=="data-"&&e!=="aria-");default:return!1}}function Id(e,n,t,r){if(n===null||typeof n>"u"||Od(e,n,t,r))return!0;if(r)return!1;if(t!==null)switch(t.type){case 3:return!n;case 4:return n===!1;case 5:return isNaN(n);case 6:return isNaN(n)||1>n}return!1}function Ne(e,n,t,r,i,l,o){this.acceptsBooleans=n===2||n===3||n===4,this.attributeName=r,this.attributeNamespace=i,this.mustUseProperty=t,this.propertyName=e,this.type=n,this.sanitizeURL=l,this.removeEmptyString=o}var ve={};"children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style".split(" ").forEach(function(e){ve[e]=new Ne(e,0,!1,e,null,!1,!1)});[["acceptCharset","accept-charset"],["className","class"],["htmlFor","for"],["httpEquiv","http-equiv"]].forEach(function(e){var n=e[0];ve[n]=new Ne(n,1,!1,e[1],null,!1,!1)});["contentEditable","draggable","spellCheck","value"].forEach(function(e){ve[e]=new Ne(e,2,!1,e.toLowerCase(),null,!1,!1)});["autoReverse","externalResourcesRequired","focusable","preserveAlpha"].forEach(function(e){ve[e]=new Ne(e,2,!1,e,null,!1,!1)});"allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope".split(" ").forEach(function(e){ve[e]=new Ne(e,3,!1,e.toLowerCase(),null,!1,!1)});["checked","multiple","muted","selected"].forEach(function(e){ve[e]=new Ne(e,3,!0,e,null,!1,!1)});["capture","download"].forEach(function(e){ve[e]=new Ne(e,4,!1,e,null,!1,!1)});["cols","rows","size","span"].forEach(function(e){ve[e]=new Ne(e,6,!1,e,null,!1,!1)});["rowSpan","start"].forEach(function(e){ve[e]=new Ne(e,5,!1,e.toLowerCase(),null,!1,!1)});var So=/[\-:]([a-z])/g;function bo(e){return e[1].toUpperCase()}"accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height".split(" ").forEach(function(e){var n=e.replace(So,bo);ve[n]=new Ne(n,1,!1,e,null,!1,!1)});"xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type".split(" ").forEach(function(e){var n=e.replace(So,bo);ve[n]=new Ne(n,1,!1,e,"http://www.w3.org/1999/xlink",!1,!1)});["xml:base","xml:lang","xml:space"].forEach(function(e){var n=e.replace(So,bo);ve[n]=new Ne(n,1,!1,e,"http://www.w3.org/XML/1998/namespace",!1,!1)});["tabIndex","crossOrigin"].forEach(function(e){ve[e]=new Ne(e,1,!1,e.toLowerCase(),null,!1,!1)});ve.xlinkHref=new Ne("xlinkHref",1,!1,"xlink:href","http://www.w3.org/1999/xlink",!0,!1);["src","href","action","formAction"].forEach(function(e){ve[e]=new Ne(e,1,!1,e.toLowerCase(),null,!0,!0)});function Co(e,n,t,r){var i=ve.hasOwnProperty(n)?ve[n]:null;(i!==null?i.type!==0:r||!(2<n.length)||n[0]!=="o"&&n[0]!=="O"||n[1]!=="n"&&n[1]!=="N")&&(Id(n,t,i,r)&&(t=null),r||i===null?Dd(n)&&(t===null?e.removeAttribute(n):e.setAttribute(n,""+t)):i.mustUseProperty?e[i.propertyName]=t===null?i.type===3?!1:"":t:(n=i.attributeName,r=i.attributeNamespace,t===null?e.removeAttribute(n):(i=i.type,t=i===3||i===4&&t===!0?"":""+t,r?e.setAttributeNS(r,n,t):e.setAttribute(n,t))))}var kn=Md.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,Pr=Symbol.for("react.element"),lt=Symbol.for("react.portal"),ot=Symbol.for("react.fragment"),Eo=Symbol.for("react.strict_mode"),$l=Symbol.for("react.profiler"),qs=Symbol.for("react.provider"),Js=Symbol.for("react.context"),$o=Symbol.for("react.forward_ref"),Pl=Symbol.for("react.suspense"),Nl=Symbol.for("react.suspense_list"),Po=Symbol.for("react.memo"),bn=Symbol.for("react.lazy"),eu=Symbol.for("react.offscreen"),ba=Symbol.iterator;function Lt(e){return e===null||typeof e!="object"?null:(e=ba&&e[ba]||e["@@iterator"],typeof e=="function"?e:null)}var te=Object.assign,Xi;function Bt(e){if(Xi===void 0)try{throw Error()}catch(t){var n=t.stack.trim().match(/\n( *(at )?)/);Xi=n&&n[1]||""}return`
`+Xi+e}var Zi=!1;function qi(e,n){if(!e||Zi)return"";Zi=!0;var t=Error.prepareStackTrace;Error.prepareStackTrace=void 0;try{if(n)if(n=function(){throw Error()},Object.defineProperty(n.prototype,"props",{set:function(){throw Error()}}),typeof Reflect=="object"&&Reflect.construct){try{Reflect.construct(n,[])}catch(d){var r=d}Reflect.construct(e,[],n)}else{try{n.call()}catch(d){r=d}e.call(n.prototype)}else{try{throw Error()}catch(d){r=d}e()}}catch(d){if(d&&r&&typeof d.stack=="string"){for(var i=d.stack.split(`
`),l=r.stack.split(`
`),o=i.length-1,a=l.length-1;1<=o&&0<=a&&i[o]!==l[a];)a--;for(;1<=o&&0<=a;o--,a--)if(i[o]!==l[a]){if(o!==1||a!==1)do if(o--,a--,0>a||i[o]!==l[a]){var u=`
`+i[o].replace(" at new "," at ");return e.displayName&&u.includes("<anonymous>")&&(u=u.replace("<anonymous>",e.displayName)),u}while(1<=o&&0<=a);break}}}finally{Zi=!1,Error.prepareStackTrace=t}return(e=e?e.displayName||e.name:"")?Bt(e):""}function Ad(e){switch(e.tag){case 5:return Bt(e.type);case 16:return Bt("Lazy");case 13:return Bt("Suspense");case 19:return Bt("SuspenseList");case 0:case 2:case 15:return e=qi(e.type,!1),e;case 11:return e=qi(e.type.render,!1),e;case 1:return e=qi(e.type,!0),e;default:return""}}function Fl(e){if(e==null)return null;if(typeof e=="function")return e.displayName||e.name||null;if(typeof e=="string")return e;switch(e){case ot:return"Fragment";case lt:return"Portal";case $l:return"Profiler";case Eo:return"StrictMode";case Pl:return"Suspense";case Nl:return"SuspenseList"}if(typeof e=="object")switch(e.$$typeof){case Js:return(e.displayName||"Context")+".Consumer";case qs:return(e._context.displayName||"Context")+".Provider";case $o:var n=e.render;return e=e.displayName,e||(e=n.displayName||n.name||"",e=e!==""?"ForwardRef("+e+")":"ForwardRef"),e;case Po:return n=e.displayName||null,n!==null?n:Fl(e.type)||"Memo";case bn:n=e._payload,e=e._init;try{return Fl(e(n))}catch{}}return null}function Ud(e){var n=e.type;switch(e.tag){case 24:return"Cache";case 9:return(n.displayName||"Context")+".Consumer";case 10:return(n._context.displayName||"Context")+".Provider";case 18:return"DehydratedFragment";case 11:return e=n.render,e=e.displayName||e.name||"",n.displayName||(e!==""?"ForwardRef("+e+")":"ForwardRef");case 7:return"Fragment";case 5:return n;case 4:return"Portal";case 3:return"Root";case 6:return"Text";case 16:return Fl(n);case 8:return n===Eo?"StrictMode":"Mode";case 22:return"Offscreen";case 12:return"Profiler";case 21:return"Scope";case 13:return"Suspense";case 19:return"SuspenseList";case 25:return"TracingMarker";case 1:case 0:case 17:case 2:case 14:case 15:if(typeof n=="function")return n.displayName||n.name||null;if(typeof n=="string")return n}return null}function In(e){switch(typeof e){case"boolean":case"number":case"string":case"undefined":return e;case"object":return e;default:return""}}function nu(e){var n=e.type;return(e=e.nodeName)&&e.toLowerCase()==="input"&&(n==="checkbox"||n==="radio")}function Bd(e){var n=nu(e)?"checked":"value",t=Object.getOwnPropertyDescriptor(e.constructor.prototype,n),r=""+e[n];if(!e.hasOwnProperty(n)&&typeof t<"u"&&typeof t.get=="function"&&typeof t.set=="function"){var i=t.get,l=t.set;return Object.defineProperty(e,n,{configurable:!0,get:function(){return i.call(this)},set:function(o){r=""+o,l.call(this,o)}}),Object.defineProperty(e,n,{enumerable:t.enumerable}),{getValue:function(){return r},setValue:function(o){r=""+o},stopTracking:function(){e._valueTracker=null,delete e[n]}}}}function Nr(e){e._valueTracker||(e._valueTracker=Bd(e))}function tu(e){if(!e)return!1;var n=e._valueTracker;if(!n)return!0;var t=n.getValue(),r="";return e&&(r=nu(e)?e.checked?"true":"false":e.value),e=r,e!==t?(n.setValue(e),!0):!1}function oi(e){if(e=e||(typeof document<"u"?document:void 0),typeof e>"u")return null;try{return e.activeElement||e.body}catch{return e.body}}function Tl(e,n){var t=n.checked;return te({},n,{defaultChecked:void 0,defaultValue:void 0,value:void 0,checked:t??e._wrapperState.initialChecked})}function Ca(e,n){var t=n.defaultValue==null?"":n.defaultValue,r=n.checked!=null?n.checked:n.defaultChecked;t=In(n.value!=null?n.value:t),e._wrapperState={initialChecked:r,initialValue:t,controlled:n.type==="checkbox"||n.type==="radio"?n.checked!=null:n.value!=null}}function ru(e,n){n=n.checked,n!=null&&Co(e,"checked",n,!1)}function jl(e,n){ru(e,n);var t=In(n.value),r=n.type;if(t!=null)r==="number"?(t===0&&e.value===""||e.value!=t)&&(e.value=""+t):e.value!==""+t&&(e.value=""+t);else if(r==="submit"||r==="reset"){e.removeAttribute("value");return}n.hasOwnProperty("value")?zl(e,n.type,t):n.hasOwnProperty("defaultValue")&&zl(e,n.type,In(n.defaultValue)),n.checked==null&&n.defaultChecked!=null&&(e.defaultChecked=!!n.defaultChecked)}function Ea(e,n,t){if(n.hasOwnProperty("value")||n.hasOwnProperty("defaultValue")){var r=n.type;if(!(r!=="submit"&&r!=="reset"||n.value!==void 0&&n.value!==null))return;n=""+e._wrapperState.initialValue,t||n===e.value||(e.value=n),e.defaultValue=n}t=e.name,t!==""&&(e.name=""),e.defaultChecked=!!e._wrapperState.initialChecked,t!==""&&(e.name=t)}function zl(e,n,t){(n!=="number"||oi(e.ownerDocument)!==e)&&(t==null?e.defaultValue=""+e._wrapperState.initialValue:e.defaultValue!==""+t&&(e.defaultValue=""+t))}var Wt=Array.isArray;function yt(e,n,t,r){if(e=e.options,n){n={};for(var i=0;i<t.length;i++)n["$"+t[i]]=!0;for(t=0;t<e.length;t++)i=n.hasOwnProperty("$"+e[t].value),e[t].selected!==i&&(e[t].selected=i),i&&r&&(e[t].defaultSelected=!0)}else{for(t=""+In(t),n=null,i=0;i<e.length;i++){if(e[i].value===t){e[i].selected=!0,r&&(e[i].defaultSelected=!0);return}n!==null||e[i].disabled||(n=e[i])}n!==null&&(n.selected=!0)}}function Ll(e,n){if(n.dangerouslySetInnerHTML!=null)throw Error(S(91));return te({},n,{value:void 0,defaultValue:void 0,children:""+e._wrapperState.initialValue})}function $a(e,n){var t=n.value;if(t==null){if(t=n.children,n=n.defaultValue,t!=null){if(n!=null)throw Error(S(92));if(Wt(t)){if(1<t.length)throw Error(S(93));t=t[0]}n=t}n==null&&(n=""),t=n}e._wrapperState={initialValue:In(t)}}function iu(e,n){var t=In(n.value),r=In(n.defaultValue);t!=null&&(t=""+t,t!==e.value&&(e.value=t),n.defaultValue==null&&e.defaultValue!==t&&(e.defaultValue=t)),r!=null&&(e.defaultValue=""+r)}function Pa(e){var n=e.textContent;n===e._wrapperState.initialValue&&n!==""&&n!==null&&(e.value=n)}function lu(e){switch(e){case"svg":return"http://www.w3.org/2000/svg";case"math":return"http://www.w3.org/1998/Math/MathML";default:return"http://www.w3.org/1999/xhtml"}}function Ml(e,n){return e==null||e==="http://www.w3.org/1999/xhtml"?lu(n):e==="http://www.w3.org/2000/svg"&&n==="foreignObject"?"http://www.w3.org/1999/xhtml":e}var Fr,ou=function(e){return typeof MSApp<"u"&&MSApp.execUnsafeLocalFunction?function(n,t,r,i){MSApp.execUnsafeLocalFunction(function(){return e(n,t,r,i)})}:e}(function(e,n){if(e.namespaceURI!=="http://www.w3.org/2000/svg"||"innerHTML"in e)e.innerHTML=n;else{for(Fr=Fr||document.createElement("div"),Fr.innerHTML="<svg>"+n.valueOf().toString()+"</svg>",n=Fr.firstChild;e.firstChild;)e.removeChild(e.firstChild);for(;n.firstChild;)e.appendChild(n.firstChild)}});function ir(e,n){if(n){var t=e.firstChild;if(t&&t===e.lastChild&&t.nodeType===3){t.nodeValue=n;return}}e.textContent=n}var Kt={animationIterationCount:!0,aspectRatio:!0,borderImageOutset:!0,borderImageSlice:!0,borderImageWidth:!0,boxFlex:!0,boxFlexGroup:!0,boxOrdinalGroup:!0,columnCount:!0,columns:!0,flex:!0,flexGrow:!0,flexPositive:!0,flexShrink:!0,flexNegative:!0,flexOrder:!0,gridArea:!0,gridRow:!0,gridRowEnd:!0,gridRowSpan:!0,gridRowStart:!0,gridColumn:!0,gridColumnEnd:!0,gridColumnSpan:!0,gridColumnStart:!0,fontWeight:!0,lineClamp:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,tabSize:!0,widows:!0,zIndex:!0,zoom:!0,fillOpacity:!0,floodOpacity:!0,stopOpacity:!0,strokeDasharray:!0,strokeDashoffset:!0,strokeMiterlimit:!0,strokeOpacity:!0,strokeWidth:!0},Wd=["Webkit","ms","Moz","O"];Object.keys(Kt).forEach(function(e){Wd.forEach(function(n){n=n+e.charAt(0).toUpperCase()+e.substring(1),Kt[n]=Kt[e]})});function au(e,n,t){return n==null||typeof n=="boolean"||n===""?"":t||typeof n!="number"||n===0||Kt.hasOwnProperty(e)&&Kt[e]?(""+n).trim():n+"px"}function su(e,n){e=e.style;for(var t in n)if(n.hasOwnProperty(t)){var r=t.indexOf("--")===0,i=au(t,n[t],r);t==="float"&&(t="cssFloat"),r?e.setProperty(t,i):e[t]=i}}var Hd=te({menuitem:!0},{area:!0,base:!0,br:!0,col:!0,embed:!0,hr:!0,img:!0,input:!0,keygen:!0,link:!0,meta:!0,param:!0,source:!0,track:!0,wbr:!0});function Rl(e,n){if(n){if(Hd[e]&&(n.children!=null||n.dangerouslySetInnerHTML!=null))throw Error(S(137,e));if(n.dangerouslySetInnerHTML!=null){if(n.children!=null)throw Error(S(60));if(typeof n.dangerouslySetInnerHTML!="object"||!("__html"in n.dangerouslySetInnerHTML))throw Error(S(61))}if(n.style!=null&&typeof n.style!="object")throw Error(S(62))}}function Dl(e,n){if(e.indexOf("-")===-1)return typeof n.is=="string";switch(e){case"annotation-xml":case"color-profile":case"font-face":case"font-face-src":case"font-face-uri":case"font-face-format":case"font-face-name":case"missing-glyph":return!1;default:return!0}}var Ol=null;function No(e){return e=e.target||e.srcElement||window,e.correspondingUseElement&&(e=e.correspondingUseElement),e.nodeType===3?e.parentNode:e}var Il=null,xt=null,wt=null;function Na(e){if(e=br(e)){if(typeof Il!="function")throw Error(S(280));var n=e.stateNode;n&&(n=Ri(n),Il(e.stateNode,e.type,n))}}function uu(e){xt?wt?wt.push(e):wt=[e]:xt=e}function cu(){if(xt){var e=xt,n=wt;if(wt=xt=null,Na(e),n)for(e=0;e<n.length;e++)Na(n[e])}}function du(e,n){return e(n)}function fu(){}var Ji=!1;function pu(e,n,t){if(Ji)return e(n,t);Ji=!0;try{return du(e,n,t)}finally{Ji=!1,(xt!==null||wt!==null)&&(fu(),cu())}}function lr(e,n){var t=e.stateNode;if(t===null)return null;var r=Ri(t);if(r===null)return null;t=r[n];e:switch(n){case"onClick":case"onClickCapture":case"onDoubleClick":case"onDoubleClickCapture":case"onMouseDown":case"onMouseDownCapture":case"onMouseMove":case"onMouseMoveCapture":case"onMouseUp":case"onMouseUpCapture":case"onMouseEnter":(r=!r.disabled)||(e=e.type,r=!(e==="button"||e==="input"||e==="select"||e==="textarea")),e=!r;break e;default:e=!1}if(e)return null;if(t&&typeof t!="function")throw Error(S(231,n,typeof t));return t}var Al=!1;if(vn)try{var Mt={};Object.defineProperty(Mt,"passive",{get:function(){Al=!0}}),window.addEventListener("test",Mt,Mt),window.removeEventListener("test",Mt,Mt)}catch{Al=!1}function Vd(e,n,t,r,i,l,o,a,u){var d=Array.prototype.slice.call(arguments,3);try{n.apply(t,d)}catch(v){this.onError(v)}}var Gt=!1,ai=null,si=!1,Ul=null,Qd={onError:function(e){Gt=!0,ai=e}};function Kd(e,n,t,r,i,l,o,a,u){Gt=!1,ai=null,Vd.apply(Qd,arguments)}function Gd(e,n,t,r,i,l,o,a,u){if(Kd.apply(this,arguments),Gt){if(Gt){var d=ai;Gt=!1,ai=null}else throw Error(S(198));si||(si=!0,Ul=d)}}function rt(e){var n=e,t=e;if(e.alternate)for(;n.return;)n=n.return;else{e=n;do n=e,n.flags&4098&&(t=n.return),e=n.return;while(e)}return n.tag===3?t:null}function mu(e){if(e.tag===13){var n=e.memoizedState;if(n===null&&(e=e.alternate,e!==null&&(n=e.memoizedState)),n!==null)return n.dehydrated}return null}function Fa(e){if(rt(e)!==e)throw Error(S(188))}function Yd(e){var n=e.alternate;if(!n){if(n=rt(e),n===null)throw Error(S(188));return n!==e?null:e}for(var t=e,r=n;;){var i=t.return;if(i===null)break;var l=i.alternate;if(l===null){if(r=i.return,r!==null){t=r;continue}break}if(i.child===l.child){for(l=i.child;l;){if(l===t)return Fa(i),e;if(l===r)return Fa(i),n;l=l.sibling}throw Error(S(188))}if(t.return!==r.return)t=i,r=l;else{for(var o=!1,a=i.child;a;){if(a===t){o=!0,t=i,r=l;break}if(a===r){o=!0,r=i,t=l;break}a=a.sibling}if(!o){for(a=l.child;a;){if(a===t){o=!0,t=l,r=i;break}if(a===r){o=!0,r=l,t=i;break}a=a.sibling}if(!o)throw Error(S(189))}}if(t.alternate!==r)throw Error(S(190))}if(t.tag!==3)throw Error(S(188));return t.stateNode.current===t?e:n}function hu(e){return e=Yd(e),e!==null?gu(e):null}function gu(e){if(e.tag===5||e.tag===6)return e;for(e=e.child;e!==null;){var n=gu(e);if(n!==null)return n;e=e.sibling}return null}var vu=Ae.unstable_scheduleCallback,Ta=Ae.unstable_cancelCallback,Xd=Ae.unstable_shouldYield,Zd=Ae.unstable_requestPaint,ie=Ae.unstable_now,qd=Ae.unstable_getCurrentPriorityLevel,Fo=Ae.unstable_ImmediatePriority,yu=Ae.unstable_UserBlockingPriority,ui=Ae.unstable_NormalPriority,Jd=Ae.unstable_LowPriority,xu=Ae.unstable_IdlePriority,ji=null,un=null;function ef(e){if(un&&typeof un.onCommitFiberRoot=="function")try{un.onCommitFiberRoot(ji,e,void 0,(e.current.flags&128)===128)}catch{}}var en=Math.clz32?Math.clz32:rf,nf=Math.log,tf=Math.LN2;function rf(e){return e>>>=0,e===0?32:31-(nf(e)/tf|0)|0}var Tr=64,jr=4194304;function Ht(e){switch(e&-e){case 1:return 1;case 2:return 2;case 4:return 4;case 8:return 8;case 16:return 16;case 32:return 32;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return e&4194240;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return e&130023424;case 134217728:return 134217728;case 268435456:return 268435456;case 536870912:return 536870912;case 1073741824:return 1073741824;default:return e}}function ci(e,n){var t=e.pendingLanes;if(t===0)return 0;var r=0,i=e.suspendedLanes,l=e.pingedLanes,o=t&268435455;if(o!==0){var a=o&~i;a!==0?r=Ht(a):(l&=o,l!==0&&(r=Ht(l)))}else o=t&~i,o!==0?r=Ht(o):l!==0&&(r=Ht(l));if(r===0)return 0;if(n!==0&&n!==r&&!(n&i)&&(i=r&-r,l=n&-n,i>=l||i===16&&(l&4194240)!==0))return n;if(r&4&&(r|=t&16),n=e.entangledLanes,n!==0)for(e=e.entanglements,n&=r;0<n;)t=31-en(n),i=1<<t,r|=e[t],n&=~i;return r}function lf(e,n){switch(e){case 1:case 2:case 4:return n+250;case 8:case 16:case 32:case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return n+5e3;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return-1;case 134217728:case 268435456:case 536870912:case 1073741824:return-1;default:return-1}}function of(e,n){for(var t=e.suspendedLanes,r=e.pingedLanes,i=e.expirationTimes,l=e.pendingLanes;0<l;){var o=31-en(l),a=1<<o,u=i[o];u===-1?(!(a&t)||a&r)&&(i[o]=lf(a,n)):u<=n&&(e.expiredLanes|=a),l&=~a}}function Bl(e){return e=e.pendingLanes&-1073741825,e!==0?e:e&1073741824?1073741824:0}function wu(){var e=Tr;return Tr<<=1,!(Tr&4194240)&&(Tr=64),e}function el(e){for(var n=[],t=0;31>t;t++)n.push(e);return n}function _r(e,n,t){e.pendingLanes|=n,n!==536870912&&(e.suspendedLanes=0,e.pingedLanes=0),e=e.eventTimes,n=31-en(n),e[n]=t}function af(e,n){var t=e.pendingLanes&~n;e.pendingLanes=n,e.suspendedLanes=0,e.pingedLanes=0,e.expiredLanes&=n,e.mutableReadLanes&=n,e.entangledLanes&=n,n=e.entanglements;var r=e.eventTimes;for(e=e.expirationTimes;0<t;){var i=31-en(t),l=1<<i;n[i]=0,r[i]=-1,e[i]=-1,t&=~l}}function To(e,n){var t=e.entangledLanes|=n;for(e=e.entanglements;t;){var r=31-en(t),i=1<<r;i&n|e[r]&n&&(e[r]|=n),t&=~i}}var K=0;function ku(e){return e&=-e,1<e?4<e?e&268435455?16:536870912:4:1}var _u,jo,Su,bu,Cu,Wl=!1,zr=[],Fn=null,Tn=null,jn=null,or=new Map,ar=new Map,En=[],sf="mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(" ");function ja(e,n){switch(e){case"focusin":case"focusout":Fn=null;break;case"dragenter":case"dragleave":Tn=null;break;case"mouseover":case"mouseout":jn=null;break;case"pointerover":case"pointerout":or.delete(n.pointerId);break;case"gotpointercapture":case"lostpointercapture":ar.delete(n.pointerId)}}function Rt(e,n,t,r,i,l){return e===null||e.nativeEvent!==l?(e={blockedOn:n,domEventName:t,eventSystemFlags:r,nativeEvent:l,targetContainers:[i]},n!==null&&(n=br(n),n!==null&&jo(n)),e):(e.eventSystemFlags|=r,n=e.targetContainers,i!==null&&n.indexOf(i)===-1&&n.push(i),e)}function uf(e,n,t,r,i){switch(n){case"focusin":return Fn=Rt(Fn,e,n,t,r,i),!0;case"dragenter":return Tn=Rt(Tn,e,n,t,r,i),!0;case"mouseover":return jn=Rt(jn,e,n,t,r,i),!0;case"pointerover":var l=i.pointerId;return or.set(l,Rt(or.get(l)||null,e,n,t,r,i)),!0;case"gotpointercapture":return l=i.pointerId,ar.set(l,Rt(ar.get(l)||null,e,n,t,r,i)),!0}return!1}function Eu(e){var n=Qn(e.target);if(n!==null){var t=rt(n);if(t!==null){if(n=t.tag,n===13){if(n=mu(t),n!==null){e.blockedOn=n,Cu(e.priority,function(){Su(t)});return}}else if(n===3&&t.stateNode.current.memoizedState.isDehydrated){e.blockedOn=t.tag===3?t.stateNode.containerInfo:null;return}}}e.blockedOn=null}function Gr(e){if(e.blockedOn!==null)return!1;for(var n=e.targetContainers;0<n.length;){var t=Hl(e.domEventName,e.eventSystemFlags,n[0],e.nativeEvent);if(t===null){t=e.nativeEvent;var r=new t.constructor(t.type,t);Ol=r,t.target.dispatchEvent(r),Ol=null}else return n=br(t),n!==null&&jo(n),e.blockedOn=t,!1;n.shift()}return!0}function za(e,n,t){Gr(e)&&t.delete(n)}function cf(){Wl=!1,Fn!==null&&Gr(Fn)&&(Fn=null),Tn!==null&&Gr(Tn)&&(Tn=null),jn!==null&&Gr(jn)&&(jn=null),or.forEach(za),ar.forEach(za)}function Dt(e,n){e.blockedOn===n&&(e.blockedOn=null,Wl||(Wl=!0,Ae.unstable_scheduleCallback(Ae.unstable_NormalPriority,cf)))}function sr(e){function n(i){return Dt(i,e)}if(0<zr.length){Dt(zr[0],e);for(var t=1;t<zr.length;t++){var r=zr[t];r.blockedOn===e&&(r.blockedOn=null)}}for(Fn!==null&&Dt(Fn,e),Tn!==null&&Dt(Tn,e),jn!==null&&Dt(jn,e),or.forEach(n),ar.forEach(n),t=0;t<En.length;t++)r=En[t],r.blockedOn===e&&(r.blockedOn=null);for(;0<En.length&&(t=En[0],t.blockedOn===null);)Eu(t),t.blockedOn===null&&En.shift()}var kt=kn.ReactCurrentBatchConfig,di=!0;function df(e,n,t,r){var i=K,l=kt.transition;kt.transition=null;try{K=1,zo(e,n,t,r)}finally{K=i,kt.transition=l}}function ff(e,n,t,r){var i=K,l=kt.transition;kt.transition=null;try{K=4,zo(e,n,t,r)}finally{K=i,kt.transition=l}}function zo(e,n,t,r){if(di){var i=Hl(e,n,t,r);if(i===null)cl(e,n,r,fi,t),ja(e,r);else if(uf(i,e,n,t,r))r.stopPropagation();else if(ja(e,r),n&4&&-1<sf.indexOf(e)){for(;i!==null;){var l=br(i);if(l!==null&&_u(l),l=Hl(e,n,t,r),l===null&&cl(e,n,r,fi,t),l===i)break;i=l}i!==null&&r.stopPropagation()}else cl(e,n,r,null,t)}}var fi=null;function Hl(e,n,t,r){if(fi=null,e=No(r),e=Qn(e),e!==null)if(n=rt(e),n===null)e=null;else if(t=n.tag,t===13){if(e=mu(n),e!==null)return e;e=null}else if(t===3){if(n.stateNode.current.memoizedState.isDehydrated)return n.tag===3?n.stateNode.containerInfo:null;e=null}else n!==e&&(e=null);return fi=e,null}function $u(e){switch(e){case"cancel":case"click":case"close":case"contextmenu":case"copy":case"cut":case"auxclick":case"dblclick":case"dragend":case"dragstart":case"drop":case"focusin":case"focusout":case"input":case"invalid":case"keydown":case"keypress":case"keyup":case"mousedown":case"mouseup":case"paste":case"pause":case"play":case"pointercancel":case"pointerdown":case"pointerup":case"ratechange":case"reset":case"resize":case"seeked":case"submit":case"touchcancel":case"touchend":case"touchstart":case"volumechange":case"change":case"selectionchange":case"textInput":case"compositionstart":case"compositionend":case"compositionupdate":case"beforeblur":case"afterblur":case"beforeinput":case"blur":case"fullscreenchange":case"focus":case"hashchange":case"popstate":case"select":case"selectstart":return 1;case"drag":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"mousemove":case"mouseout":case"mouseover":case"pointermove":case"pointerout":case"pointerover":case"scroll":case"toggle":case"touchmove":case"wheel":case"mouseenter":case"mouseleave":case"pointerenter":case"pointerleave":return 4;case"message":switch(qd()){case Fo:return 1;case yu:return 4;case ui:case Jd:return 16;case xu:return 536870912;default:return 16}default:return 16}}var Pn=null,Lo=null,Yr=null;function Pu(){if(Yr)return Yr;var e,n=Lo,t=n.length,r,i="value"in Pn?Pn.value:Pn.textContent,l=i.length;for(e=0;e<t&&n[e]===i[e];e++);var o=t-e;for(r=1;r<=o&&n[t-r]===i[l-r];r++);return Yr=i.slice(e,1<r?1-r:void 0)}function Xr(e){var n=e.keyCode;return"charCode"in e?(e=e.charCode,e===0&&n===13&&(e=13)):e=n,e===10&&(e=13),32<=e||e===13?e:0}function Lr(){return!0}function La(){return!1}function Be(e){function n(t,r,i,l,o){this._reactName=t,this._targetInst=i,this.type=r,this.nativeEvent=l,this.target=o,this.currentTarget=null;for(var a in e)e.hasOwnProperty(a)&&(t=e[a],this[a]=t?t(l):l[a]);return this.isDefaultPrevented=(l.defaultPrevented!=null?l.defaultPrevented:l.returnValue===!1)?Lr:La,this.isPropagationStopped=La,this}return te(n.prototype,{preventDefault:function(){this.defaultPrevented=!0;var t=this.nativeEvent;t&&(t.preventDefault?t.preventDefault():typeof t.returnValue!="unknown"&&(t.returnValue=!1),this.isDefaultPrevented=Lr)},stopPropagation:function(){var t=this.nativeEvent;t&&(t.stopPropagation?t.stopPropagation():typeof t.cancelBubble!="unknown"&&(t.cancelBubble=!0),this.isPropagationStopped=Lr)},persist:function(){},isPersistent:Lr}),n}var jt={eventPhase:0,bubbles:0,cancelable:0,timeStamp:function(e){return e.timeStamp||Date.now()},defaultPrevented:0,isTrusted:0},Mo=Be(jt),Sr=te({},jt,{view:0,detail:0}),pf=Be(Sr),nl,tl,Ot,zi=te({},Sr,{screenX:0,screenY:0,clientX:0,clientY:0,pageX:0,pageY:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,getModifierState:Ro,button:0,buttons:0,relatedTarget:function(e){return e.relatedTarget===void 0?e.fromElement===e.srcElement?e.toElement:e.fromElement:e.relatedTarget},movementX:function(e){return"movementX"in e?e.movementX:(e!==Ot&&(Ot&&e.type==="mousemove"?(nl=e.screenX-Ot.screenX,tl=e.screenY-Ot.screenY):tl=nl=0,Ot=e),nl)},movementY:function(e){return"movementY"in e?e.movementY:tl}}),Ma=Be(zi),mf=te({},zi,{dataTransfer:0}),hf=Be(mf),gf=te({},Sr,{relatedTarget:0}),rl=Be(gf),vf=te({},jt,{animationName:0,elapsedTime:0,pseudoElement:0}),yf=Be(vf),xf=te({},jt,{clipboardData:function(e){return"clipboardData"in e?e.clipboardData:window.clipboardData}}),wf=Be(xf),kf=te({},jt,{data:0}),Ra=Be(kf),_f={Esc:"Escape",Spacebar:" ",Left:"ArrowLeft",Up:"ArrowUp",Right:"ArrowRight",Down:"ArrowDown",Del:"Delete",Win:"OS",Menu:"ContextMenu",Apps:"ContextMenu",Scroll:"ScrollLock",MozPrintableKey:"Unidentified"},Sf={8:"Backspace",9:"Tab",12:"Clear",13:"Enter",16:"Shift",17:"Control",18:"Alt",19:"Pause",20:"CapsLock",27:"Escape",32:" ",33:"PageUp",34:"PageDown",35:"End",36:"Home",37:"ArrowLeft",38:"ArrowUp",39:"ArrowRight",40:"ArrowDown",45:"Insert",46:"Delete",112:"F1",113:"F2",114:"F3",115:"F4",116:"F5",117:"F6",118:"F7",119:"F8",120:"F9",121:"F10",122:"F11",123:"F12",144:"NumLock",145:"ScrollLock",224:"Meta"},bf={Alt:"altKey",Control:"ctrlKey",Meta:"metaKey",Shift:"shiftKey"};function Cf(e){var n=this.nativeEvent;return n.getModifierState?n.getModifierState(e):(e=bf[e])?!!n[e]:!1}function Ro(){return Cf}var Ef=te({},Sr,{key:function(e){if(e.key){var n=_f[e.key]||e.key;if(n!=="Unidentified")return n}return e.type==="keypress"?(e=Xr(e),e===13?"Enter":String.fromCharCode(e)):e.type==="keydown"||e.type==="keyup"?Sf[e.keyCode]||"Unidentified":""},code:0,location:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,repeat:0,locale:0,getModifierState:Ro,charCode:function(e){return e.type==="keypress"?Xr(e):0},keyCode:function(e){return e.type==="keydown"||e.type==="keyup"?e.keyCode:0},which:function(e){return e.type==="keypress"?Xr(e):e.type==="keydown"||e.type==="keyup"?e.keyCode:0}}),$f=Be(Ef),Pf=te({},zi,{pointerId:0,width:0,height:0,pressure:0,tangentialPressure:0,tiltX:0,tiltY:0,twist:0,pointerType:0,isPrimary:0}),Da=Be(Pf),Nf=te({},Sr,{touches:0,targetTouches:0,changedTouches:0,altKey:0,metaKey:0,ctrlKey:0,shiftKey:0,getModifierState:Ro}),Ff=Be(Nf),Tf=te({},jt,{propertyName:0,elapsedTime:0,pseudoElement:0}),jf=Be(Tf),zf=te({},zi,{deltaX:function(e){return"deltaX"in e?e.deltaX:"wheelDeltaX"in e?-e.wheelDeltaX:0},deltaY:function(e){return"deltaY"in e?e.deltaY:"wheelDeltaY"in e?-e.wheelDeltaY:"wheelDelta"in e?-e.wheelDelta:0},deltaZ:0,deltaMode:0}),Lf=Be(zf),Mf=[9,13,27,32],Do=vn&&"CompositionEvent"in window,Yt=null;vn&&"documentMode"in document&&(Yt=document.documentMode);var Rf=vn&&"TextEvent"in window&&!Yt,Nu=vn&&(!Do||Yt&&8<Yt&&11>=Yt),Oa=" ",Ia=!1;function Fu(e,n){switch(e){case"keyup":return Mf.indexOf(n.keyCode)!==-1;case"keydown":return n.keyCode!==229;case"keypress":case"mousedown":case"focusout":return!0;default:return!1}}function Tu(e){return e=e.detail,typeof e=="object"&&"data"in e?e.data:null}var at=!1;function Df(e,n){switch(e){case"compositionend":return Tu(n);case"keypress":return n.which!==32?null:(Ia=!0,Oa);case"textInput":return e=n.data,e===Oa&&Ia?null:e;default:return null}}function Of(e,n){if(at)return e==="compositionend"||!Do&&Fu(e,n)?(e=Pu(),Yr=Lo=Pn=null,at=!1,e):null;switch(e){case"paste":return null;case"keypress":if(!(n.ctrlKey||n.altKey||n.metaKey)||n.ctrlKey&&n.altKey){if(n.char&&1<n.char.length)return n.char;if(n.which)return String.fromCharCode(n.which)}return null;case"compositionend":return Nu&&n.locale!=="ko"?null:n.data;default:return null}}var If={color:!0,date:!0,datetime:!0,"datetime-local":!0,email:!0,month:!0,number:!0,password:!0,range:!0,search:!0,tel:!0,text:!0,time:!0,url:!0,week:!0};function Aa(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n==="input"?!!If[e.type]:n==="textarea"}function ju(e,n,t,r){uu(r),n=pi(n,"onChange"),0<n.length&&(t=new Mo("onChange","change",null,t,r),e.push({event:t,listeners:n}))}var Xt=null,ur=null;function Af(e){Wu(e,0)}function Li(e){var n=ct(e);if(tu(n))return e}function Uf(e,n){if(e==="change")return n}var zu=!1;if(vn){var il;if(vn){var ll="oninput"in document;if(!ll){var Ua=document.createElement("div");Ua.setAttribute("oninput","return;"),ll=typeof Ua.oninput=="function"}il=ll}else il=!1;zu=il&&(!document.documentMode||9<document.documentMode)}function Ba(){Xt&&(Xt.detachEvent("onpropertychange",Lu),ur=Xt=null)}function Lu(e){if(e.propertyName==="value"&&Li(ur)){var n=[];ju(n,ur,e,No(e)),pu(Af,n)}}function Bf(e,n,t){e==="focusin"?(Ba(),Xt=n,ur=t,Xt.attachEvent("onpropertychange",Lu)):e==="focusout"&&Ba()}function Wf(e){if(e==="selectionchange"||e==="keyup"||e==="keydown")return Li(ur)}function Hf(e,n){if(e==="click")return Li(n)}function Vf(e,n){if(e==="input"||e==="change")return Li(n)}function Qf(e,n){return e===n&&(e!==0||1/e===1/n)||e!==e&&n!==n}var tn=typeof Object.is=="function"?Object.is:Qf;function cr(e,n){if(tn(e,n))return!0;if(typeof e!="object"||e===null||typeof n!="object"||n===null)return!1;var t=Object.keys(e),r=Object.keys(n);if(t.length!==r.length)return!1;for(r=0;r<t.length;r++){var i=t[r];if(!El.call(n,i)||!tn(e[i],n[i]))return!1}return!0}function Wa(e){for(;e&&e.firstChild;)e=e.firstChild;return e}function Ha(e,n){var t=Wa(e);e=0;for(var r;t;){if(t.nodeType===3){if(r=e+t.textContent.length,e<=n&&r>=n)return{node:t,offset:n-e};e=r}e:{for(;t;){if(t.nextSibling){t=t.nextSibling;break e}t=t.parentNode}t=void 0}t=Wa(t)}}function Mu(e,n){return e&&n?e===n?!0:e&&e.nodeType===3?!1:n&&n.nodeType===3?Mu(e,n.parentNode):"contains"in e?e.contains(n):e.compareDocumentPosition?!!(e.compareDocumentPosition(n)&16):!1:!1}function Ru(){for(var e=window,n=oi();n instanceof e.HTMLIFrameElement;){try{var t=typeof n.contentWindow.location.href=="string"}catch{t=!1}if(t)e=n.contentWindow;else break;n=oi(e.document)}return n}function Oo(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n&&(n==="input"&&(e.type==="text"||e.type==="search"||e.type==="tel"||e.type==="url"||e.type==="password")||n==="textarea"||e.contentEditable==="true")}function Kf(e){var n=Ru(),t=e.focusedElem,r=e.selectionRange;if(n!==t&&t&&t.ownerDocument&&Mu(t.ownerDocument.documentElement,t)){if(r!==null&&Oo(t)){if(n=r.start,e=r.end,e===void 0&&(e=n),"selectionStart"in t)t.selectionStart=n,t.selectionEnd=Math.min(e,t.value.length);else if(e=(n=t.ownerDocument||document)&&n.defaultView||window,e.getSelection){e=e.getSelection();var i=t.textContent.length,l=Math.min(r.start,i);r=r.end===void 0?l:Math.min(r.end,i),!e.extend&&l>r&&(i=r,r=l,l=i),i=Ha(t,l);var o=Ha(t,r);i&&o&&(e.rangeCount!==1||e.anchorNode!==i.node||e.anchorOffset!==i.offset||e.focusNode!==o.node||e.focusOffset!==o.offset)&&(n=n.createRange(),n.setStart(i.node,i.offset),e.removeAllRanges(),l>r?(e.addRange(n),e.extend(o.node,o.offset)):(n.setEnd(o.node,o.offset),e.addRange(n)))}}for(n=[],e=t;e=e.parentNode;)e.nodeType===1&&n.push({element:e,left:e.scrollLeft,top:e.scrollTop});for(typeof t.focus=="function"&&t.focus(),t=0;t<n.length;t++)e=n[t],e.element.scrollLeft=e.left,e.element.scrollTop=e.top}}var Gf=vn&&"documentMode"in document&&11>=document.documentMode,st=null,Vl=null,Zt=null,Ql=!1;function Va(e,n,t){var r=t.window===t?t.document:t.nodeType===9?t:t.ownerDocument;Ql||st==null||st!==oi(r)||(r=st,"selectionStart"in r&&Oo(r)?r={start:r.selectionStart,end:r.selectionEnd}:(r=(r.ownerDocument&&r.ownerDocument.defaultView||window).getSelection(),r={anchorNode:r.anchorNode,anchorOffset:r.anchorOffset,focusNode:r.focusNode,focusOffset:r.focusOffset}),Zt&&cr(Zt,r)||(Zt=r,r=pi(Vl,"onSelect"),0<r.length&&(n=new Mo("onSelect","select",null,n,t),e.push({event:n,listeners:r}),n.target=st)))}function Mr(e,n){var t={};return t[e.toLowerCase()]=n.toLowerCase(),t["Webkit"+e]="webkit"+n,t["Moz"+e]="moz"+n,t}var ut={animationend:Mr("Animation","AnimationEnd"),animationiteration:Mr("Animation","AnimationIteration"),animationstart:Mr("Animation","AnimationStart"),transitionend:Mr("Transition","TransitionEnd")},ol={},Du={};vn&&(Du=document.createElement("div").style,"AnimationEvent"in window||(delete ut.animationend.animation,delete ut.animationiteration.animation,delete ut.animationstart.animation),"TransitionEvent"in window||delete ut.transitionend.transition);function Mi(e){if(ol[e])return ol[e];if(!ut[e])return e;var n=ut[e],t;for(t in n)if(n.hasOwnProperty(t)&&t in Du)return ol[e]=n[t];return e}var Ou=Mi("animationend"),Iu=Mi("animationiteration"),Au=Mi("animationstart"),Uu=Mi("transitionend"),Bu=new Map,Qa="abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(" ");function Un(e,n){Bu.set(e,n),tt(n,[e])}for(var al=0;al<Qa.length;al++){var sl=Qa[al],Yf=sl.toLowerCase(),Xf=sl[0].toUpperCase()+sl.slice(1);Un(Yf,"on"+Xf)}Un(Ou,"onAnimationEnd");Un(Iu,"onAnimationIteration");Un(Au,"onAnimationStart");Un("dblclick","onDoubleClick");Un("focusin","onFocus");Un("focusout","onBlur");Un(Uu,"onTransitionEnd");bt("onMouseEnter",["mouseout","mouseover"]);bt("onMouseLeave",["mouseout","mouseover"]);bt("onPointerEnter",["pointerout","pointerover"]);bt("onPointerLeave",["pointerout","pointerover"]);tt("onChange","change click focusin focusout input keydown keyup selectionchange".split(" "));tt("onSelect","focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(" "));tt("onBeforeInput",["compositionend","keypress","textInput","paste"]);tt("onCompositionEnd","compositionend focusout keydown keypress keyup mousedown".split(" "));tt("onCompositionStart","compositionstart focusout keydown keypress keyup mousedown".split(" "));tt("onCompositionUpdate","compositionupdate focusout keydown keypress keyup mousedown".split(" "));var Vt="abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(" "),Zf=new Set("cancel close invalid load scroll toggle".split(" ").concat(Vt));function Ka(e,n,t){var r=e.type||"unknown-event";e.currentTarget=t,Gd(r,n,void 0,e),e.currentTarget=null}function Wu(e,n){n=(n&4)!==0;for(var t=0;t<e.length;t++){var r=e[t],i=r.event;r=r.listeners;e:{var l=void 0;if(n)for(var o=r.length-1;0<=o;o--){var a=r[o],u=a.instance,d=a.currentTarget;if(a=a.listener,u!==l&&i.isPropagationStopped())break e;Ka(i,a,d),l=u}else for(o=0;o<r.length;o++){if(a=r[o],u=a.instance,d=a.currentTarget,a=a.listener,u!==l&&i.isPropagationStopped())break e;Ka(i,a,d),l=u}}}if(si)throw e=Ul,si=!1,Ul=null,e}function X(e,n){var t=n[Zl];t===void 0&&(t=n[Zl]=new Set);var r=e+"__bubble";t.has(r)||(Hu(n,e,2,!1),t.add(r))}function ul(e,n,t){var r=0;n&&(r|=4),Hu(t,e,r,n)}var Rr="_reactListening"+Math.random().toString(36).slice(2);function dr(e){if(!e[Rr]){e[Rr]=!0,Zs.forEach(function(t){t!=="selectionchange"&&(Zf.has(t)||ul(t,!1,e),ul(t,!0,e))});var n=e.nodeType===9?e:e.ownerDocument;n===null||n[Rr]||(n[Rr]=!0,ul("selectionchange",!1,n))}}function Hu(e,n,t,r){switch($u(n)){case 1:var i=df;break;case 4:i=ff;break;default:i=zo}t=i.bind(null,n,t,e),i=void 0,!Al||n!=="touchstart"&&n!=="touchmove"&&n!=="wheel"||(i=!0),r?i!==void 0?e.addEventListener(n,t,{capture:!0,passive:i}):e.addEventListener(n,t,!0):i!==void 0?e.addEventListener(n,t,{passive:i}):e.addEventListener(n,t,!1)}function cl(e,n,t,r,i){var l=r;if(!(n&1)&&!(n&2)&&r!==null)e:for(;;){if(r===null)return;var o=r.tag;if(o===3||o===4){var a=r.stateNode.containerInfo;if(a===i||a.nodeType===8&&a.parentNode===i)break;if(o===4)for(o=r.return;o!==null;){var u=o.tag;if((u===3||u===4)&&(u=o.stateNode.containerInfo,u===i||u.nodeType===8&&u.parentNode===i))return;o=o.return}for(;a!==null;){if(o=Qn(a),o===null)return;if(u=o.tag,u===5||u===6){r=l=o;continue e}a=a.parentNode}}r=r.return}pu(function(){var d=l,v=No(t),m=[];e:{var p=Bu.get(e);if(p!==void 0){var h=Mo,x=e;switch(e){case"keypress":if(Xr(t)===0)break e;case"keydown":case"keyup":h=$f;break;case"focusin":x="focus",h=rl;break;case"focusout":x="blur",h=rl;break;case"beforeblur":case"afterblur":h=rl;break;case"click":if(t.button===2)break e;case"auxclick":case"dblclick":case"mousedown":case"mousemove":case"mouseup":case"mouseout":case"mouseover":case"contextmenu":h=Ma;break;case"drag":case"dragend":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"dragstart":case"drop":h=hf;break;case"touchcancel":case"touchend":case"touchmove":case"touchstart":h=Ff;break;case Ou:case Iu:case Au:h=yf;break;case Uu:h=jf;break;case"scroll":h=pf;break;case"wheel":h=Lf;break;case"copy":case"cut":case"paste":h=wf;break;case"gotpointercapture":case"lostpointercapture":case"pointercancel":case"pointerdown":case"pointermove":case"pointerout":case"pointerover":case"pointerup":h=Da}var w=(n&4)!==0,L=!w&&e==="scroll",c=w?p!==null?p+"Capture":null:p;w=[];for(var s=d,f;s!==null;){f=s;var g=f.stateNode;if(f.tag===5&&g!==null&&(f=g,c!==null&&(g=lr(s,c),g!=null&&w.push(fr(s,g,f)))),L)break;s=s.return}0<w.length&&(p=new h(p,x,null,t,v),m.push({event:p,listeners:w}))}}if(!(n&7)){e:{if(p=e==="mouseover"||e==="pointerover",h=e==="mouseout"||e==="pointerout",p&&t!==Ol&&(x=t.relatedTarget||t.fromElement)&&(Qn(x)||x[yn]))break e;if((h||p)&&(p=v.window===v?v:(p=v.ownerDocument)?p.defaultView||p.parentWindow:window,h?(x=t.relatedTarget||t.toElement,h=d,x=x?Qn(x):null,x!==null&&(L=rt(x),x!==L||x.tag!==5&&x.tag!==6)&&(x=null)):(h=null,x=d),h!==x)){if(w=Ma,g="onMouseLeave",c="onMouseEnter",s="mouse",(e==="pointerout"||e==="pointerover")&&(w=Da,g="onPointerLeave",c="onPointerEnter",s="pointer"),L=h==null?p:ct(h),f=x==null?p:ct(x),p=new w(g,s+"leave",h,t,v),p.target=L,p.relatedTarget=f,g=null,Qn(v)===d&&(w=new w(c,s+"enter",x,t,v),w.target=f,w.relatedTarget=L,g=w),L=g,h&&x)n:{for(w=h,c=x,s=0,f=w;f;f=it(f))s++;for(f=0,g=c;g;g=it(g))f++;for(;0<s-f;)w=it(w),s--;for(;0<f-s;)c=it(c),f--;for(;s--;){if(w===c||c!==null&&w===c.alternate)break n;w=it(w),c=it(c)}w=null}else w=null;h!==null&&Ga(m,p,h,w,!1),x!==null&&L!==null&&Ga(m,L,x,w,!0)}}e:{if(p=d?ct(d):window,h=p.nodeName&&p.nodeName.toLowerCase(),h==="select"||h==="input"&&p.type==="file")var _=Uf;else if(Aa(p))if(zu)_=Vf;else{_=Wf;var b=Bf}else(h=p.nodeName)&&h.toLowerCase()==="input"&&(p.type==="checkbox"||p.type==="radio")&&(_=Hf);if(_&&(_=_(e,d))){ju(m,_,t,v);break e}b&&b(e,p,d),e==="focusout"&&(b=p._wrapperState)&&b.controlled&&p.type==="number"&&zl(p,"number",p.value)}switch(b=d?ct(d):window,e){case"focusin":(Aa(b)||b.contentEditable==="true")&&(st=b,Vl=d,Zt=null);break;case"focusout":Zt=Vl=st=null;break;case"mousedown":Ql=!0;break;case"contextmenu":case"mouseup":case"dragend":Ql=!1,Va(m,t,v);break;case"selectionchange":if(Gf)break;case"keydown":case"keyup":Va(m,t,v)}var E;if(Do)e:{switch(e){case"compositionstart":var C="onCompositionStart";break e;case"compositionend":C="onCompositionEnd";break e;case"compositionupdate":C="onCompositionUpdate";break e}C=void 0}else at?Fu(e,t)&&(C="onCompositionEnd"):e==="keydown"&&t.keyCode===229&&(C="onCompositionStart");C&&(Nu&&t.locale!=="ko"&&(at||C!=="onCompositionStart"?C==="onCompositionEnd"&&at&&(E=Pu()):(Pn=v,Lo="value"in Pn?Pn.value:Pn.textContent,at=!0)),b=pi(d,C),0<b.length&&(C=new Ra(C,e,null,t,v),m.push({event:C,listeners:b}),E?C.data=E:(E=Tu(t),E!==null&&(C.data=E)))),(E=Rf?Df(e,t):Of(e,t))&&(d=pi(d,"onBeforeInput"),0<d.length&&(v=new Ra("onBeforeInput","beforeinput",null,t,v),m.push({event:v,listeners:d}),v.data=E))}Wu(m,n)})}function fr(e,n,t){return{instance:e,listener:n,currentTarget:t}}function pi(e,n){for(var t=n+"Capture",r=[];e!==null;){var i=e,l=i.stateNode;i.tag===5&&l!==null&&(i=l,l=lr(e,t),l!=null&&r.unshift(fr(e,l,i)),l=lr(e,n),l!=null&&r.push(fr(e,l,i))),e=e.return}return r}function it(e){if(e===null)return null;do e=e.return;while(e&&e.tag!==5);return e||null}function Ga(e,n,t,r,i){for(var l=n._reactName,o=[];t!==null&&t!==r;){var a=t,u=a.alternate,d=a.stateNode;if(u!==null&&u===r)break;a.tag===5&&d!==null&&(a=d,i?(u=lr(t,l),u!=null&&o.unshift(fr(t,u,a))):i||(u=lr(t,l),u!=null&&o.push(fr(t,u,a)))),t=t.return}o.length!==0&&e.push({event:n,listeners:o})}var qf=/\r\n?/g,Jf=/\u0000|\uFFFD/g;function Ya(e){return(typeof e=="string"?e:""+e).replace(qf,`
`).replace(Jf,"")}function Dr(e,n,t){if(n=Ya(n),Ya(e)!==n&&t)throw Error(S(425))}function mi(){}var Kl=null,Gl=null;function Yl(e,n){return e==="textarea"||e==="noscript"||typeof n.children=="string"||typeof n.children=="number"||typeof n.dangerouslySetInnerHTML=="object"&&n.dangerouslySetInnerHTML!==null&&n.dangerouslySetInnerHTML.__html!=null}var Xl=typeof setTimeout=="function"?setTimeout:void 0,ep=typeof clearTimeout=="function"?clearTimeout:void 0,Xa=typeof Promise=="function"?Promise:void 0,np=typeof queueMicrotask=="function"?queueMicrotask:typeof Xa<"u"?function(e){return Xa.resolve(null).then(e).catch(tp)}:Xl;function tp(e){setTimeout(function(){throw e})}function dl(e,n){var t=n,r=0;do{var i=t.nextSibling;if(e.removeChild(t),i&&i.nodeType===8)if(t=i.data,t==="/$"){if(r===0){e.removeChild(i),sr(n);return}r--}else t!=="$"&&t!=="$?"&&t!=="$!"||r++;t=i}while(t);sr(n)}function zn(e){for(;e!=null;e=e.nextSibling){var n=e.nodeType;if(n===1||n===3)break;if(n===8){if(n=e.data,n==="$"||n==="$!"||n==="$?")break;if(n==="/$")return null}}return e}function Za(e){e=e.previousSibling;for(var n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="$"||t==="$!"||t==="$?"){if(n===0)return e;n--}else t==="/$"&&n++}e=e.previousSibling}return null}var zt=Math.random().toString(36).slice(2),sn="__reactFiber$"+zt,pr="__reactProps$"+zt,yn="__reactContainer$"+zt,Zl="__reactEvents$"+zt,rp="__reactListeners$"+zt,ip="__reactHandles$"+zt;function Qn(e){var n=e[sn];if(n)return n;for(var t=e.parentNode;t;){if(n=t[yn]||t[sn]){if(t=n.alternate,n.child!==null||t!==null&&t.child!==null)for(e=Za(e);e!==null;){if(t=e[sn])return t;e=Za(e)}return n}e=t,t=e.parentNode}return null}function br(e){return e=e[sn]||e[yn],!e||e.tag!==5&&e.tag!==6&&e.tag!==13&&e.tag!==3?null:e}function ct(e){if(e.tag===5||e.tag===6)return e.stateNode;throw Error(S(33))}function Ri(e){return e[pr]||null}var ql=[],dt=-1;function Bn(e){return{current:e}}function Z(e){0>dt||(e.current=ql[dt],ql[dt]=null,dt--)}function Y(e,n){dt++,ql[dt]=e.current,e.current=n}var An={},_e=Bn(An),je=Bn(!1),Zn=An;function Ct(e,n){var t=e.type.contextTypes;if(!t)return An;var r=e.stateNode;if(r&&r.__reactInternalMemoizedUnmaskedChildContext===n)return r.__reactInternalMemoizedMaskedChildContext;var i={},l;for(l in t)i[l]=n[l];return r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=n,e.__reactInternalMemoizedMaskedChildContext=i),i}function ze(e){return e=e.childContextTypes,e!=null}function hi(){Z(je),Z(_e)}function qa(e,n,t){if(_e.current!==An)throw Error(S(168));Y(_e,n),Y(je,t)}function Vu(e,n,t){var r=e.stateNode;if(n=n.childContextTypes,typeof r.getChildContext!="function")return t;r=r.getChildContext();for(var i in r)if(!(i in n))throw Error(S(108,Ud(e)||"Unknown",i));return te({},t,r)}function gi(e){return e=(e=e.stateNode)&&e.__reactInternalMemoizedMergedChildContext||An,Zn=_e.current,Y(_e,e),Y(je,je.current),!0}function Ja(e,n,t){var r=e.stateNode;if(!r)throw Error(S(169));t?(e=Vu(e,n,Zn),r.__reactInternalMemoizedMergedChildContext=e,Z(je),Z(_e),Y(_e,e)):Z(je),Y(je,t)}var pn=null,Di=!1,fl=!1;function Qu(e){pn===null?pn=[e]:pn.push(e)}function lp(e){Di=!0,Qu(e)}function Wn(){if(!fl&&pn!==null){fl=!0;var e=0,n=K;try{var t=pn;for(K=1;e<t.length;e++){var r=t[e];do r=r(!0);while(r!==null)}pn=null,Di=!1}catch(i){throw pn!==null&&(pn=pn.slice(e+1)),vu(Fo,Wn),i}finally{K=n,fl=!1}}return null}var ft=[],pt=0,vi=null,yi=0,He=[],Ve=0,qn=null,mn=1,hn="";function Hn(e,n){ft[pt++]=yi,ft[pt++]=vi,vi=e,yi=n}function Ku(e,n,t){He[Ve++]=mn,He[Ve++]=hn,He[Ve++]=qn,qn=e;var r=mn;e=hn;var i=32-en(r)-1;r&=~(1<<i),t+=1;var l=32-en(n)+i;if(30<l){var o=i-i%5;l=(r&(1<<o)-1).toString(32),r>>=o,i-=o,mn=1<<32-en(n)+i|t<<i|r,hn=l+e}else mn=1<<l|t<<i|r,hn=e}function Io(e){e.return!==null&&(Hn(e,1),Ku(e,1,0))}function Ao(e){for(;e===vi;)vi=ft[--pt],ft[pt]=null,yi=ft[--pt],ft[pt]=null;for(;e===qn;)qn=He[--Ve],He[Ve]=null,hn=He[--Ve],He[Ve]=null,mn=He[--Ve],He[Ve]=null}var Ie=null,Oe=null,J=!1,Je=null;function Gu(e,n){var t=Qe(5,null,null,0);t.elementType="DELETED",t.stateNode=n,t.return=e,n=e.deletions,n===null?(e.deletions=[t],e.flags|=16):n.push(t)}function es(e,n){switch(e.tag){case 5:var t=e.type;return n=n.nodeType!==1||t.toLowerCase()!==n.nodeName.toLowerCase()?null:n,n!==null?(e.stateNode=n,Ie=e,Oe=zn(n.firstChild),!0):!1;case 6:return n=e.pendingProps===""||n.nodeType!==3?null:n,n!==null?(e.stateNode=n,Ie=e,Oe=null,!0):!1;case 13:return n=n.nodeType!==8?null:n,n!==null?(t=qn!==null?{id:mn,overflow:hn}:null,e.memoizedState={dehydrated:n,treeContext:t,retryLane:1073741824},t=Qe(18,null,null,0),t.stateNode=n,t.return=e,e.child=t,Ie=e,Oe=null,!0):!1;default:return!1}}function Jl(e){return(e.mode&1)!==0&&(e.flags&128)===0}function eo(e){if(J){var n=Oe;if(n){var t=n;if(!es(e,n)){if(Jl(e))throw Error(S(418));n=zn(t.nextSibling);var r=Ie;n&&es(e,n)?Gu(r,t):(e.flags=e.flags&-4097|2,J=!1,Ie=e)}}else{if(Jl(e))throw Error(S(418));e.flags=e.flags&-4097|2,J=!1,Ie=e}}}function ns(e){for(e=e.return;e!==null&&e.tag!==5&&e.tag!==3&&e.tag!==13;)e=e.return;Ie=e}function Or(e){if(e!==Ie)return!1;if(!J)return ns(e),J=!0,!1;var n;if((n=e.tag!==3)&&!(n=e.tag!==5)&&(n=e.type,n=n!=="head"&&n!=="body"&&!Yl(e.type,e.memoizedProps)),n&&(n=Oe)){if(Jl(e))throw Yu(),Error(S(418));for(;n;)Gu(e,n),n=zn(n.nextSibling)}if(ns(e),e.tag===13){if(e=e.memoizedState,e=e!==null?e.dehydrated:null,!e)throw Error(S(317));e:{for(e=e.nextSibling,n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="/$"){if(n===0){Oe=zn(e.nextSibling);break e}n--}else t!=="$"&&t!=="$!"&&t!=="$?"||n++}e=e.nextSibling}Oe=null}}else Oe=Ie?zn(e.stateNode.nextSibling):null;return!0}function Yu(){for(var e=Oe;e;)e=zn(e.nextSibling)}function Et(){Oe=Ie=null,J=!1}function Uo(e){Je===null?Je=[e]:Je.push(e)}var op=kn.ReactCurrentBatchConfig;function It(e,n,t){if(e=t.ref,e!==null&&typeof e!="function"&&typeof e!="object"){if(t._owner){if(t=t._owner,t){if(t.tag!==1)throw Error(S(309));var r=t.stateNode}if(!r)throw Error(S(147,e));var i=r,l=""+e;return n!==null&&n.ref!==null&&typeof n.ref=="function"&&n.ref._stringRef===l?n.ref:(n=function(o){var a=i.refs;o===null?delete a[l]:a[l]=o},n._stringRef=l,n)}if(typeof e!="string")throw Error(S(284));if(!t._owner)throw Error(S(290,e))}return e}function Ir(e,n){throw e=Object.prototype.toString.call(n),Error(S(31,e==="[object Object]"?"object with keys {"+Object.keys(n).join(", ")+"}":e))}function ts(e){var n=e._init;return n(e._payload)}function Xu(e){function n(c,s){if(e){var f=c.deletions;f===null?(c.deletions=[s],c.flags|=16):f.push(s)}}function t(c,s){if(!e)return null;for(;s!==null;)n(c,s),s=s.sibling;return null}function r(c,s){for(c=new Map;s!==null;)s.key!==null?c.set(s.key,s):c.set(s.index,s),s=s.sibling;return c}function i(c,s){return c=Dn(c,s),c.index=0,c.sibling=null,c}function l(c,s,f){return c.index=f,e?(f=c.alternate,f!==null?(f=f.index,f<s?(c.flags|=2,s):f):(c.flags|=2,s)):(c.flags|=1048576,s)}function o(c){return e&&c.alternate===null&&(c.flags|=2),c}function a(c,s,f,g){return s===null||s.tag!==6?(s=xl(f,c.mode,g),s.return=c,s):(s=i(s,f),s.return=c,s)}function u(c,s,f,g){var _=f.type;return _===ot?v(c,s,f.props.children,g,f.key):s!==null&&(s.elementType===_||typeof _=="object"&&_!==null&&_.$$typeof===bn&&ts(_)===s.type)?(g=i(s,f.props),g.ref=It(c,s,f),g.return=c,g):(g=ri(f.type,f.key,f.props,null,c.mode,g),g.ref=It(c,s,f),g.return=c,g)}function d(c,s,f,g){return s===null||s.tag!==4||s.stateNode.containerInfo!==f.containerInfo||s.stateNode.implementation!==f.implementation?(s=wl(f,c.mode,g),s.return=c,s):(s=i(s,f.children||[]),s.return=c,s)}function v(c,s,f,g,_){return s===null||s.tag!==7?(s=Xn(f,c.mode,g,_),s.return=c,s):(s=i(s,f),s.return=c,s)}function m(c,s,f){if(typeof s=="string"&&s!==""||typeof s=="number")return s=xl(""+s,c.mode,f),s.return=c,s;if(typeof s=="object"&&s!==null){switch(s.$$typeof){case Pr:return f=ri(s.type,s.key,s.props,null,c.mode,f),f.ref=It(c,null,s),f.return=c,f;case lt:return s=wl(s,c.mode,f),s.return=c,s;case bn:var g=s._init;return m(c,g(s._payload),f)}if(Wt(s)||Lt(s))return s=Xn(s,c.mode,f,null),s.return=c,s;Ir(c,s)}return null}function p(c,s,f,g){var _=s!==null?s.key:null;if(typeof f=="string"&&f!==""||typeof f=="number")return _!==null?null:a(c,s,""+f,g);if(typeof f=="object"&&f!==null){switch(f.$$typeof){case Pr:return f.key===_?u(c,s,f,g):null;case lt:return f.key===_?d(c,s,f,g):null;case bn:return _=f._init,p(c,s,_(f._payload),g)}if(Wt(f)||Lt(f))return _!==null?null:v(c,s,f,g,null);Ir(c,f)}return null}function h(c,s,f,g,_){if(typeof g=="string"&&g!==""||typeof g=="number")return c=c.get(f)||null,a(s,c,""+g,_);if(typeof g=="object"&&g!==null){switch(g.$$typeof){case Pr:return c=c.get(g.key===null?f:g.key)||null,u(s,c,g,_);case lt:return c=c.get(g.key===null?f:g.key)||null,d(s,c,g,_);case bn:var b=g._init;return h(c,s,f,b(g._payload),_)}if(Wt(g)||Lt(g))return c=c.get(f)||null,v(s,c,g,_,null);Ir(s,g)}return null}function x(c,s,f,g){for(var _=null,b=null,E=s,C=s=0,R=null;E!==null&&C<f.length;C++){E.index>C?(R=E,E=null):R=E.sibling;var N=p(c,E,f[C],g);if(N===null){E===null&&(E=R);break}e&&E&&N.alternate===null&&n(c,E),s=l(N,s,C),b===null?_=N:b.sibling=N,b=N,E=R}if(C===f.length)return t(c,E),J&&Hn(c,C),_;if(E===null){for(;C<f.length;C++)E=m(c,f[C],g),E!==null&&(s=l(E,s,C),b===null?_=E:b.sibling=E,b=E);return J&&Hn(c,C),_}for(E=r(c,E);C<f.length;C++)R=h(E,c,C,f[C],g),R!==null&&(e&&R.alternate!==null&&E.delete(R.key===null?C:R.key),s=l(R,s,C),b===null?_=R:b.sibling=R,b=R);return e&&E.forEach(function(q){return n(c,q)}),J&&Hn(c,C),_}function w(c,s,f,g){var _=Lt(f);if(typeof _!="function")throw Error(S(150));if(f=_.call(f),f==null)throw Error(S(151));for(var b=_=null,E=s,C=s=0,R=null,N=f.next();E!==null&&!N.done;C++,N=f.next()){E.index>C?(R=E,E=null):R=E.sibling;var q=p(c,E,N.value,g);if(q===null){E===null&&(E=R);break}e&&E&&q.alternate===null&&n(c,E),s=l(q,s,C),b===null?_=q:b.sibling=q,b=q,E=R}if(N.done)return t(c,E),J&&Hn(c,C),_;if(E===null){for(;!N.done;C++,N=f.next())N=m(c,N.value,g),N!==null&&(s=l(N,s,C),b===null?_=N:b.sibling=N,b=N);return J&&Hn(c,C),_}for(E=r(c,E);!N.done;C++,N=f.next())N=h(E,c,C,N.value,g),N!==null&&(e&&N.alternate!==null&&E.delete(N.key===null?C:N.key),s=l(N,s,C),b===null?_=N:b.sibling=N,b=N);return e&&E.forEach(function(Me){return n(c,Me)}),J&&Hn(c,C),_}function L(c,s,f,g){if(typeof f=="object"&&f!==null&&f.type===ot&&f.key===null&&(f=f.props.children),typeof f=="object"&&f!==null){switch(f.$$typeof){case Pr:e:{for(var _=f.key,b=s;b!==null;){if(b.key===_){if(_=f.type,_===ot){if(b.tag===7){t(c,b.sibling),s=i(b,f.props.children),s.return=c,c=s;break e}}else if(b.elementType===_||typeof _=="object"&&_!==null&&_.$$typeof===bn&&ts(_)===b.type){t(c,b.sibling),s=i(b,f.props),s.ref=It(c,b,f),s.return=c,c=s;break e}t(c,b);break}else n(c,b);b=b.sibling}f.type===ot?(s=Xn(f.props.children,c.mode,g,f.key),s.return=c,c=s):(g=ri(f.type,f.key,f.props,null,c.mode,g),g.ref=It(c,s,f),g.return=c,c=g)}return o(c);case lt:e:{for(b=f.key;s!==null;){if(s.key===b)if(s.tag===4&&s.stateNode.containerInfo===f.containerInfo&&s.stateNode.implementation===f.implementation){t(c,s.sibling),s=i(s,f.children||[]),s.return=c,c=s;break e}else{t(c,s);break}else n(c,s);s=s.sibling}s=wl(f,c.mode,g),s.return=c,c=s}return o(c);case bn:return b=f._init,L(c,s,b(f._payload),g)}if(Wt(f))return x(c,s,f,g);if(Lt(f))return w(c,s,f,g);Ir(c,f)}return typeof f=="string"&&f!==""||typeof f=="number"?(f=""+f,s!==null&&s.tag===6?(t(c,s.sibling),s=i(s,f),s.return=c,c=s):(t(c,s),s=xl(f,c.mode,g),s.return=c,c=s),o(c)):t(c,s)}return L}var $t=Xu(!0),Zu=Xu(!1),xi=Bn(null),wi=null,mt=null,Bo=null;function Wo(){Bo=mt=wi=null}function Ho(e){var n=xi.current;Z(xi),e._currentValue=n}function no(e,n,t){for(;e!==null;){var r=e.alternate;if((e.childLanes&n)!==n?(e.childLanes|=n,r!==null&&(r.childLanes|=n)):r!==null&&(r.childLanes&n)!==n&&(r.childLanes|=n),e===t)break;e=e.return}}function _t(e,n){wi=e,Bo=mt=null,e=e.dependencies,e!==null&&e.firstContext!==null&&(e.lanes&n&&(Te=!0),e.firstContext=null)}function Ge(e){var n=e._currentValue;if(Bo!==e)if(e={context:e,memoizedValue:n,next:null},mt===null){if(wi===null)throw Error(S(308));mt=e,wi.dependencies={lanes:0,firstContext:e}}else mt=mt.next=e;return n}var Kn=null;function Vo(e){Kn===null?Kn=[e]:Kn.push(e)}function qu(e,n,t,r){var i=n.interleaved;return i===null?(t.next=t,Vo(n)):(t.next=i.next,i.next=t),n.interleaved=t,xn(e,r)}function xn(e,n){e.lanes|=n;var t=e.alternate;for(t!==null&&(t.lanes|=n),t=e,e=e.return;e!==null;)e.childLanes|=n,t=e.alternate,t!==null&&(t.childLanes|=n),t=e,e=e.return;return t.tag===3?t.stateNode:null}var Cn=!1;function Qo(e){e.updateQueue={baseState:e.memoizedState,firstBaseUpdate:null,lastBaseUpdate:null,shared:{pending:null,interleaved:null,lanes:0},effects:null}}function Ju(e,n){e=e.updateQueue,n.updateQueue===e&&(n.updateQueue={baseState:e.baseState,firstBaseUpdate:e.firstBaseUpdate,lastBaseUpdate:e.lastBaseUpdate,shared:e.shared,effects:e.effects})}function gn(e,n){return{eventTime:e,lane:n,tag:0,payload:null,callback:null,next:null}}function Ln(e,n,t){var r=e.updateQueue;if(r===null)return null;if(r=r.shared,H&2){var i=r.pending;return i===null?n.next=n:(n.next=i.next,i.next=n),r.pending=n,xn(e,t)}return i=r.interleaved,i===null?(n.next=n,Vo(r)):(n.next=i.next,i.next=n),r.interleaved=n,xn(e,t)}function Zr(e,n,t){if(n=n.updateQueue,n!==null&&(n=n.shared,(t&4194240)!==0)){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,To(e,t)}}function rs(e,n){var t=e.updateQueue,r=e.alternate;if(r!==null&&(r=r.updateQueue,t===r)){var i=null,l=null;if(t=t.firstBaseUpdate,t!==null){do{var o={eventTime:t.eventTime,lane:t.lane,tag:t.tag,payload:t.payload,callback:t.callback,next:null};l===null?i=l=o:l=l.next=o,t=t.next}while(t!==null);l===null?i=l=n:l=l.next=n}else i=l=n;t={baseState:r.baseState,firstBaseUpdate:i,lastBaseUpdate:l,shared:r.shared,effects:r.effects},e.updateQueue=t;return}e=t.lastBaseUpdate,e===null?t.firstBaseUpdate=n:e.next=n,t.lastBaseUpdate=n}function ki(e,n,t,r){var i=e.updateQueue;Cn=!1;var l=i.firstBaseUpdate,o=i.lastBaseUpdate,a=i.shared.pending;if(a!==null){i.shared.pending=null;var u=a,d=u.next;u.next=null,o===null?l=d:o.next=d,o=u;var v=e.alternate;v!==null&&(v=v.updateQueue,a=v.lastBaseUpdate,a!==o&&(a===null?v.firstBaseUpdate=d:a.next=d,v.lastBaseUpdate=u))}if(l!==null){var m=i.baseState;o=0,v=d=u=null,a=l;do{var p=a.lane,h=a.eventTime;if((r&p)===p){v!==null&&(v=v.next={eventTime:h,lane:0,tag:a.tag,payload:a.payload,callback:a.callback,next:null});e:{var x=e,w=a;switch(p=n,h=t,w.tag){case 1:if(x=w.payload,typeof x=="function"){m=x.call(h,m,p);break e}m=x;break e;case 3:x.flags=x.flags&-65537|128;case 0:if(x=w.payload,p=typeof x=="function"?x.call(h,m,p):x,p==null)break e;m=te({},m,p);break e;case 2:Cn=!0}}a.callback!==null&&a.lane!==0&&(e.flags|=64,p=i.effects,p===null?i.effects=[a]:p.push(a))}else h={eventTime:h,lane:p,tag:a.tag,payload:a.payload,callback:a.callback,next:null},v===null?(d=v=h,u=m):v=v.next=h,o|=p;if(a=a.next,a===null){if(a=i.shared.pending,a===null)break;p=a,a=p.next,p.next=null,i.lastBaseUpdate=p,i.shared.pending=null}}while(!0);if(v===null&&(u=m),i.baseState=u,i.firstBaseUpdate=d,i.lastBaseUpdate=v,n=i.shared.interleaved,n!==null){i=n;do o|=i.lane,i=i.next;while(i!==n)}else l===null&&(i.shared.lanes=0);et|=o,e.lanes=o,e.memoizedState=m}}function is(e,n,t){if(e=n.effects,n.effects=null,e!==null)for(n=0;n<e.length;n++){var r=e[n],i=r.callback;if(i!==null){if(r.callback=null,r=t,typeof i!="function")throw Error(S(191,i));i.call(r)}}}var Cr={},cn=Bn(Cr),mr=Bn(Cr),hr=Bn(Cr);function Gn(e){if(e===Cr)throw Error(S(174));return e}function Ko(e,n){switch(Y(hr,n),Y(mr,e),Y(cn,Cr),e=n.nodeType,e){case 9:case 11:n=(n=n.documentElement)?n.namespaceURI:Ml(null,"");break;default:e=e===8?n.parentNode:n,n=e.namespaceURI||null,e=e.tagName,n=Ml(n,e)}Z(cn),Y(cn,n)}function Pt(){Z(cn),Z(mr),Z(hr)}function ec(e){Gn(hr.current);var n=Gn(cn.current),t=Ml(n,e.type);n!==t&&(Y(mr,e),Y(cn,t))}function Go(e){mr.current===e&&(Z(cn),Z(mr))}var ee=Bn(0);function _i(e){for(var n=e;n!==null;){if(n.tag===13){var t=n.memoizedState;if(t!==null&&(t=t.dehydrated,t===null||t.data==="$?"||t.data==="$!"))return n}else if(n.tag===19&&n.memoizedProps.revealOrder!==void 0){if(n.flags&128)return n}else if(n.child!==null){n.child.return=n,n=n.child;continue}if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return null;n=n.return}n.sibling.return=n.return,n=n.sibling}return null}var pl=[];function Yo(){for(var e=0;e<pl.length;e++)pl[e]._workInProgressVersionPrimary=null;pl.length=0}var qr=kn.ReactCurrentDispatcher,ml=kn.ReactCurrentBatchConfig,Jn=0,ne=null,ae=null,fe=null,Si=!1,qt=!1,gr=0,ap=0;function xe(){throw Error(S(321))}function Xo(e,n){if(n===null)return!1;for(var t=0;t<n.length&&t<e.length;t++)if(!tn(e[t],n[t]))return!1;return!0}function Zo(e,n,t,r,i,l){if(Jn=l,ne=n,n.memoizedState=null,n.updateQueue=null,n.lanes=0,qr.current=e===null||e.memoizedState===null?dp:fp,e=t(r,i),qt){l=0;do{if(qt=!1,gr=0,25<=l)throw Error(S(301));l+=1,fe=ae=null,n.updateQueue=null,qr.current=pp,e=t(r,i)}while(qt)}if(qr.current=bi,n=ae!==null&&ae.next!==null,Jn=0,fe=ae=ne=null,Si=!1,n)throw Error(S(300));return e}function qo(){var e=gr!==0;return gr=0,e}function an(){var e={memoizedState:null,baseState:null,baseQueue:null,queue:null,next:null};return fe===null?ne.memoizedState=fe=e:fe=fe.next=e,fe}function Ye(){if(ae===null){var e=ne.alternate;e=e!==null?e.memoizedState:null}else e=ae.next;var n=fe===null?ne.memoizedState:fe.next;if(n!==null)fe=n,ae=e;else{if(e===null)throw Error(S(310));ae=e,e={memoizedState:ae.memoizedState,baseState:ae.baseState,baseQueue:ae.baseQueue,queue:ae.queue,next:null},fe===null?ne.memoizedState=fe=e:fe=fe.next=e}return fe}function vr(e,n){return typeof n=="function"?n(e):n}function hl(e){var n=Ye(),t=n.queue;if(t===null)throw Error(S(311));t.lastRenderedReducer=e;var r=ae,i=r.baseQueue,l=t.pending;if(l!==null){if(i!==null){var o=i.next;i.next=l.next,l.next=o}r.baseQueue=i=l,t.pending=null}if(i!==null){l=i.next,r=r.baseState;var a=o=null,u=null,d=l;do{var v=d.lane;if((Jn&v)===v)u!==null&&(u=u.next={lane:0,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null}),r=d.hasEagerState?d.eagerState:e(r,d.action);else{var m={lane:v,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null};u===null?(a=u=m,o=r):u=u.next=m,ne.lanes|=v,et|=v}d=d.next}while(d!==null&&d!==l);u===null?o=r:u.next=a,tn(r,n.memoizedState)||(Te=!0),n.memoizedState=r,n.baseState=o,n.baseQueue=u,t.lastRenderedState=r}if(e=t.interleaved,e!==null){i=e;do l=i.lane,ne.lanes|=l,et|=l,i=i.next;while(i!==e)}else i===null&&(t.lanes=0);return[n.memoizedState,t.dispatch]}function gl(e){var n=Ye(),t=n.queue;if(t===null)throw Error(S(311));t.lastRenderedReducer=e;var r=t.dispatch,i=t.pending,l=n.memoizedState;if(i!==null){t.pending=null;var o=i=i.next;do l=e(l,o.action),o=o.next;while(o!==i);tn(l,n.memoizedState)||(Te=!0),n.memoizedState=l,n.baseQueue===null&&(n.baseState=l),t.lastRenderedState=l}return[l,r]}function nc(){}function tc(e,n){var t=ne,r=Ye(),i=n(),l=!tn(r.memoizedState,i);if(l&&(r.memoizedState=i,Te=!0),r=r.queue,Jo(lc.bind(null,t,r,e),[e]),r.getSnapshot!==n||l||fe!==null&&fe.memoizedState.tag&1){if(t.flags|=2048,yr(9,ic.bind(null,t,r,i,n),void 0,null),pe===null)throw Error(S(349));Jn&30||rc(t,n,i)}return i}function rc(e,n,t){e.flags|=16384,e={getSnapshot:n,value:t},n=ne.updateQueue,n===null?(n={lastEffect:null,stores:null},ne.updateQueue=n,n.stores=[e]):(t=n.stores,t===null?n.stores=[e]:t.push(e))}function ic(e,n,t,r){n.value=t,n.getSnapshot=r,oc(n)&&ac(e)}function lc(e,n,t){return t(function(){oc(n)&&ac(e)})}function oc(e){var n=e.getSnapshot;e=e.value;try{var t=n();return!tn(e,t)}catch{return!0}}function ac(e){var n=xn(e,1);n!==null&&nn(n,e,1,-1)}function ls(e){var n=an();return typeof e=="function"&&(e=e()),n.memoizedState=n.baseState=e,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:vr,lastRenderedState:e},n.queue=e,e=e.dispatch=cp.bind(null,ne,e),[n.memoizedState,e]}function yr(e,n,t,r){return e={tag:e,create:n,destroy:t,deps:r,next:null},n=ne.updateQueue,n===null?(n={lastEffect:null,stores:null},ne.updateQueue=n,n.lastEffect=e.next=e):(t=n.lastEffect,t===null?n.lastEffect=e.next=e:(r=t.next,t.next=e,e.next=r,n.lastEffect=e)),e}function sc(){return Ye().memoizedState}function Jr(e,n,t,r){var i=an();ne.flags|=e,i.memoizedState=yr(1|n,t,void 0,r===void 0?null:r)}function Oi(e,n,t,r){var i=Ye();r=r===void 0?null:r;var l=void 0;if(ae!==null){var o=ae.memoizedState;if(l=o.destroy,r!==null&&Xo(r,o.deps)){i.memoizedState=yr(n,t,l,r);return}}ne.flags|=e,i.memoizedState=yr(1|n,t,l,r)}function os(e,n){return Jr(8390656,8,e,n)}function Jo(e,n){return Oi(2048,8,e,n)}function uc(e,n){return Oi(4,2,e,n)}function cc(e,n){return Oi(4,4,e,n)}function dc(e,n){if(typeof n=="function")return e=e(),n(e),function(){n(null)};if(n!=null)return e=e(),n.current=e,function(){n.current=null}}function fc(e,n,t){return t=t!=null?t.concat([e]):null,Oi(4,4,dc.bind(null,n,e),t)}function ea(){}function pc(e,n){var t=Ye();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Xo(n,r[1])?r[0]:(t.memoizedState=[e,n],e)}function mc(e,n){var t=Ye();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Xo(n,r[1])?r[0]:(e=e(),t.memoizedState=[e,n],e)}function hc(e,n,t){return Jn&21?(tn(t,n)||(t=wu(),ne.lanes|=t,et|=t,e.baseState=!0),n):(e.baseState&&(e.baseState=!1,Te=!0),e.memoizedState=t)}function sp(e,n){var t=K;K=t!==0&&4>t?t:4,e(!0);var r=ml.transition;ml.transition={};try{e(!1),n()}finally{K=t,ml.transition=r}}function gc(){return Ye().memoizedState}function up(e,n,t){var r=Rn(e);if(t={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null},vc(e))yc(n,t);else if(t=qu(e,n,t,r),t!==null){var i=$e();nn(t,e,r,i),xc(t,n,r)}}function cp(e,n,t){var r=Rn(e),i={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null};if(vc(e))yc(n,i);else{var l=e.alternate;if(e.lanes===0&&(l===null||l.lanes===0)&&(l=n.lastRenderedReducer,l!==null))try{var o=n.lastRenderedState,a=l(o,t);if(i.hasEagerState=!0,i.eagerState=a,tn(a,o)){var u=n.interleaved;u===null?(i.next=i,Vo(n)):(i.next=u.next,u.next=i),n.interleaved=i;return}}catch{}finally{}t=qu(e,n,i,r),t!==null&&(i=$e(),nn(t,e,r,i),xc(t,n,r))}}function vc(e){var n=e.alternate;return e===ne||n!==null&&n===ne}function yc(e,n){qt=Si=!0;var t=e.pending;t===null?n.next=n:(n.next=t.next,t.next=n),e.pending=n}function xc(e,n,t){if(t&4194240){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,To(e,t)}}var bi={readContext:Ge,useCallback:xe,useContext:xe,useEffect:xe,useImperativeHandle:xe,useInsertionEffect:xe,useLayoutEffect:xe,useMemo:xe,useReducer:xe,useRef:xe,useState:xe,useDebugValue:xe,useDeferredValue:xe,useTransition:xe,useMutableSource:xe,useSyncExternalStore:xe,useId:xe,unstable_isNewReconciler:!1},dp={readContext:Ge,useCallback:function(e,n){return an().memoizedState=[e,n===void 0?null:n],e},useContext:Ge,useEffect:os,useImperativeHandle:function(e,n,t){return t=t!=null?t.concat([e]):null,Jr(4194308,4,dc.bind(null,n,e),t)},useLayoutEffect:function(e,n){return Jr(4194308,4,e,n)},useInsertionEffect:function(e,n){return Jr(4,2,e,n)},useMemo:function(e,n){var t=an();return n=n===void 0?null:n,e=e(),t.memoizedState=[e,n],e},useReducer:function(e,n,t){var r=an();return n=t!==void 0?t(n):n,r.memoizedState=r.baseState=n,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:e,lastRenderedState:n},r.queue=e,e=e.dispatch=up.bind(null,ne,e),[r.memoizedState,e]},useRef:function(e){var n=an();return e={current:e},n.memoizedState=e},useState:ls,useDebugValue:ea,useDeferredValue:function(e){return an().memoizedState=e},useTransition:function(){var e=ls(!1),n=e[0];return e=sp.bind(null,e[1]),an().memoizedState=e,[n,e]},useMutableSource:function(){},useSyncExternalStore:function(e,n,t){var r=ne,i=an();if(J){if(t===void 0)throw Error(S(407));t=t()}else{if(t=n(),pe===null)throw Error(S(349));Jn&30||rc(r,n,t)}i.memoizedState=t;var l={value:t,getSnapshot:n};return i.queue=l,os(lc.bind(null,r,l,e),[e]),r.flags|=2048,yr(9,ic.bind(null,r,l,t,n),void 0,null),t},useId:function(){var e=an(),n=pe.identifierPrefix;if(J){var t=hn,r=mn;t=(r&~(1<<32-en(r)-1)).toString(32)+t,n=":"+n+"R"+t,t=gr++,0<t&&(n+="H"+t.toString(32)),n+=":"}else t=ap++,n=":"+n+"r"+t.toString(32)+":";return e.memoizedState=n},unstable_isNewReconciler:!1},fp={readContext:Ge,useCallback:pc,useContext:Ge,useEffect:Jo,useImperativeHandle:fc,useInsertionEffect:uc,useLayoutEffect:cc,useMemo:mc,useReducer:hl,useRef:sc,useState:function(){return hl(vr)},useDebugValue:ea,useDeferredValue:function(e){var n=Ye();return hc(n,ae.memoizedState,e)},useTransition:function(){var e=hl(vr)[0],n=Ye().memoizedState;return[e,n]},useMutableSource:nc,useSyncExternalStore:tc,useId:gc,unstable_isNewReconciler:!1},pp={readContext:Ge,useCallback:pc,useContext:Ge,useEffect:Jo,useImperativeHandle:fc,useInsertionEffect:uc,useLayoutEffect:cc,useMemo:mc,useReducer:gl,useRef:sc,useState:function(){return gl(vr)},useDebugValue:ea,useDeferredValue:function(e){var n=Ye();return ae===null?n.memoizedState=e:hc(n,ae.memoizedState,e)},useTransition:function(){var e=gl(vr)[0],n=Ye().memoizedState;return[e,n]},useMutableSource:nc,useSyncExternalStore:tc,useId:gc,unstable_isNewReconciler:!1};function Ze(e,n){if(e&&e.defaultProps){n=te({},n),e=e.defaultProps;for(var t in e)n[t]===void 0&&(n[t]=e[t]);return n}return n}function to(e,n,t,r){n=e.memoizedState,t=t(r,n),t=t==null?n:te({},n,t),e.memoizedState=t,e.lanes===0&&(e.updateQueue.baseState=t)}var Ii={isMounted:function(e){return(e=e._reactInternals)?rt(e)===e:!1},enqueueSetState:function(e,n,t){e=e._reactInternals;var r=$e(),i=Rn(e),l=gn(r,i);l.payload=n,t!=null&&(l.callback=t),n=Ln(e,l,i),n!==null&&(nn(n,e,i,r),Zr(n,e,i))},enqueueReplaceState:function(e,n,t){e=e._reactInternals;var r=$e(),i=Rn(e),l=gn(r,i);l.tag=1,l.payload=n,t!=null&&(l.callback=t),n=Ln(e,l,i),n!==null&&(nn(n,e,i,r),Zr(n,e,i))},enqueueForceUpdate:function(e,n){e=e._reactInternals;var t=$e(),r=Rn(e),i=gn(t,r);i.tag=2,n!=null&&(i.callback=n),n=Ln(e,i,r),n!==null&&(nn(n,e,r,t),Zr(n,e,r))}};function as(e,n,t,r,i,l,o){return e=e.stateNode,typeof e.shouldComponentUpdate=="function"?e.shouldComponentUpdate(r,l,o):n.prototype&&n.prototype.isPureReactComponent?!cr(t,r)||!cr(i,l):!0}function wc(e,n,t){var r=!1,i=An,l=n.contextType;return typeof l=="object"&&l!==null?l=Ge(l):(i=ze(n)?Zn:_e.current,r=n.contextTypes,l=(r=r!=null)?Ct(e,i):An),n=new n(t,l),e.memoizedState=n.state!==null&&n.state!==void 0?n.state:null,n.updater=Ii,e.stateNode=n,n._reactInternals=e,r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=i,e.__reactInternalMemoizedMaskedChildContext=l),n}function ss(e,n,t,r){e=n.state,typeof n.componentWillReceiveProps=="function"&&n.componentWillReceiveProps(t,r),typeof n.UNSAFE_componentWillReceiveProps=="function"&&n.UNSAFE_componentWillReceiveProps(t,r),n.state!==e&&Ii.enqueueReplaceState(n,n.state,null)}function ro(e,n,t,r){var i=e.stateNode;i.props=t,i.state=e.memoizedState,i.refs={},Qo(e);var l=n.contextType;typeof l=="object"&&l!==null?i.context=Ge(l):(l=ze(n)?Zn:_e.current,i.context=Ct(e,l)),i.state=e.memoizedState,l=n.getDerivedStateFromProps,typeof l=="function"&&(to(e,n,l,t),i.state=e.memoizedState),typeof n.getDerivedStateFromProps=="function"||typeof i.getSnapshotBeforeUpdate=="function"||typeof i.UNSAFE_componentWillMount!="function"&&typeof i.componentWillMount!="function"||(n=i.state,typeof i.componentWillMount=="function"&&i.componentWillMount(),typeof i.UNSAFE_componentWillMount=="function"&&i.UNSAFE_componentWillMount(),n!==i.state&&Ii.enqueueReplaceState(i,i.state,null),ki(e,t,i,r),i.state=e.memoizedState),typeof i.componentDidMount=="function"&&(e.flags|=4194308)}function Nt(e,n){try{var t="",r=n;do t+=Ad(r),r=r.return;while(r);var i=t}catch(l){i=`
Error generating stack: `+l.message+`
`+l.stack}return{value:e,source:n,stack:i,digest:null}}function vl(e,n,t){return{value:e,source:null,stack:t??null,digest:n??null}}function io(e,n){try{console.error(n.value)}catch(t){setTimeout(function(){throw t})}}var mp=typeof WeakMap=="function"?WeakMap:Map;function kc(e,n,t){t=gn(-1,t),t.tag=3,t.payload={element:null};var r=n.value;return t.callback=function(){Ei||(Ei=!0,ho=r),io(e,n)},t}function _c(e,n,t){t=gn(-1,t),t.tag=3;var r=e.type.getDerivedStateFromError;if(typeof r=="function"){var i=n.value;t.payload=function(){return r(i)},t.callback=function(){io(e,n)}}var l=e.stateNode;return l!==null&&typeof l.componentDidCatch=="function"&&(t.callback=function(){io(e,n),typeof r!="function"&&(Mn===null?Mn=new Set([this]):Mn.add(this));var o=n.stack;this.componentDidCatch(n.value,{componentStack:o!==null?o:""})}),t}function us(e,n,t){var r=e.pingCache;if(r===null){r=e.pingCache=new mp;var i=new Set;r.set(n,i)}else i=r.get(n),i===void 0&&(i=new Set,r.set(n,i));i.has(t)||(i.add(t),e=Pp.bind(null,e,n,t),n.then(e,e))}function cs(e){do{var n;if((n=e.tag===13)&&(n=e.memoizedState,n=n!==null?n.dehydrated!==null:!0),n)return e;e=e.return}while(e!==null);return null}function ds(e,n,t,r,i){return e.mode&1?(e.flags|=65536,e.lanes=i,e):(e===n?e.flags|=65536:(e.flags|=128,t.flags|=131072,t.flags&=-52805,t.tag===1&&(t.alternate===null?t.tag=17:(n=gn(-1,1),n.tag=2,Ln(t,n,1))),t.lanes|=1),e)}var hp=kn.ReactCurrentOwner,Te=!1;function Ee(e,n,t,r){n.child=e===null?Zu(n,null,t,r):$t(n,e.child,t,r)}function fs(e,n,t,r,i){t=t.render;var l=n.ref;return _t(n,i),r=Zo(e,n,t,r,l,i),t=qo(),e!==null&&!Te?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,wn(e,n,i)):(J&&t&&Io(n),n.flags|=1,Ee(e,n,r,i),n.child)}function ps(e,n,t,r,i){if(e===null){var l=t.type;return typeof l=="function"&&!sa(l)&&l.defaultProps===void 0&&t.compare===null&&t.defaultProps===void 0?(n.tag=15,n.type=l,Sc(e,n,l,r,i)):(e=ri(t.type,null,r,n,n.mode,i),e.ref=n.ref,e.return=n,n.child=e)}if(l=e.child,!(e.lanes&i)){var o=l.memoizedProps;if(t=t.compare,t=t!==null?t:cr,t(o,r)&&e.ref===n.ref)return wn(e,n,i)}return n.flags|=1,e=Dn(l,r),e.ref=n.ref,e.return=n,n.child=e}function Sc(e,n,t,r,i){if(e!==null){var l=e.memoizedProps;if(cr(l,r)&&e.ref===n.ref)if(Te=!1,n.pendingProps=r=l,(e.lanes&i)!==0)e.flags&131072&&(Te=!0);else return n.lanes=e.lanes,wn(e,n,i)}return lo(e,n,t,r,i)}function bc(e,n,t){var r=n.pendingProps,i=r.children,l=e!==null?e.memoizedState:null;if(r.mode==="hidden")if(!(n.mode&1))n.memoizedState={baseLanes:0,cachePool:null,transitions:null},Y(gt,Re),Re|=t;else{if(!(t&1073741824))return e=l!==null?l.baseLanes|t:t,n.lanes=n.childLanes=1073741824,n.memoizedState={baseLanes:e,cachePool:null,transitions:null},n.updateQueue=null,Y(gt,Re),Re|=e,null;n.memoizedState={baseLanes:0,cachePool:null,transitions:null},r=l!==null?l.baseLanes:t,Y(gt,Re),Re|=r}else l!==null?(r=l.baseLanes|t,n.memoizedState=null):r=t,Y(gt,Re),Re|=r;return Ee(e,n,i,t),n.child}function Cc(e,n){var t=n.ref;(e===null&&t!==null||e!==null&&e.ref!==t)&&(n.flags|=512,n.flags|=2097152)}function lo(e,n,t,r,i){var l=ze(t)?Zn:_e.current;return l=Ct(n,l),_t(n,i),t=Zo(e,n,t,r,l,i),r=qo(),e!==null&&!Te?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,wn(e,n,i)):(J&&r&&Io(n),n.flags|=1,Ee(e,n,t,i),n.child)}function ms(e,n,t,r,i){if(ze(t)){var l=!0;gi(n)}else l=!1;if(_t(n,i),n.stateNode===null)ei(e,n),wc(n,t,r),ro(n,t,r,i),r=!0;else if(e===null){var o=n.stateNode,a=n.memoizedProps;o.props=a;var u=o.context,d=t.contextType;typeof d=="object"&&d!==null?d=Ge(d):(d=ze(t)?Zn:_e.current,d=Ct(n,d));var v=t.getDerivedStateFromProps,m=typeof v=="function"||typeof o.getSnapshotBeforeUpdate=="function";m||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==r||u!==d)&&ss(n,o,r,d),Cn=!1;var p=n.memoizedState;o.state=p,ki(n,r,o,i),u=n.memoizedState,a!==r||p!==u||je.current||Cn?(typeof v=="function"&&(to(n,t,v,r),u=n.memoizedState),(a=Cn||as(n,t,a,r,p,u,d))?(m||typeof o.UNSAFE_componentWillMount!="function"&&typeof o.componentWillMount!="function"||(typeof o.componentWillMount=="function"&&o.componentWillMount(),typeof o.UNSAFE_componentWillMount=="function"&&o.UNSAFE_componentWillMount()),typeof o.componentDidMount=="function"&&(n.flags|=4194308)):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),n.memoizedProps=r,n.memoizedState=u),o.props=r,o.state=u,o.context=d,r=a):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),r=!1)}else{o=n.stateNode,Ju(e,n),a=n.memoizedProps,d=n.type===n.elementType?a:Ze(n.type,a),o.props=d,m=n.pendingProps,p=o.context,u=t.contextType,typeof u=="object"&&u!==null?u=Ge(u):(u=ze(t)?Zn:_e.current,u=Ct(n,u));var h=t.getDerivedStateFromProps;(v=typeof h=="function"||typeof o.getSnapshotBeforeUpdate=="function")||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==m||p!==u)&&ss(n,o,r,u),Cn=!1,p=n.memoizedState,o.state=p,ki(n,r,o,i);var x=n.memoizedState;a!==m||p!==x||je.current||Cn?(typeof h=="function"&&(to(n,t,h,r),x=n.memoizedState),(d=Cn||as(n,t,d,r,p,x,u)||!1)?(v||typeof o.UNSAFE_componentWillUpdate!="function"&&typeof o.componentWillUpdate!="function"||(typeof o.componentWillUpdate=="function"&&o.componentWillUpdate(r,x,u),typeof o.UNSAFE_componentWillUpdate=="function"&&o.UNSAFE_componentWillUpdate(r,x,u)),typeof o.componentDidUpdate=="function"&&(n.flags|=4),typeof o.getSnapshotBeforeUpdate=="function"&&(n.flags|=1024)):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),n.memoizedProps=r,n.memoizedState=x),o.props=r,o.state=x,o.context=u,r=d):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),r=!1)}return oo(e,n,t,r,l,i)}function oo(e,n,t,r,i,l){Cc(e,n);var o=(n.flags&128)!==0;if(!r&&!o)return i&&Ja(n,t,!1),wn(e,n,l);r=n.stateNode,hp.current=n;var a=o&&typeof t.getDerivedStateFromError!="function"?null:r.render();return n.flags|=1,e!==null&&o?(n.child=$t(n,e.child,null,l),n.child=$t(n,null,a,l)):Ee(e,n,a,l),n.memoizedState=r.state,i&&Ja(n,t,!0),n.child}function Ec(e){var n=e.stateNode;n.pendingContext?qa(e,n.pendingContext,n.pendingContext!==n.context):n.context&&qa(e,n.context,!1),Ko(e,n.containerInfo)}function hs(e,n,t,r,i){return Et(),Uo(i),n.flags|=256,Ee(e,n,t,r),n.child}var ao={dehydrated:null,treeContext:null,retryLane:0};function so(e){return{baseLanes:e,cachePool:null,transitions:null}}function $c(e,n,t){var r=n.pendingProps,i=ee.current,l=!1,o=(n.flags&128)!==0,a;if((a=o)||(a=e!==null&&e.memoizedState===null?!1:(i&2)!==0),a?(l=!0,n.flags&=-129):(e===null||e.memoizedState!==null)&&(i|=1),Y(ee,i&1),e===null)return eo(n),e=n.memoizedState,e!==null&&(e=e.dehydrated,e!==null)?(n.mode&1?e.data==="$!"?n.lanes=8:n.lanes=1073741824:n.lanes=1,null):(o=r.children,e=r.fallback,l?(r=n.mode,l=n.child,o={mode:"hidden",children:o},!(r&1)&&l!==null?(l.childLanes=0,l.pendingProps=o):l=Bi(o,r,0,null),e=Xn(e,r,t,null),l.return=n,e.return=n,l.sibling=e,n.child=l,n.child.memoizedState=so(t),n.memoizedState=ao,e):na(n,o));if(i=e.memoizedState,i!==null&&(a=i.dehydrated,a!==null))return gp(e,n,o,r,a,i,t);if(l){l=r.fallback,o=n.mode,i=e.child,a=i.sibling;var u={mode:"hidden",children:r.children};return!(o&1)&&n.child!==i?(r=n.child,r.childLanes=0,r.pendingProps=u,n.deletions=null):(r=Dn(i,u),r.subtreeFlags=i.subtreeFlags&14680064),a!==null?l=Dn(a,l):(l=Xn(l,o,t,null),l.flags|=2),l.return=n,r.return=n,r.sibling=l,n.child=r,r=l,l=n.child,o=e.child.memoizedState,o=o===null?so(t):{baseLanes:o.baseLanes|t,cachePool:null,transitions:o.transitions},l.memoizedState=o,l.childLanes=e.childLanes&~t,n.memoizedState=ao,r}return l=e.child,e=l.sibling,r=Dn(l,{mode:"visible",children:r.children}),!(n.mode&1)&&(r.lanes=t),r.return=n,r.sibling=null,e!==null&&(t=n.deletions,t===null?(n.deletions=[e],n.flags|=16):t.push(e)),n.child=r,n.memoizedState=null,r}function na(e,n){return n=Bi({mode:"visible",children:n},e.mode,0,null),n.return=e,e.child=n}function Ar(e,n,t,r){return r!==null&&Uo(r),$t(n,e.child,null,t),e=na(n,n.pendingProps.children),e.flags|=2,n.memoizedState=null,e}function gp(e,n,t,r,i,l,o){if(t)return n.flags&256?(n.flags&=-257,r=vl(Error(S(422))),Ar(e,n,o,r)):n.memoizedState!==null?(n.child=e.child,n.flags|=128,null):(l=r.fallback,i=n.mode,r=Bi({mode:"visible",children:r.children},i,0,null),l=Xn(l,i,o,null),l.flags|=2,r.return=n,l.return=n,r.sibling=l,n.child=r,n.mode&1&&$t(n,e.child,null,o),n.child.memoizedState=so(o),n.memoizedState=ao,l);if(!(n.mode&1))return Ar(e,n,o,null);if(i.data==="$!"){if(r=i.nextSibling&&i.nextSibling.dataset,r)var a=r.dgst;return r=a,l=Error(S(419)),r=vl(l,r,void 0),Ar(e,n,o,r)}if(a=(o&e.childLanes)!==0,Te||a){if(r=pe,r!==null){switch(o&-o){case 4:i=2;break;case 16:i=8;break;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:i=32;break;case 536870912:i=268435456;break;default:i=0}i=i&(r.suspendedLanes|o)?0:i,i!==0&&i!==l.retryLane&&(l.retryLane=i,xn(e,i),nn(r,e,i,-1))}return aa(),r=vl(Error(S(421))),Ar(e,n,o,r)}return i.data==="$?"?(n.flags|=128,n.child=e.child,n=Np.bind(null,e),i._reactRetry=n,null):(e=l.treeContext,Oe=zn(i.nextSibling),Ie=n,J=!0,Je=null,e!==null&&(He[Ve++]=mn,He[Ve++]=hn,He[Ve++]=qn,mn=e.id,hn=e.overflow,qn=n),n=na(n,r.children),n.flags|=4096,n)}function gs(e,n,t){e.lanes|=n;var r=e.alternate;r!==null&&(r.lanes|=n),no(e.return,n,t)}function yl(e,n,t,r,i){var l=e.memoizedState;l===null?e.memoizedState={isBackwards:n,rendering:null,renderingStartTime:0,last:r,tail:t,tailMode:i}:(l.isBackwards=n,l.rendering=null,l.renderingStartTime=0,l.last=r,l.tail=t,l.tailMode=i)}function Pc(e,n,t){var r=n.pendingProps,i=r.revealOrder,l=r.tail;if(Ee(e,n,r.children,t),r=ee.current,r&2)r=r&1|2,n.flags|=128;else{if(e!==null&&e.flags&128)e:for(e=n.child;e!==null;){if(e.tag===13)e.memoizedState!==null&&gs(e,t,n);else if(e.tag===19)gs(e,t,n);else if(e.child!==null){e.child.return=e,e=e.child;continue}if(e===n)break e;for(;e.sibling===null;){if(e.return===null||e.return===n)break e;e=e.return}e.sibling.return=e.return,e=e.sibling}r&=1}if(Y(ee,r),!(n.mode&1))n.memoizedState=null;else switch(i){case"forwards":for(t=n.child,i=null;t!==null;)e=t.alternate,e!==null&&_i(e)===null&&(i=t),t=t.sibling;t=i,t===null?(i=n.child,n.child=null):(i=t.sibling,t.sibling=null),yl(n,!1,i,t,l);break;case"backwards":for(t=null,i=n.child,n.child=null;i!==null;){if(e=i.alternate,e!==null&&_i(e)===null){n.child=i;break}e=i.sibling,i.sibling=t,t=i,i=e}yl(n,!0,t,null,l);break;case"together":yl(n,!1,null,null,void 0);break;default:n.memoizedState=null}return n.child}function ei(e,n){!(n.mode&1)&&e!==null&&(e.alternate=null,n.alternate=null,n.flags|=2)}function wn(e,n,t){if(e!==null&&(n.dependencies=e.dependencies),et|=n.lanes,!(t&n.childLanes))return null;if(e!==null&&n.child!==e.child)throw Error(S(153));if(n.child!==null){for(e=n.child,t=Dn(e,e.pendingProps),n.child=t,t.return=n;e.sibling!==null;)e=e.sibling,t=t.sibling=Dn(e,e.pendingProps),t.return=n;t.sibling=null}return n.child}function vp(e,n,t){switch(n.tag){case 3:Ec(n),Et();break;case 5:ec(n);break;case 1:ze(n.type)&&gi(n);break;case 4:Ko(n,n.stateNode.containerInfo);break;case 10:var r=n.type._context,i=n.memoizedProps.value;Y(xi,r._currentValue),r._currentValue=i;break;case 13:if(r=n.memoizedState,r!==null)return r.dehydrated!==null?(Y(ee,ee.current&1),n.flags|=128,null):t&n.child.childLanes?$c(e,n,t):(Y(ee,ee.current&1),e=wn(e,n,t),e!==null?e.sibling:null);Y(ee,ee.current&1);break;case 19:if(r=(t&n.childLanes)!==0,e.flags&128){if(r)return Pc(e,n,t);n.flags|=128}if(i=n.memoizedState,i!==null&&(i.rendering=null,i.tail=null,i.lastEffect=null),Y(ee,ee.current),r)break;return null;case 22:case 23:return n.lanes=0,bc(e,n,t)}return wn(e,n,t)}var Nc,uo,Fc,Tc;Nc=function(e,n){for(var t=n.child;t!==null;){if(t.tag===5||t.tag===6)e.appendChild(t.stateNode);else if(t.tag!==4&&t.child!==null){t.child.return=t,t=t.child;continue}if(t===n)break;for(;t.sibling===null;){if(t.return===null||t.return===n)return;t=t.return}t.sibling.return=t.return,t=t.sibling}};uo=function(){};Fc=function(e,n,t,r){var i=e.memoizedProps;if(i!==r){e=n.stateNode,Gn(cn.current);var l=null;switch(t){case"input":i=Tl(e,i),r=Tl(e,r),l=[];break;case"select":i=te({},i,{value:void 0}),r=te({},r,{value:void 0}),l=[];break;case"textarea":i=Ll(e,i),r=Ll(e,r),l=[];break;default:typeof i.onClick!="function"&&typeof r.onClick=="function"&&(e.onclick=mi)}Rl(t,r);var o;t=null;for(d in i)if(!r.hasOwnProperty(d)&&i.hasOwnProperty(d)&&i[d]!=null)if(d==="style"){var a=i[d];for(o in a)a.hasOwnProperty(o)&&(t||(t={}),t[o]="")}else d!=="dangerouslySetInnerHTML"&&d!=="children"&&d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&d!=="autoFocus"&&(rr.hasOwnProperty(d)?l||(l=[]):(l=l||[]).push(d,null));for(d in r){var u=r[d];if(a=i!=null?i[d]:void 0,r.hasOwnProperty(d)&&u!==a&&(u!=null||a!=null))if(d==="style")if(a){for(o in a)!a.hasOwnProperty(o)||u&&u.hasOwnProperty(o)||(t||(t={}),t[o]="");for(o in u)u.hasOwnProperty(o)&&a[o]!==u[o]&&(t||(t={}),t[o]=u[o])}else t||(l||(l=[]),l.push(d,t)),t=u;else d==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,a=a?a.__html:void 0,u!=null&&a!==u&&(l=l||[]).push(d,u)):d==="children"?typeof u!="string"&&typeof u!="number"||(l=l||[]).push(d,""+u):d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&(rr.hasOwnProperty(d)?(u!=null&&d==="onScroll"&&X("scroll",e),l||a===u||(l=[])):(l=l||[]).push(d,u))}t&&(l=l||[]).push("style",t);var d=l;(n.updateQueue=d)&&(n.flags|=4)}};Tc=function(e,n,t,r){t!==r&&(n.flags|=4)};function At(e,n){if(!J)switch(e.tailMode){case"hidden":n=e.tail;for(var t=null;n!==null;)n.alternate!==null&&(t=n),n=n.sibling;t===null?e.tail=null:t.sibling=null;break;case"collapsed":t=e.tail;for(var r=null;t!==null;)t.alternate!==null&&(r=t),t=t.sibling;r===null?n||e.tail===null?e.tail=null:e.tail.sibling=null:r.sibling=null}}function we(e){var n=e.alternate!==null&&e.alternate.child===e.child,t=0,r=0;if(n)for(var i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags&14680064,r|=i.flags&14680064,i.return=e,i=i.sibling;else for(i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags,r|=i.flags,i.return=e,i=i.sibling;return e.subtreeFlags|=r,e.childLanes=t,n}function yp(e,n,t){var r=n.pendingProps;switch(Ao(n),n.tag){case 2:case 16:case 15:case 0:case 11:case 7:case 8:case 12:case 9:case 14:return we(n),null;case 1:return ze(n.type)&&hi(),we(n),null;case 3:return r=n.stateNode,Pt(),Z(je),Z(_e),Yo(),r.pendingContext&&(r.context=r.pendingContext,r.pendingContext=null),(e===null||e.child===null)&&(Or(n)?n.flags|=4:e===null||e.memoizedState.isDehydrated&&!(n.flags&256)||(n.flags|=1024,Je!==null&&(yo(Je),Je=null))),uo(e,n),we(n),null;case 5:Go(n);var i=Gn(hr.current);if(t=n.type,e!==null&&n.stateNode!=null)Fc(e,n,t,r,i),e.ref!==n.ref&&(n.flags|=512,n.flags|=2097152);else{if(!r){if(n.stateNode===null)throw Error(S(166));return we(n),null}if(e=Gn(cn.current),Or(n)){r=n.stateNode,t=n.type;var l=n.memoizedProps;switch(r[sn]=n,r[pr]=l,e=(n.mode&1)!==0,t){case"dialog":X("cancel",r),X("close",r);break;case"iframe":case"object":case"embed":X("load",r);break;case"video":case"audio":for(i=0;i<Vt.length;i++)X(Vt[i],r);break;case"source":X("error",r);break;case"img":case"image":case"link":X("error",r),X("load",r);break;case"details":X("toggle",r);break;case"input":Ca(r,l),X("invalid",r);break;case"select":r._wrapperState={wasMultiple:!!l.multiple},X("invalid",r);break;case"textarea":$a(r,l),X("invalid",r)}Rl(t,l),i=null;for(var o in l)if(l.hasOwnProperty(o)){var a=l[o];o==="children"?typeof a=="string"?r.textContent!==a&&(l.suppressHydrationWarning!==!0&&Dr(r.textContent,a,e),i=["children",a]):typeof a=="number"&&r.textContent!==""+a&&(l.suppressHydrationWarning!==!0&&Dr(r.textContent,a,e),i=["children",""+a]):rr.hasOwnProperty(o)&&a!=null&&o==="onScroll"&&X("scroll",r)}switch(t){case"input":Nr(r),Ea(r,l,!0);break;case"textarea":Nr(r),Pa(r);break;case"select":case"option":break;default:typeof l.onClick=="function"&&(r.onclick=mi)}r=i,n.updateQueue=r,r!==null&&(n.flags|=4)}else{o=i.nodeType===9?i:i.ownerDocument,e==="http://www.w3.org/1999/xhtml"&&(e=lu(t)),e==="http://www.w3.org/1999/xhtml"?t==="script"?(e=o.createElement("div"),e.innerHTML="<script><\/script>",e=e.removeChild(e.firstChild)):typeof r.is=="string"?e=o.createElement(t,{is:r.is}):(e=o.createElement(t),t==="select"&&(o=e,r.multiple?o.multiple=!0:r.size&&(o.size=r.size))):e=o.createElementNS(e,t),e[sn]=n,e[pr]=r,Nc(e,n,!1,!1),n.stateNode=e;e:{switch(o=Dl(t,r),t){case"dialog":X("cancel",e),X("close",e),i=r;break;case"iframe":case"object":case"embed":X("load",e),i=r;break;case"video":case"audio":for(i=0;i<Vt.length;i++)X(Vt[i],e);i=r;break;case"source":X("error",e),i=r;break;case"img":case"image":case"link":X("error",e),X("load",e),i=r;break;case"details":X("toggle",e),i=r;break;case"input":Ca(e,r),i=Tl(e,r),X("invalid",e);break;case"option":i=r;break;case"select":e._wrapperState={wasMultiple:!!r.multiple},i=te({},r,{value:void 0}),X("invalid",e);break;case"textarea":$a(e,r),i=Ll(e,r),X("invalid",e);break;default:i=r}Rl(t,i),a=i;for(l in a)if(a.hasOwnProperty(l)){var u=a[l];l==="style"?su(e,u):l==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,u!=null&&ou(e,u)):l==="children"?typeof u=="string"?(t!=="textarea"||u!=="")&&ir(e,u):typeof u=="number"&&ir(e,""+u):l!=="suppressContentEditableWarning"&&l!=="suppressHydrationWarning"&&l!=="autoFocus"&&(rr.hasOwnProperty(l)?u!=null&&l==="onScroll"&&X("scroll",e):u!=null&&Co(e,l,u,o))}switch(t){case"input":Nr(e),Ea(e,r,!1);break;case"textarea":Nr(e),Pa(e);break;case"option":r.value!=null&&e.setAttribute("value",""+In(r.value));break;case"select":e.multiple=!!r.multiple,l=r.value,l!=null?yt(e,!!r.multiple,l,!1):r.defaultValue!=null&&yt(e,!!r.multiple,r.defaultValue,!0);break;default:typeof i.onClick=="function"&&(e.onclick=mi)}switch(t){case"button":case"input":case"select":case"textarea":r=!!r.autoFocus;break e;case"img":r=!0;break e;default:r=!1}}r&&(n.flags|=4)}n.ref!==null&&(n.flags|=512,n.flags|=2097152)}return we(n),null;case 6:if(e&&n.stateNode!=null)Tc(e,n,e.memoizedProps,r);else{if(typeof r!="string"&&n.stateNode===null)throw Error(S(166));if(t=Gn(hr.current),Gn(cn.current),Or(n)){if(r=n.stateNode,t=n.memoizedProps,r[sn]=n,(l=r.nodeValue!==t)&&(e=Ie,e!==null))switch(e.tag){case 3:Dr(r.nodeValue,t,(e.mode&1)!==0);break;case 5:e.memoizedProps.suppressHydrationWarning!==!0&&Dr(r.nodeValue,t,(e.mode&1)!==0)}l&&(n.flags|=4)}else r=(t.nodeType===9?t:t.ownerDocument).createTextNode(r),r[sn]=n,n.stateNode=r}return we(n),null;case 13:if(Z(ee),r=n.memoizedState,e===null||e.memoizedState!==null&&e.memoizedState.dehydrated!==null){if(J&&Oe!==null&&n.mode&1&&!(n.flags&128))Yu(),Et(),n.flags|=98560,l=!1;else if(l=Or(n),r!==null&&r.dehydrated!==null){if(e===null){if(!l)throw Error(S(318));if(l=n.memoizedState,l=l!==null?l.dehydrated:null,!l)throw Error(S(317));l[sn]=n}else Et(),!(n.flags&128)&&(n.memoizedState=null),n.flags|=4;we(n),l=!1}else Je!==null&&(yo(Je),Je=null),l=!0;if(!l)return n.flags&65536?n:null}return n.flags&128?(n.lanes=t,n):(r=r!==null,r!==(e!==null&&e.memoizedState!==null)&&r&&(n.child.flags|=8192,n.mode&1&&(e===null||ee.current&1?se===0&&(se=3):aa())),n.updateQueue!==null&&(n.flags|=4),we(n),null);case 4:return Pt(),uo(e,n),e===null&&dr(n.stateNode.containerInfo),we(n),null;case 10:return Ho(n.type._context),we(n),null;case 17:return ze(n.type)&&hi(),we(n),null;case 19:if(Z(ee),l=n.memoizedState,l===null)return we(n),null;if(r=(n.flags&128)!==0,o=l.rendering,o===null)if(r)At(l,!1);else{if(se!==0||e!==null&&e.flags&128)for(e=n.child;e!==null;){if(o=_i(e),o!==null){for(n.flags|=128,At(l,!1),r=o.updateQueue,r!==null&&(n.updateQueue=r,n.flags|=4),n.subtreeFlags=0,r=t,t=n.child;t!==null;)l=t,e=r,l.flags&=14680066,o=l.alternate,o===null?(l.childLanes=0,l.lanes=e,l.child=null,l.subtreeFlags=0,l.memoizedProps=null,l.memoizedState=null,l.updateQueue=null,l.dependencies=null,l.stateNode=null):(l.childLanes=o.childLanes,l.lanes=o.lanes,l.child=o.child,l.subtreeFlags=0,l.deletions=null,l.memoizedProps=o.memoizedProps,l.memoizedState=o.memoizedState,l.updateQueue=o.updateQueue,l.type=o.type,e=o.dependencies,l.dependencies=e===null?null:{lanes:e.lanes,firstContext:e.firstContext}),t=t.sibling;return Y(ee,ee.current&1|2),n.child}e=e.sibling}l.tail!==null&&ie()>Ft&&(n.flags|=128,r=!0,At(l,!1),n.lanes=4194304)}else{if(!r)if(e=_i(o),e!==null){if(n.flags|=128,r=!0,t=e.updateQueue,t!==null&&(n.updateQueue=t,n.flags|=4),At(l,!0),l.tail===null&&l.tailMode==="hidden"&&!o.alternate&&!J)return we(n),null}else 2*ie()-l.renderingStartTime>Ft&&t!==1073741824&&(n.flags|=128,r=!0,At(l,!1),n.lanes=4194304);l.isBackwards?(o.sibling=n.child,n.child=o):(t=l.last,t!==null?t.sibling=o:n.child=o,l.last=o)}return l.tail!==null?(n=l.tail,l.rendering=n,l.tail=n.sibling,l.renderingStartTime=ie(),n.sibling=null,t=ee.current,Y(ee,r?t&1|2:t&1),n):(we(n),null);case 22:case 23:return oa(),r=n.memoizedState!==null,e!==null&&e.memoizedState!==null!==r&&(n.flags|=8192),r&&n.mode&1?Re&1073741824&&(we(n),n.subtreeFlags&6&&(n.flags|=8192)):we(n),null;case 24:return null;case 25:return null}throw Error(S(156,n.tag))}function xp(e,n){switch(Ao(n),n.tag){case 1:return ze(n.type)&&hi(),e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 3:return Pt(),Z(je),Z(_e),Yo(),e=n.flags,e&65536&&!(e&128)?(n.flags=e&-65537|128,n):null;case 5:return Go(n),null;case 13:if(Z(ee),e=n.memoizedState,e!==null&&e.dehydrated!==null){if(n.alternate===null)throw Error(S(340));Et()}return e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 19:return Z(ee),null;case 4:return Pt(),null;case 10:return Ho(n.type._context),null;case 22:case 23:return oa(),null;case 24:return null;default:return null}}var Ur=!1,ke=!1,wp=typeof WeakSet=="function"?WeakSet:Set,T=null;function ht(e,n){var t=e.ref;if(t!==null)if(typeof t=="function")try{t(null)}catch(r){re(e,n,r)}else t.current=null}function co(e,n,t){try{t()}catch(r){re(e,n,r)}}var vs=!1;function kp(e,n){if(Kl=di,e=Ru(),Oo(e)){if("selectionStart"in e)var t={start:e.selectionStart,end:e.selectionEnd};else e:{t=(t=e.ownerDocument)&&t.defaultView||window;var r=t.getSelection&&t.getSelection();if(r&&r.rangeCount!==0){t=r.anchorNode;var i=r.anchorOffset,l=r.focusNode;r=r.focusOffset;try{t.nodeType,l.nodeType}catch{t=null;break e}var o=0,a=-1,u=-1,d=0,v=0,m=e,p=null;n:for(;;){for(var h;m!==t||i!==0&&m.nodeType!==3||(a=o+i),m!==l||r!==0&&m.nodeType!==3||(u=o+r),m.nodeType===3&&(o+=m.nodeValue.length),(h=m.firstChild)!==null;)p=m,m=h;for(;;){if(m===e)break n;if(p===t&&++d===i&&(a=o),p===l&&++v===r&&(u=o),(h=m.nextSibling)!==null)break;m=p,p=m.parentNode}m=h}t=a===-1||u===-1?null:{start:a,end:u}}else t=null}t=t||{start:0,end:0}}else t=null;for(Gl={focusedElem:e,selectionRange:t},di=!1,T=n;T!==null;)if(n=T,e=n.child,(n.subtreeFlags&1028)!==0&&e!==null)e.return=n,T=e;else for(;T!==null;){n=T;try{var x=n.alternate;if(n.flags&1024)switch(n.tag){case 0:case 11:case 15:break;case 1:if(x!==null){var w=x.memoizedProps,L=x.memoizedState,c=n.stateNode,s=c.getSnapshotBeforeUpdate(n.elementType===n.type?w:Ze(n.type,w),L);c.__reactInternalSnapshotBeforeUpdate=s}break;case 3:var f=n.stateNode.containerInfo;f.nodeType===1?f.textContent="":f.nodeType===9&&f.documentElement&&f.removeChild(f.documentElement);break;case 5:case 6:case 4:case 17:break;default:throw Error(S(163))}}catch(g){re(n,n.return,g)}if(e=n.sibling,e!==null){e.return=n.return,T=e;break}T=n.return}return x=vs,vs=!1,x}function Jt(e,n,t){var r=n.updateQueue;if(r=r!==null?r.lastEffect:null,r!==null){var i=r=r.next;do{if((i.tag&e)===e){var l=i.destroy;i.destroy=void 0,l!==void 0&&co(n,t,l)}i=i.next}while(i!==r)}}function Ai(e,n){if(n=n.updateQueue,n=n!==null?n.lastEffect:null,n!==null){var t=n=n.next;do{if((t.tag&e)===e){var r=t.create;t.destroy=r()}t=t.next}while(t!==n)}}function fo(e){var n=e.ref;if(n!==null){var t=e.stateNode;switch(e.tag){case 5:e=t;break;default:e=t}typeof n=="function"?n(e):n.current=e}}function jc(e){var n=e.alternate;n!==null&&(e.alternate=null,jc(n)),e.child=null,e.deletions=null,e.sibling=null,e.tag===5&&(n=e.stateNode,n!==null&&(delete n[sn],delete n[pr],delete n[Zl],delete n[rp],delete n[ip])),e.stateNode=null,e.return=null,e.dependencies=null,e.memoizedProps=null,e.memoizedState=null,e.pendingProps=null,e.stateNode=null,e.updateQueue=null}function zc(e){return e.tag===5||e.tag===3||e.tag===4}function ys(e){e:for(;;){for(;e.sibling===null;){if(e.return===null||zc(e.return))return null;e=e.return}for(e.sibling.return=e.return,e=e.sibling;e.tag!==5&&e.tag!==6&&e.tag!==18;){if(e.flags&2||e.child===null||e.tag===4)continue e;e.child.return=e,e=e.child}if(!(e.flags&2))return e.stateNode}}function po(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.nodeType===8?t.parentNode.insertBefore(e,n):t.insertBefore(e,n):(t.nodeType===8?(n=t.parentNode,n.insertBefore(e,t)):(n=t,n.appendChild(e)),t=t._reactRootContainer,t!=null||n.onclick!==null||(n.onclick=mi));else if(r!==4&&(e=e.child,e!==null))for(po(e,n,t),e=e.sibling;e!==null;)po(e,n,t),e=e.sibling}function mo(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.insertBefore(e,n):t.appendChild(e);else if(r!==4&&(e=e.child,e!==null))for(mo(e,n,t),e=e.sibling;e!==null;)mo(e,n,t),e=e.sibling}var me=null,qe=!1;function Sn(e,n,t){for(t=t.child;t!==null;)Lc(e,n,t),t=t.sibling}function Lc(e,n,t){if(un&&typeof un.onCommitFiberUnmount=="function")try{un.onCommitFiberUnmount(ji,t)}catch{}switch(t.tag){case 5:ke||ht(t,n);case 6:var r=me,i=qe;me=null,Sn(e,n,t),me=r,qe=i,me!==null&&(qe?(e=me,t=t.stateNode,e.nodeType===8?e.parentNode.removeChild(t):e.removeChild(t)):me.removeChild(t.stateNode));break;case 18:me!==null&&(qe?(e=me,t=t.stateNode,e.nodeType===8?dl(e.parentNode,t):e.nodeType===1&&dl(e,t),sr(e)):dl(me,t.stateNode));break;case 4:r=me,i=qe,me=t.stateNode.containerInfo,qe=!0,Sn(e,n,t),me=r,qe=i;break;case 0:case 11:case 14:case 15:if(!ke&&(r=t.updateQueue,r!==null&&(r=r.lastEffect,r!==null))){i=r=r.next;do{var l=i,o=l.destroy;l=l.tag,o!==void 0&&(l&2||l&4)&&co(t,n,o),i=i.next}while(i!==r)}Sn(e,n,t);break;case 1:if(!ke&&(ht(t,n),r=t.stateNode,typeof r.componentWillUnmount=="function"))try{r.props=t.memoizedProps,r.state=t.memoizedState,r.componentWillUnmount()}catch(a){re(t,n,a)}Sn(e,n,t);break;case 21:Sn(e,n,t);break;case 22:t.mode&1?(ke=(r=ke)||t.memoizedState!==null,Sn(e,n,t),ke=r):Sn(e,n,t);break;default:Sn(e,n,t)}}function xs(e){var n=e.updateQueue;if(n!==null){e.updateQueue=null;var t=e.stateNode;t===null&&(t=e.stateNode=new wp),n.forEach(function(r){var i=Fp.bind(null,e,r);t.has(r)||(t.add(r),r.then(i,i))})}}function Xe(e,n){var t=n.deletions;if(t!==null)for(var r=0;r<t.length;r++){var i=t[r];try{var l=e,o=n,a=o;e:for(;a!==null;){switch(a.tag){case 5:me=a.stateNode,qe=!1;break e;case 3:me=a.stateNode.containerInfo,qe=!0;break e;case 4:me=a.stateNode.containerInfo,qe=!0;break e}a=a.return}if(me===null)throw Error(S(160));Lc(l,o,i),me=null,qe=!1;var u=i.alternate;u!==null&&(u.return=null),i.return=null}catch(d){re(i,n,d)}}if(n.subtreeFlags&12854)for(n=n.child;n!==null;)Mc(n,e),n=n.sibling}function Mc(e,n){var t=e.alternate,r=e.flags;switch(e.tag){case 0:case 11:case 14:case 15:if(Xe(n,e),on(e),r&4){try{Jt(3,e,e.return),Ai(3,e)}catch(w){re(e,e.return,w)}try{Jt(5,e,e.return)}catch(w){re(e,e.return,w)}}break;case 1:Xe(n,e),on(e),r&512&&t!==null&&ht(t,t.return);break;case 5:if(Xe(n,e),on(e),r&512&&t!==null&&ht(t,t.return),e.flags&32){var i=e.stateNode;try{ir(i,"")}catch(w){re(e,e.return,w)}}if(r&4&&(i=e.stateNode,i!=null)){var l=e.memoizedProps,o=t!==null?t.memoizedProps:l,a=e.type,u=e.updateQueue;if(e.updateQueue=null,u!==null)try{a==="input"&&l.type==="radio"&&l.name!=null&&ru(i,l),Dl(a,o);var d=Dl(a,l);for(o=0;o<u.length;o+=2){var v=u[o],m=u[o+1];v==="style"?su(i,m):v==="dangerouslySetInnerHTML"?ou(i,m):v==="children"?ir(i,m):Co(i,v,m,d)}switch(a){case"input":jl(i,l);break;case"textarea":iu(i,l);break;case"select":var p=i._wrapperState.wasMultiple;i._wrapperState.wasMultiple=!!l.multiple;var h=l.value;h!=null?yt(i,!!l.multiple,h,!1):p!==!!l.multiple&&(l.defaultValue!=null?yt(i,!!l.multiple,l.defaultValue,!0):yt(i,!!l.multiple,l.multiple?[]:"",!1))}i[pr]=l}catch(w){re(e,e.return,w)}}break;case 6:if(Xe(n,e),on(e),r&4){if(e.stateNode===null)throw Error(S(162));i=e.stateNode,l=e.memoizedProps;try{i.nodeValue=l}catch(w){re(e,e.return,w)}}break;case 3:if(Xe(n,e),on(e),r&4&&t!==null&&t.memoizedState.isDehydrated)try{sr(n.containerInfo)}catch(w){re(e,e.return,w)}break;case 4:Xe(n,e),on(e);break;case 13:Xe(n,e),on(e),i=e.child,i.flags&8192&&(l=i.memoizedState!==null,i.stateNode.isHidden=l,!l||i.alternate!==null&&i.alternate.memoizedState!==null||(ia=ie())),r&4&&xs(e);break;case 22:if(v=t!==null&&t.memoizedState!==null,e.mode&1?(ke=(d=ke)||v,Xe(n,e),ke=d):Xe(n,e),on(e),r&8192){if(d=e.memoizedState!==null,(e.stateNode.isHidden=d)&&!v&&e.mode&1)for(T=e,v=e.child;v!==null;){for(m=T=v;T!==null;){switch(p=T,h=p.child,p.tag){case 0:case 11:case 14:case 15:Jt(4,p,p.return);break;case 1:ht(p,p.return);var x=p.stateNode;if(typeof x.componentWillUnmount=="function"){r=p,t=p.return;try{n=r,x.props=n.memoizedProps,x.state=n.memoizedState,x.componentWillUnmount()}catch(w){re(r,t,w)}}break;case 5:ht(p,p.return);break;case 22:if(p.memoizedState!==null){ks(m);continue}}h!==null?(h.return=p,T=h):ks(m)}v=v.sibling}e:for(v=null,m=e;;){if(m.tag===5){if(v===null){v=m;try{i=m.stateNode,d?(l=i.style,typeof l.setProperty=="function"?l.setProperty("display","none","important"):l.display="none"):(a=m.stateNode,u=m.memoizedProps.style,o=u!=null&&u.hasOwnProperty("display")?u.display:null,a.style.display=au("display",o))}catch(w){re(e,e.return,w)}}}else if(m.tag===6){if(v===null)try{m.stateNode.nodeValue=d?"":m.memoizedProps}catch(w){re(e,e.return,w)}}else if((m.tag!==22&&m.tag!==23||m.memoizedState===null||m===e)&&m.child!==null){m.child.return=m,m=m.child;continue}if(m===e)break e;for(;m.sibling===null;){if(m.return===null||m.return===e)break e;v===m&&(v=null),m=m.return}v===m&&(v=null),m.sibling.return=m.return,m=m.sibling}}break;case 19:Xe(n,e),on(e),r&4&&xs(e);break;case 21:break;default:Xe(n,e),on(e)}}function on(e){var n=e.flags;if(n&2){try{e:{for(var t=e.return;t!==null;){if(zc(t)){var r=t;break e}t=t.return}throw Error(S(160))}switch(r.tag){case 5:var i=r.stateNode;r.flags&32&&(ir(i,""),r.flags&=-33);var l=ys(e);mo(e,l,i);break;case 3:case 4:var o=r.stateNode.containerInfo,a=ys(e);po(e,a,o);break;default:throw Error(S(161))}}catch(u){re(e,e.return,u)}e.flags&=-3}n&4096&&(e.flags&=-4097)}function _p(e,n,t){T=e,Rc(e)}function Rc(e,n,t){for(var r=(e.mode&1)!==0;T!==null;){var i=T,l=i.child;if(i.tag===22&&r){var o=i.memoizedState!==null||Ur;if(!o){var a=i.alternate,u=a!==null&&a.memoizedState!==null||ke;a=Ur;var d=ke;if(Ur=o,(ke=u)&&!d)for(T=i;T!==null;)o=T,u=o.child,o.tag===22&&o.memoizedState!==null?_s(i):u!==null?(u.return=o,T=u):_s(i);for(;l!==null;)T=l,Rc(l),l=l.sibling;T=i,Ur=a,ke=d}ws(e)}else i.subtreeFlags&8772&&l!==null?(l.return=i,T=l):ws(e)}}function ws(e){for(;T!==null;){var n=T;if(n.flags&8772){var t=n.alternate;try{if(n.flags&8772)switch(n.tag){case 0:case 11:case 15:ke||Ai(5,n);break;case 1:var r=n.stateNode;if(n.flags&4&&!ke)if(t===null)r.componentDidMount();else{var i=n.elementType===n.type?t.memoizedProps:Ze(n.type,t.memoizedProps);r.componentDidUpdate(i,t.memoizedState,r.__reactInternalSnapshotBeforeUpdate)}var l=n.updateQueue;l!==null&&is(n,l,r);break;case 3:var o=n.updateQueue;if(o!==null){if(t=null,n.child!==null)switch(n.child.tag){case 5:t=n.child.stateNode;break;case 1:t=n.child.stateNode}is(n,o,t)}break;case 5:var a=n.stateNode;if(t===null&&n.flags&4){t=a;var u=n.memoizedProps;switch(n.type){case"button":case"input":case"select":case"textarea":u.autoFocus&&t.focus();break;case"img":u.src&&(t.src=u.src)}}break;case 6:break;case 4:break;case 12:break;case 13:if(n.memoizedState===null){var d=n.alternate;if(d!==null){var v=d.memoizedState;if(v!==null){var m=v.dehydrated;m!==null&&sr(m)}}}break;case 19:case 17:case 21:case 22:case 23:case 25:break;default:throw Error(S(163))}ke||n.flags&512&&fo(n)}catch(p){re(n,n.return,p)}}if(n===e){T=null;break}if(t=n.sibling,t!==null){t.return=n.return,T=t;break}T=n.return}}function ks(e){for(;T!==null;){var n=T;if(n===e){T=null;break}var t=n.sibling;if(t!==null){t.return=n.return,T=t;break}T=n.return}}function _s(e){for(;T!==null;){var n=T;try{switch(n.tag){case 0:case 11:case 15:var t=n.return;try{Ai(4,n)}catch(u){re(n,t,u)}break;case 1:var r=n.stateNode;if(typeof r.componentDidMount=="function"){var i=n.return;try{r.componentDidMount()}catch(u){re(n,i,u)}}var l=n.return;try{fo(n)}catch(u){re(n,l,u)}break;case 5:var o=n.return;try{fo(n)}catch(u){re(n,o,u)}}}catch(u){re(n,n.return,u)}if(n===e){T=null;break}var a=n.sibling;if(a!==null){a.return=n.return,T=a;break}T=n.return}}var Sp=Math.ceil,Ci=kn.ReactCurrentDispatcher,ta=kn.ReactCurrentOwner,Ke=kn.ReactCurrentBatchConfig,H=0,pe=null,oe=null,ge=0,Re=0,gt=Bn(0),se=0,xr=null,et=0,Ui=0,ra=0,er=null,Fe=null,ia=0,Ft=1/0,fn=null,Ei=!1,ho=null,Mn=null,Br=!1,Nn=null,$i=0,nr=0,go=null,ni=-1,ti=0;function $e(){return H&6?ie():ni!==-1?ni:ni=ie()}function Rn(e){return e.mode&1?H&2&&ge!==0?ge&-ge:op.transition!==null?(ti===0&&(ti=wu()),ti):(e=K,e!==0||(e=window.event,e=e===void 0?16:$u(e.type)),e):1}function nn(e,n,t,r){if(50<nr)throw nr=0,go=null,Error(S(185));_r(e,t,r),(!(H&2)||e!==pe)&&(e===pe&&(!(H&2)&&(Ui|=t),se===4&&$n(e,ge)),Le(e,r),t===1&&H===0&&!(n.mode&1)&&(Ft=ie()+500,Di&&Wn()))}function Le(e,n){var t=e.callbackNode;of(e,n);var r=ci(e,e===pe?ge:0);if(r===0)t!==null&&Ta(t),e.callbackNode=null,e.callbackPriority=0;else if(n=r&-r,e.callbackPriority!==n){if(t!=null&&Ta(t),n===1)e.tag===0?lp(Ss.bind(null,e)):Qu(Ss.bind(null,e)),np(function(){!(H&6)&&Wn()}),t=null;else{switch(ku(r)){case 1:t=Fo;break;case 4:t=yu;break;case 16:t=ui;break;case 536870912:t=xu;break;default:t=ui}t=Hc(t,Dc.bind(null,e))}e.callbackPriority=n,e.callbackNode=t}}function Dc(e,n){if(ni=-1,ti=0,H&6)throw Error(S(327));var t=e.callbackNode;if(St()&&e.callbackNode!==t)return null;var r=ci(e,e===pe?ge:0);if(r===0)return null;if(r&30||r&e.expiredLanes||n)n=Pi(e,r);else{n=r;var i=H;H|=2;var l=Ic();(pe!==e||ge!==n)&&(fn=null,Ft=ie()+500,Yn(e,n));do try{Ep();break}catch(a){Oc(e,a)}while(!0);Wo(),Ci.current=l,H=i,oe!==null?n=0:(pe=null,ge=0,n=se)}if(n!==0){if(n===2&&(i=Bl(e),i!==0&&(r=i,n=vo(e,i))),n===1)throw t=xr,Yn(e,0),$n(e,r),Le(e,ie()),t;if(n===6)$n(e,r);else{if(i=e.current.alternate,!(r&30)&&!bp(i)&&(n=Pi(e,r),n===2&&(l=Bl(e),l!==0&&(r=l,n=vo(e,l))),n===1))throw t=xr,Yn(e,0),$n(e,r),Le(e,ie()),t;switch(e.finishedWork=i,e.finishedLanes=r,n){case 0:case 1:throw Error(S(345));case 2:Vn(e,Fe,fn);break;case 3:if($n(e,r),(r&130023424)===r&&(n=ia+500-ie(),10<n)){if(ci(e,0)!==0)break;if(i=e.suspendedLanes,(i&r)!==r){$e(),e.pingedLanes|=e.suspendedLanes&i;break}e.timeoutHandle=Xl(Vn.bind(null,e,Fe,fn),n);break}Vn(e,Fe,fn);break;case 4:if($n(e,r),(r&4194240)===r)break;for(n=e.eventTimes,i=-1;0<r;){var o=31-en(r);l=1<<o,o=n[o],o>i&&(i=o),r&=~l}if(r=i,r=ie()-r,r=(120>r?120:480>r?480:1080>r?1080:1920>r?1920:3e3>r?3e3:4320>r?4320:1960*Sp(r/1960))-r,10<r){e.timeoutHandle=Xl(Vn.bind(null,e,Fe,fn),r);break}Vn(e,Fe,fn);break;case 5:Vn(e,Fe,fn);break;default:throw Error(S(329))}}}return Le(e,ie()),e.callbackNode===t?Dc.bind(null,e):null}function vo(e,n){var t=er;return e.current.memoizedState.isDehydrated&&(Yn(e,n).flags|=256),e=Pi(e,n),e!==2&&(n=Fe,Fe=t,n!==null&&yo(n)),e}function yo(e){Fe===null?Fe=e:Fe.push.apply(Fe,e)}function bp(e){for(var n=e;;){if(n.flags&16384){var t=n.updateQueue;if(t!==null&&(t=t.stores,t!==null))for(var r=0;r<t.length;r++){var i=t[r],l=i.getSnapshot;i=i.value;try{if(!tn(l(),i))return!1}catch{return!1}}}if(t=n.child,n.subtreeFlags&16384&&t!==null)t.return=n,n=t;else{if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return!0;n=n.return}n.sibling.return=n.return,n=n.sibling}}return!0}function $n(e,n){for(n&=~ra,n&=~Ui,e.suspendedLanes|=n,e.pingedLanes&=~n,e=e.expirationTimes;0<n;){var t=31-en(n),r=1<<t;e[t]=-1,n&=~r}}function Ss(e){if(H&6)throw Error(S(327));St();var n=ci(e,0);if(!(n&1))return Le(e,ie()),null;var t=Pi(e,n);if(e.tag!==0&&t===2){var r=Bl(e);r!==0&&(n=r,t=vo(e,r))}if(t===1)throw t=xr,Yn(e,0),$n(e,n),Le(e,ie()),t;if(t===6)throw Error(S(345));return e.finishedWork=e.current.alternate,e.finishedLanes=n,Vn(e,Fe,fn),Le(e,ie()),null}function la(e,n){var t=H;H|=1;try{return e(n)}finally{H=t,H===0&&(Ft=ie()+500,Di&&Wn())}}function nt(e){Nn!==null&&Nn.tag===0&&!(H&6)&&St();var n=H;H|=1;var t=Ke.transition,r=K;try{if(Ke.transition=null,K=1,e)return e()}finally{K=r,Ke.transition=t,H=n,!(H&6)&&Wn()}}function oa(){Re=gt.current,Z(gt)}function Yn(e,n){e.finishedWork=null,e.finishedLanes=0;var t=e.timeoutHandle;if(t!==-1&&(e.timeoutHandle=-1,ep(t)),oe!==null)for(t=oe.return;t!==null;){var r=t;switch(Ao(r),r.tag){case 1:r=r.type.childContextTypes,r!=null&&hi();break;case 3:Pt(),Z(je),Z(_e),Yo();break;case 5:Go(r);break;case 4:Pt();break;case 13:Z(ee);break;case 19:Z(ee);break;case 10:Ho(r.type._context);break;case 22:case 23:oa()}t=t.return}if(pe=e,oe=e=Dn(e.current,null),ge=Re=n,se=0,xr=null,ra=Ui=et=0,Fe=er=null,Kn!==null){for(n=0;n<Kn.length;n++)if(t=Kn[n],r=t.interleaved,r!==null){t.interleaved=null;var i=r.next,l=t.pending;if(l!==null){var o=l.next;l.next=i,r.next=o}t.pending=r}Kn=null}return e}function Oc(e,n){do{var t=oe;try{if(Wo(),qr.current=bi,Si){for(var r=ne.memoizedState;r!==null;){var i=r.queue;i!==null&&(i.pending=null),r=r.next}Si=!1}if(Jn=0,fe=ae=ne=null,qt=!1,gr=0,ta.current=null,t===null||t.return===null){se=1,xr=n,oe=null;break}e:{var l=e,o=t.return,a=t,u=n;if(n=ge,a.flags|=32768,u!==null&&typeof u=="object"&&typeof u.then=="function"){var d=u,v=a,m=v.tag;if(!(v.mode&1)&&(m===0||m===11||m===15)){var p=v.alternate;p?(v.updateQueue=p.updateQueue,v.memoizedState=p.memoizedState,v.lanes=p.lanes):(v.updateQueue=null,v.memoizedState=null)}var h=cs(o);if(h!==null){h.flags&=-257,ds(h,o,a,l,n),h.mode&1&&us(l,d,n),n=h,u=d;var x=n.updateQueue;if(x===null){var w=new Set;w.add(u),n.updateQueue=w}else x.add(u);break e}else{if(!(n&1)){us(l,d,n),aa();break e}u=Error(S(426))}}else if(J&&a.mode&1){var L=cs(o);if(L!==null){!(L.flags&65536)&&(L.flags|=256),ds(L,o,a,l,n),Uo(Nt(u,a));break e}}l=u=Nt(u,a),se!==4&&(se=2),er===null?er=[l]:er.push(l),l=o;do{switch(l.tag){case 3:l.flags|=65536,n&=-n,l.lanes|=n;var c=kc(l,u,n);rs(l,c);break e;case 1:a=u;var s=l.type,f=l.stateNode;if(!(l.flags&128)&&(typeof s.getDerivedStateFromError=="function"||f!==null&&typeof f.componentDidCatch=="function"&&(Mn===null||!Mn.has(f)))){l.flags|=65536,n&=-n,l.lanes|=n;var g=_c(l,a,n);rs(l,g);break e}}l=l.return}while(l!==null)}Uc(t)}catch(_){n=_,oe===t&&t!==null&&(oe=t=t.return);continue}break}while(!0)}function Ic(){var e=Ci.current;return Ci.current=bi,e===null?bi:e}function aa(){(se===0||se===3||se===2)&&(se=4),pe===null||!(et&268435455)&&!(Ui&268435455)||$n(pe,ge)}function Pi(e,n){var t=H;H|=2;var r=Ic();(pe!==e||ge!==n)&&(fn=null,Yn(e,n));do try{Cp();break}catch(i){Oc(e,i)}while(!0);if(Wo(),H=t,Ci.current=r,oe!==null)throw Error(S(261));return pe=null,ge=0,se}function Cp(){for(;oe!==null;)Ac(oe)}function Ep(){for(;oe!==null&&!Xd();)Ac(oe)}function Ac(e){var n=Wc(e.alternate,e,Re);e.memoizedProps=e.pendingProps,n===null?Uc(e):oe=n,ta.current=null}function Uc(e){var n=e;do{var t=n.alternate;if(e=n.return,n.flags&32768){if(t=xp(t,n),t!==null){t.flags&=32767,oe=t;return}if(e!==null)e.flags|=32768,e.subtreeFlags=0,e.deletions=null;else{se=6,oe=null;return}}else if(t=yp(t,n,Re),t!==null){oe=t;return}if(n=n.sibling,n!==null){oe=n;return}oe=n=e}while(n!==null);se===0&&(se=5)}function Vn(e,n,t){var r=K,i=Ke.transition;try{Ke.transition=null,K=1,$p(e,n,t,r)}finally{Ke.transition=i,K=r}return null}function $p(e,n,t,r){do St();while(Nn!==null);if(H&6)throw Error(S(327));t=e.finishedWork;var i=e.finishedLanes;if(t===null)return null;if(e.finishedWork=null,e.finishedLanes=0,t===e.current)throw Error(S(177));e.callbackNode=null,e.callbackPriority=0;var l=t.lanes|t.childLanes;if(af(e,l),e===pe&&(oe=pe=null,ge=0),!(t.subtreeFlags&2064)&&!(t.flags&2064)||Br||(Br=!0,Hc(ui,function(){return St(),null})),l=(t.flags&15990)!==0,t.subtreeFlags&15990||l){l=Ke.transition,Ke.transition=null;var o=K;K=1;var a=H;H|=4,ta.current=null,kp(e,t),Mc(t,e),Kf(Gl),di=!!Kl,Gl=Kl=null,e.current=t,_p(t),Zd(),H=a,K=o,Ke.transition=l}else e.current=t;if(Br&&(Br=!1,Nn=e,$i=i),l=e.pendingLanes,l===0&&(Mn=null),ef(t.stateNode),Le(e,ie()),n!==null)for(r=e.onRecoverableError,t=0;t<n.length;t++)i=n[t],r(i.value,{componentStack:i.stack,digest:i.digest});if(Ei)throw Ei=!1,e=ho,ho=null,e;return $i&1&&e.tag!==0&&St(),l=e.pendingLanes,l&1?e===go?nr++:(nr=0,go=e):nr=0,Wn(),null}function St(){if(Nn!==null){var e=ku($i),n=Ke.transition,t=K;try{if(Ke.transition=null,K=16>e?16:e,Nn===null)var r=!1;else{if(e=Nn,Nn=null,$i=0,H&6)throw Error(S(331));var i=H;for(H|=4,T=e.current;T!==null;){var l=T,o=l.child;if(T.flags&16){var a=l.deletions;if(a!==null){for(var u=0;u<a.length;u++){var d=a[u];for(T=d;T!==null;){var v=T;switch(v.tag){case 0:case 11:case 15:Jt(8,v,l)}var m=v.child;if(m!==null)m.return=v,T=m;else for(;T!==null;){v=T;var p=v.sibling,h=v.return;if(jc(v),v===d){T=null;break}if(p!==null){p.return=h,T=p;break}T=h}}}var x=l.alternate;if(x!==null){var w=x.child;if(w!==null){x.child=null;do{var L=w.sibling;w.sibling=null,w=L}while(w!==null)}}T=l}}if(l.subtreeFlags&2064&&o!==null)o.return=l,T=o;else e:for(;T!==null;){if(l=T,l.flags&2048)switch(l.tag){case 0:case 11:case 15:Jt(9,l,l.return)}var c=l.sibling;if(c!==null){c.return=l.return,T=c;break e}T=l.return}}var s=e.current;for(T=s;T!==null;){o=T;var f=o.child;if(o.subtreeFlags&2064&&f!==null)f.return=o,T=f;else e:for(o=s;T!==null;){if(a=T,a.flags&2048)try{switch(a.tag){case 0:case 11:case 15:Ai(9,a)}}catch(_){re(a,a.return,_)}if(a===o){T=null;break e}var g=a.sibling;if(g!==null){g.return=a.return,T=g;break e}T=a.return}}if(H=i,Wn(),un&&typeof un.onPostCommitFiberRoot=="function")try{un.onPostCommitFiberRoot(ji,e)}catch{}r=!0}return r}finally{K=t,Ke.transition=n}}return!1}function bs(e,n,t){n=Nt(t,n),n=kc(e,n,1),e=Ln(e,n,1),n=$e(),e!==null&&(_r(e,1,n),Le(e,n))}function re(e,n,t){if(e.tag===3)bs(e,e,t);else for(;n!==null;){if(n.tag===3){bs(n,e,t);break}else if(n.tag===1){var r=n.stateNode;if(typeof n.type.getDerivedStateFromError=="function"||typeof r.componentDidCatch=="function"&&(Mn===null||!Mn.has(r))){e=Nt(t,e),e=_c(n,e,1),n=Ln(n,e,1),e=$e(),n!==null&&(_r(n,1,e),Le(n,e));break}}n=n.return}}function Pp(e,n,t){var r=e.pingCache;r!==null&&r.delete(n),n=$e(),e.pingedLanes|=e.suspendedLanes&t,pe===e&&(ge&t)===t&&(se===4||se===3&&(ge&130023424)===ge&&500>ie()-ia?Yn(e,0):ra|=t),Le(e,n)}function Bc(e,n){n===0&&(e.mode&1?(n=jr,jr<<=1,!(jr&130023424)&&(jr=4194304)):n=1);var t=$e();e=xn(e,n),e!==null&&(_r(e,n,t),Le(e,t))}function Np(e){var n=e.memoizedState,t=0;n!==null&&(t=n.retryLane),Bc(e,t)}function Fp(e,n){var t=0;switch(e.tag){case 13:var r=e.stateNode,i=e.memoizedState;i!==null&&(t=i.retryLane);break;case 19:r=e.stateNode;break;default:throw Error(S(314))}r!==null&&r.delete(n),Bc(e,t)}var Wc;Wc=function(e,n,t){if(e!==null)if(e.memoizedProps!==n.pendingProps||je.current)Te=!0;else{if(!(e.lanes&t)&&!(n.flags&128))return Te=!1,vp(e,n,t);Te=!!(e.flags&131072)}else Te=!1,J&&n.flags&1048576&&Ku(n,yi,n.index);switch(n.lanes=0,n.tag){case 2:var r=n.type;ei(e,n),e=n.pendingProps;var i=Ct(n,_e.current);_t(n,t),i=Zo(null,n,r,e,i,t);var l=qo();return n.flags|=1,typeof i=="object"&&i!==null&&typeof i.render=="function"&&i.$$typeof===void 0?(n.tag=1,n.memoizedState=null,n.updateQueue=null,ze(r)?(l=!0,gi(n)):l=!1,n.memoizedState=i.state!==null&&i.state!==void 0?i.state:null,Qo(n),i.updater=Ii,n.stateNode=i,i._reactInternals=n,ro(n,r,e,t),n=oo(null,n,r,!0,l,t)):(n.tag=0,J&&l&&Io(n),Ee(null,n,i,t),n=n.child),n;case 16:r=n.elementType;e:{switch(ei(e,n),e=n.pendingProps,i=r._init,r=i(r._payload),n.type=r,i=n.tag=jp(r),e=Ze(r,e),i){case 0:n=lo(null,n,r,e,t);break e;case 1:n=ms(null,n,r,e,t);break e;case 11:n=fs(null,n,r,e,t);break e;case 14:n=ps(null,n,r,Ze(r.type,e),t);break e}throw Error(S(306,r,""))}return n;case 0:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ze(r,i),lo(e,n,r,i,t);case 1:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ze(r,i),ms(e,n,r,i,t);case 3:e:{if(Ec(n),e===null)throw Error(S(387));r=n.pendingProps,l=n.memoizedState,i=l.element,Ju(e,n),ki(n,r,null,t);var o=n.memoizedState;if(r=o.element,l.isDehydrated)if(l={element:r,isDehydrated:!1,cache:o.cache,pendingSuspenseBoundaries:o.pendingSuspenseBoundaries,transitions:o.transitions},n.updateQueue.baseState=l,n.memoizedState=l,n.flags&256){i=Nt(Error(S(423)),n),n=hs(e,n,r,t,i);break e}else if(r!==i){i=Nt(Error(S(424)),n),n=hs(e,n,r,t,i);break e}else for(Oe=zn(n.stateNode.containerInfo.firstChild),Ie=n,J=!0,Je=null,t=Zu(n,null,r,t),n.child=t;t;)t.flags=t.flags&-3|4096,t=t.sibling;else{if(Et(),r===i){n=wn(e,n,t);break e}Ee(e,n,r,t)}n=n.child}return n;case 5:return ec(n),e===null&&eo(n),r=n.type,i=n.pendingProps,l=e!==null?e.memoizedProps:null,o=i.children,Yl(r,i)?o=null:l!==null&&Yl(r,l)&&(n.flags|=32),Cc(e,n),Ee(e,n,o,t),n.child;case 6:return e===null&&eo(n),null;case 13:return $c(e,n,t);case 4:return Ko(n,n.stateNode.containerInfo),r=n.pendingProps,e===null?n.child=$t(n,null,r,t):Ee(e,n,r,t),n.child;case 11:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ze(r,i),fs(e,n,r,i,t);case 7:return Ee(e,n,n.pendingProps,t),n.child;case 8:return Ee(e,n,n.pendingProps.children,t),n.child;case 12:return Ee(e,n,n.pendingProps.children,t),n.child;case 10:e:{if(r=n.type._context,i=n.pendingProps,l=n.memoizedProps,o=i.value,Y(xi,r._currentValue),r._currentValue=o,l!==null)if(tn(l.value,o)){if(l.children===i.children&&!je.current){n=wn(e,n,t);break e}}else for(l=n.child,l!==null&&(l.return=n);l!==null;){var a=l.dependencies;if(a!==null){o=l.child;for(var u=a.firstContext;u!==null;){if(u.context===r){if(l.tag===1){u=gn(-1,t&-t),u.tag=2;var d=l.updateQueue;if(d!==null){d=d.shared;var v=d.pending;v===null?u.next=u:(u.next=v.next,v.next=u),d.pending=u}}l.lanes|=t,u=l.alternate,u!==null&&(u.lanes|=t),no(l.return,t,n),a.lanes|=t;break}u=u.next}}else if(l.tag===10)o=l.type===n.type?null:l.child;else if(l.tag===18){if(o=l.return,o===null)throw Error(S(341));o.lanes|=t,a=o.alternate,a!==null&&(a.lanes|=t),no(o,t,n),o=l.sibling}else o=l.child;if(o!==null)o.return=l;else for(o=l;o!==null;){if(o===n){o=null;break}if(l=o.sibling,l!==null){l.return=o.return,o=l;break}o=o.return}l=o}Ee(e,n,i.children,t),n=n.child}return n;case 9:return i=n.type,r=n.pendingProps.children,_t(n,t),i=Ge(i),r=r(i),n.flags|=1,Ee(e,n,r,t),n.child;case 14:return r=n.type,i=Ze(r,n.pendingProps),i=Ze(r.type,i),ps(e,n,r,i,t);case 15:return Sc(e,n,n.type,n.pendingProps,t);case 17:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ze(r,i),ei(e,n),n.tag=1,ze(r)?(e=!0,gi(n)):e=!1,_t(n,t),wc(n,r,i),ro(n,r,i,t),oo(null,n,r,!0,e,t);case 19:return Pc(e,n,t);case 22:return bc(e,n,t)}throw Error(S(156,n.tag))};function Hc(e,n){return vu(e,n)}function Tp(e,n,t,r){this.tag=e,this.key=t,this.sibling=this.child=this.return=this.stateNode=this.type=this.elementType=null,this.index=0,this.ref=null,this.pendingProps=n,this.dependencies=this.memoizedState=this.updateQueue=this.memoizedProps=null,this.mode=r,this.subtreeFlags=this.flags=0,this.deletions=null,this.childLanes=this.lanes=0,this.alternate=null}function Qe(e,n,t,r){return new Tp(e,n,t,r)}function sa(e){return e=e.prototype,!(!e||!e.isReactComponent)}function jp(e){if(typeof e=="function")return sa(e)?1:0;if(e!=null){if(e=e.$$typeof,e===$o)return 11;if(e===Po)return 14}return 2}function Dn(e,n){var t=e.alternate;return t===null?(t=Qe(e.tag,n,e.key,e.mode),t.elementType=e.elementType,t.type=e.type,t.stateNode=e.stateNode,t.alternate=e,e.alternate=t):(t.pendingProps=n,t.type=e.type,t.flags=0,t.subtreeFlags=0,t.deletions=null),t.flags=e.flags&14680064,t.childLanes=e.childLanes,t.lanes=e.lanes,t.child=e.child,t.memoizedProps=e.memoizedProps,t.memoizedState=e.memoizedState,t.updateQueue=e.updateQueue,n=e.dependencies,t.dependencies=n===null?null:{lanes:n.lanes,firstContext:n.firstContext},t.sibling=e.sibling,t.index=e.index,t.ref=e.ref,t}function ri(e,n,t,r,i,l){var o=2;if(r=e,typeof e=="function")sa(e)&&(o=1);else if(typeof e=="string")o=5;else e:switch(e){case ot:return Xn(t.children,i,l,n);case Eo:o=8,i|=8;break;case $l:return e=Qe(12,t,n,i|2),e.elementType=$l,e.lanes=l,e;case Pl:return e=Qe(13,t,n,i),e.elementType=Pl,e.lanes=l,e;case Nl:return e=Qe(19,t,n,i),e.elementType=Nl,e.lanes=l,e;case eu:return Bi(t,i,l,n);default:if(typeof e=="object"&&e!==null)switch(e.$$typeof){case qs:o=10;break e;case Js:o=9;break e;case $o:o=11;break e;case Po:o=14;break e;case bn:o=16,r=null;break e}throw Error(S(130,e==null?e:typeof e,""))}return n=Qe(o,t,n,i),n.elementType=e,n.type=r,n.lanes=l,n}function Xn(e,n,t,r){return e=Qe(7,e,r,n),e.lanes=t,e}function Bi(e,n,t,r){return e=Qe(22,e,r,n),e.elementType=eu,e.lanes=t,e.stateNode={isHidden:!1},e}function xl(e,n,t){return e=Qe(6,e,null,n),e.lanes=t,e}function wl(e,n,t){return n=Qe(4,e.children!==null?e.children:[],e.key,n),n.lanes=t,n.stateNode={containerInfo:e.containerInfo,pendingChildren:null,implementation:e.implementation},n}function zp(e,n,t,r,i){this.tag=n,this.containerInfo=e,this.finishedWork=this.pingCache=this.current=this.pendingChildren=null,this.timeoutHandle=-1,this.callbackNode=this.pendingContext=this.context=null,this.callbackPriority=0,this.eventTimes=el(0),this.expirationTimes=el(-1),this.entangledLanes=this.finishedLanes=this.mutableReadLanes=this.expiredLanes=this.pingedLanes=this.suspendedLanes=this.pendingLanes=0,this.entanglements=el(0),this.identifierPrefix=r,this.onRecoverableError=i,this.mutableSourceEagerHydrationData=null}function ua(e,n,t,r,i,l,o,a,u){return e=new zp(e,n,t,a,u),n===1?(n=1,l===!0&&(n|=8)):n=0,l=Qe(3,null,null,n),e.current=l,l.stateNode=e,l.memoizedState={element:r,isDehydrated:t,cache:null,transitions:null,pendingSuspenseBoundaries:null},Qo(l),e}function Lp(e,n,t){var r=3<arguments.length&&arguments[3]!==void 0?arguments[3]:null;return{$$typeof:lt,key:r==null?null:""+r,children:e,containerInfo:n,implementation:t}}function Vc(e){if(!e)return An;e=e._reactInternals;e:{if(rt(e)!==e||e.tag!==1)throw Error(S(170));var n=e;do{switch(n.tag){case 3:n=n.stateNode.context;break e;case 1:if(ze(n.type)){n=n.stateNode.__reactInternalMemoizedMergedChildContext;break e}}n=n.return}while(n!==null);throw Error(S(171))}if(e.tag===1){var t=e.type;if(ze(t))return Vu(e,t,n)}return n}function Qc(e,n,t,r,i,l,o,a,u){return e=ua(t,r,!0,e,i,l,o,a,u),e.context=Vc(null),t=e.current,r=$e(),i=Rn(t),l=gn(r,i),l.callback=n??null,Ln(t,l,i),e.current.lanes=i,_r(e,i,r),Le(e,r),e}function Wi(e,n,t,r){var i=n.current,l=$e(),o=Rn(i);return t=Vc(t),n.context===null?n.context=t:n.pendingContext=t,n=gn(l,o),n.payload={element:e},r=r===void 0?null:r,r!==null&&(n.callback=r),e=Ln(i,n,o),e!==null&&(nn(e,i,o,l),Zr(e,i,o)),o}function Ni(e){if(e=e.current,!e.child)return null;switch(e.child.tag){case 5:return e.child.stateNode;default:return e.child.stateNode}}function Cs(e,n){if(e=e.memoizedState,e!==null&&e.dehydrated!==null){var t=e.retryLane;e.retryLane=t!==0&&t<n?t:n}}function ca(e,n){Cs(e,n),(e=e.alternate)&&Cs(e,n)}function Mp(){return null}var Kc=typeof reportError=="function"?reportError:function(e){console.error(e)};function da(e){this._internalRoot=e}Hi.prototype.render=da.prototype.render=function(e){var n=this._internalRoot;if(n===null)throw Error(S(409));Wi(e,n,null,null)};Hi.prototype.unmount=da.prototype.unmount=function(){var e=this._internalRoot;if(e!==null){this._internalRoot=null;var n=e.containerInfo;nt(function(){Wi(null,e,null,null)}),n[yn]=null}};function Hi(e){this._internalRoot=e}Hi.prototype.unstable_scheduleHydration=function(e){if(e){var n=bu();e={blockedOn:null,target:e,priority:n};for(var t=0;t<En.length&&n!==0&&n<En[t].priority;t++);En.splice(t,0,e),t===0&&Eu(e)}};function fa(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11)}function Vi(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11&&(e.nodeType!==8||e.nodeValue!==" react-mount-point-unstable "))}function Es(){}function Rp(e,n,t,r,i){if(i){if(typeof r=="function"){var l=r;r=function(){var d=Ni(o);l.call(d)}}var o=Qc(n,r,e,0,null,!1,!1,"",Es);return e._reactRootContainer=o,e[yn]=o.current,dr(e.nodeType===8?e.parentNode:e),nt(),o}for(;i=e.lastChild;)e.removeChild(i);if(typeof r=="function"){var a=r;r=function(){var d=Ni(u);a.call(d)}}var u=ua(e,0,!1,null,null,!1,!1,"",Es);return e._reactRootContainer=u,e[yn]=u.current,dr(e.nodeType===8?e.parentNode:e),nt(function(){Wi(n,u,t,r)}),u}function Qi(e,n,t,r,i){var l=t._reactRootContainer;if(l){var o=l;if(typeof i=="function"){var a=i;i=function(){var u=Ni(o);a.call(u)}}Wi(n,o,e,i)}else o=Rp(t,n,e,i,r);return Ni(o)}_u=function(e){switch(e.tag){case 3:var n=e.stateNode;if(n.current.memoizedState.isDehydrated){var t=Ht(n.pendingLanes);t!==0&&(To(n,t|1),Le(n,ie()),!(H&6)&&(Ft=ie()+500,Wn()))}break;case 13:nt(function(){var r=xn(e,1);if(r!==null){var i=$e();nn(r,e,1,i)}}),ca(e,1)}};jo=function(e){if(e.tag===13){var n=xn(e,134217728);if(n!==null){var t=$e();nn(n,e,134217728,t)}ca(e,134217728)}};Su=function(e){if(e.tag===13){var n=Rn(e),t=xn(e,n);if(t!==null){var r=$e();nn(t,e,n,r)}ca(e,n)}};bu=function(){return K};Cu=function(e,n){var t=K;try{return K=e,n()}finally{K=t}};Il=function(e,n,t){switch(n){case"input":if(jl(e,t),n=t.name,t.type==="radio"&&n!=null){for(t=e;t.parentNode;)t=t.parentNode;for(t=t.querySelectorAll("input[name="+JSON.stringify(""+n)+'][type="radio"]'),n=0;n<t.length;n++){var r=t[n];if(r!==e&&r.form===e.form){var i=Ri(r);if(!i)throw Error(S(90));tu(r),jl(r,i)}}}break;case"textarea":iu(e,t);break;case"select":n=t.value,n!=null&&yt(e,!!t.multiple,n,!1)}};du=la;fu=nt;var Dp={usingClientEntryPoint:!1,Events:[br,ct,Ri,uu,cu,la]},Ut={findFiberByHostInstance:Qn,bundleType:0,version:"18.3.1",rendererPackageName:"react-dom"},Op={bundleType:Ut.bundleType,version:Ut.version,rendererPackageName:Ut.rendererPackageName,rendererConfig:Ut.rendererConfig,overrideHookState:null,overrideHookStateDeletePath:null,overrideHookStateRenamePath:null,overrideProps:null,overridePropsDeletePath:null,overridePropsRenamePath:null,setErrorHandler:null,setSuspenseHandler:null,scheduleUpdate:null,currentDispatcherRef:kn.ReactCurrentDispatcher,findHostInstanceByFiber:function(e){return e=hu(e),e===null?null:e.stateNode},findFiberByHostInstance:Ut.findFiberByHostInstance||Mp,findHostInstancesForRefresh:null,scheduleRefresh:null,scheduleRoot:null,setRefreshHandler:null,getCurrentFiber:null,reconcilerVersion:"18.3.1-next-f1338f8080-20240426"};if(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__<"u"){var Wr=__REACT_DEVTOOLS_GLOBAL_HOOK__;if(!Wr.isDisabled&&Wr.supportsFiber)try{ji=Wr.inject(Op),un=Wr}catch{}}Ue.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Dp;Ue.createPortal=function(e,n){var t=2<arguments.length&&arguments[2]!==void 0?arguments[2]:null;if(!fa(n))throw Error(S(200));return Lp(e,n,null,t)};Ue.createRoot=function(e,n){if(!fa(e))throw Error(S(299));var t=!1,r="",i=Kc;return n!=null&&(n.unstable_strictMode===!0&&(t=!0),n.identifierPrefix!==void 0&&(r=n.identifierPrefix),n.onRecoverableError!==void 0&&(i=n.onRecoverableError)),n=ua(e,1,!1,null,null,t,!1,r,i),e[yn]=n.current,dr(e.nodeType===8?e.parentNode:e),new da(n)};Ue.findDOMNode=function(e){if(e==null)return null;if(e.nodeType===1)return e;var n=e._reactInternals;if(n===void 0)throw typeof e.render=="function"?Error(S(188)):(e=Object.keys(e).join(","),Error(S(268,e)));return e=hu(n),e=e===null?null:e.stateNode,e};Ue.flushSync=function(e){return nt(e)};Ue.hydrate=function(e,n,t){if(!Vi(n))throw Error(S(200));return Qi(null,e,n,!0,t)};Ue.hydrateRoot=function(e,n,t){if(!fa(e))throw Error(S(405));var r=t!=null&&t.hydratedSources||null,i=!1,l="",o=Kc;if(t!=null&&(t.unstable_strictMode===!0&&(i=!0),t.identifierPrefix!==void 0&&(l=t.identifierPrefix),t.onRecoverableError!==void 0&&(o=t.onRecoverableError)),n=Qc(n,null,e,1,t??null,i,!1,l,o),e[yn]=n.current,dr(e),r)for(e=0;e<r.length;e++)t=r[e],i=t._getVersion,i=i(t._source),n.mutableSourceEagerHydrationData==null?n.mutableSourceEagerHydrationData=[t,i]:n.mutableSourceEagerHydrationData.push(t,i);return new Hi(n)};Ue.render=function(e,n,t){if(!Vi(n))throw Error(S(200));return Qi(null,e,n,!1,t)};Ue.unmountComponentAtNode=function(e){if(!Vi(e))throw Error(S(40));return e._reactRootContainer?(nt(function(){Qi(null,null,e,!1,function(){e._reactRootContainer=null,e[yn]=null})}),!0):!1};Ue.unstable_batchedUpdates=la;Ue.unstable_renderSubtreeIntoContainer=function(e,n,t,r){if(!Vi(t))throw Error(S(200));if(e==null||e._reactInternals===void 0)throw Error(S(38));return Qi(e,n,t,!1,r)};Ue.version="18.3.1-next-f1338f8080-20240426";function Gc(){if(!(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__>"u"||typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE!="function"))try{__REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(Gc)}catch(e){console.error(e)}}Gc(),Gs.exports=Ue;var Ip=Gs.exports,$s=Ip;Cl.createRoot=$s.createRoot,Cl.hydrateRoot=$s.hydrateRoot;const Ap=`version: 0.1

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

  `,Up=`version: 0.1


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


 `,Bp=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #checkboxVal(updatable) text(dd, "clickCheckbox", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 20)), builderParameter("checkbox")) {
            settings(checkboxBuildName=>checkbox2) // override builder name (will use checkbox2 programmable from std)
      }

      
      
}


 
`,Wp=`version: 0.1

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

      
      
}`,Hp=`version: 0.1


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

      



    `,Vp=`version: 0.1


#ui programmable() {
      pos:400,200
      
      #selectedFileText(updatable) text(dd, "No file selected", #ffffff00, center, 400): 0,50
      
      point {
      
        placeholder(generated(cross(20, 20)), builderParameter("openDialog1button"));
        placeholder(generated(cross(200, 20)), builderParameter("openDialog2button")):250,0;
        
      }
}


      



    `,Qp=`version: 0.1





#ui programmable() {
    // Title
    text(dd, "Draggable Test Screen", #ffffff, center, 800): 0, 30
    
    // Drop zones
    rect(180, 180, #ffffff): 300, 300
    text(dd, "Drop Zone", #000000, center, 80): 400, 185
    
    rect(100, 60, red): 100, 100
    text(dd, "Zone 2", #ffffff, center, 100): 500, 185
} `,Kp=`version: 0.1

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



                

      

      
`,Gp=`version: 0.1

relativeLayouts {
  #fontNames sequence($i: 1..40) point: 100, 20+20 * $i
  #fonts sequence($i: 1..40) point: 200, 20+20 * $i
}


`,Yp=`version: 0.1



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
`,Xp=`version: 0.1




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
}`,Zp=`version: 0.1

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
} `,qp=`version: 0.1


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



    `,Jp=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #listVal(updatable) text(dd, "Select an item from the list!", #ffffff00): 10,50
     
     placeholder(generated(cross(200, 150)), builderParameter("scrollableList")) {
            pos: 10,80
            settings(panelBuilder=>list-panel, itemBuilder=>list-item-120) // use standard list components
      }

      
      
}


`,e0=`version: 0.1

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


      



    `,n0=`version: 0.1


#ui programmable() {
      pos:100,300
      
      #sliderVal(updatable) text(dd, "move slider", #ffffff00): 10,50
      
      placeholder(generated(cross(200, 20)), builderParameter("slider")) {
            pos:10,30
      }

      
      
}`,t0=`version: 0.1


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


`,r0=`version: 0.1

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
}`,i0=`sheet: crew2
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

`,l0=`sheet: crew2
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


`,o0=`sheet: crew2
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

`,a0=`sheet: crew2
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



`,s0=`sheet: crew2
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

`,u0=Object.assign({"../public/assets/atlas-test.manim":Ap,"../public/assets/button.manim":Up,"../public/assets/checkbox.manim":Bp,"../public/assets/components.manim":Wp,"../public/assets/dialog-base.manim":Hp,"../public/assets/dialog-start.manim":Vp,"../public/assets/draggable.manim":Qp,"../public/assets/examples1.manim":Kp,"../public/assets/fonts.manim":Gp,"../public/assets/particles.manim":Yp,"../public/assets/paths.manim":Xp,"../public/assets/pixels.manim":Zp,"../public/assets/room1.manim":qp,"../public/assets/scrollable-list.manim":Jp,"../public/assets/settings.manim":e0,"../public/assets/slider.manim":n0,"../public/assets/stateanim.manim":t0,"../public/assets/std.manim":r0}),c0=Object.assign({"../public/assets/arrows.anim":i0,"../public/assets/dice.anim":l0,"../public/assets/marine.anim":o0,"../public/assets/shield.anim":a0,"../public/assets/turret.anim":s0}),pa=Object.fromEntries([...Object.entries(u0).map(([e,n])=>[e.split("/").pop(),n]),...Object.entries(c0).map(([e,n])=>[e.split("/").pop(),n])]),kl=e=>pa[e]||null,ii=(e,n)=>{pa[e]=n},d0=e=>e in pa;class f0{constructor(){Ce(this,"screens",[{name:"scrollableList",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",manimFile:"scrollable-list.manim"},{name:"button",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",manimFile:"button.manim"},{name:"checkbox",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",manimFile:"checkbox.manim"},{name:"slider",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",manimFile:"slider.manim"},{name:"particles",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",manimFile:"particles.manim"},{name:"pixels",displayName:"Pixels",description:"Pixel art and static pixel demo screen.",manimFile:"pixels.manim"},{name:"components",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",manimFile:"components.manim"},{name:"examples1",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",manimFile:"examples1.manim"},{name:"paths",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",manimFile:"paths.manim"},{name:"fonts",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",manimFile:"fonts.manim"},{name:"room1",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",manimFile:"room1.manim"},{name:"stateAnim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",manimFile:"stateanim.manim"},{name:"dialogStart",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",manimFile:"dialog-start.manim"},{name:"settings",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",manimFile:"settings.manim"},{name:"atlasTest",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",manimFile:"atlas-test.manim"},{name:"draggable",displayName:"Draggable Test",description:"Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.",manimFile:"draggable.manim"}]);Ce(this,"manimFiles",[{filename:"scrollable-list.manim",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",content:null},{filename:"button.manim",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",content:null},{filename:"checkbox.manim",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",content:null},{filename:"slider.manim",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",content:null},{filename:"examples1.manim",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",content:null},{filename:"components.manim",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",content:null},{filename:"dialog-base.manim",displayName:"Dialog Base",description:"Dialog system foundation with base dialog layouts, text rendering, and dialog-specific animations and transitions.",content:null},{filename:"dialog-start.manim",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",content:null},{filename:"fonts.manim",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",content:null},{filename:"particles.manim",displayName:"Particles",description:"Particle system examples with various particle effects, explosions, trails, and dynamic particle animations.",content:null},{filename:"pixels.manim",displayName:"Pixels",description:"Pixel art and static pixel demo screen.",content:null},{filename:"paths.manim",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",content:null},{filename:"room1.manim",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",content:null},{filename:"settings.manim",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",content:null},{filename:"stateanim.manim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",content:null},{filename:"std.manim",displayName:"Standard Library",description:"Standard library components and utilities for hx-multianim including common animations, effects, and helper functions.",content:null},{filename:"draggable.manim",displayName:"Draggable Test",description:"Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.",content:null},{filename:"atlas-test.manim",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",content:null}]);Ce(this,"animFiles",[{filename:"arrows.anim",content:null},{filename:"dice.anim",content:null},{filename:"marine.anim",content:null},{filename:"shield.anim",content:null},{filename:"turret.anim",content:null}]);Ce(this,"currentFile",null);Ce(this,"currentExample",null);Ce(this,"reloadTimeout",null);Ce(this,"reloadDelay",1e3);Ce(this,"mainApp",null);Ce(this,"baseUrl","");this.init()}init(){this.setupFileLoader(),this.loadFilesFromMap(),this.waitForMainApp()}loadFilesFromMap(){this.manimFiles.forEach(n=>{const t=kl(n.filename);t&&(n.content=t)}),this.animFiles.forEach(n=>{const t=kl(n.filename);t&&(n.content=t)})}waitForMainApp(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?this.mainApp=window.PlaygroundMain.instance:setTimeout(()=>this.waitForMainApp(),100)}setupFileLoader(){this.baseUrl=typeof window<"u"&&window.location?window.location.href:"",window.FileLoader={baseUrl:this.baseUrl,resolveUrl:n=>this.resolveUrl(n),load:n=>this.loadFile(n),stringToArrayBuffer:this.stringToArrayBuffer}}resolveUrl(n){if(n.startsWith("http://")||n.startsWith("https://")||n.startsWith("//")||n.startsWith("file://")||!this.baseUrl)return n;try{return new URL(n,this.baseUrl).href}catch{const r=this.baseUrl.endsWith("/")?this.baseUrl:this.baseUrl+"/",i=n.startsWith("/")?n.substring(1):n;return r+i}}stringToArrayBuffer(n){const t=new ArrayBuffer(n.length),r=new Uint8Array(t);for(let i=0,l=n.length;i<l;i++)r[i]=n.charCodeAt(i);return t}loadFile(n){const t=this.extractFilenameFromUrl(n);if(t&&d0(t)){const l=kl(t);if(l)return this.stringToArrayBuffer(l)}if(typeof window.hxd<"u"&&window.hxd.res&&window.hxd.res.load)try{const l=window.hxd.res.load(n);if(l&&l.entry&&l.entry.getBytes){const o=l.entry.getBytes();return this.stringToArrayBuffer(o.toString())}}catch{}const r=this.resolveUrl(n),i=new XMLHttpRequest;return i.open("GET",r,!1),i.send(),i.status===200?this.stringToArrayBuffer(i.response):new ArrayBuffer(0)}extractFilenameFromUrl(n){const r=n.split("?")[0].split("#")[0].split("/"),i=r[r.length-1];return i&&(i.endsWith(".manim")||i.endsWith(".anim")||i.endsWith(".png")||i.endsWith(".atlas2")||i.endsWith(".fnt")||i.endsWith(".tps"))?i:null}onContentChanged(n){if(this.currentFile){const t=this.manimFiles.find(i=>i.filename===this.currentFile);t&&(t.content=n,ii(this.currentFile,n));const r=this.animFiles.find(i=>i.filename===this.currentFile);r&&(r.content=n,ii(this.currentFile,n))}this.reloadTimeout&&clearTimeout(this.reloadTimeout),this.reloadTimeout=setTimeout(()=>{this.reloadPlayground()},this.reloadDelay)}reloadPlayground(n){var r;let t=n;if(!t){const i=document.getElementById("screen-selector");t=i?i.value:"particles"}if((r=window.PlaygroundMain)!=null&&r.instance)try{const i=window.PlaygroundMain.instance.reload(t,!0);return console.log("PlaygroundLoader reload result:",i),console.log("Result type:",typeof i),console.log("Result keys:",i?Object.keys(i):"null"),i&&i.__nativeException&&console.log("Error in reload result:",i.__nativeException),i}catch(i){return console.log("Exception during reload:",i),{__nativeException:i}}return null}getCurrentContent(){const n=document.getElementById("manim-textarea");return n?n.value:""}getCurrentFile(){return this.currentFile}getEditedContent(n){const t=this.manimFiles.find(i=>i.filename===n);if(t)return t.content;const r=this.animFiles.find(i=>i.filename===n);return r?r.content:null}updateContent(n,t){const r=this.manimFiles.find(i=>i.filename===n);r&&(r.content=t,ii(n,t))}dispose(){this.mainApp&&typeof this.mainApp.dispose=="function"&&this.mainApp.dispose()}static getDefaultScreen(){return li}}function p0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Ps(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Ns(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Ps(Object(t),!0).forEach(function(r){p0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Ps(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function m0(e,n){if(e==null)return{};var t={},r=Object.keys(e),i,l;for(l=0;l<r.length;l++)i=r[l],!(n.indexOf(i)>=0)&&(t[i]=e[i]);return t}function h0(e,n){if(e==null)return{};var t=m0(e,n),r,i;if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(i=0;i<l.length;i++)r=l[i],!(n.indexOf(r)>=0)&&Object.prototype.propertyIsEnumerable.call(e,r)&&(t[r]=e[r])}return t}function g0(e,n){return v0(e)||y0(e,n)||x0(e,n)||w0()}function v0(e){if(Array.isArray(e))return e}function y0(e,n){if(!(typeof Symbol>"u"||!(Symbol.iterator in Object(e)))){var t=[],r=!0,i=!1,l=void 0;try{for(var o=e[Symbol.iterator](),a;!(r=(a=o.next()).done)&&(t.push(a.value),!(n&&t.length===n));r=!0);}catch(u){i=!0,l=u}finally{try{!r&&o.return!=null&&o.return()}finally{if(i)throw l}}return t}}function x0(e,n){if(e){if(typeof e=="string")return Fs(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);if(t==="Object"&&e.constructor&&(t=e.constructor.name),t==="Map"||t==="Set")return Array.from(e);if(t==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return Fs(e,n)}}function Fs(e,n){(n==null||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function w0(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function k0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Ts(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function js(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Ts(Object(t),!0).forEach(function(r){k0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Ts(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function _0(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];return function(r){return n.reduceRight(function(i,l){return l(i)},r)}}function Qt(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function Fi(e){return{}.toString.call(e).includes("Object")}function S0(e){return!Object.keys(e).length}function wr(e){return typeof e=="function"}function b0(e,n){return Object.prototype.hasOwnProperty.call(e,n)}function C0(e,n){return Fi(n)||On("changeType"),Object.keys(n).some(function(t){return!b0(e,t)})&&On("changeField"),n}function E0(e){wr(e)||On("selectorType")}function $0(e){wr(e)||Fi(e)||On("handlerType"),Fi(e)&&Object.values(e).some(function(n){return!wr(n)})&&On("handlersType")}function P0(e){e||On("initialIsRequired"),Fi(e)||On("initialType"),S0(e)&&On("initialContent")}function N0(e,n){throw new Error(e[n]||e.default)}var F0={initialIsRequired:"initial state is required",initialType:"initial state should be an object",initialContent:"initial state shouldn't be an empty object",handlerType:"handler should be an object or a function",handlersType:"all handlers should be a functions",selectorType:"selector should be a function",changeType:"provided value of changes should be an object",changeField:'it seams you want to change a field in the state which is not specified in the "initial" state',default:"an unknown error accured in `state-local` package"},On=Qt(N0)(F0),Hr={changes:C0,selector:E0,handler:$0,initial:P0};function T0(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};Hr.initial(e),Hr.handler(n);var t={current:e},r=Qt(L0)(t,n),i=Qt(z0)(t),l=Qt(Hr.changes)(e),o=Qt(j0)(t);function a(){var d=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(v){return v};return Hr.selector(d),d(t.current)}function u(d){_0(r,i,l,o)(d)}return[a,u]}function j0(e,n){return wr(n)?n(e.current):n}function z0(e,n){return e.current=js(js({},e.current),n),n}function L0(e,n,t){return wr(n)?n(e.current):Object.keys(t).forEach(function(r){var i;return(i=n[r])===null||i===void 0?void 0:i.call(n,e.current[r])}),t}var M0={create:T0},R0={paths:{vs:"https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs"}};function D0(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function O0(e){return{}.toString.call(e).includes("Object")}function I0(e){return e||zs("configIsRequired"),O0(e)||zs("configType"),e.urls?(A0(),{paths:{vs:e.urls.monacoBase}}):e}function A0(){console.warn(Yc.deprecation)}function U0(e,n){throw new Error(e[n]||e.default)}var Yc={configIsRequired:"the configuration object is required",configType:"the configuration object should be an object",default:"an unknown error accured in `@monaco-editor/loader` package",deprecation:`Deprecation warning!
    You are using deprecated way of configuration.

    Instead of using
      monaco.config({ urls: { monacoBase: '...' } })
    use
      monaco.config({ paths: { vs: '...' } })

    For more please check the link https://github.com/suren-atoyan/monaco-loader#config
  `},zs=D0(U0)(Yc),B0={config:I0},W0=function(){for(var n=arguments.length,t=new Array(n),r=0;r<n;r++)t[r]=arguments[r];return function(i){return t.reduceRight(function(l,o){return o(l)},i)}};function Xc(e,n){return Object.keys(n).forEach(function(t){n[t]instanceof Object&&e[t]&&Object.assign(n[t],Xc(e[t],n[t]))}),Ns(Ns({},e),n)}var H0={type:"cancelation",msg:"operation is manually canceled"};function _l(e){var n=!1,t=new Promise(function(r,i){e.then(function(l){return n?i(H0):r(l)}),e.catch(i)});return t.cancel=function(){return n=!0},t}var V0=M0.create({config:R0,isInitialized:!1,resolve:null,reject:null,monaco:null}),Zc=g0(V0,2),Er=Zc[0],Ki=Zc[1];function Q0(e){var n=B0.config(e),t=n.monaco,r=h0(n,["monaco"]);Ki(function(i){return{config:Xc(i.config,r),monaco:t}})}function K0(){var e=Er(function(n){var t=n.monaco,r=n.isInitialized,i=n.resolve;return{monaco:t,isInitialized:r,resolve:i}});if(!e.isInitialized){if(Ki({isInitialized:!0}),e.monaco)return e.resolve(e.monaco),_l(Sl);if(window.monaco&&window.monaco.editor)return qc(window.monaco),e.resolve(window.monaco),_l(Sl);W0(G0,X0)(Z0)}return _l(Sl)}function G0(e){return document.body.appendChild(e)}function Y0(e){var n=document.createElement("script");return e&&(n.src=e),n}function X0(e){var n=Er(function(r){var i=r.config,l=r.reject;return{config:i,reject:l}}),t=Y0("".concat(n.config.paths.vs,"/loader.js"));return t.onload=function(){return e()},t.onerror=n.reject,t}function Z0(){var e=Er(function(t){var r=t.config,i=t.resolve,l=t.reject;return{config:r,resolve:i,reject:l}}),n=window.require;n.config(e.config),n(["vs/editor/editor.main"],function(t){qc(t),e.resolve(t)},function(t){e.reject(t)})}function qc(e){Er().monaco||Ki({monaco:e})}function q0(){return Er(function(e){var n=e.monaco;return n})}var Sl=new Promise(function(e,n){return Ki({resolve:e,reject:n})}),Jc={config:Q0,init:K0,__getMonacoInstance:q0},J0={wrapper:{display:"flex",position:"relative",textAlign:"initial"},fullWidth:{width:"100%"},hide:{display:"none"}},bl=J0,em={container:{display:"flex",height:"100%",width:"100%",justifyContent:"center",alignItems:"center"}},nm=em;function tm({children:e}){return he.createElement("div",{style:nm.container},e)}var rm=tm,im=rm;function lm({width:e,height:n,isEditorReady:t,loading:r,_ref:i,className:l,wrapperProps:o}){return he.createElement("section",{style:{...bl.wrapper,width:e,height:n},...o},!t&&he.createElement(im,null,r),he.createElement("div",{ref:i,style:{...bl.fullWidth,...!t&&bl.hide},className:l}))}var om=lm,ed=$.memo(om);function am(e){$.useEffect(e,[])}var nd=am;function sm(e,n,t=!0){let r=$.useRef(!0);$.useEffect(r.current||!t?()=>{r.current=!1}:e,n)}var De=sm;function tr(){}function vt(e,n,t,r){return um(e,r)||cm(e,n,t,r)}function um(e,n){return e.editor.getModel(td(e,n))}function cm(e,n,t,r){return e.editor.createModel(n,t,r?td(e,r):void 0)}function td(e,n){return e.Uri.parse(n)}function dm({original:e,modified:n,language:t,originalLanguage:r,modifiedLanguage:i,originalModelPath:l,modifiedModelPath:o,keepCurrentOriginalModel:a=!1,keepCurrentModifiedModel:u=!1,theme:d="light",loading:v="Loading...",options:m={},height:p="100%",width:h="100%",className:x,wrapperProps:w={},beforeMount:L=tr,onMount:c=tr}){let[s,f]=$.useState(!1),[g,_]=$.useState(!0),b=$.useRef(null),E=$.useRef(null),C=$.useRef(null),R=$.useRef(c),N=$.useRef(L),q=$.useRef(!1);nd(()=>{let D=Jc.init();return D.then(V=>(E.current=V)&&_(!1)).catch(V=>(V==null?void 0:V.type)!=="cancelation"&&console.error("Monaco initialization: error:",V)),()=>b.current?rn():D.cancel()}),De(()=>{if(b.current&&E.current){let D=b.current.getOriginalEditor(),V=vt(E.current,e||"",r||t||"text",l||"");V!==D.getModel()&&D.setModel(V)}},[l],s),De(()=>{if(b.current&&E.current){let D=b.current.getModifiedEditor(),V=vt(E.current,n||"",i||t||"text",o||"");V!==D.getModel()&&D.setModel(V)}},[o],s),De(()=>{let D=b.current.getModifiedEditor();D.getOption(E.current.editor.EditorOption.readOnly)?D.setValue(n||""):n!==D.getValue()&&(D.executeEdits("",[{range:D.getModel().getFullModelRange(),text:n||"",forceMoveMarkers:!0}]),D.pushUndoStop())},[n],s),De(()=>{var D,V;(V=(D=b.current)==null?void 0:D.getModel())==null||V.original.setValue(e||"")},[e],s),De(()=>{let{original:D,modified:V}=b.current.getModel();E.current.editor.setModelLanguage(D,r||t||"text"),E.current.editor.setModelLanguage(V,i||t||"text")},[t,r,i],s),De(()=>{var D;(D=E.current)==null||D.editor.setTheme(d)},[d],s),De(()=>{var D;(D=b.current)==null||D.updateOptions(m)},[m],s);let Me=$.useCallback(()=>{var ue;if(!E.current)return;N.current(E.current);let D=vt(E.current,e||"",r||t||"text",l||""),V=vt(E.current,n||"",i||t||"text",o||"");(ue=b.current)==null||ue.setModel({original:D,modified:V})},[t,n,i,e,r,l,o]),Se=$.useCallback(()=>{var D;!q.current&&C.current&&(b.current=E.current.editor.createDiffEditor(C.current,{automaticLayout:!0,...m}),Me(),(D=E.current)==null||D.editor.setTheme(d),f(!0),q.current=!0)},[m,d,Me]);$.useEffect(()=>{s&&R.current(b.current,E.current)},[s]),$.useEffect(()=>{!g&&!s&&Se()},[g,s,Se]);function rn(){var V,ue,F,M;let D=(V=b.current)==null?void 0:V.getModel();a||((ue=D==null?void 0:D.original)==null||ue.dispose()),u||((F=D==null?void 0:D.modified)==null||F.dispose()),(M=b.current)==null||M.dispose()}return he.createElement(ed,{width:h,height:p,isEditorReady:s,loading:v,_ref:C,className:x,wrapperProps:w})}var fm=dm;$.memo(fm);function pm(e){let n=$.useRef();return $.useEffect(()=>{n.current=e},[e]),n.current}var mm=pm,Vr=new Map;function hm({defaultValue:e,defaultLanguage:n,defaultPath:t,value:r,language:i,path:l,theme:o="light",line:a,loading:u="Loading...",options:d={},overrideServices:v={},saveViewState:m=!0,keepCurrentModel:p=!1,width:h="100%",height:x="100%",className:w,wrapperProps:L={},beforeMount:c=tr,onMount:s=tr,onChange:f,onValidate:g=tr}){let[_,b]=$.useState(!1),[E,C]=$.useState(!0),R=$.useRef(null),N=$.useRef(null),q=$.useRef(null),Me=$.useRef(s),Se=$.useRef(c),rn=$.useRef(),D=$.useRef(r),V=mm(l),ue=$.useRef(!1),F=$.useRef(!1);nd(()=>{let z=Jc.init();return z.then(O=>(R.current=O)&&C(!1)).catch(O=>(O==null?void 0:O.type)!=="cancelation"&&console.error("Monaco initialization: error:",O)),()=>N.current?A():z.cancel()}),De(()=>{var O,le,ye,We;let z=vt(R.current,e||r||"",n||i||"",l||t||"");z!==((O=N.current)==null?void 0:O.getModel())&&(m&&Vr.set(V,(le=N.current)==null?void 0:le.saveViewState()),(ye=N.current)==null||ye.setModel(z),m&&((We=N.current)==null||We.restoreViewState(Vr.get(l))))},[l],_),De(()=>{var z;(z=N.current)==null||z.updateOptions(d)},[d],_),De(()=>{!N.current||r===void 0||(N.current.getOption(R.current.editor.EditorOption.readOnly)?N.current.setValue(r):r!==N.current.getValue()&&(F.current=!0,N.current.executeEdits("",[{range:N.current.getModel().getFullModelRange(),text:r,forceMoveMarkers:!0}]),N.current.pushUndoStop(),F.current=!1))},[r],_),De(()=>{var O,le;let z=(O=N.current)==null?void 0:O.getModel();z&&i&&((le=R.current)==null||le.editor.setModelLanguage(z,i))},[i],_),De(()=>{var z;a!==void 0&&((z=N.current)==null||z.revealLine(a))},[a],_),De(()=>{var z;(z=R.current)==null||z.editor.setTheme(o)},[o],_);let M=$.useCallback(()=>{var z;if(!(!q.current||!R.current)&&!ue.current){Se.current(R.current);let O=l||t,le=vt(R.current,r||e||"",n||i||"",O||"");N.current=(z=R.current)==null?void 0:z.editor.create(q.current,{model:le,automaticLayout:!0,...d},v),m&&N.current.restoreViewState(Vr.get(O)),R.current.editor.setTheme(o),a!==void 0&&N.current.revealLine(a),b(!0),ue.current=!0}},[e,n,t,r,i,l,d,v,m,o,a]);$.useEffect(()=>{_&&Me.current(N.current,R.current)},[_]),$.useEffect(()=>{!E&&!_&&M()},[E,_,M]),D.current=r,$.useEffect(()=>{var z,O;_&&f&&((z=rn.current)==null||z.dispose(),rn.current=(O=N.current)==null?void 0:O.onDidChangeModelContent(le=>{F.current||f(N.current.getValue(),le)}))},[_,f]),$.useEffect(()=>{if(_){let z=R.current.editor.onDidChangeMarkers(O=>{var ye;let le=(ye=N.current.getModel())==null?void 0:ye.uri;if(le&&O.find(We=>We.path===le.path)){let We=R.current.editor.getModelMarkers({resource:le});g==null||g(We)}});return()=>{z==null||z.dispose()}}return()=>{}},[_,g]);function A(){var z,O;(z=rn.current)==null||z.dispose(),p?m&&Vr.set(l,N.current.saveViewState()):(O=N.current.getModel())==null||O.dispose(),N.current.dispose()}return he.createElement(ed,{width:h,height:x,isEditorReady:_,loading:u,_ref:q,className:w,wrapperProps:L})}var gm=hm,vm=$.memo(gm),ym=vm;const xm=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{include:"#keywords"}],wm={keywords:{patterns:[{name:"entity.name.class",match:"\\b(sheet|allowedExtraPoints|states|center)\\b"},{name:"keyword",match:"\\b(animation)\\b"},{name:"entity.name.type",match:"\\b(name|fps|playlist|sheet|extrapoints|playlist|loop|event|goto|hit|random|trigger|command|frames|untilCommand|duration|file)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},km={patterns:xm,repository:wm},_m=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{name:"variable.name",match:"\\$[A-Za-z][A-Za-z0-9]*"},{name:"entity.name.tag",match:"#[A-Za-z][A-Za-z0-9\\-]*\\b"},{begin:"(@|@if|@ifstrict)\\(",beginCaptures:{0:{name:"keyword.control.at-sign"}},end:"\\)",endCaptures:{0:{name:"keyword.control.parenthesis"}},name:"meta.condition-block",contentName:"meta.condition-content",patterns:[{match:"\\b([A-Za-z_][A-Za-z0-9_]*)\\s*=>",name:"meta.condition-pair",captures:{0:{name:"keyword.other"},1:{name:"variable.other.key"}}},{match:"([A-Za-z_][A-Za-z0-9_]*)",name:"constant.other.value"},{match:",",name:"punctuation.separator.comma"}]},{name:"entity.name.method",match:"\\b@[A-Za-z][A-Za-z0-9]*\\b"},{include:"#keywords"}],Sm={keywords:{patterns:[{name:"entity.name.class",match:"\\b(animatedPath|particles|programmable|stateanim|flow|apply|text|tilegroup|repeatable|ninepatch|layers|placeholder|reference|bitmap|point|interactive|pixels|relativeLayouts|palettes|paths)\\b"},{name:"keyword",match:"\\b(external|path|debug|version|nothing|list|line|flat|pointy|layer|layout|callback|builderParam|tileSource|sheet|file|generated|hex|hexCorner|hexEdge|grid|settings|pos|alpha|blendMode|scale|updatable|cross|function|gridWidth|gridHeight|center|left|right|top|bottom|offset|construct|palette|position|import|filter)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},bm={patterns:_m,repository:Sm},Ls=e=>{const n={root:[]};return e.patterns&&e.patterns.forEach(t=>{if(t.include){const r=t.include.replace("#","");e.repository&&e.repository[r]&&e.repository[r].patterns.forEach(l=>{l.match&&n.root.push([new RegExp(l.match),l.name||"identifier"])})}else t.match&&n.root.push([new RegExp(t.match),t.name||"identifier"])}),e.repository&&Object.keys(e.repository).forEach(t=>{const r=e.repository[t];r.patterns&&(n[t]=r.patterns.map(i=>i.match?[new RegExp(i.match),i.name||"identifier"]:["",""]).filter(([i])=>i!==""))}),n},rd=$.forwardRef(({value:e,onChange:n,language:t="text",disabled:r=!1,placeholder:i,onSave:l,errorLine:o,errorColumn:a,errorStart:u,errorEnd:d},v)=>{const m=$.useRef(null),p=$.useRef(),h=$.useRef([]);$.useEffect(()=>{p.current=l},[l]),$.useEffect(()=>{if(m.current&&(h.current.length>0&&(m.current.deltaDecorations(h.current,[]),h.current=[]),o)){const c=[];if(c.push({range:{startLineNumber:o,startColumn:1,endLineNumber:o,endColumn:1},options:{isWholeLine:!0,className:"error-line",glyphMarginClassName:"error-glyph",linesDecorationsClassName:"error-line-decoration"}}),u!==void 0&&d!==void 0){const s=m.current.getModel();if(s)try{const f=s.getPositionAt(u),g=s.getPositionAt(d);c.push({range:{startLineNumber:f.lineNumber,startColumn:f.column,endLineNumber:g.lineNumber,endColumn:g.column},options:{className:"error-token",hoverMessage:{value:"Parse error at this position"}}})}catch(f){console.log("Error calculating character position:",f)}}h.current=m.current.deltaDecorations([],c)}},[o,a,u,d]);const x=(c,s)=>{m.current=c,s.languages.register({id:"haxe-anim"}),s.languages.register({id:"haxe-manim"});const f=Ls(km);s.languages.setMonarchTokensProvider("haxe-anim",{tokenizer:f});const g=Ls(bm);s.languages.setMonarchTokensProvider("haxe-manim",{tokenizer:g}),c.addAction({id:"save-file",label:"Save File",keybindings:[s.KeyMod.CtrlCmd|s.KeyCode.KeyS],run:()=>{p.current&&p.current()}}),c.focus()},w=c=>{c!==void 0&&n(c)},L=()=>t==="typescript"&&(e.includes("class")||e.includes("function")||e.includes("var"))?"haxe-manim":t;return y.jsxs("div",{ref:v,className:"w-full h-full min-h-[200px] border border-zinc-700 rounded overflow-hidden",style:{minHeight:200},children:[y.jsx("style",{children:`
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
        `}),y.jsx(ym,{height:"100%",defaultLanguage:L(),value:e,onChange:w,onMount:x,options:{readOnly:r,minimap:{enabled:!1},scrollBeyondLastLine:!1,fontSize:12,fontFamily:'Consolas, Monaco, "Courier New", monospace',lineNumbers:"on",roundedSelection:!1,scrollbar:{vertical:"visible",horizontal:"visible",verticalScrollbarSize:8,horizontalScrollbarSize:8},automaticLayout:!0,wordWrap:"on",theme:"vs-dark",tabSize:2,insertSpaces:!0,detectIndentation:!1,trimAutoWhitespace:!0,largeFileOptimizations:!1,placeholder:i,suggest:{showKeywords:!0,showSnippets:!0,showClasses:!0,showFunctions:!0,showVariables:!0},quickSuggestions:{other:!0,comments:!1,strings:!1}},theme:"vs-dark"})]})});rd.displayName="CodeEditor";const li="draggable";function Cm(){var ya;const[e,n]=$.useState(li),[t,r]=$.useState(""),[i,l]=$.useState(""),[o,a]=$.useState(!1),[u,d]=$.useState(""),[v,m]=$.useState(!1),[p,h]=$.useState(null),[x,w]=$.useState(null),[L,c]=$.useState(!0),[s]=$.useState(()=>new f0),[f,g]=$.useState(250),[_,b]=$.useState(400),[E,C]=$.useState(600),[R,N]=$.useState("playground"),[q,Me]=$.useState([]),Se=$.useRef(null),rn=$.useRef(null),D=$.useRef(null),V=$.useRef(!1),ue=$.useRef("");$.useEffect(()=>{p&&N("console")},[p]),$.useEffect(()=>{L&&x&&w(null)},[L,x]),$.useEffect(()=>{const k=console.log,P=console.error,U=console.warn,G=console.info,de=(Q,...W)=>{const j=W.map(I=>{var be;if(typeof I=="object")try{return JSON.stringify(I,null,2)}catch{return((be=I.toString)==null?void 0:be.call(I))||"[Circular Object]"}return String(I)}).join(" ");Me(I=>[...I,{type:Q,message:j,timestamp:new Date}])};return console.log=(...Q)=>{k(...Q),de("log",...Q)},console.error=(...Q)=>{P(...Q),de("error",...Q)},console.warn=(...Q)=>{U(...Q),de("warn",...Q)},console.info=(...Q)=>{G(...Q),de("info",...Q)},()=>{console.log=k,console.error=P,console.warn=U,console.info=G}},[]),$.useEffect(()=>{Se.current&&(Se.current.scrollTop=Se.current.scrollHeight)},[q]);const F=()=>{Me([])},M=he.useMemo(()=>{const k=new Map;return s.screens.forEach(P=>{P.manimFile&&k.set(P.manimFile,P.name)}),k},[s.screens]),A=he.useCallback(k=>{if(!k.endsWith(".manim")){w(null);return}const P=M.get(k);P&&P!==e?L?(n(P),s.reloadPlayground(P)):w({file:k,screen:P}):w(null)},[M,e,L,s]),z=he.useMemo(()=>({scrollableList:"ScrollableListTestScreen.hx",button:"ButtonTestScreen.hx",checkbox:"CheckboxTestScreen.hx",slider:"SliderTestScreen.hx",particles:"ParticlesScreen.hx",components:"ComponentsTestScreen.hx",examples1:"Examples1Screen.hx",paths:"PathsScreen.hx",fonts:"FontsScreen.hx",room1:"Room1Screen.hx",stateAnim:"StateAnimScreen.hx",dialogStart:"DialogStartScreen.hx",settings:"SettingsScreen.hx",atlasTest:"AtlasTestScreen.hx",draggable:"DraggableTestScreen.hx"}),[]),O=he.useCallback(k=>z[k]||`${k.charAt(0).toUpperCase()+k.slice(1)}Screen.hx`,[z]),le=()=>{x&&(n(x.screen),w(null),s.reloadPlayground(x.screen))},ye=()=>{w(null)},We=k=>{switch(k){case"error":return"❌";case"warn":return"⚠️";case"info":return"ℹ️";default:return"📋"}},dn=k=>{switch(k){case"error":return"text-red-400";case"warn":return"text-yellow-400";case"info":return"text-blue-400";default:return"text-gray-300"}};$.useEffect(()=>{const k=()=>{var U;(U=window.PlaygroundMain)!=null&&U.defaultScreen&&n(window.PlaygroundMain.defaultScreen)};k();const P=setTimeout(k,100);return()=>clearTimeout(P)},[]),$.useEffect(()=>(window.playgroundLoader=s,window.defaultScreen=li,s.onContentChanged=k=>{l(k)},()=>{s.dispose()}),[s]);function _n(){var k,P,U,G,de,Q;if(e)try{const W=s.reloadPlayground(e);if(W&&W.__nativeException){const j=W.__nativeException,I={message:j.message||((k=j.toString)==null?void 0:k.call(j))||"Unknown error occurred",pos:(P=j.value)==null?void 0:P.pos,token:(U=j.value)==null?void 0:U.token};h(I)}else if(W&&W.value&&W.value.__nativeException){const j=W.value.__nativeException,I={message:j.message||((G=j.toString)==null?void 0:G.call(j))||"Unknown error occurred",pos:(de=j.value)==null?void 0:de.pos,token:(Q=j.value)==null?void 0:Q.token};h(I)}else if(W&&W.error){const j={message:W.error||"Unknown error occurred",pos:W.pos,token:W.token};h(j)}else if(W&&!W.success){const j={message:W.error||"Operation failed",pos:W.pos,token:W.token};h(j)}else h(null)}catch(W){let j="Unknown error occurred";try{if(W instanceof Error)j=W.message;else if(typeof W=="string")j=W;else if(W&&typeof W=="object"){const be=W;be.message?j=be.message:be.toString?j=be.toString():j="Error occurred"}}catch{j="Error occurred (could not serialize)"}h({message:j,pos:void 0,token:void 0})}}$.useEffect(()=>{if(s.manimFiles.length>0&&e){const k=s.screens.find(P=>P.name===e);if(k&&k.manimFile){const P=s.manimFiles.find(U=>U.filename===k.manimFile);P&&(r(k.manimFile),l(P.content||""),d(P.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,m(!1),_n())}}},[s.manimFiles,e]),$.useEffect(()=>{const k=s.screens.find(P=>P.name===e);if(k&&k.manimFile){const P=s.manimFiles.find(U=>U.filename===k.manimFile);P&&(r(k.manimFile),l(P.content||""),d(P.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,m(!1),_n())}},[e,s]);const od=()=>{if(t&&s.manimFiles.find(k=>k.filename===t))return t;if(e&&s.manimFiles.length>0){const k=s.screens.find(U=>U.name===e);if(k&&k.manimFile){const U=s.manimFiles.find(G=>G.filename===k.manimFile);if(U)return r(k.manimFile),(!i||i.trim()==="")&&l(U.content||""),d(U.description),a(!0),s.currentFile=k.manimFile,s.currentExample=k.manimFile,k.manimFile}const P=s.manimFiles[0];return r(P.filename),(!i||i.trim()==="")&&l(P.content||""),d(P.description),a(!0),s.currentFile=P.filename,s.currentExample=P.filename,P.filename}if(s.manimFiles.length>0){const k=s.manimFiles[0];return r(k.filename),s.currentFile=k.filename,s.currentExample=k.filename,k.filename}return null},ad=k=>{const P=k.target.value;n(P),w(null),s.reloadPlayground(P)},ma=he.useMemo(()=>{const k=new Map;return s.manimFiles.forEach(P=>{k.set(P.filename,P)}),k},[s.manimFiles]),ha=he.useMemo(()=>{const k=new Map;return s.animFiles.forEach(P=>{k.set(P.filename,P)}),k},[s.animFiles]),ga=he.useCallback(k=>{const P=k.target.value;if(r(P),P){if(P.endsWith(".manim")){const U=ma.get(P);U&&(l(U.content||""),d(U.description),a(!0),s.currentFile=P,s.currentExample=P,m(!1),A(P))}else if(P.endsWith(".anim")){const U=ha.get(P);U&&(l(U.content||""),d("Animation file - content loaded and available to playground"),a(!0),s.currentFile=P,s.currentExample=P,m(!1),w(null))}}else l(""),a(!1),s.currentFile=null,s.currentExample=null,m(!1),w(null)},[ma,ha,A,s]),sd=he.useCallback(k=>{l(k),m(!0)},[]),ud=()=>{var P,U,G,de,Q,W;const k=od();if(k&&(s.updateContent(k,i),ii(k,i),m(!1),e))try{const j=s.reloadPlayground(e);if(j&&j.__nativeException){const I=j.__nativeException,be={message:I.message||((P=I.toString)==null?void 0:P.call(I))||"Unknown error occurred",pos:(U=I.value)==null?void 0:U.pos,token:(G=I.value)==null?void 0:G.token};h(be)}else if(j&&j.value&&j.value.__nativeException){const I=j.value.__nativeException,be={message:I.message||((de=I.toString)==null?void 0:de.call(I))||"Unknown error occurred",pos:(Q=I.value)==null?void 0:Q.pos,token:(W=I.value)==null?void 0:W.token};h(be)}else if(j&&j.error){const I={message:j.error||"Unknown error occurred",pos:j.pos,token:j.token};h(I)}else if(j&&!j.success){const I={message:j.error||"Operation failed",pos:j.pos,token:j.token};h(I)}else h(null)}catch(j){let I="Unknown error occurred";try{if(j instanceof Error)I=j.message;else if(typeof j=="string")I=j;else if(j&&typeof j=="object"){const ln=j;ln.message?I=ln.message:ln.toString?I=ln.toString():I="Error occurred"}}catch{I="Error occurred (could not serialize)"}h({message:I,pos:void 0,token:void 0})}},va=he.useCallback(()=>{ud()},[t,i,e,s]),ce=he.useMemo(()=>{if(!(p!=null&&p.pos))return null;const{pmin:k,pmax:P}=p.pos,U=i;let G=1,de=1;for(let Q=0;Q<k&&Q<U.length;Q++)U[Q]===`
`?(G++,de=1):de++;return{line:G,column:de,start:k,end:P}},[p==null?void 0:p.pos,i]),Gi=k=>P=>{V.current=!0,ue.current=k,P.preventDefault()};return $.useEffect(()=>{const k=U=>{if(V.current){if(ue.current==="file"){const G=U.clientX;G>150&&G<window.innerWidth-300&&g(G)}else if(ue.current==="editor"){const G=U.clientX-f;G>200&&G<window.innerWidth-f-200&&b(G)}else if(ue.current==="playground"){const G=window.innerWidth-f-_-2,de=f+_+2,Q=U.clientX-de,W=200,j=G-200;Q>W&&Q<j&&C(Q)}}},P=()=>{V.current=!1,ue.current=""};return document.addEventListener("mousemove",k),document.addEventListener("mouseup",P),()=>{document.removeEventListener("mousemove",k),document.removeEventListener("mouseup",P)}},[f,_]),$.useEffect(()=>{window.PlaygroundMain||(window.PlaygroundMain={}),window.PlaygroundMain.defaultScreen=li},[]),$.useEffect(()=>{i&&e&&_n()},[i,e]),$.useEffect(()=>{function k(P){if(P.error&&P.error.message&&P.error.message.includes("unexpected MP")){const U=P.error.message.match(/at ([^:]+):(\d+): characters (\d+)-(\d+)/);let G;if(U){const de=parseInt(U[2],10),Q=parseInt(U[3],10),W=parseInt(U[4],10),j=i.split(`
`);let I=0;for(let ln=0;ln<de-1;ln++)I+=j[ln].length+1;I+=Q;let be=I+(W-Q);G={psource:"",pmin:I,pmax:be}}h({message:P.error.message,pos:G,token:void 0}),N("console")}}return window.addEventListener("error",k),()=>window.removeEventListener("error",k)},[i]),y.jsxs("div",{className:"flex h-screen w-screen bg-gray-900 text-white",children:[y.jsxs("div",{ref:rn,className:"bg-gray-800 border-r border-gray-700 flex flex-col",style:{width:f},children:[y.jsxs("div",{className:"p-4 border-b border-gray-700",children:[y.jsxs("div",{className:"mb-4",children:[y.jsx("label",{className:"block mb-2 text-xs font-medium text-gray-300",children:"Screen:"}),y.jsx("select",{className:"w-full p-2 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500",value:e,onChange:ad,children:s.screens.map(k=>y.jsx("option",{value:k.name,children:k.displayName},k.name))})]}),o&&y.jsxs("div",{className:"p-3 bg-gray-700 border border-gray-600 rounded h-20 overflow-y-auto overflow-x-hidden",children:[y.jsx("p",{className:"text-xs text-gray-300 leading-relaxed mb-2",children:u}),y.jsxs("a",{href:`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${O(e)}`,target:"_blank",rel:"noopener noreferrer",className:"text-xs text-blue-400 hover:text-blue-300 transition-colors",children:["📖 View ",e," Screen on GitHub"]})]})]}),y.jsx("div",{className:"flex-1 p-4",children:y.jsxs("div",{className:"text-xs text-gray-400",children:[y.jsx("div",{className:"mb-2",children:y.jsx("span",{className:"font-medium",children:"📁 Files:"})}),y.jsxs("div",{className:"space-y-1 scrollable",style:{maxHeight:"calc(100vh - 300px)"},children:[s.manimFiles.map(k=>y.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===k.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>ga({target:{value:k.filename}}),children:["📄 ",k.filename]},k.filename)),s.animFiles.map(k=>y.jsxs("div",{className:`p-2 rounded cursor-pointer text-xs ${t===k.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>ga({target:{value:k.filename}}),children:["🎬 ",k.filename]},k.filename))]})]})})]}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Gi("file")}),y.jsxs("div",{ref:D,className:"bg-gray-900 flex flex-col",style:{width:_},children:[y.jsxs("div",{className:"p-4 border-b border-gray-700",children:[y.jsxs("div",{className:"flex items-center justify-between mb-2",children:[y.jsxs("div",{className:"flex items-center space-x-4",children:[y.jsx("h2",{className:"text-base font-semibold text-gray-200",children:"Editor"}),y.jsxs("label",{className:"flex items-center space-x-2 text-xs text-gray-300",children:[y.jsx("input",{type:"checkbox",checked:L,onChange:k=>c(k.target.checked),className:"w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"}),y.jsx("span",{children:"Auto sync screen"})]})]}),v&&y.jsx("button",{className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition",onClick:va,title:"Save changes and reload playground (Ctrl+S)",children:"💾 Apply Changes"})]}),v&&!p&&y.jsx("div",{className:"text-xs text-orange-400 mb-2",children:'⚠️ Unsaved changes - Click "Apply Changes" to save and reload'}),p&&y.jsxs("div",{className:"p-3 bg-red-900/20 border border-red-700 rounded mb-2",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-red-400 text-xs",children:"❌ Parse Error:"}),y.jsx("button",{className:"text-red-300 hover:text-red-100 text-xs",onClick:()=>h(null),title:"Clear error",children:"✕"})]}),y.jsx("div",{className:"text-red-300 text-xs mb-1",children:p.message}),ce&&y.jsxs("div",{className:"text-red-400 text-xs",children:["Line ",ce.line,", Column ",ce.column]})]})]}),y.jsx("div",{className:"flex-1 scrollable",children:y.jsx(rd,{value:i,onChange:sd,language:"haxe-manim",disabled:!t,placeholder:"Select a manim file to load its content here...",onSave:va,errorLine:ce==null?void 0:ce.line,errorColumn:ce==null?void 0:ce.column,errorStart:ce==null?void 0:ce.start,errorEnd:ce==null?void 0:ce.end})}),x&&y.jsxs("div",{className:"p-3 bg-blue-900/20 border-t border-blue-700",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-blue-400",children:"🔄 Screen Sync:"}),y.jsx("button",{className:"text-blue-300 hover:text-blue-100",onClick:ye,title:"Dismiss",children:"✕"})]}),y.jsxs("div",{className:"text-blue-300 mb-3",children:["Switch to ",y.jsx("strong",{children:((ya=s.screens.find(k=>k.name===x.screen))==null?void 0:ya.displayName)||x.screen})," screen to match ",y.jsx("strong",{children:x.file}),"?"]}),y.jsxs("div",{className:"flex space-x-2",children:[y.jsx("button",{onClick:le,className:"px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded transition-colors",children:"✅ Switch Screen"}),y.jsx("button",{onClick:ye,className:"px-3 py-1 bg-gray-600 hover:bg-gray-700 text-white text-sm rounded transition-colors",children:"❌ Keep Current"})]})]})]}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Gi("editor")}),y.jsxs("div",{className:"flex-1 bg-gray-900 flex flex-col h-full min-h-0",children:[y.jsx("div",{className:"border-b border-gray-700 flex-shrink-0",children:y.jsxs("div",{className:"flex",children:[y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="playground"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>N("playground"),children:"🎮 Playground"}),y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="console"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>N("console"),children:p?"❌ Console":"📋 Console"}),y.jsx("button",{className:`px-4 py-2 text-xs font-medium transition-colors ${R==="info"?"bg-gray-800 text-white border-b-2 border-blue-500":"text-gray-400 hover:text-white hover:bg-gray-800"}`,onClick:()=>N("info"),children:"ℹ️ Info"})]})}),y.jsxs("div",{className:"flex-1 flex min-h-0",children:[y.jsx("div",{className:`${R==="playground"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,style:{width:R==="playground"?E:0},children:y.jsx("div",{className:"w-full h-full flex-1 min-h-0",children:y.jsx("canvas",{id:"webgl",className:"w-full h-full block"})})}),y.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Gi("playground")}),y.jsxs("div",{className:`${R==="console"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:[y.jsxs("div",{className:"p-3 border-b border-gray-700 flex justify-between items-center flex-shrink-0",children:[y.jsx("h3",{className:"text-xs font-medium text-gray-200",children:"Console Output"}),y.jsx("button",{onClick:F,className:"px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 rounded transition-colors",title:"Clear console",children:"🗑️ Clear"})]}),y.jsxs("div",{ref:Se,className:"flex-1 p-3 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0",children:[q.length===0?y.jsxs("div",{className:"text-gray-400 text-center py-8",children:[y.jsx("div",{className:"text-2xl mb-2",children:"📋"}),y.jsx("div",{children:"Console output will appear here."})]}):y.jsx("div",{className:"space-y-1",children:q.map((k,P)=>y.jsxs("div",{className:"flex items-start space-x-2",children:[y.jsx("span",{className:"text-gray-500 text-xs mt-1",children:k.timestamp.toLocaleTimeString()}),y.jsx("span",{className:"text-gray-500",children:We(k.type)}),y.jsx("span",{className:`${dn(k.type)} break-all`,children:k.message})]},P))}),p&&y.jsxs("div",{className:"mt-4 p-3 bg-red-900/20 border border-red-700 rounded",children:[y.jsxs("div",{className:"flex justify-between items-start mb-2",children:[y.jsx("div",{className:"font-bold text-red-400",children:"❌ Parse Error:"}),y.jsx("button",{className:"text-red-300 hover:text-red-100",onClick:()=>h(null),title:"Clear error",children:"✕"})]}),y.jsx("div",{className:"text-red-300 mb-2",children:p.message}),ce&&y.jsxs("div",{className:"text-red-400 text-sm",children:["Line ",ce.line,", Column ",ce.column]})]})]})]}),y.jsx("div",{className:`${R==="info"?"flex-1":"w-0"} transition-all duration-300 overflow-hidden flex flex-col h-full`,children:y.jsxs("div",{className:"p-4 h-full overflow-y-auto",children:[y.jsx("h3",{className:"text-base font-semibold text-gray-200 mb-4",children:"About hx-multianim Playground"}),y.jsxs("div",{className:"space-y-6",children:[y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"📚 Documentation & Resources"}),y.jsxs("div",{className:"space-y-2",children:[y.jsxs("a",{href:"https://github.com/bh213/hx-multianim",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"hx-multianim"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Animation library for Haxe driving this playground"})]}),y.jsxs("a",{href:"https://github.com/HeapsIO/heaps",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"Heaps"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform graphics framework"})]}),y.jsxs("a",{href:"https://haxe.org",target:"_blank",rel:"noopener noreferrer",className:"block p-3 bg-gray-700 hover:bg-gray-600 rounded transition-colors",children:[y.jsx("div",{className:"font-medium text-blue-400",children:"Haxe"}),y.jsx("div",{className:"text-xs text-gray-400",children:"Cross-platform programming language"})]})]})]}),y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"🎮 Playground Features"}),y.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[y.jsx("li",{children:"• Real-time code editing and preview"}),y.jsx("li",{children:"• Multiple animation examples and components"}),y.jsx("li",{children:"• File management for manim and anim files"}),y.jsx("li",{children:"• Console output and error display"}),y.jsx("li",{children:"• Resizable panels for optimal workflow"})]})]}),y.jsxs("div",{children:[y.jsx("h4",{className:"text-sm font-medium text-gray-300 mb-2",children:"💡 Tips"}),y.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[y.jsx("li",{children:"• Use Ctrl+S to apply changes quickly"}),y.jsx("li",{children:"• Switch between playground and console tabs"}),y.jsx("li",{children:"• Resize panels by dragging the dividers"}),y.jsx("li",{children:"• Select files to edit their content"}),y.jsx("li",{children:"• Check console for errors and output"})]})]})]})]})})]})]})]})}var id={exports:{}};(function(e,n){(function(t,r){e.exports=r()})(fd,function(){var t=function(){},r={},i={},l={};function o(p,h){p=p.push?p:[p];var x=[],w=p.length,L=w,c,s,f,g;for(c=function(_,b){b.length&&x.push(_),L--,L||h(x)};w--;){if(s=p[w],f=i[s],f){c(s,f);continue}g=l[s]=l[s]||[],g.push(c)}}function a(p,h){if(p){var x=l[p];if(i[p]=h,!!x)for(;x.length;)x[0](p,h),x.splice(0,1)}}function u(p,h){p.call&&(p={success:p}),h.length?(p.error||t)(h):(p.success||t)(p)}function d(p,h,x,w){var L=document,c=x.async,s=(x.numRetries||0)+1,f=x.before||t,g=p.replace(/[\?|#].*$/,""),_=p.replace(/^(css|img|module|nomodule)!/,""),b,E,C;if(w=w||0,/(^css!|\.css$)/.test(g))C=L.createElement("link"),C.rel="stylesheet",C.href=_,b="hideFocus"in C,b&&C.relList&&(b=0,C.rel="preload",C.as="style");else if(/(^img!|\.(png|gif|jpg|svg|webp)$)/.test(g))C=L.createElement("img"),C.src=_;else if(C=L.createElement("script"),C.src=_,C.async=c===void 0?!0:c,E="noModule"in C,/^module!/.test(g)){if(!E)return h(p,"l");C.type="module"}else if(/^nomodule!/.test(g)&&E)return h(p,"l");C.onload=C.onerror=C.onbeforeload=function(R){var N=R.type[0];if(b)try{C.sheet.cssText.length||(N="e")}catch(q){q.code!=18&&(N="e")}if(N=="e"){if(w+=1,w<s)return d(p,h,x,w)}else if(C.rel=="preload"&&C.as=="style")return C.rel="stylesheet";h(p,N,R.defaultPrevented)},f(p,C)!==!1&&L.head.appendChild(C)}function v(p,h,x){p=p.push?p:[p];var w=p.length,L=w,c=[],s,f;for(s=function(g,_,b){if(_=="e"&&c.push(g),_=="b")if(b)c.push(g);else return;w--,w||h(c)},f=0;f<L;f++)d(p[f],s,x)}function m(p,h,x){var w,L;if(h&&h.trim&&(w=h),L=(w?x:h)||{},w){if(w in r)throw"LoadJS";r[w]=!0}function c(s,f){v(p,function(g){u(L,g),s&&u({success:s,error:f},g),a(w,g)},L)}if(L.returnPromise)return new Promise(c);c()}return m.ready=function(h,x){return o(h,function(w){u(x,w)}),m},m.done=function(h){a(h,[])},m.reset=function(){r={},i={},l={}},m.isDefined=function(h){return h in r},m})})(id);var Em=id.exports;const Ms=Rs(Em);class $m{constructor(n={}){Ce(this,"maxRetries");Ce(this,"retryDelay");Ce(this,"timeout");Ce(this,"retryCount",0);Ce(this,"isLoaded",!1);this.maxRetries=n.maxRetries||5,this.retryDelay=n.retryDelay||2e3,this.timeout=n.timeout||1e4}waitForReactApp(){document.getElementById("root")&&window.playgroundLoader?(console.log("React app ready, loading Haxe application..."),this.loadHaxeApp()):setTimeout(()=>this.waitForReactApp(),300)}loadHaxeApp(){console.log(`Attempting to load playground.js (attempt ${this.retryCount+1}/${this.maxRetries+1})`);const n=setTimeout(()=>{console.error("Timeout loading playground.js"),this.handleLoadError()},this.timeout);Ms("playground.js",{success:()=>{clearTimeout(n),console.log("playground.js loaded successfully"),this.isLoaded=!0,this.waitForHaxeApp()},error:t=>{clearTimeout(n),console.error("Failed to load playground.js:",t),this.handleLoadError()}})}handleLoadError(){this.retryCount++,this.retryCount<=this.maxRetries?(console.log(`Retrying in ${this.retryDelay}ms... (${this.retryCount}/${this.maxRetries})`),setTimeout(()=>{this.loadHaxeApp()},this.retryDelay)):(console.error(`Failed to load playground.js after ${this.maxRetries} retries`),this.showErrorUI())}showErrorUI(){const n=document.createElement("div");n.style.cssText=`
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
    `,document.body.appendChild(n)}waitForHaxeApp(){Ms.ready("playground.js",()=>{console.log("playground.js is ready and executed"),this.waitForPlaygroundMain()})}waitForPlaygroundMain(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?(console.log("Haxe application initialized successfully"),window.playgroundLoader&&window.playgroundLoader.mainApp===null&&(window.playgroundLoader.mainApp=window.PlaygroundMain.instance)):setTimeout(()=>this.waitForPlaygroundMain(),100)}start(){document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>this.waitForReactApp()):this.waitForReactApp()}isScriptLoaded(){return this.isLoaded}getRetryCount(){return this.retryCount}}const ld=new $m({maxRetries:5,retryDelay:2e3,timeout:1e4});ld.start();window.haxeLoader=ld;Cl.createRoot(document.getElementById("root")).render(y.jsx(he.StrictMode,{children:y.jsx(Cm,{})}));
//# sourceMappingURL=index-D0rxadxO.js.map
