var md=Object.defineProperty;var hd=(e,n,t)=>n in e?md(e,n,{enumerable:!0,configurable:!0,writable:!0,value:t}):e[n]=t;var fe=(e,n,t)=>hd(e,typeof n!="symbol"?n+"":n,t);(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))r(i);new MutationObserver(i=>{for(const l of i)if(l.type==="childList")for(const o of l.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&r(o)}).observe(document,{childList:!0,subtree:!0});function t(i){const l={};return i.integrity&&(l.integrity=i.integrity),i.referrerPolicy&&(l.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?l.credentials="include":i.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function r(i){if(i.ep)return;i.ep=!0;const l=t(i);fetch(i.href,l)}})();var gd=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};function Os(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var Is={exports:{}},Ti={},Bs={exports:{}},O={};/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var yr=Symbol.for("react.element"),vd=Symbol.for("react.portal"),yd=Symbol.for("react.fragment"),xd=Symbol.for("react.strict_mode"),wd=Symbol.for("react.profiler"),Sd=Symbol.for("react.provider"),_d=Symbol.for("react.context"),kd=Symbol.for("react.forward_ref"),bd=Symbol.for("react.suspense"),Ed=Symbol.for("react.memo"),Cd=Symbol.for("react.lazy"),_a=Symbol.iterator;function Fd(e){return e===null||typeof e!="object"?null:(e=_a&&e[_a]||e["@@iterator"],typeof e=="function"?e:null)}var Ws={isMounted:function(){return!1},enqueueForceUpdate:function(){},enqueueReplaceState:function(){},enqueueSetState:function(){}},Us=Object.assign,Hs={};function Ft(e,n,t){this.props=e,this.context=n,this.refs=Hs,this.updater=t||Ws}Ft.prototype.isReactComponent={};Ft.prototype.setState=function(e,n){if(typeof e!="object"&&typeof e!="function"&&e!=null)throw Error("setState(...): takes an object of state variables to update or a function which returns an object of state variables.");this.updater.enqueueSetState(this,e,n,"setState")};Ft.prototype.forceUpdate=function(e){this.updater.enqueueForceUpdate(this,e,"forceUpdate")};function Vs(){}Vs.prototype=Ft.prototype;function _o(e,n,t){this.props=e,this.context=n,this.refs=Hs,this.updater=t||Ws}var ko=_o.prototype=new Vs;ko.constructor=_o;Us(ko,Ft.prototype);ko.isPureReactComponent=!0;var ka=Array.isArray,Gs=Object.prototype.hasOwnProperty,bo={current:null},Qs={key:!0,ref:!0,__self:!0,__source:!0};function Xs(e,n,t){var r,i={},l=null,o=null;if(n!=null)for(r in n.ref!==void 0&&(o=n.ref),n.key!==void 0&&(l=""+n.key),n)Gs.call(n,r)&&!Qs.hasOwnProperty(r)&&(i[r]=n[r]);var a=arguments.length-2;if(a===1)i.children=t;else if(1<a){for(var u=Array(a),d=0;d<a;d++)u[d]=arguments[d+2];i.children=u}if(e&&e.defaultProps)for(r in a=e.defaultProps,a)i[r]===void 0&&(i[r]=a[r]);return{$$typeof:yr,type:e,key:l,ref:o,props:i,_owner:bo.current}}function Nd(e,n){return{$$typeof:yr,type:e.type,key:n,ref:e.ref,props:e.props,_owner:e._owner}}function Eo(e){return typeof e=="object"&&e!==null&&e.$$typeof===yr}function Pd(e){var n={"=":"=0",":":"=2"};return"$"+e.replace(/[=:]/g,function(t){return n[t]})}var ba=/\/+/g;function Zi(e,n){return typeof e=="object"&&e!==null&&e.key!=null?Pd(""+e.key):n.toString(36)}function Gr(e,n,t,r,i){var l=typeof e;(l==="undefined"||l==="boolean")&&(e=null);var o=!1;if(e===null)o=!0;else switch(l){case"string":case"number":o=!0;break;case"object":switch(e.$$typeof){case yr:case vd:o=!0}}if(o)return o=e,i=i(o),e=r===""?"."+Zi(o,0):r,ka(i)?(t="",e!=null&&(t=e.replace(ba,"$&/")+"/"),Gr(i,n,t,"",function(d){return d})):i!=null&&(Eo(i)&&(i=Nd(i,t+(!i.key||o&&o.key===i.key?"":(""+i.key).replace(ba,"$&/")+"/")+e)),n.push(i)),1;if(o=0,r=r===""?".":r+":",ka(e))for(var a=0;a<e.length;a++){l=e[a];var u=r+Zi(l,a);o+=Gr(l,n,t,u,i)}else if(u=Fd(e),typeof u=="function")for(e=u.call(e),a=0;!(l=e.next()).done;)l=l.value,u=r+Zi(l,a++),o+=Gr(l,n,t,u,i);else if(l==="object")throw n=String(e),Error("Objects are not valid as a React child (found: "+(n==="[object Object]"?"object with keys {"+Object.keys(e).join(", ")+"}":n)+"). If you meant to render a collection of children, use an array instead.");return o}function Fr(e,n,t){if(e==null)return e;var r=[],i=0;return Gr(e,r,"","",function(l){return n.call(t,l,i++)}),r}function $d(e){if(e._status===-1){var n=e._result;n=n(),n.then(function(t){(e._status===0||e._status===-1)&&(e._status=1,e._result=t)},function(t){(e._status===0||e._status===-1)&&(e._status=2,e._result=t)}),e._status===-1&&(e._status=0,e._result=n)}if(e._status===1)return e._result.default;throw e._result}var be={current:null},Qr={transition:null},Td={ReactCurrentDispatcher:be,ReactCurrentBatchConfig:Qr,ReactCurrentOwner:bo};function Ks(){throw Error("act(...) is not supported in production builds of React.")}O.Children={map:Fr,forEach:function(e,n,t){Fr(e,function(){n.apply(this,arguments)},t)},count:function(e){var n=0;return Fr(e,function(){n++}),n},toArray:function(e){return Fr(e,function(n){return n})||[]},only:function(e){if(!Eo(e))throw Error("React.Children.only expected to receive a single React element child.");return e}};O.Component=Ft;O.Fragment=yd;O.Profiler=wd;O.PureComponent=_o;O.StrictMode=xd;O.Suspense=bd;O.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Td;O.act=Ks;O.cloneElement=function(e,n,t){if(e==null)throw Error("React.cloneElement(...): The argument must be a React element, but you passed "+e+".");var r=Us({},e.props),i=e.key,l=e.ref,o=e._owner;if(n!=null){if(n.ref!==void 0&&(l=n.ref,o=bo.current),n.key!==void 0&&(i=""+n.key),e.type&&e.type.defaultProps)var a=e.type.defaultProps;for(u in n)Gs.call(n,u)&&!Qs.hasOwnProperty(u)&&(r[u]=n[u]===void 0&&a!==void 0?a[u]:n[u])}var u=arguments.length-2;if(u===1)r.children=t;else if(1<u){a=Array(u);for(var d=0;d<u;d++)a[d]=arguments[d+2];r.children=a}return{$$typeof:yr,type:e.type,key:i,ref:l,props:r,_owner:o}};O.createContext=function(e){return e={$$typeof:_d,_currentValue:e,_currentValue2:e,_threadCount:0,Provider:null,Consumer:null,_defaultValue:null,_globalName:null},e.Provider={$$typeof:Sd,_context:e},e.Consumer=e};O.createElement=Xs;O.createFactory=function(e){var n=Xs.bind(null,e);return n.type=e,n};O.createRef=function(){return{current:null}};O.forwardRef=function(e){return{$$typeof:kd,render:e}};O.isValidElement=Eo;O.lazy=function(e){return{$$typeof:Cd,_payload:{_status:-1,_result:e},_init:$d}};O.memo=function(e,n){return{$$typeof:Ed,type:e,compare:n===void 0?null:n}};O.startTransition=function(e){var n=Qr.transition;Qr.transition={};try{e()}finally{Qr.transition=n}};O.unstable_act=Ks;O.useCallback=function(e,n){return be.current.useCallback(e,n)};O.useContext=function(e){return be.current.useContext(e)};O.useDebugValue=function(){};O.useDeferredValue=function(e){return be.current.useDeferredValue(e)};O.useEffect=function(e,n){return be.current.useEffect(e,n)};O.useId=function(){return be.current.useId()};O.useImperativeHandle=function(e,n,t){return be.current.useImperativeHandle(e,n,t)};O.useInsertionEffect=function(e,n){return be.current.useInsertionEffect(e,n)};O.useLayoutEffect=function(e,n){return be.current.useLayoutEffect(e,n)};O.useMemo=function(e,n){return be.current.useMemo(e,n)};O.useReducer=function(e,n,t){return be.current.useReducer(e,n,t)};O.useRef=function(e){return be.current.useRef(e)};O.useState=function(e){return be.current.useState(e)};O.useSyncExternalStore=function(e,n,t){return be.current.useSyncExternalStore(e,n,t)};O.useTransition=function(){return be.current.useTransition()};O.version="18.3.1";Bs.exports=O;var F=Bs.exports;const _e=Os(F);/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Rd=F,zd=Symbol.for("react.element"),Ld=Symbol.for("react.fragment"),Md=Object.prototype.hasOwnProperty,Dd=Rd.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,jd={key:!0,ref:!0,__self:!0,__source:!0};function Ys(e,n,t){var r,i={},l=null,o=null;t!==void 0&&(l=""+t),n.key!==void 0&&(l=""+n.key),n.ref!==void 0&&(o=n.ref);for(r in n)Md.call(n,r)&&!jd.hasOwnProperty(r)&&(i[r]=n[r]);if(e&&e.defaultProps)for(r in n=e.defaultProps,n)i[r]===void 0&&(i[r]=n[r]);return{$$typeof:zd,type:e,key:l,ref:o,props:i,_owner:Dd.current}}Ti.Fragment=Ld;Ti.jsx=Ys;Ti.jsxs=Ys;Is.exports=Ti;var _=Is.exports,Nl={},Zs={exports:{}},Ae={},qs={exports:{}},Js={};/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */(function(e){function n(N,z){var A=N.length;N.push(z);e:for(;0<A;){var R=A-1>>>1,D=N[R];if(0<i(D,z))N[R]=z,N[A]=D,A=R;else break e}}function t(N){return N.length===0?null:N[0]}function r(N){if(N.length===0)return null;var z=N[0],A=N.pop();if(A!==z){N[0]=A;e:for(var R=0,D=N.length,te=D>>>1;R<te;){var xe=2*(R+1)-1,Re=N[xe],an=xe+1,yn=N[an];if(0>i(Re,A))an<D&&0>i(yn,Re)?(N[R]=yn,N[an]=A,R=an):(N[R]=Re,N[xe]=A,R=xe);else if(an<D&&0>i(yn,A))N[R]=yn,N[an]=A,R=an;else break e}}return z}function i(N,z){var A=N.sortIndex-z.sortIndex;return A!==0?A:N.id-z.id}if(typeof performance=="object"&&typeof performance.now=="function"){var l=performance;e.unstable_now=function(){return l.now()}}else{var o=Date,a=o.now();e.unstable_now=function(){return o.now()-a}}var u=[],d=[],g=1,m=null,p=3,v=!1,w=!1,x=!1,L=typeof setTimeout=="function"?setTimeout:null,c=typeof clearTimeout=="function"?clearTimeout:null,s=typeof setImmediate<"u"?setImmediate:null;typeof navigator<"u"&&navigator.scheduling!==void 0&&navigator.scheduling.isInputPending!==void 0&&navigator.scheduling.isInputPending.bind(navigator.scheduling);function f(N){for(var z=t(d);z!==null;){if(z.callback===null)r(d);else if(z.startTime<=N)r(d),z.sortIndex=z.expirationTime,n(u,z);else break;z=t(d)}}function h(N){if(x=!1,f(N),!w)if(t(u)!==null)w=!0,W(S);else{var z=t(d);z!==null&&Ce(h,z.startTime-N)}}function S(N,z){w=!1,x&&(x=!1,c(E),E=-1),v=!0;var A=p;try{for(f(z),m=t(u);m!==null&&(!(m.expirationTime>z)||N&&!H());){var R=m.callback;if(typeof R=="function"){m.callback=null,p=m.priorityLevel;var D=R(m.expirationTime<=z);z=e.unstable_now(),typeof D=="function"?m.callback=D:m===t(u)&&r(u),f(z)}else r(u);m=t(u)}if(m!==null)var te=!0;else{var xe=t(d);xe!==null&&Ce(h,xe.startTime-z),te=!1}return te}finally{m=null,p=A,v=!1}}var b=!1,C=null,E=-1,j=5,P=-1;function H(){return!(e.unstable_now()-P<j)}function ve(){if(C!==null){var N=e.unstable_now();P=N;var z=!0;try{z=C(!0,N)}finally{z?ye():(b=!1,C=null)}}else b=!1}var ye;if(typeof s=="function")ye=function(){s(ve)};else if(typeof MessageChannel<"u"){var Ie=new MessageChannel,M=Ie.port2;Ie.port1.onmessage=ve,ye=function(){M.postMessage(null)}}else ye=function(){L(ve,0)};function W(N){C=N,b||(b=!0,ye())}function Ce(N,z){E=L(function(){N(e.unstable_now())},z)}e.unstable_IdlePriority=5,e.unstable_ImmediatePriority=1,e.unstable_LowPriority=4,e.unstable_NormalPriority=3,e.unstable_Profiling=null,e.unstable_UserBlockingPriority=2,e.unstable_cancelCallback=function(N){N.callback=null},e.unstable_continueExecution=function(){w||v||(w=!0,W(S))},e.unstable_forceFrameRate=function(N){0>N||125<N?console.error("forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported"):j=0<N?Math.floor(1e3/N):5},e.unstable_getCurrentPriorityLevel=function(){return p},e.unstable_getFirstCallbackNode=function(){return t(u)},e.unstable_next=function(N){switch(p){case 1:case 2:case 3:var z=3;break;default:z=p}var A=p;p=z;try{return N()}finally{p=A}},e.unstable_pauseExecution=function(){},e.unstable_requestPaint=function(){},e.unstable_runWithPriority=function(N,z){switch(N){case 1:case 2:case 3:case 4:case 5:break;default:N=3}var A=p;p=N;try{return z()}finally{p=A}},e.unstable_scheduleCallback=function(N,z,A){var R=e.unstable_now();switch(typeof A=="object"&&A!==null?(A=A.delay,A=typeof A=="number"&&0<A?R+A:R):A=R,N){case 1:var D=-1;break;case 2:D=250;break;case 5:D=1073741823;break;case 4:D=1e4;break;default:D=5e3}return D=A+D,N={id:g++,callback:z,priorityLevel:N,startTime:A,expirationTime:D,sortIndex:-1},A>R?(N.sortIndex=A,n(d,N),t(u)===null&&N===t(d)&&(x?(c(E),E=-1):x=!0,Ce(h,A-R))):(N.sortIndex=D,n(u,N),w||v||(w=!0,W(S))),N},e.unstable_shouldYield=H,e.unstable_wrapCallback=function(N){var z=p;return function(){var A=p;p=z;try{return N.apply(this,arguments)}finally{p=A}}}})(Js);qs.exports=Js;var Ad=qs.exports;/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var Od=F,je=Ad;function k(e){for(var n="https://reactjs.org/docs/error-decoder.html?invariant="+e,t=1;t<arguments.length;t++)n+="&args[]="+encodeURIComponent(arguments[t]);return"Minified React error #"+e+"; visit "+n+" for the full message or use the non-minified dev environment for full errors and additional helpful warnings."}var eu=new Set,er={};function qn(e,n){wt(e,n),wt(e+"Capture",n)}function wt(e,n){for(er[e]=n,e=0;e<n.length;e++)eu.add(n[e])}var pn=!(typeof window>"u"||typeof window.document>"u"||typeof window.document.createElement>"u"),Pl=Object.prototype.hasOwnProperty,Id=/^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,Ea={},Ca={};function Bd(e){return Pl.call(Ca,e)?!0:Pl.call(Ea,e)?!1:Id.test(e)?Ca[e]=!0:(Ea[e]=!0,!1)}function Wd(e,n,t,r){if(t!==null&&t.type===0)return!1;switch(typeof n){case"function":case"symbol":return!0;case"boolean":return r?!1:t!==null?!t.acceptsBooleans:(e=e.toLowerCase().slice(0,5),e!=="data-"&&e!=="aria-");default:return!1}}function Ud(e,n,t,r){if(n===null||typeof n>"u"||Wd(e,n,t,r))return!0;if(r)return!1;if(t!==null)switch(t.type){case 3:return!n;case 4:return n===!1;case 5:return isNaN(n);case 6:return isNaN(n)||1>n}return!1}function Ee(e,n,t,r,i,l,o){this.acceptsBooleans=n===2||n===3||n===4,this.attributeName=r,this.attributeNamespace=i,this.mustUseProperty=t,this.propertyName=e,this.type=n,this.sanitizeURL=l,this.removeEmptyString=o}var de={};"children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style".split(" ").forEach(function(e){de[e]=new Ee(e,0,!1,e,null,!1,!1)});[["acceptCharset","accept-charset"],["className","class"],["htmlFor","for"],["httpEquiv","http-equiv"]].forEach(function(e){var n=e[0];de[n]=new Ee(n,1,!1,e[1],null,!1,!1)});["contentEditable","draggable","spellCheck","value"].forEach(function(e){de[e]=new Ee(e,2,!1,e.toLowerCase(),null,!1,!1)});["autoReverse","externalResourcesRequired","focusable","preserveAlpha"].forEach(function(e){de[e]=new Ee(e,2,!1,e,null,!1,!1)});"allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope".split(" ").forEach(function(e){de[e]=new Ee(e,3,!1,e.toLowerCase(),null,!1,!1)});["checked","multiple","muted","selected"].forEach(function(e){de[e]=new Ee(e,3,!0,e,null,!1,!1)});["capture","download"].forEach(function(e){de[e]=new Ee(e,4,!1,e,null,!1,!1)});["cols","rows","size","span"].forEach(function(e){de[e]=new Ee(e,6,!1,e,null,!1,!1)});["rowSpan","start"].forEach(function(e){de[e]=new Ee(e,5,!1,e.toLowerCase(),null,!1,!1)});var Co=/[\-:]([a-z])/g;function Fo(e){return e[1].toUpperCase()}"accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height".split(" ").forEach(function(e){var n=e.replace(Co,Fo);de[n]=new Ee(n,1,!1,e,null,!1,!1)});"xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type".split(" ").forEach(function(e){var n=e.replace(Co,Fo);de[n]=new Ee(n,1,!1,e,"http://www.w3.org/1999/xlink",!1,!1)});["xml:base","xml:lang","xml:space"].forEach(function(e){var n=e.replace(Co,Fo);de[n]=new Ee(n,1,!1,e,"http://www.w3.org/XML/1998/namespace",!1,!1)});["tabIndex","crossOrigin"].forEach(function(e){de[e]=new Ee(e,1,!1,e.toLowerCase(),null,!1,!1)});de.xlinkHref=new Ee("xlinkHref",1,!1,"xlink:href","http://www.w3.org/1999/xlink",!0,!1);["src","href","action","formAction"].forEach(function(e){de[e]=new Ee(e,1,!1,e.toLowerCase(),null,!0,!0)});function No(e,n,t,r){var i=de.hasOwnProperty(n)?de[n]:null;(i!==null?i.type!==0:r||!(2<n.length)||n[0]!=="o"&&n[0]!=="O"||n[1]!=="n"&&n[1]!=="N")&&(Ud(n,t,i,r)&&(t=null),r||i===null?Bd(n)&&(t===null?e.removeAttribute(n):e.setAttribute(n,""+t)):i.mustUseProperty?e[i.propertyName]=t===null?i.type===3?!1:"":t:(n=i.attributeName,r=i.attributeNamespace,t===null?e.removeAttribute(n):(i=i.type,t=i===3||i===4&&t===!0?"":""+t,r?e.setAttributeNS(r,n,t):e.setAttribute(n,t))))}var vn=Od.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,Nr=Symbol.for("react.element"),nt=Symbol.for("react.portal"),tt=Symbol.for("react.fragment"),Po=Symbol.for("react.strict_mode"),$l=Symbol.for("react.profiler"),nu=Symbol.for("react.provider"),tu=Symbol.for("react.context"),$o=Symbol.for("react.forward_ref"),Tl=Symbol.for("react.suspense"),Rl=Symbol.for("react.suspense_list"),To=Symbol.for("react.memo"),wn=Symbol.for("react.lazy"),ru=Symbol.for("react.offscreen"),Fa=Symbol.iterator;function Tt(e){return e===null||typeof e!="object"?null:(e=Fa&&e[Fa]||e["@@iterator"],typeof e=="function"?e:null)}var J=Object.assign,qi;function Ot(e){if(qi===void 0)try{throw Error()}catch(t){var n=t.stack.trim().match(/\n( *(at )?)/);qi=n&&n[1]||""}return`
`+qi+e}var Ji=!1;function el(e,n){if(!e||Ji)return"";Ji=!0;var t=Error.prepareStackTrace;Error.prepareStackTrace=void 0;try{if(n)if(n=function(){throw Error()},Object.defineProperty(n.prototype,"props",{set:function(){throw Error()}}),typeof Reflect=="object"&&Reflect.construct){try{Reflect.construct(n,[])}catch(d){var r=d}Reflect.construct(e,[],n)}else{try{n.call()}catch(d){r=d}e.call(n.prototype)}else{try{throw Error()}catch(d){r=d}e()}}catch(d){if(d&&r&&typeof d.stack=="string"){for(var i=d.stack.split(`
`),l=r.stack.split(`
`),o=i.length-1,a=l.length-1;1<=o&&0<=a&&i[o]!==l[a];)a--;for(;1<=o&&0<=a;o--,a--)if(i[o]!==l[a]){if(o!==1||a!==1)do if(o--,a--,0>a||i[o]!==l[a]){var u=`
`+i[o].replace(" at new "," at ");return e.displayName&&u.includes("<anonymous>")&&(u=u.replace("<anonymous>",e.displayName)),u}while(1<=o&&0<=a);break}}}finally{Ji=!1,Error.prepareStackTrace=t}return(e=e?e.displayName||e.name:"")?Ot(e):""}function Hd(e){switch(e.tag){case 5:return Ot(e.type);case 16:return Ot("Lazy");case 13:return Ot("Suspense");case 19:return Ot("SuspenseList");case 0:case 2:case 15:return e=el(e.type,!1),e;case 11:return e=el(e.type.render,!1),e;case 1:return e=el(e.type,!0),e;default:return""}}function zl(e){if(e==null)return null;if(typeof e=="function")return e.displayName||e.name||null;if(typeof e=="string")return e;switch(e){case tt:return"Fragment";case nt:return"Portal";case $l:return"Profiler";case Po:return"StrictMode";case Tl:return"Suspense";case Rl:return"SuspenseList"}if(typeof e=="object")switch(e.$$typeof){case tu:return(e.displayName||"Context")+".Consumer";case nu:return(e._context.displayName||"Context")+".Provider";case $o:var n=e.render;return e=e.displayName,e||(e=n.displayName||n.name||"",e=e!==""?"ForwardRef("+e+")":"ForwardRef"),e;case To:return n=e.displayName||null,n!==null?n:zl(e.type)||"Memo";case wn:n=e._payload,e=e._init;try{return zl(e(n))}catch{}}return null}function Vd(e){var n=e.type;switch(e.tag){case 24:return"Cache";case 9:return(n.displayName||"Context")+".Consumer";case 10:return(n._context.displayName||"Context")+".Provider";case 18:return"DehydratedFragment";case 11:return e=n.render,e=e.displayName||e.name||"",n.displayName||(e!==""?"ForwardRef("+e+")":"ForwardRef");case 7:return"Fragment";case 5:return n;case 4:return"Portal";case 3:return"Root";case 6:return"Text";case 16:return zl(n);case 8:return n===Po?"StrictMode":"Mode";case 22:return"Offscreen";case 12:return"Profiler";case 21:return"Scope";case 13:return"Suspense";case 19:return"SuspenseList";case 25:return"TracingMarker";case 1:case 0:case 17:case 2:case 14:case 15:if(typeof n=="function")return n.displayName||n.name||null;if(typeof n=="string")return n}return null}function Mn(e){switch(typeof e){case"boolean":case"number":case"string":case"undefined":return e;case"object":return e;default:return""}}function iu(e){var n=e.type;return(e=e.nodeName)&&e.toLowerCase()==="input"&&(n==="checkbox"||n==="radio")}function Gd(e){var n=iu(e)?"checked":"value",t=Object.getOwnPropertyDescriptor(e.constructor.prototype,n),r=""+e[n];if(!e.hasOwnProperty(n)&&typeof t<"u"&&typeof t.get=="function"&&typeof t.set=="function"){var i=t.get,l=t.set;return Object.defineProperty(e,n,{configurable:!0,get:function(){return i.call(this)},set:function(o){r=""+o,l.call(this,o)}}),Object.defineProperty(e,n,{enumerable:t.enumerable}),{getValue:function(){return r},setValue:function(o){r=""+o},stopTracking:function(){e._valueTracker=null,delete e[n]}}}}function Pr(e){e._valueTracker||(e._valueTracker=Gd(e))}function lu(e){if(!e)return!1;var n=e._valueTracker;if(!n)return!0;var t=n.getValue(),r="";return e&&(r=iu(e)?e.checked?"true":"false":e.value),e=r,e!==t?(n.setValue(e),!0):!1}function oi(e){if(e=e||(typeof document<"u"?document:void 0),typeof e>"u")return null;try{return e.activeElement||e.body}catch{return e.body}}function Ll(e,n){var t=n.checked;return J({},n,{defaultChecked:void 0,defaultValue:void 0,value:void 0,checked:t??e._wrapperState.initialChecked})}function Na(e,n){var t=n.defaultValue==null?"":n.defaultValue,r=n.checked!=null?n.checked:n.defaultChecked;t=Mn(n.value!=null?n.value:t),e._wrapperState={initialChecked:r,initialValue:t,controlled:n.type==="checkbox"||n.type==="radio"?n.checked!=null:n.value!=null}}function ou(e,n){n=n.checked,n!=null&&No(e,"checked",n,!1)}function Ml(e,n){ou(e,n);var t=Mn(n.value),r=n.type;if(t!=null)r==="number"?(t===0&&e.value===""||e.value!=t)&&(e.value=""+t):e.value!==""+t&&(e.value=""+t);else if(r==="submit"||r==="reset"){e.removeAttribute("value");return}n.hasOwnProperty("value")?Dl(e,n.type,t):n.hasOwnProperty("defaultValue")&&Dl(e,n.type,Mn(n.defaultValue)),n.checked==null&&n.defaultChecked!=null&&(e.defaultChecked=!!n.defaultChecked)}function Pa(e,n,t){if(n.hasOwnProperty("value")||n.hasOwnProperty("defaultValue")){var r=n.type;if(!(r!=="submit"&&r!=="reset"||n.value!==void 0&&n.value!==null))return;n=""+e._wrapperState.initialValue,t||n===e.value||(e.value=n),e.defaultValue=n}t=e.name,t!==""&&(e.name=""),e.defaultChecked=!!e._wrapperState.initialChecked,t!==""&&(e.name=t)}function Dl(e,n,t){(n!=="number"||oi(e.ownerDocument)!==e)&&(t==null?e.defaultValue=""+e._wrapperState.initialValue:e.defaultValue!==""+t&&(e.defaultValue=""+t))}var It=Array.isArray;function mt(e,n,t,r){if(e=e.options,n){n={};for(var i=0;i<t.length;i++)n["$"+t[i]]=!0;for(t=0;t<e.length;t++)i=n.hasOwnProperty("$"+e[t].value),e[t].selected!==i&&(e[t].selected=i),i&&r&&(e[t].defaultSelected=!0)}else{for(t=""+Mn(t),n=null,i=0;i<e.length;i++){if(e[i].value===t){e[i].selected=!0,r&&(e[i].defaultSelected=!0);return}n!==null||e[i].disabled||(n=e[i])}n!==null&&(n.selected=!0)}}function jl(e,n){if(n.dangerouslySetInnerHTML!=null)throw Error(k(91));return J({},n,{value:void 0,defaultValue:void 0,children:""+e._wrapperState.initialValue})}function $a(e,n){var t=n.value;if(t==null){if(t=n.children,n=n.defaultValue,t!=null){if(n!=null)throw Error(k(92));if(It(t)){if(1<t.length)throw Error(k(93));t=t[0]}n=t}n==null&&(n=""),t=n}e._wrapperState={initialValue:Mn(t)}}function au(e,n){var t=Mn(n.value),r=Mn(n.defaultValue);t!=null&&(t=""+t,t!==e.value&&(e.value=t),n.defaultValue==null&&e.defaultValue!==t&&(e.defaultValue=t)),r!=null&&(e.defaultValue=""+r)}function Ta(e){var n=e.textContent;n===e._wrapperState.initialValue&&n!==""&&n!==null&&(e.value=n)}function su(e){switch(e){case"svg":return"http://www.w3.org/2000/svg";case"math":return"http://www.w3.org/1998/Math/MathML";default:return"http://www.w3.org/1999/xhtml"}}function Al(e,n){return e==null||e==="http://www.w3.org/1999/xhtml"?su(n):e==="http://www.w3.org/2000/svg"&&n==="foreignObject"?"http://www.w3.org/1999/xhtml":e}var $r,uu=function(e){return typeof MSApp<"u"&&MSApp.execUnsafeLocalFunction?function(n,t,r,i){MSApp.execUnsafeLocalFunction(function(){return e(n,t,r,i)})}:e}(function(e,n){if(e.namespaceURI!=="http://www.w3.org/2000/svg"||"innerHTML"in e)e.innerHTML=n;else{for($r=$r||document.createElement("div"),$r.innerHTML="<svg>"+n.valueOf().toString()+"</svg>",n=$r.firstChild;e.firstChild;)e.removeChild(e.firstChild);for(;n.firstChild;)e.appendChild(n.firstChild)}});function nr(e,n){if(n){var t=e.firstChild;if(t&&t===e.lastChild&&t.nodeType===3){t.nodeValue=n;return}}e.textContent=n}var Ht={animationIterationCount:!0,aspectRatio:!0,borderImageOutset:!0,borderImageSlice:!0,borderImageWidth:!0,boxFlex:!0,boxFlexGroup:!0,boxOrdinalGroup:!0,columnCount:!0,columns:!0,flex:!0,flexGrow:!0,flexPositive:!0,flexShrink:!0,flexNegative:!0,flexOrder:!0,gridArea:!0,gridRow:!0,gridRowEnd:!0,gridRowSpan:!0,gridRowStart:!0,gridColumn:!0,gridColumnEnd:!0,gridColumnSpan:!0,gridColumnStart:!0,fontWeight:!0,lineClamp:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,tabSize:!0,widows:!0,zIndex:!0,zoom:!0,fillOpacity:!0,floodOpacity:!0,stopOpacity:!0,strokeDasharray:!0,strokeDashoffset:!0,strokeMiterlimit:!0,strokeOpacity:!0,strokeWidth:!0},Qd=["Webkit","ms","Moz","O"];Object.keys(Ht).forEach(function(e){Qd.forEach(function(n){n=n+e.charAt(0).toUpperCase()+e.substring(1),Ht[n]=Ht[e]})});function cu(e,n,t){return n==null||typeof n=="boolean"||n===""?"":t||typeof n!="number"||n===0||Ht.hasOwnProperty(e)&&Ht[e]?(""+n).trim():n+"px"}function du(e,n){e=e.style;for(var t in n)if(n.hasOwnProperty(t)){var r=t.indexOf("--")===0,i=cu(t,n[t],r);t==="float"&&(t="cssFloat"),r?e.setProperty(t,i):e[t]=i}}var Xd=J({menuitem:!0},{area:!0,base:!0,br:!0,col:!0,embed:!0,hr:!0,img:!0,input:!0,keygen:!0,link:!0,meta:!0,param:!0,source:!0,track:!0,wbr:!0});function Ol(e,n){if(n){if(Xd[e]&&(n.children!=null||n.dangerouslySetInnerHTML!=null))throw Error(k(137,e));if(n.dangerouslySetInnerHTML!=null){if(n.children!=null)throw Error(k(60));if(typeof n.dangerouslySetInnerHTML!="object"||!("__html"in n.dangerouslySetInnerHTML))throw Error(k(61))}if(n.style!=null&&typeof n.style!="object")throw Error(k(62))}}function Il(e,n){if(e.indexOf("-")===-1)return typeof n.is=="string";switch(e){case"annotation-xml":case"color-profile":case"font-face":case"font-face-src":case"font-face-uri":case"font-face-format":case"font-face-name":case"missing-glyph":return!1;default:return!0}}var Bl=null;function Ro(e){return e=e.target||e.srcElement||window,e.correspondingUseElement&&(e=e.correspondingUseElement),e.nodeType===3?e.parentNode:e}var Wl=null,ht=null,gt=null;function Ra(e){if(e=Sr(e)){if(typeof Wl!="function")throw Error(k(280));var n=e.stateNode;n&&(n=Di(n),Wl(e.stateNode,e.type,n))}}function fu(e){ht?gt?gt.push(e):gt=[e]:ht=e}function pu(){if(ht){var e=ht,n=gt;if(gt=ht=null,Ra(e),n)for(e=0;e<n.length;e++)Ra(n[e])}}function mu(e,n){return e(n)}function hu(){}var nl=!1;function gu(e,n,t){if(nl)return e(n,t);nl=!0;try{return mu(e,n,t)}finally{nl=!1,(ht!==null||gt!==null)&&(hu(),pu())}}function tr(e,n){var t=e.stateNode;if(t===null)return null;var r=Di(t);if(r===null)return null;t=r[n];e:switch(n){case"onClick":case"onClickCapture":case"onDoubleClick":case"onDoubleClickCapture":case"onMouseDown":case"onMouseDownCapture":case"onMouseMove":case"onMouseMoveCapture":case"onMouseUp":case"onMouseUpCapture":case"onMouseEnter":(r=!r.disabled)||(e=e.type,r=!(e==="button"||e==="input"||e==="select"||e==="textarea")),e=!r;break e;default:e=!1}if(e)return null;if(t&&typeof t!="function")throw Error(k(231,n,typeof t));return t}var Ul=!1;if(pn)try{var Rt={};Object.defineProperty(Rt,"passive",{get:function(){Ul=!0}}),window.addEventListener("test",Rt,Rt),window.removeEventListener("test",Rt,Rt)}catch{Ul=!1}function Kd(e,n,t,r,i,l,o,a,u){var d=Array.prototype.slice.call(arguments,3);try{n.apply(t,d)}catch(g){this.onError(g)}}var Vt=!1,ai=null,si=!1,Hl=null,Yd={onError:function(e){Vt=!0,ai=e}};function Zd(e,n,t,r,i,l,o,a,u){Vt=!1,ai=null,Kd.apply(Yd,arguments)}function qd(e,n,t,r,i,l,o,a,u){if(Zd.apply(this,arguments),Vt){if(Vt){var d=ai;Vt=!1,ai=null}else throw Error(k(198));si||(si=!0,Hl=d)}}function Jn(e){var n=e,t=e;if(e.alternate)for(;n.return;)n=n.return;else{e=n;do n=e,n.flags&4098&&(t=n.return),e=n.return;while(e)}return n.tag===3?t:null}function vu(e){if(e.tag===13){var n=e.memoizedState;if(n===null&&(e=e.alternate,e!==null&&(n=e.memoizedState)),n!==null)return n.dehydrated}return null}function za(e){if(Jn(e)!==e)throw Error(k(188))}function Jd(e){var n=e.alternate;if(!n){if(n=Jn(e),n===null)throw Error(k(188));return n!==e?null:e}for(var t=e,r=n;;){var i=t.return;if(i===null)break;var l=i.alternate;if(l===null){if(r=i.return,r!==null){t=r;continue}break}if(i.child===l.child){for(l=i.child;l;){if(l===t)return za(i),e;if(l===r)return za(i),n;l=l.sibling}throw Error(k(188))}if(t.return!==r.return)t=i,r=l;else{for(var o=!1,a=i.child;a;){if(a===t){o=!0,t=i,r=l;break}if(a===r){o=!0,r=i,t=l;break}a=a.sibling}if(!o){for(a=l.child;a;){if(a===t){o=!0,t=l,r=i;break}if(a===r){o=!0,r=l,t=i;break}a=a.sibling}if(!o)throw Error(k(189))}}if(t.alternate!==r)throw Error(k(190))}if(t.tag!==3)throw Error(k(188));return t.stateNode.current===t?e:n}function yu(e){return e=Jd(e),e!==null?xu(e):null}function xu(e){if(e.tag===5||e.tag===6)return e;for(e=e.child;e!==null;){var n=xu(e);if(n!==null)return n;e=e.sibling}return null}var wu=je.unstable_scheduleCallback,La=je.unstable_cancelCallback,ef=je.unstable_shouldYield,nf=je.unstable_requestPaint,ne=je.unstable_now,tf=je.unstable_getCurrentPriorityLevel,zo=je.unstable_ImmediatePriority,Su=je.unstable_UserBlockingPriority,ui=je.unstable_NormalPriority,rf=je.unstable_LowPriority,_u=je.unstable_IdlePriority,Ri=null,ln=null;function lf(e){if(ln&&typeof ln.onCommitFiberRoot=="function")try{ln.onCommitFiberRoot(Ri,e,void 0,(e.current.flags&128)===128)}catch{}}var qe=Math.clz32?Math.clz32:sf,of=Math.log,af=Math.LN2;function sf(e){return e>>>=0,e===0?32:31-(of(e)/af|0)|0}var Tr=64,Rr=4194304;function Bt(e){switch(e&-e){case 1:return 1;case 2:return 2;case 4:return 4;case 8:return 8;case 16:return 16;case 32:return 32;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return e&4194240;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return e&130023424;case 134217728:return 134217728;case 268435456:return 268435456;case 536870912:return 536870912;case 1073741824:return 1073741824;default:return e}}function ci(e,n){var t=e.pendingLanes;if(t===0)return 0;var r=0,i=e.suspendedLanes,l=e.pingedLanes,o=t&268435455;if(o!==0){var a=o&~i;a!==0?r=Bt(a):(l&=o,l!==0&&(r=Bt(l)))}else o=t&~i,o!==0?r=Bt(o):l!==0&&(r=Bt(l));if(r===0)return 0;if(n!==0&&n!==r&&!(n&i)&&(i=r&-r,l=n&-n,i>=l||i===16&&(l&4194240)!==0))return n;if(r&4&&(r|=t&16),n=e.entangledLanes,n!==0)for(e=e.entanglements,n&=r;0<n;)t=31-qe(n),i=1<<t,r|=e[t],n&=~i;return r}function uf(e,n){switch(e){case 1:case 2:case 4:return n+250;case 8:case 16:case 32:case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:return n+5e3;case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:return-1;case 134217728:case 268435456:case 536870912:case 1073741824:return-1;default:return-1}}function cf(e,n){for(var t=e.suspendedLanes,r=e.pingedLanes,i=e.expirationTimes,l=e.pendingLanes;0<l;){var o=31-qe(l),a=1<<o,u=i[o];u===-1?(!(a&t)||a&r)&&(i[o]=uf(a,n)):u<=n&&(e.expiredLanes|=a),l&=~a}}function Vl(e){return e=e.pendingLanes&-1073741825,e!==0?e:e&1073741824?1073741824:0}function ku(){var e=Tr;return Tr<<=1,!(Tr&4194240)&&(Tr=64),e}function tl(e){for(var n=[],t=0;31>t;t++)n.push(e);return n}function xr(e,n,t){e.pendingLanes|=n,n!==536870912&&(e.suspendedLanes=0,e.pingedLanes=0),e=e.eventTimes,n=31-qe(n),e[n]=t}function df(e,n){var t=e.pendingLanes&~n;e.pendingLanes=n,e.suspendedLanes=0,e.pingedLanes=0,e.expiredLanes&=n,e.mutableReadLanes&=n,e.entangledLanes&=n,n=e.entanglements;var r=e.eventTimes;for(e=e.expirationTimes;0<t;){var i=31-qe(t),l=1<<i;n[i]=0,r[i]=-1,e[i]=-1,t&=~l}}function Lo(e,n){var t=e.entangledLanes|=n;for(e=e.entanglements;t;){var r=31-qe(t),i=1<<r;i&n|e[r]&n&&(e[r]|=n),t&=~i}}var U=0;function bu(e){return e&=-e,1<e?4<e?e&268435455?16:536870912:4:1}var Eu,Mo,Cu,Fu,Nu,Gl=!1,zr=[],Cn=null,Fn=null,Nn=null,rr=new Map,ir=new Map,_n=[],ff="mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(" ");function Ma(e,n){switch(e){case"focusin":case"focusout":Cn=null;break;case"dragenter":case"dragleave":Fn=null;break;case"mouseover":case"mouseout":Nn=null;break;case"pointerover":case"pointerout":rr.delete(n.pointerId);break;case"gotpointercapture":case"lostpointercapture":ir.delete(n.pointerId)}}function zt(e,n,t,r,i,l){return e===null||e.nativeEvent!==l?(e={blockedOn:n,domEventName:t,eventSystemFlags:r,nativeEvent:l,targetContainers:[i]},n!==null&&(n=Sr(n),n!==null&&Mo(n)),e):(e.eventSystemFlags|=r,n=e.targetContainers,i!==null&&n.indexOf(i)===-1&&n.push(i),e)}function pf(e,n,t,r,i){switch(n){case"focusin":return Cn=zt(Cn,e,n,t,r,i),!0;case"dragenter":return Fn=zt(Fn,e,n,t,r,i),!0;case"mouseover":return Nn=zt(Nn,e,n,t,r,i),!0;case"pointerover":var l=i.pointerId;return rr.set(l,zt(rr.get(l)||null,e,n,t,r,i)),!0;case"gotpointercapture":return l=i.pointerId,ir.set(l,zt(ir.get(l)||null,e,n,t,r,i)),!0}return!1}function Pu(e){var n=Wn(e.target);if(n!==null){var t=Jn(n);if(t!==null){if(n=t.tag,n===13){if(n=vu(t),n!==null){e.blockedOn=n,Nu(e.priority,function(){Cu(t)});return}}else if(n===3&&t.stateNode.current.memoizedState.isDehydrated){e.blockedOn=t.tag===3?t.stateNode.containerInfo:null;return}}}e.blockedOn=null}function Xr(e){if(e.blockedOn!==null)return!1;for(var n=e.targetContainers;0<n.length;){var t=Ql(e.domEventName,e.eventSystemFlags,n[0],e.nativeEvent);if(t===null){t=e.nativeEvent;var r=new t.constructor(t.type,t);Bl=r,t.target.dispatchEvent(r),Bl=null}else return n=Sr(t),n!==null&&Mo(n),e.blockedOn=t,!1;n.shift()}return!0}function Da(e,n,t){Xr(e)&&t.delete(n)}function mf(){Gl=!1,Cn!==null&&Xr(Cn)&&(Cn=null),Fn!==null&&Xr(Fn)&&(Fn=null),Nn!==null&&Xr(Nn)&&(Nn=null),rr.forEach(Da),ir.forEach(Da)}function Lt(e,n){e.blockedOn===n&&(e.blockedOn=null,Gl||(Gl=!0,je.unstable_scheduleCallback(je.unstable_NormalPriority,mf)))}function lr(e){function n(i){return Lt(i,e)}if(0<zr.length){Lt(zr[0],e);for(var t=1;t<zr.length;t++){var r=zr[t];r.blockedOn===e&&(r.blockedOn=null)}}for(Cn!==null&&Lt(Cn,e),Fn!==null&&Lt(Fn,e),Nn!==null&&Lt(Nn,e),rr.forEach(n),ir.forEach(n),t=0;t<_n.length;t++)r=_n[t],r.blockedOn===e&&(r.blockedOn=null);for(;0<_n.length&&(t=_n[0],t.blockedOn===null);)Pu(t),t.blockedOn===null&&_n.shift()}var vt=vn.ReactCurrentBatchConfig,di=!0;function hf(e,n,t,r){var i=U,l=vt.transition;vt.transition=null;try{U=1,Do(e,n,t,r)}finally{U=i,vt.transition=l}}function gf(e,n,t,r){var i=U,l=vt.transition;vt.transition=null;try{U=4,Do(e,n,t,r)}finally{U=i,vt.transition=l}}function Do(e,n,t,r){if(di){var i=Ql(e,n,t,r);if(i===null)fl(e,n,r,fi,t),Ma(e,r);else if(pf(i,e,n,t,r))r.stopPropagation();else if(Ma(e,r),n&4&&-1<ff.indexOf(e)){for(;i!==null;){var l=Sr(i);if(l!==null&&Eu(l),l=Ql(e,n,t,r),l===null&&fl(e,n,r,fi,t),l===i)break;i=l}i!==null&&r.stopPropagation()}else fl(e,n,r,null,t)}}var fi=null;function Ql(e,n,t,r){if(fi=null,e=Ro(r),e=Wn(e),e!==null)if(n=Jn(e),n===null)e=null;else if(t=n.tag,t===13){if(e=vu(n),e!==null)return e;e=null}else if(t===3){if(n.stateNode.current.memoizedState.isDehydrated)return n.tag===3?n.stateNode.containerInfo:null;e=null}else n!==e&&(e=null);return fi=e,null}function $u(e){switch(e){case"cancel":case"click":case"close":case"contextmenu":case"copy":case"cut":case"auxclick":case"dblclick":case"dragend":case"dragstart":case"drop":case"focusin":case"focusout":case"input":case"invalid":case"keydown":case"keypress":case"keyup":case"mousedown":case"mouseup":case"paste":case"pause":case"play":case"pointercancel":case"pointerdown":case"pointerup":case"ratechange":case"reset":case"resize":case"seeked":case"submit":case"touchcancel":case"touchend":case"touchstart":case"volumechange":case"change":case"selectionchange":case"textInput":case"compositionstart":case"compositionend":case"compositionupdate":case"beforeblur":case"afterblur":case"beforeinput":case"blur":case"fullscreenchange":case"focus":case"hashchange":case"popstate":case"select":case"selectstart":return 1;case"drag":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"mousemove":case"mouseout":case"mouseover":case"pointermove":case"pointerout":case"pointerover":case"scroll":case"toggle":case"touchmove":case"wheel":case"mouseenter":case"mouseleave":case"pointerenter":case"pointerleave":return 4;case"message":switch(tf()){case zo:return 1;case Su:return 4;case ui:case rf:return 16;case _u:return 536870912;default:return 16}default:return 16}}var bn=null,jo=null,Kr=null;function Tu(){if(Kr)return Kr;var e,n=jo,t=n.length,r,i="value"in bn?bn.value:bn.textContent,l=i.length;for(e=0;e<t&&n[e]===i[e];e++);var o=t-e;for(r=1;r<=o&&n[t-r]===i[l-r];r++);return Kr=i.slice(e,1<r?1-r:void 0)}function Yr(e){var n=e.keyCode;return"charCode"in e?(e=e.charCode,e===0&&n===13&&(e=13)):e=n,e===10&&(e=13),32<=e||e===13?e:0}function Lr(){return!0}function ja(){return!1}function Oe(e){function n(t,r,i,l,o){this._reactName=t,this._targetInst=i,this.type=r,this.nativeEvent=l,this.target=o,this.currentTarget=null;for(var a in e)e.hasOwnProperty(a)&&(t=e[a],this[a]=t?t(l):l[a]);return this.isDefaultPrevented=(l.defaultPrevented!=null?l.defaultPrevented:l.returnValue===!1)?Lr:ja,this.isPropagationStopped=ja,this}return J(n.prototype,{preventDefault:function(){this.defaultPrevented=!0;var t=this.nativeEvent;t&&(t.preventDefault?t.preventDefault():typeof t.returnValue!="unknown"&&(t.returnValue=!1),this.isDefaultPrevented=Lr)},stopPropagation:function(){var t=this.nativeEvent;t&&(t.stopPropagation?t.stopPropagation():typeof t.cancelBubble!="unknown"&&(t.cancelBubble=!0),this.isPropagationStopped=Lr)},persist:function(){},isPersistent:Lr}),n}var Nt={eventPhase:0,bubbles:0,cancelable:0,timeStamp:function(e){return e.timeStamp||Date.now()},defaultPrevented:0,isTrusted:0},Ao=Oe(Nt),wr=J({},Nt,{view:0,detail:0}),vf=Oe(wr),rl,il,Mt,zi=J({},wr,{screenX:0,screenY:0,clientX:0,clientY:0,pageX:0,pageY:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,getModifierState:Oo,button:0,buttons:0,relatedTarget:function(e){return e.relatedTarget===void 0?e.fromElement===e.srcElement?e.toElement:e.fromElement:e.relatedTarget},movementX:function(e){return"movementX"in e?e.movementX:(e!==Mt&&(Mt&&e.type==="mousemove"?(rl=e.screenX-Mt.screenX,il=e.screenY-Mt.screenY):il=rl=0,Mt=e),rl)},movementY:function(e){return"movementY"in e?e.movementY:il}}),Aa=Oe(zi),yf=J({},zi,{dataTransfer:0}),xf=Oe(yf),wf=J({},wr,{relatedTarget:0}),ll=Oe(wf),Sf=J({},Nt,{animationName:0,elapsedTime:0,pseudoElement:0}),_f=Oe(Sf),kf=J({},Nt,{clipboardData:function(e){return"clipboardData"in e?e.clipboardData:window.clipboardData}}),bf=Oe(kf),Ef=J({},Nt,{data:0}),Oa=Oe(Ef),Cf={Esc:"Escape",Spacebar:" ",Left:"ArrowLeft",Up:"ArrowUp",Right:"ArrowRight",Down:"ArrowDown",Del:"Delete",Win:"OS",Menu:"ContextMenu",Apps:"ContextMenu",Scroll:"ScrollLock",MozPrintableKey:"Unidentified"},Ff={8:"Backspace",9:"Tab",12:"Clear",13:"Enter",16:"Shift",17:"Control",18:"Alt",19:"Pause",20:"CapsLock",27:"Escape",32:" ",33:"PageUp",34:"PageDown",35:"End",36:"Home",37:"ArrowLeft",38:"ArrowUp",39:"ArrowRight",40:"ArrowDown",45:"Insert",46:"Delete",112:"F1",113:"F2",114:"F3",115:"F4",116:"F5",117:"F6",118:"F7",119:"F8",120:"F9",121:"F10",122:"F11",123:"F12",144:"NumLock",145:"ScrollLock",224:"Meta"},Nf={Alt:"altKey",Control:"ctrlKey",Meta:"metaKey",Shift:"shiftKey"};function Pf(e){var n=this.nativeEvent;return n.getModifierState?n.getModifierState(e):(e=Nf[e])?!!n[e]:!1}function Oo(){return Pf}var $f=J({},wr,{key:function(e){if(e.key){var n=Cf[e.key]||e.key;if(n!=="Unidentified")return n}return e.type==="keypress"?(e=Yr(e),e===13?"Enter":String.fromCharCode(e)):e.type==="keydown"||e.type==="keyup"?Ff[e.keyCode]||"Unidentified":""},code:0,location:0,ctrlKey:0,shiftKey:0,altKey:0,metaKey:0,repeat:0,locale:0,getModifierState:Oo,charCode:function(e){return e.type==="keypress"?Yr(e):0},keyCode:function(e){return e.type==="keydown"||e.type==="keyup"?e.keyCode:0},which:function(e){return e.type==="keypress"?Yr(e):e.type==="keydown"||e.type==="keyup"?e.keyCode:0}}),Tf=Oe($f),Rf=J({},zi,{pointerId:0,width:0,height:0,pressure:0,tangentialPressure:0,tiltX:0,tiltY:0,twist:0,pointerType:0,isPrimary:0}),Ia=Oe(Rf),zf=J({},wr,{touches:0,targetTouches:0,changedTouches:0,altKey:0,metaKey:0,ctrlKey:0,shiftKey:0,getModifierState:Oo}),Lf=Oe(zf),Mf=J({},Nt,{propertyName:0,elapsedTime:0,pseudoElement:0}),Df=Oe(Mf),jf=J({},zi,{deltaX:function(e){return"deltaX"in e?e.deltaX:"wheelDeltaX"in e?-e.wheelDeltaX:0},deltaY:function(e){return"deltaY"in e?e.deltaY:"wheelDeltaY"in e?-e.wheelDeltaY:"wheelDelta"in e?-e.wheelDelta:0},deltaZ:0,deltaMode:0}),Af=Oe(jf),Of=[9,13,27,32],Io=pn&&"CompositionEvent"in window,Gt=null;pn&&"documentMode"in document&&(Gt=document.documentMode);var If=pn&&"TextEvent"in window&&!Gt,Ru=pn&&(!Io||Gt&&8<Gt&&11>=Gt),Ba=" ",Wa=!1;function zu(e,n){switch(e){case"keyup":return Of.indexOf(n.keyCode)!==-1;case"keydown":return n.keyCode!==229;case"keypress":case"mousedown":case"focusout":return!0;default:return!1}}function Lu(e){return e=e.detail,typeof e=="object"&&"data"in e?e.data:null}var rt=!1;function Bf(e,n){switch(e){case"compositionend":return Lu(n);case"keypress":return n.which!==32?null:(Wa=!0,Ba);case"textInput":return e=n.data,e===Ba&&Wa?null:e;default:return null}}function Wf(e,n){if(rt)return e==="compositionend"||!Io&&zu(e,n)?(e=Tu(),Kr=jo=bn=null,rt=!1,e):null;switch(e){case"paste":return null;case"keypress":if(!(n.ctrlKey||n.altKey||n.metaKey)||n.ctrlKey&&n.altKey){if(n.char&&1<n.char.length)return n.char;if(n.which)return String.fromCharCode(n.which)}return null;case"compositionend":return Ru&&n.locale!=="ko"?null:n.data;default:return null}}var Uf={color:!0,date:!0,datetime:!0,"datetime-local":!0,email:!0,month:!0,number:!0,password:!0,range:!0,search:!0,tel:!0,text:!0,time:!0,url:!0,week:!0};function Ua(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n==="input"?!!Uf[e.type]:n==="textarea"}function Mu(e,n,t,r){fu(r),n=pi(n,"onChange"),0<n.length&&(t=new Ao("onChange","change",null,t,r),e.push({event:t,listeners:n}))}var Qt=null,or=null;function Hf(e){Gu(e,0)}function Li(e){var n=ot(e);if(lu(n))return e}function Vf(e,n){if(e==="change")return n}var Du=!1;if(pn){var ol;if(pn){var al="oninput"in document;if(!al){var Ha=document.createElement("div");Ha.setAttribute("oninput","return;"),al=typeof Ha.oninput=="function"}ol=al}else ol=!1;Du=ol&&(!document.documentMode||9<document.documentMode)}function Va(){Qt&&(Qt.detachEvent("onpropertychange",ju),or=Qt=null)}function ju(e){if(e.propertyName==="value"&&Li(or)){var n=[];Mu(n,or,e,Ro(e)),gu(Hf,n)}}function Gf(e,n,t){e==="focusin"?(Va(),Qt=n,or=t,Qt.attachEvent("onpropertychange",ju)):e==="focusout"&&Va()}function Qf(e){if(e==="selectionchange"||e==="keyup"||e==="keydown")return Li(or)}function Xf(e,n){if(e==="click")return Li(n)}function Kf(e,n){if(e==="input"||e==="change")return Li(n)}function Yf(e,n){return e===n&&(e!==0||1/e===1/n)||e!==e&&n!==n}var en=typeof Object.is=="function"?Object.is:Yf;function ar(e,n){if(en(e,n))return!0;if(typeof e!="object"||e===null||typeof n!="object"||n===null)return!1;var t=Object.keys(e),r=Object.keys(n);if(t.length!==r.length)return!1;for(r=0;r<t.length;r++){var i=t[r];if(!Pl.call(n,i)||!en(e[i],n[i]))return!1}return!0}function Ga(e){for(;e&&e.firstChild;)e=e.firstChild;return e}function Qa(e,n){var t=Ga(e);e=0;for(var r;t;){if(t.nodeType===3){if(r=e+t.textContent.length,e<=n&&r>=n)return{node:t,offset:n-e};e=r}e:{for(;t;){if(t.nextSibling){t=t.nextSibling;break e}t=t.parentNode}t=void 0}t=Ga(t)}}function Au(e,n){return e&&n?e===n?!0:e&&e.nodeType===3?!1:n&&n.nodeType===3?Au(e,n.parentNode):"contains"in e?e.contains(n):e.compareDocumentPosition?!!(e.compareDocumentPosition(n)&16):!1:!1}function Ou(){for(var e=window,n=oi();n instanceof e.HTMLIFrameElement;){try{var t=typeof n.contentWindow.location.href=="string"}catch{t=!1}if(t)e=n.contentWindow;else break;n=oi(e.document)}return n}function Bo(e){var n=e&&e.nodeName&&e.nodeName.toLowerCase();return n&&(n==="input"&&(e.type==="text"||e.type==="search"||e.type==="tel"||e.type==="url"||e.type==="password")||n==="textarea"||e.contentEditable==="true")}function Zf(e){var n=Ou(),t=e.focusedElem,r=e.selectionRange;if(n!==t&&t&&t.ownerDocument&&Au(t.ownerDocument.documentElement,t)){if(r!==null&&Bo(t)){if(n=r.start,e=r.end,e===void 0&&(e=n),"selectionStart"in t)t.selectionStart=n,t.selectionEnd=Math.min(e,t.value.length);else if(e=(n=t.ownerDocument||document)&&n.defaultView||window,e.getSelection){e=e.getSelection();var i=t.textContent.length,l=Math.min(r.start,i);r=r.end===void 0?l:Math.min(r.end,i),!e.extend&&l>r&&(i=r,r=l,l=i),i=Qa(t,l);var o=Qa(t,r);i&&o&&(e.rangeCount!==1||e.anchorNode!==i.node||e.anchorOffset!==i.offset||e.focusNode!==o.node||e.focusOffset!==o.offset)&&(n=n.createRange(),n.setStart(i.node,i.offset),e.removeAllRanges(),l>r?(e.addRange(n),e.extend(o.node,o.offset)):(n.setEnd(o.node,o.offset),e.addRange(n)))}}for(n=[],e=t;e=e.parentNode;)e.nodeType===1&&n.push({element:e,left:e.scrollLeft,top:e.scrollTop});for(typeof t.focus=="function"&&t.focus(),t=0;t<n.length;t++)e=n[t],e.element.scrollLeft=e.left,e.element.scrollTop=e.top}}var qf=pn&&"documentMode"in document&&11>=document.documentMode,it=null,Xl=null,Xt=null,Kl=!1;function Xa(e,n,t){var r=t.window===t?t.document:t.nodeType===9?t:t.ownerDocument;Kl||it==null||it!==oi(r)||(r=it,"selectionStart"in r&&Bo(r)?r={start:r.selectionStart,end:r.selectionEnd}:(r=(r.ownerDocument&&r.ownerDocument.defaultView||window).getSelection(),r={anchorNode:r.anchorNode,anchorOffset:r.anchorOffset,focusNode:r.focusNode,focusOffset:r.focusOffset}),Xt&&ar(Xt,r)||(Xt=r,r=pi(Xl,"onSelect"),0<r.length&&(n=new Ao("onSelect","select",null,n,t),e.push({event:n,listeners:r}),n.target=it)))}function Mr(e,n){var t={};return t[e.toLowerCase()]=n.toLowerCase(),t["Webkit"+e]="webkit"+n,t["Moz"+e]="moz"+n,t}var lt={animationend:Mr("Animation","AnimationEnd"),animationiteration:Mr("Animation","AnimationIteration"),animationstart:Mr("Animation","AnimationStart"),transitionend:Mr("Transition","TransitionEnd")},sl={},Iu={};pn&&(Iu=document.createElement("div").style,"AnimationEvent"in window||(delete lt.animationend.animation,delete lt.animationiteration.animation,delete lt.animationstart.animation),"TransitionEvent"in window||delete lt.transitionend.transition);function Mi(e){if(sl[e])return sl[e];if(!lt[e])return e;var n=lt[e],t;for(t in n)if(n.hasOwnProperty(t)&&t in Iu)return sl[e]=n[t];return e}var Bu=Mi("animationend"),Wu=Mi("animationiteration"),Uu=Mi("animationstart"),Hu=Mi("transitionend"),Vu=new Map,Ka="abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(" ");function jn(e,n){Vu.set(e,n),qn(n,[e])}for(var ul=0;ul<Ka.length;ul++){var cl=Ka[ul],Jf=cl.toLowerCase(),ep=cl[0].toUpperCase()+cl.slice(1);jn(Jf,"on"+ep)}jn(Bu,"onAnimationEnd");jn(Wu,"onAnimationIteration");jn(Uu,"onAnimationStart");jn("dblclick","onDoubleClick");jn("focusin","onFocus");jn("focusout","onBlur");jn(Hu,"onTransitionEnd");wt("onMouseEnter",["mouseout","mouseover"]);wt("onMouseLeave",["mouseout","mouseover"]);wt("onPointerEnter",["pointerout","pointerover"]);wt("onPointerLeave",["pointerout","pointerover"]);qn("onChange","change click focusin focusout input keydown keyup selectionchange".split(" "));qn("onSelect","focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(" "));qn("onBeforeInput",["compositionend","keypress","textInput","paste"]);qn("onCompositionEnd","compositionend focusout keydown keypress keyup mousedown".split(" "));qn("onCompositionStart","compositionstart focusout keydown keypress keyup mousedown".split(" "));qn("onCompositionUpdate","compositionupdate focusout keydown keypress keyup mousedown".split(" "));var Wt="abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(" "),np=new Set("cancel close invalid load scroll toggle".split(" ").concat(Wt));function Ya(e,n,t){var r=e.type||"unknown-event";e.currentTarget=t,qd(r,n,void 0,e),e.currentTarget=null}function Gu(e,n){n=(n&4)!==0;for(var t=0;t<e.length;t++){var r=e[t],i=r.event;r=r.listeners;e:{var l=void 0;if(n)for(var o=r.length-1;0<=o;o--){var a=r[o],u=a.instance,d=a.currentTarget;if(a=a.listener,u!==l&&i.isPropagationStopped())break e;Ya(i,a,d),l=u}else for(o=0;o<r.length;o++){if(a=r[o],u=a.instance,d=a.currentTarget,a=a.listener,u!==l&&i.isPropagationStopped())break e;Ya(i,a,d),l=u}}}if(si)throw e=Hl,si=!1,Hl=null,e}function G(e,n){var t=n[eo];t===void 0&&(t=n[eo]=new Set);var r=e+"__bubble";t.has(r)||(Qu(n,e,2,!1),t.add(r))}function dl(e,n,t){var r=0;n&&(r|=4),Qu(t,e,r,n)}var Dr="_reactListening"+Math.random().toString(36).slice(2);function sr(e){if(!e[Dr]){e[Dr]=!0,eu.forEach(function(t){t!=="selectionchange"&&(np.has(t)||dl(t,!1,e),dl(t,!0,e))});var n=e.nodeType===9?e:e.ownerDocument;n===null||n[Dr]||(n[Dr]=!0,dl("selectionchange",!1,n))}}function Qu(e,n,t,r){switch($u(n)){case 1:var i=hf;break;case 4:i=gf;break;default:i=Do}t=i.bind(null,n,t,e),i=void 0,!Ul||n!=="touchstart"&&n!=="touchmove"&&n!=="wheel"||(i=!0),r?i!==void 0?e.addEventListener(n,t,{capture:!0,passive:i}):e.addEventListener(n,t,!0):i!==void 0?e.addEventListener(n,t,{passive:i}):e.addEventListener(n,t,!1)}function fl(e,n,t,r,i){var l=r;if(!(n&1)&&!(n&2)&&r!==null)e:for(;;){if(r===null)return;var o=r.tag;if(o===3||o===4){var a=r.stateNode.containerInfo;if(a===i||a.nodeType===8&&a.parentNode===i)break;if(o===4)for(o=r.return;o!==null;){var u=o.tag;if((u===3||u===4)&&(u=o.stateNode.containerInfo,u===i||u.nodeType===8&&u.parentNode===i))return;o=o.return}for(;a!==null;){if(o=Wn(a),o===null)return;if(u=o.tag,u===5||u===6){r=l=o;continue e}a=a.parentNode}}r=r.return}gu(function(){var d=l,g=Ro(t),m=[];e:{var p=Vu.get(e);if(p!==void 0){var v=Ao,w=e;switch(e){case"keypress":if(Yr(t)===0)break e;case"keydown":case"keyup":v=Tf;break;case"focusin":w="focus",v=ll;break;case"focusout":w="blur",v=ll;break;case"beforeblur":case"afterblur":v=ll;break;case"click":if(t.button===2)break e;case"auxclick":case"dblclick":case"mousedown":case"mousemove":case"mouseup":case"mouseout":case"mouseover":case"contextmenu":v=Aa;break;case"drag":case"dragend":case"dragenter":case"dragexit":case"dragleave":case"dragover":case"dragstart":case"drop":v=xf;break;case"touchcancel":case"touchend":case"touchmove":case"touchstart":v=Lf;break;case Bu:case Wu:case Uu:v=_f;break;case Hu:v=Df;break;case"scroll":v=vf;break;case"wheel":v=Af;break;case"copy":case"cut":case"paste":v=bf;break;case"gotpointercapture":case"lostpointercapture":case"pointercancel":case"pointerdown":case"pointermove":case"pointerout":case"pointerover":case"pointerup":v=Ia}var x=(n&4)!==0,L=!x&&e==="scroll",c=x?p!==null?p+"Capture":null:p;x=[];for(var s=d,f;s!==null;){f=s;var h=f.stateNode;if(f.tag===5&&h!==null&&(f=h,c!==null&&(h=tr(s,c),h!=null&&x.push(ur(s,h,f)))),L)break;s=s.return}0<x.length&&(p=new v(p,w,null,t,g),m.push({event:p,listeners:x}))}}if(!(n&7)){e:{if(p=e==="mouseover"||e==="pointerover",v=e==="mouseout"||e==="pointerout",p&&t!==Bl&&(w=t.relatedTarget||t.fromElement)&&(Wn(w)||w[mn]))break e;if((v||p)&&(p=g.window===g?g:(p=g.ownerDocument)?p.defaultView||p.parentWindow:window,v?(w=t.relatedTarget||t.toElement,v=d,w=w?Wn(w):null,w!==null&&(L=Jn(w),w!==L||w.tag!==5&&w.tag!==6)&&(w=null)):(v=null,w=d),v!==w)){if(x=Aa,h="onMouseLeave",c="onMouseEnter",s="mouse",(e==="pointerout"||e==="pointerover")&&(x=Ia,h="onPointerLeave",c="onPointerEnter",s="pointer"),L=v==null?p:ot(v),f=w==null?p:ot(w),p=new x(h,s+"leave",v,t,g),p.target=L,p.relatedTarget=f,h=null,Wn(g)===d&&(x=new x(c,s+"enter",w,t,g),x.target=f,x.relatedTarget=L,h=x),L=h,v&&w)n:{for(x=v,c=w,s=0,f=x;f;f=et(f))s++;for(f=0,h=c;h;h=et(h))f++;for(;0<s-f;)x=et(x),s--;for(;0<f-s;)c=et(c),f--;for(;s--;){if(x===c||c!==null&&x===c.alternate)break n;x=et(x),c=et(c)}x=null}else x=null;v!==null&&Za(m,p,v,x,!1),w!==null&&L!==null&&Za(m,L,w,x,!0)}}e:{if(p=d?ot(d):window,v=p.nodeName&&p.nodeName.toLowerCase(),v==="select"||v==="input"&&p.type==="file")var S=Vf;else if(Ua(p))if(Du)S=Kf;else{S=Qf;var b=Gf}else(v=p.nodeName)&&v.toLowerCase()==="input"&&(p.type==="checkbox"||p.type==="radio")&&(S=Xf);if(S&&(S=S(e,d))){Mu(m,S,t,g);break e}b&&b(e,p,d),e==="focusout"&&(b=p._wrapperState)&&b.controlled&&p.type==="number"&&Dl(p,"number",p.value)}switch(b=d?ot(d):window,e){case"focusin":(Ua(b)||b.contentEditable==="true")&&(it=b,Xl=d,Xt=null);break;case"focusout":Xt=Xl=it=null;break;case"mousedown":Kl=!0;break;case"contextmenu":case"mouseup":case"dragend":Kl=!1,Xa(m,t,g);break;case"selectionchange":if(qf)break;case"keydown":case"keyup":Xa(m,t,g)}var C;if(Io)e:{switch(e){case"compositionstart":var E="onCompositionStart";break e;case"compositionend":E="onCompositionEnd";break e;case"compositionupdate":E="onCompositionUpdate";break e}E=void 0}else rt?zu(e,t)&&(E="onCompositionEnd"):e==="keydown"&&t.keyCode===229&&(E="onCompositionStart");E&&(Ru&&t.locale!=="ko"&&(rt||E!=="onCompositionStart"?E==="onCompositionEnd"&&rt&&(C=Tu()):(bn=g,jo="value"in bn?bn.value:bn.textContent,rt=!0)),b=pi(d,E),0<b.length&&(E=new Oa(E,e,null,t,g),m.push({event:E,listeners:b}),C?E.data=C:(C=Lu(t),C!==null&&(E.data=C)))),(C=If?Bf(e,t):Wf(e,t))&&(d=pi(d,"onBeforeInput"),0<d.length&&(g=new Oa("onBeforeInput","beforeinput",null,t,g),m.push({event:g,listeners:d}),g.data=C))}Gu(m,n)})}function ur(e,n,t){return{instance:e,listener:n,currentTarget:t}}function pi(e,n){for(var t=n+"Capture",r=[];e!==null;){var i=e,l=i.stateNode;i.tag===5&&l!==null&&(i=l,l=tr(e,t),l!=null&&r.unshift(ur(e,l,i)),l=tr(e,n),l!=null&&r.push(ur(e,l,i))),e=e.return}return r}function et(e){if(e===null)return null;do e=e.return;while(e&&e.tag!==5);return e||null}function Za(e,n,t,r,i){for(var l=n._reactName,o=[];t!==null&&t!==r;){var a=t,u=a.alternate,d=a.stateNode;if(u!==null&&u===r)break;a.tag===5&&d!==null&&(a=d,i?(u=tr(t,l),u!=null&&o.unshift(ur(t,u,a))):i||(u=tr(t,l),u!=null&&o.push(ur(t,u,a)))),t=t.return}o.length!==0&&e.push({event:n,listeners:o})}var tp=/\r\n?/g,rp=/\u0000|\uFFFD/g;function qa(e){return(typeof e=="string"?e:""+e).replace(tp,`
`).replace(rp,"")}function jr(e,n,t){if(n=qa(n),qa(e)!==n&&t)throw Error(k(425))}function mi(){}var Yl=null,Zl=null;function ql(e,n){return e==="textarea"||e==="noscript"||typeof n.children=="string"||typeof n.children=="number"||typeof n.dangerouslySetInnerHTML=="object"&&n.dangerouslySetInnerHTML!==null&&n.dangerouslySetInnerHTML.__html!=null}var Jl=typeof setTimeout=="function"?setTimeout:void 0,ip=typeof clearTimeout=="function"?clearTimeout:void 0,Ja=typeof Promise=="function"?Promise:void 0,lp=typeof queueMicrotask=="function"?queueMicrotask:typeof Ja<"u"?function(e){return Ja.resolve(null).then(e).catch(op)}:Jl;function op(e){setTimeout(function(){throw e})}function pl(e,n){var t=n,r=0;do{var i=t.nextSibling;if(e.removeChild(t),i&&i.nodeType===8)if(t=i.data,t==="/$"){if(r===0){e.removeChild(i),lr(n);return}r--}else t!=="$"&&t!=="$?"&&t!=="$!"||r++;t=i}while(t);lr(n)}function Pn(e){for(;e!=null;e=e.nextSibling){var n=e.nodeType;if(n===1||n===3)break;if(n===8){if(n=e.data,n==="$"||n==="$!"||n==="$?")break;if(n==="/$")return null}}return e}function es(e){e=e.previousSibling;for(var n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="$"||t==="$!"||t==="$?"){if(n===0)return e;n--}else t==="/$"&&n++}e=e.previousSibling}return null}var Pt=Math.random().toString(36).slice(2),rn="__reactFiber$"+Pt,cr="__reactProps$"+Pt,mn="__reactContainer$"+Pt,eo="__reactEvents$"+Pt,ap="__reactListeners$"+Pt,sp="__reactHandles$"+Pt;function Wn(e){var n=e[rn];if(n)return n;for(var t=e.parentNode;t;){if(n=t[mn]||t[rn]){if(t=n.alternate,n.child!==null||t!==null&&t.child!==null)for(e=es(e);e!==null;){if(t=e[rn])return t;e=es(e)}return n}e=t,t=e.parentNode}return null}function Sr(e){return e=e[rn]||e[mn],!e||e.tag!==5&&e.tag!==6&&e.tag!==13&&e.tag!==3?null:e}function ot(e){if(e.tag===5||e.tag===6)return e.stateNode;throw Error(k(33))}function Di(e){return e[cr]||null}var no=[],at=-1;function An(e){return{current:e}}function Q(e){0>at||(e.current=no[at],no[at]=null,at--)}function V(e,n){at++,no[at]=e.current,e.current=n}var Dn={},ge=An(Dn),Pe=An(!1),Qn=Dn;function St(e,n){var t=e.type.contextTypes;if(!t)return Dn;var r=e.stateNode;if(r&&r.__reactInternalMemoizedUnmaskedChildContext===n)return r.__reactInternalMemoizedMaskedChildContext;var i={},l;for(l in t)i[l]=n[l];return r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=n,e.__reactInternalMemoizedMaskedChildContext=i),i}function $e(e){return e=e.childContextTypes,e!=null}function hi(){Q(Pe),Q(ge)}function ns(e,n,t){if(ge.current!==Dn)throw Error(k(168));V(ge,n),V(Pe,t)}function Xu(e,n,t){var r=e.stateNode;if(n=n.childContextTypes,typeof r.getChildContext!="function")return t;r=r.getChildContext();for(var i in r)if(!(i in n))throw Error(k(108,Vd(e)||"Unknown",i));return J({},t,r)}function gi(e){return e=(e=e.stateNode)&&e.__reactInternalMemoizedMergedChildContext||Dn,Qn=ge.current,V(ge,e),V(Pe,Pe.current),!0}function ts(e,n,t){var r=e.stateNode;if(!r)throw Error(k(169));t?(e=Xu(e,n,Qn),r.__reactInternalMemoizedMergedChildContext=e,Q(Pe),Q(ge),V(ge,e)):Q(Pe),V(Pe,t)}var un=null,ji=!1,ml=!1;function Ku(e){un===null?un=[e]:un.push(e)}function up(e){ji=!0,Ku(e)}function On(){if(!ml&&un!==null){ml=!0;var e=0,n=U;try{var t=un;for(U=1;e<t.length;e++){var r=t[e];do r=r(!0);while(r!==null)}un=null,ji=!1}catch(i){throw un!==null&&(un=un.slice(e+1)),wu(zo,On),i}finally{U=n,ml=!1}}return null}var st=[],ut=0,vi=null,yi=0,Be=[],We=0,Xn=null,cn=1,dn="";function In(e,n){st[ut++]=yi,st[ut++]=vi,vi=e,yi=n}function Yu(e,n,t){Be[We++]=cn,Be[We++]=dn,Be[We++]=Xn,Xn=e;var r=cn;e=dn;var i=32-qe(r)-1;r&=~(1<<i),t+=1;var l=32-qe(n)+i;if(30<l){var o=i-i%5;l=(r&(1<<o)-1).toString(32),r>>=o,i-=o,cn=1<<32-qe(n)+i|t<<i|r,dn=l+e}else cn=1<<l|t<<i|r,dn=e}function Wo(e){e.return!==null&&(In(e,1),Yu(e,1,0))}function Uo(e){for(;e===vi;)vi=st[--ut],st[ut]=null,yi=st[--ut],st[ut]=null;for(;e===Xn;)Xn=Be[--We],Be[We]=null,dn=Be[--We],Be[We]=null,cn=Be[--We],Be[We]=null}var De=null,Me=null,Y=!1,Ze=null;function Zu(e,n){var t=Ue(5,null,null,0);t.elementType="DELETED",t.stateNode=n,t.return=e,n=e.deletions,n===null?(e.deletions=[t],e.flags|=16):n.push(t)}function rs(e,n){switch(e.tag){case 5:var t=e.type;return n=n.nodeType!==1||t.toLowerCase()!==n.nodeName.toLowerCase()?null:n,n!==null?(e.stateNode=n,De=e,Me=Pn(n.firstChild),!0):!1;case 6:return n=e.pendingProps===""||n.nodeType!==3?null:n,n!==null?(e.stateNode=n,De=e,Me=null,!0):!1;case 13:return n=n.nodeType!==8?null:n,n!==null?(t=Xn!==null?{id:cn,overflow:dn}:null,e.memoizedState={dehydrated:n,treeContext:t,retryLane:1073741824},t=Ue(18,null,null,0),t.stateNode=n,t.return=e,e.child=t,De=e,Me=null,!0):!1;default:return!1}}function to(e){return(e.mode&1)!==0&&(e.flags&128)===0}function ro(e){if(Y){var n=Me;if(n){var t=n;if(!rs(e,n)){if(to(e))throw Error(k(418));n=Pn(t.nextSibling);var r=De;n&&rs(e,n)?Zu(r,t):(e.flags=e.flags&-4097|2,Y=!1,De=e)}}else{if(to(e))throw Error(k(418));e.flags=e.flags&-4097|2,Y=!1,De=e}}}function is(e){for(e=e.return;e!==null&&e.tag!==5&&e.tag!==3&&e.tag!==13;)e=e.return;De=e}function Ar(e){if(e!==De)return!1;if(!Y)return is(e),Y=!0,!1;var n;if((n=e.tag!==3)&&!(n=e.tag!==5)&&(n=e.type,n=n!=="head"&&n!=="body"&&!ql(e.type,e.memoizedProps)),n&&(n=Me)){if(to(e))throw qu(),Error(k(418));for(;n;)Zu(e,n),n=Pn(n.nextSibling)}if(is(e),e.tag===13){if(e=e.memoizedState,e=e!==null?e.dehydrated:null,!e)throw Error(k(317));e:{for(e=e.nextSibling,n=0;e;){if(e.nodeType===8){var t=e.data;if(t==="/$"){if(n===0){Me=Pn(e.nextSibling);break e}n--}else t!=="$"&&t!=="$!"&&t!=="$?"||n++}e=e.nextSibling}Me=null}}else Me=De?Pn(e.stateNode.nextSibling):null;return!0}function qu(){for(var e=Me;e;)e=Pn(e.nextSibling)}function _t(){Me=De=null,Y=!1}function Ho(e){Ze===null?Ze=[e]:Ze.push(e)}var cp=vn.ReactCurrentBatchConfig;function Dt(e,n,t){if(e=t.ref,e!==null&&typeof e!="function"&&typeof e!="object"){if(t._owner){if(t=t._owner,t){if(t.tag!==1)throw Error(k(309));var r=t.stateNode}if(!r)throw Error(k(147,e));var i=r,l=""+e;return n!==null&&n.ref!==null&&typeof n.ref=="function"&&n.ref._stringRef===l?n.ref:(n=function(o){var a=i.refs;o===null?delete a[l]:a[l]=o},n._stringRef=l,n)}if(typeof e!="string")throw Error(k(284));if(!t._owner)throw Error(k(290,e))}return e}function Or(e,n){throw e=Object.prototype.toString.call(n),Error(k(31,e==="[object Object]"?"object with keys {"+Object.keys(n).join(", ")+"}":e))}function ls(e){var n=e._init;return n(e._payload)}function Ju(e){function n(c,s){if(e){var f=c.deletions;f===null?(c.deletions=[s],c.flags|=16):f.push(s)}}function t(c,s){if(!e)return null;for(;s!==null;)n(c,s),s=s.sibling;return null}function r(c,s){for(c=new Map;s!==null;)s.key!==null?c.set(s.key,s):c.set(s.index,s),s=s.sibling;return c}function i(c,s){return c=zn(c,s),c.index=0,c.sibling=null,c}function l(c,s,f){return c.index=f,e?(f=c.alternate,f!==null?(f=f.index,f<s?(c.flags|=2,s):f):(c.flags|=2,s)):(c.flags|=1048576,s)}function o(c){return e&&c.alternate===null&&(c.flags|=2),c}function a(c,s,f,h){return s===null||s.tag!==6?(s=Sl(f,c.mode,h),s.return=c,s):(s=i(s,f),s.return=c,s)}function u(c,s,f,h){var S=f.type;return S===tt?g(c,s,f.props.children,h,f.key):s!==null&&(s.elementType===S||typeof S=="object"&&S!==null&&S.$$typeof===wn&&ls(S)===s.type)?(h=i(s,f.props),h.ref=Dt(c,s,f),h.return=c,h):(h=ri(f.type,f.key,f.props,null,c.mode,h),h.ref=Dt(c,s,f),h.return=c,h)}function d(c,s,f,h){return s===null||s.tag!==4||s.stateNode.containerInfo!==f.containerInfo||s.stateNode.implementation!==f.implementation?(s=_l(f,c.mode,h),s.return=c,s):(s=i(s,f.children||[]),s.return=c,s)}function g(c,s,f,h,S){return s===null||s.tag!==7?(s=Gn(f,c.mode,h,S),s.return=c,s):(s=i(s,f),s.return=c,s)}function m(c,s,f){if(typeof s=="string"&&s!==""||typeof s=="number")return s=Sl(""+s,c.mode,f),s.return=c,s;if(typeof s=="object"&&s!==null){switch(s.$$typeof){case Nr:return f=ri(s.type,s.key,s.props,null,c.mode,f),f.ref=Dt(c,null,s),f.return=c,f;case nt:return s=_l(s,c.mode,f),s.return=c,s;case wn:var h=s._init;return m(c,h(s._payload),f)}if(It(s)||Tt(s))return s=Gn(s,c.mode,f,null),s.return=c,s;Or(c,s)}return null}function p(c,s,f,h){var S=s!==null?s.key:null;if(typeof f=="string"&&f!==""||typeof f=="number")return S!==null?null:a(c,s,""+f,h);if(typeof f=="object"&&f!==null){switch(f.$$typeof){case Nr:return f.key===S?u(c,s,f,h):null;case nt:return f.key===S?d(c,s,f,h):null;case wn:return S=f._init,p(c,s,S(f._payload),h)}if(It(f)||Tt(f))return S!==null?null:g(c,s,f,h,null);Or(c,f)}return null}function v(c,s,f,h,S){if(typeof h=="string"&&h!==""||typeof h=="number")return c=c.get(f)||null,a(s,c,""+h,S);if(typeof h=="object"&&h!==null){switch(h.$$typeof){case Nr:return c=c.get(h.key===null?f:h.key)||null,u(s,c,h,S);case nt:return c=c.get(h.key===null?f:h.key)||null,d(s,c,h,S);case wn:var b=h._init;return v(c,s,f,b(h._payload),S)}if(It(h)||Tt(h))return c=c.get(f)||null,g(s,c,h,S,null);Or(s,h)}return null}function w(c,s,f,h){for(var S=null,b=null,C=s,E=s=0,j=null;C!==null&&E<f.length;E++){C.index>E?(j=C,C=null):j=C.sibling;var P=p(c,C,f[E],h);if(P===null){C===null&&(C=j);break}e&&C&&P.alternate===null&&n(c,C),s=l(P,s,E),b===null?S=P:b.sibling=P,b=P,C=j}if(E===f.length)return t(c,C),Y&&In(c,E),S;if(C===null){for(;E<f.length;E++)C=m(c,f[E],h),C!==null&&(s=l(C,s,E),b===null?S=C:b.sibling=C,b=C);return Y&&In(c,E),S}for(C=r(c,C);E<f.length;E++)j=v(C,c,E,f[E],h),j!==null&&(e&&j.alternate!==null&&C.delete(j.key===null?E:j.key),s=l(j,s,E),b===null?S=j:b.sibling=j,b=j);return e&&C.forEach(function(H){return n(c,H)}),Y&&In(c,E),S}function x(c,s,f,h){var S=Tt(f);if(typeof S!="function")throw Error(k(150));if(f=S.call(f),f==null)throw Error(k(151));for(var b=S=null,C=s,E=s=0,j=null,P=f.next();C!==null&&!P.done;E++,P=f.next()){C.index>E?(j=C,C=null):j=C.sibling;var H=p(c,C,P.value,h);if(H===null){C===null&&(C=j);break}e&&C&&H.alternate===null&&n(c,C),s=l(H,s,E),b===null?S=H:b.sibling=H,b=H,C=j}if(P.done)return t(c,C),Y&&In(c,E),S;if(C===null){for(;!P.done;E++,P=f.next())P=m(c,P.value,h),P!==null&&(s=l(P,s,E),b===null?S=P:b.sibling=P,b=P);return Y&&In(c,E),S}for(C=r(c,C);!P.done;E++,P=f.next())P=v(C,c,E,P.value,h),P!==null&&(e&&P.alternate!==null&&C.delete(P.key===null?E:P.key),s=l(P,s,E),b===null?S=P:b.sibling=P,b=P);return e&&C.forEach(function(ve){return n(c,ve)}),Y&&In(c,E),S}function L(c,s,f,h){if(typeof f=="object"&&f!==null&&f.type===tt&&f.key===null&&(f=f.props.children),typeof f=="object"&&f!==null){switch(f.$$typeof){case Nr:e:{for(var S=f.key,b=s;b!==null;){if(b.key===S){if(S=f.type,S===tt){if(b.tag===7){t(c,b.sibling),s=i(b,f.props.children),s.return=c,c=s;break e}}else if(b.elementType===S||typeof S=="object"&&S!==null&&S.$$typeof===wn&&ls(S)===b.type){t(c,b.sibling),s=i(b,f.props),s.ref=Dt(c,b,f),s.return=c,c=s;break e}t(c,b);break}else n(c,b);b=b.sibling}f.type===tt?(s=Gn(f.props.children,c.mode,h,f.key),s.return=c,c=s):(h=ri(f.type,f.key,f.props,null,c.mode,h),h.ref=Dt(c,s,f),h.return=c,c=h)}return o(c);case nt:e:{for(b=f.key;s!==null;){if(s.key===b)if(s.tag===4&&s.stateNode.containerInfo===f.containerInfo&&s.stateNode.implementation===f.implementation){t(c,s.sibling),s=i(s,f.children||[]),s.return=c,c=s;break e}else{t(c,s);break}else n(c,s);s=s.sibling}s=_l(f,c.mode,h),s.return=c,c=s}return o(c);case wn:return b=f._init,L(c,s,b(f._payload),h)}if(It(f))return w(c,s,f,h);if(Tt(f))return x(c,s,f,h);Or(c,f)}return typeof f=="string"&&f!==""||typeof f=="number"?(f=""+f,s!==null&&s.tag===6?(t(c,s.sibling),s=i(s,f),s.return=c,c=s):(t(c,s),s=Sl(f,c.mode,h),s.return=c,c=s),o(c)):t(c,s)}return L}var kt=Ju(!0),ec=Ju(!1),xi=An(null),wi=null,ct=null,Vo=null;function Go(){Vo=ct=wi=null}function Qo(e){var n=xi.current;Q(xi),e._currentValue=n}function io(e,n,t){for(;e!==null;){var r=e.alternate;if((e.childLanes&n)!==n?(e.childLanes|=n,r!==null&&(r.childLanes|=n)):r!==null&&(r.childLanes&n)!==n&&(r.childLanes|=n),e===t)break;e=e.return}}function yt(e,n){wi=e,Vo=ct=null,e=e.dependencies,e!==null&&e.firstContext!==null&&(e.lanes&n&&(Ne=!0),e.firstContext=null)}function Ve(e){var n=e._currentValue;if(Vo!==e)if(e={context:e,memoizedValue:n,next:null},ct===null){if(wi===null)throw Error(k(308));ct=e,wi.dependencies={lanes:0,firstContext:e}}else ct=ct.next=e;return n}var Un=null;function Xo(e){Un===null?Un=[e]:Un.push(e)}function nc(e,n,t,r){var i=n.interleaved;return i===null?(t.next=t,Xo(n)):(t.next=i.next,i.next=t),n.interleaved=t,hn(e,r)}function hn(e,n){e.lanes|=n;var t=e.alternate;for(t!==null&&(t.lanes|=n),t=e,e=e.return;e!==null;)e.childLanes|=n,t=e.alternate,t!==null&&(t.childLanes|=n),t=e,e=e.return;return t.tag===3?t.stateNode:null}var Sn=!1;function Ko(e){e.updateQueue={baseState:e.memoizedState,firstBaseUpdate:null,lastBaseUpdate:null,shared:{pending:null,interleaved:null,lanes:0},effects:null}}function tc(e,n){e=e.updateQueue,n.updateQueue===e&&(n.updateQueue={baseState:e.baseState,firstBaseUpdate:e.firstBaseUpdate,lastBaseUpdate:e.lastBaseUpdate,shared:e.shared,effects:e.effects})}function fn(e,n){return{eventTime:e,lane:n,tag:0,payload:null,callback:null,next:null}}function $n(e,n,t){var r=e.updateQueue;if(r===null)return null;if(r=r.shared,B&2){var i=r.pending;return i===null?n.next=n:(n.next=i.next,i.next=n),r.pending=n,hn(e,t)}return i=r.interleaved,i===null?(n.next=n,Xo(r)):(n.next=i.next,i.next=n),r.interleaved=n,hn(e,t)}function Zr(e,n,t){if(n=n.updateQueue,n!==null&&(n=n.shared,(t&4194240)!==0)){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,Lo(e,t)}}function os(e,n){var t=e.updateQueue,r=e.alternate;if(r!==null&&(r=r.updateQueue,t===r)){var i=null,l=null;if(t=t.firstBaseUpdate,t!==null){do{var o={eventTime:t.eventTime,lane:t.lane,tag:t.tag,payload:t.payload,callback:t.callback,next:null};l===null?i=l=o:l=l.next=o,t=t.next}while(t!==null);l===null?i=l=n:l=l.next=n}else i=l=n;t={baseState:r.baseState,firstBaseUpdate:i,lastBaseUpdate:l,shared:r.shared,effects:r.effects},e.updateQueue=t;return}e=t.lastBaseUpdate,e===null?t.firstBaseUpdate=n:e.next=n,t.lastBaseUpdate=n}function Si(e,n,t,r){var i=e.updateQueue;Sn=!1;var l=i.firstBaseUpdate,o=i.lastBaseUpdate,a=i.shared.pending;if(a!==null){i.shared.pending=null;var u=a,d=u.next;u.next=null,o===null?l=d:o.next=d,o=u;var g=e.alternate;g!==null&&(g=g.updateQueue,a=g.lastBaseUpdate,a!==o&&(a===null?g.firstBaseUpdate=d:a.next=d,g.lastBaseUpdate=u))}if(l!==null){var m=i.baseState;o=0,g=d=u=null,a=l;do{var p=a.lane,v=a.eventTime;if((r&p)===p){g!==null&&(g=g.next={eventTime:v,lane:0,tag:a.tag,payload:a.payload,callback:a.callback,next:null});e:{var w=e,x=a;switch(p=n,v=t,x.tag){case 1:if(w=x.payload,typeof w=="function"){m=w.call(v,m,p);break e}m=w;break e;case 3:w.flags=w.flags&-65537|128;case 0:if(w=x.payload,p=typeof w=="function"?w.call(v,m,p):w,p==null)break e;m=J({},m,p);break e;case 2:Sn=!0}}a.callback!==null&&a.lane!==0&&(e.flags|=64,p=i.effects,p===null?i.effects=[a]:p.push(a))}else v={eventTime:v,lane:p,tag:a.tag,payload:a.payload,callback:a.callback,next:null},g===null?(d=g=v,u=m):g=g.next=v,o|=p;if(a=a.next,a===null){if(a=i.shared.pending,a===null)break;p=a,a=p.next,p.next=null,i.lastBaseUpdate=p,i.shared.pending=null}}while(!0);if(g===null&&(u=m),i.baseState=u,i.firstBaseUpdate=d,i.lastBaseUpdate=g,n=i.shared.interleaved,n!==null){i=n;do o|=i.lane,i=i.next;while(i!==n)}else l===null&&(i.shared.lanes=0);Yn|=o,e.lanes=o,e.memoizedState=m}}function as(e,n,t){if(e=n.effects,n.effects=null,e!==null)for(n=0;n<e.length;n++){var r=e[n],i=r.callback;if(i!==null){if(r.callback=null,r=t,typeof i!="function")throw Error(k(191,i));i.call(r)}}}var _r={},on=An(_r),dr=An(_r),fr=An(_r);function Hn(e){if(e===_r)throw Error(k(174));return e}function Yo(e,n){switch(V(fr,n),V(dr,e),V(on,_r),e=n.nodeType,e){case 9:case 11:n=(n=n.documentElement)?n.namespaceURI:Al(null,"");break;default:e=e===8?n.parentNode:n,n=e.namespaceURI||null,e=e.tagName,n=Al(n,e)}Q(on),V(on,n)}function bt(){Q(on),Q(dr),Q(fr)}function rc(e){Hn(fr.current);var n=Hn(on.current),t=Al(n,e.type);n!==t&&(V(dr,e),V(on,t))}function Zo(e){dr.current===e&&(Q(on),Q(dr))}var Z=An(0);function _i(e){for(var n=e;n!==null;){if(n.tag===13){var t=n.memoizedState;if(t!==null&&(t=t.dehydrated,t===null||t.data==="$?"||t.data==="$!"))return n}else if(n.tag===19&&n.memoizedProps.revealOrder!==void 0){if(n.flags&128)return n}else if(n.child!==null){n.child.return=n,n=n.child;continue}if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return null;n=n.return}n.sibling.return=n.return,n=n.sibling}return null}var hl=[];function qo(){for(var e=0;e<hl.length;e++)hl[e]._workInProgressVersionPrimary=null;hl.length=0}var qr=vn.ReactCurrentDispatcher,gl=vn.ReactCurrentBatchConfig,Kn=0,q=null,le=null,ae=null,ki=!1,Kt=!1,pr=0,dp=0;function pe(){throw Error(k(321))}function Jo(e,n){if(n===null)return!1;for(var t=0;t<n.length&&t<e.length;t++)if(!en(e[t],n[t]))return!1;return!0}function ea(e,n,t,r,i,l){if(Kn=l,q=n,n.memoizedState=null,n.updateQueue=null,n.lanes=0,qr.current=e===null||e.memoizedState===null?hp:gp,e=t(r,i),Kt){l=0;do{if(Kt=!1,pr=0,25<=l)throw Error(k(301));l+=1,ae=le=null,n.updateQueue=null,qr.current=vp,e=t(r,i)}while(Kt)}if(qr.current=bi,n=le!==null&&le.next!==null,Kn=0,ae=le=q=null,ki=!1,n)throw Error(k(300));return e}function na(){var e=pr!==0;return pr=0,e}function tn(){var e={memoizedState:null,baseState:null,baseQueue:null,queue:null,next:null};return ae===null?q.memoizedState=ae=e:ae=ae.next=e,ae}function Ge(){if(le===null){var e=q.alternate;e=e!==null?e.memoizedState:null}else e=le.next;var n=ae===null?q.memoizedState:ae.next;if(n!==null)ae=n,le=e;else{if(e===null)throw Error(k(310));le=e,e={memoizedState:le.memoizedState,baseState:le.baseState,baseQueue:le.baseQueue,queue:le.queue,next:null},ae===null?q.memoizedState=ae=e:ae=ae.next=e}return ae}function mr(e,n){return typeof n=="function"?n(e):n}function vl(e){var n=Ge(),t=n.queue;if(t===null)throw Error(k(311));t.lastRenderedReducer=e;var r=le,i=r.baseQueue,l=t.pending;if(l!==null){if(i!==null){var o=i.next;i.next=l.next,l.next=o}r.baseQueue=i=l,t.pending=null}if(i!==null){l=i.next,r=r.baseState;var a=o=null,u=null,d=l;do{var g=d.lane;if((Kn&g)===g)u!==null&&(u=u.next={lane:0,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null}),r=d.hasEagerState?d.eagerState:e(r,d.action);else{var m={lane:g,action:d.action,hasEagerState:d.hasEagerState,eagerState:d.eagerState,next:null};u===null?(a=u=m,o=r):u=u.next=m,q.lanes|=g,Yn|=g}d=d.next}while(d!==null&&d!==l);u===null?o=r:u.next=a,en(r,n.memoizedState)||(Ne=!0),n.memoizedState=r,n.baseState=o,n.baseQueue=u,t.lastRenderedState=r}if(e=t.interleaved,e!==null){i=e;do l=i.lane,q.lanes|=l,Yn|=l,i=i.next;while(i!==e)}else i===null&&(t.lanes=0);return[n.memoizedState,t.dispatch]}function yl(e){var n=Ge(),t=n.queue;if(t===null)throw Error(k(311));t.lastRenderedReducer=e;var r=t.dispatch,i=t.pending,l=n.memoizedState;if(i!==null){t.pending=null;var o=i=i.next;do l=e(l,o.action),o=o.next;while(o!==i);en(l,n.memoizedState)||(Ne=!0),n.memoizedState=l,n.baseQueue===null&&(n.baseState=l),t.lastRenderedState=l}return[l,r]}function ic(){}function lc(e,n){var t=q,r=Ge(),i=n(),l=!en(r.memoizedState,i);if(l&&(r.memoizedState=i,Ne=!0),r=r.queue,ta(sc.bind(null,t,r,e),[e]),r.getSnapshot!==n||l||ae!==null&&ae.memoizedState.tag&1){if(t.flags|=2048,hr(9,ac.bind(null,t,r,i,n),void 0,null),se===null)throw Error(k(349));Kn&30||oc(t,n,i)}return i}function oc(e,n,t){e.flags|=16384,e={getSnapshot:n,value:t},n=q.updateQueue,n===null?(n={lastEffect:null,stores:null},q.updateQueue=n,n.stores=[e]):(t=n.stores,t===null?n.stores=[e]:t.push(e))}function ac(e,n,t,r){n.value=t,n.getSnapshot=r,uc(n)&&cc(e)}function sc(e,n,t){return t(function(){uc(n)&&cc(e)})}function uc(e){var n=e.getSnapshot;e=e.value;try{var t=n();return!en(e,t)}catch{return!0}}function cc(e){var n=hn(e,1);n!==null&&Je(n,e,1,-1)}function ss(e){var n=tn();return typeof e=="function"&&(e=e()),n.memoizedState=n.baseState=e,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:mr,lastRenderedState:e},n.queue=e,e=e.dispatch=mp.bind(null,q,e),[n.memoizedState,e]}function hr(e,n,t,r){return e={tag:e,create:n,destroy:t,deps:r,next:null},n=q.updateQueue,n===null?(n={lastEffect:null,stores:null},q.updateQueue=n,n.lastEffect=e.next=e):(t=n.lastEffect,t===null?n.lastEffect=e.next=e:(r=t.next,t.next=e,e.next=r,n.lastEffect=e)),e}function dc(){return Ge().memoizedState}function Jr(e,n,t,r){var i=tn();q.flags|=e,i.memoizedState=hr(1|n,t,void 0,r===void 0?null:r)}function Ai(e,n,t,r){var i=Ge();r=r===void 0?null:r;var l=void 0;if(le!==null){var o=le.memoizedState;if(l=o.destroy,r!==null&&Jo(r,o.deps)){i.memoizedState=hr(n,t,l,r);return}}q.flags|=e,i.memoizedState=hr(1|n,t,l,r)}function us(e,n){return Jr(8390656,8,e,n)}function ta(e,n){return Ai(2048,8,e,n)}function fc(e,n){return Ai(4,2,e,n)}function pc(e,n){return Ai(4,4,e,n)}function mc(e,n){if(typeof n=="function")return e=e(),n(e),function(){n(null)};if(n!=null)return e=e(),n.current=e,function(){n.current=null}}function hc(e,n,t){return t=t!=null?t.concat([e]):null,Ai(4,4,mc.bind(null,n,e),t)}function ra(){}function gc(e,n){var t=Ge();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Jo(n,r[1])?r[0]:(t.memoizedState=[e,n],e)}function vc(e,n){var t=Ge();n=n===void 0?null:n;var r=t.memoizedState;return r!==null&&n!==null&&Jo(n,r[1])?r[0]:(e=e(),t.memoizedState=[e,n],e)}function yc(e,n,t){return Kn&21?(en(t,n)||(t=ku(),q.lanes|=t,Yn|=t,e.baseState=!0),n):(e.baseState&&(e.baseState=!1,Ne=!0),e.memoizedState=t)}function fp(e,n){var t=U;U=t!==0&&4>t?t:4,e(!0);var r=gl.transition;gl.transition={};try{e(!1),n()}finally{U=t,gl.transition=r}}function xc(){return Ge().memoizedState}function pp(e,n,t){var r=Rn(e);if(t={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null},wc(e))Sc(n,t);else if(t=nc(e,n,t,r),t!==null){var i=ke();Je(t,e,r,i),_c(t,n,r)}}function mp(e,n,t){var r=Rn(e),i={lane:r,action:t,hasEagerState:!1,eagerState:null,next:null};if(wc(e))Sc(n,i);else{var l=e.alternate;if(e.lanes===0&&(l===null||l.lanes===0)&&(l=n.lastRenderedReducer,l!==null))try{var o=n.lastRenderedState,a=l(o,t);if(i.hasEagerState=!0,i.eagerState=a,en(a,o)){var u=n.interleaved;u===null?(i.next=i,Xo(n)):(i.next=u.next,u.next=i),n.interleaved=i;return}}catch{}finally{}t=nc(e,n,i,r),t!==null&&(i=ke(),Je(t,e,r,i),_c(t,n,r))}}function wc(e){var n=e.alternate;return e===q||n!==null&&n===q}function Sc(e,n){Kt=ki=!0;var t=e.pending;t===null?n.next=n:(n.next=t.next,t.next=n),e.pending=n}function _c(e,n,t){if(t&4194240){var r=n.lanes;r&=e.pendingLanes,t|=r,n.lanes=t,Lo(e,t)}}var bi={readContext:Ve,useCallback:pe,useContext:pe,useEffect:pe,useImperativeHandle:pe,useInsertionEffect:pe,useLayoutEffect:pe,useMemo:pe,useReducer:pe,useRef:pe,useState:pe,useDebugValue:pe,useDeferredValue:pe,useTransition:pe,useMutableSource:pe,useSyncExternalStore:pe,useId:pe,unstable_isNewReconciler:!1},hp={readContext:Ve,useCallback:function(e,n){return tn().memoizedState=[e,n===void 0?null:n],e},useContext:Ve,useEffect:us,useImperativeHandle:function(e,n,t){return t=t!=null?t.concat([e]):null,Jr(4194308,4,mc.bind(null,n,e),t)},useLayoutEffect:function(e,n){return Jr(4194308,4,e,n)},useInsertionEffect:function(e,n){return Jr(4,2,e,n)},useMemo:function(e,n){var t=tn();return n=n===void 0?null:n,e=e(),t.memoizedState=[e,n],e},useReducer:function(e,n,t){var r=tn();return n=t!==void 0?t(n):n,r.memoizedState=r.baseState=n,e={pending:null,interleaved:null,lanes:0,dispatch:null,lastRenderedReducer:e,lastRenderedState:n},r.queue=e,e=e.dispatch=pp.bind(null,q,e),[r.memoizedState,e]},useRef:function(e){var n=tn();return e={current:e},n.memoizedState=e},useState:ss,useDebugValue:ra,useDeferredValue:function(e){return tn().memoizedState=e},useTransition:function(){var e=ss(!1),n=e[0];return e=fp.bind(null,e[1]),tn().memoizedState=e,[n,e]},useMutableSource:function(){},useSyncExternalStore:function(e,n,t){var r=q,i=tn();if(Y){if(t===void 0)throw Error(k(407));t=t()}else{if(t=n(),se===null)throw Error(k(349));Kn&30||oc(r,n,t)}i.memoizedState=t;var l={value:t,getSnapshot:n};return i.queue=l,us(sc.bind(null,r,l,e),[e]),r.flags|=2048,hr(9,ac.bind(null,r,l,t,n),void 0,null),t},useId:function(){var e=tn(),n=se.identifierPrefix;if(Y){var t=dn,r=cn;t=(r&~(1<<32-qe(r)-1)).toString(32)+t,n=":"+n+"R"+t,t=pr++,0<t&&(n+="H"+t.toString(32)),n+=":"}else t=dp++,n=":"+n+"r"+t.toString(32)+":";return e.memoizedState=n},unstable_isNewReconciler:!1},gp={readContext:Ve,useCallback:gc,useContext:Ve,useEffect:ta,useImperativeHandle:hc,useInsertionEffect:fc,useLayoutEffect:pc,useMemo:vc,useReducer:vl,useRef:dc,useState:function(){return vl(mr)},useDebugValue:ra,useDeferredValue:function(e){var n=Ge();return yc(n,le.memoizedState,e)},useTransition:function(){var e=vl(mr)[0],n=Ge().memoizedState;return[e,n]},useMutableSource:ic,useSyncExternalStore:lc,useId:xc,unstable_isNewReconciler:!1},vp={readContext:Ve,useCallback:gc,useContext:Ve,useEffect:ta,useImperativeHandle:hc,useInsertionEffect:fc,useLayoutEffect:pc,useMemo:vc,useReducer:yl,useRef:dc,useState:function(){return yl(mr)},useDebugValue:ra,useDeferredValue:function(e){var n=Ge();return le===null?n.memoizedState=e:yc(n,le.memoizedState,e)},useTransition:function(){var e=yl(mr)[0],n=Ge().memoizedState;return[e,n]},useMutableSource:ic,useSyncExternalStore:lc,useId:xc,unstable_isNewReconciler:!1};function Ke(e,n){if(e&&e.defaultProps){n=J({},n),e=e.defaultProps;for(var t in e)n[t]===void 0&&(n[t]=e[t]);return n}return n}function lo(e,n,t,r){n=e.memoizedState,t=t(r,n),t=t==null?n:J({},n,t),e.memoizedState=t,e.lanes===0&&(e.updateQueue.baseState=t)}var Oi={isMounted:function(e){return(e=e._reactInternals)?Jn(e)===e:!1},enqueueSetState:function(e,n,t){e=e._reactInternals;var r=ke(),i=Rn(e),l=fn(r,i);l.payload=n,t!=null&&(l.callback=t),n=$n(e,l,i),n!==null&&(Je(n,e,i,r),Zr(n,e,i))},enqueueReplaceState:function(e,n,t){e=e._reactInternals;var r=ke(),i=Rn(e),l=fn(r,i);l.tag=1,l.payload=n,t!=null&&(l.callback=t),n=$n(e,l,i),n!==null&&(Je(n,e,i,r),Zr(n,e,i))},enqueueForceUpdate:function(e,n){e=e._reactInternals;var t=ke(),r=Rn(e),i=fn(t,r);i.tag=2,n!=null&&(i.callback=n),n=$n(e,i,r),n!==null&&(Je(n,e,r,t),Zr(n,e,r))}};function cs(e,n,t,r,i,l,o){return e=e.stateNode,typeof e.shouldComponentUpdate=="function"?e.shouldComponentUpdate(r,l,o):n.prototype&&n.prototype.isPureReactComponent?!ar(t,r)||!ar(i,l):!0}function kc(e,n,t){var r=!1,i=Dn,l=n.contextType;return typeof l=="object"&&l!==null?l=Ve(l):(i=$e(n)?Qn:ge.current,r=n.contextTypes,l=(r=r!=null)?St(e,i):Dn),n=new n(t,l),e.memoizedState=n.state!==null&&n.state!==void 0?n.state:null,n.updater=Oi,e.stateNode=n,n._reactInternals=e,r&&(e=e.stateNode,e.__reactInternalMemoizedUnmaskedChildContext=i,e.__reactInternalMemoizedMaskedChildContext=l),n}function ds(e,n,t,r){e=n.state,typeof n.componentWillReceiveProps=="function"&&n.componentWillReceiveProps(t,r),typeof n.UNSAFE_componentWillReceiveProps=="function"&&n.UNSAFE_componentWillReceiveProps(t,r),n.state!==e&&Oi.enqueueReplaceState(n,n.state,null)}function oo(e,n,t,r){var i=e.stateNode;i.props=t,i.state=e.memoizedState,i.refs={},Ko(e);var l=n.contextType;typeof l=="object"&&l!==null?i.context=Ve(l):(l=$e(n)?Qn:ge.current,i.context=St(e,l)),i.state=e.memoizedState,l=n.getDerivedStateFromProps,typeof l=="function"&&(lo(e,n,l,t),i.state=e.memoizedState),typeof n.getDerivedStateFromProps=="function"||typeof i.getSnapshotBeforeUpdate=="function"||typeof i.UNSAFE_componentWillMount!="function"&&typeof i.componentWillMount!="function"||(n=i.state,typeof i.componentWillMount=="function"&&i.componentWillMount(),typeof i.UNSAFE_componentWillMount=="function"&&i.UNSAFE_componentWillMount(),n!==i.state&&Oi.enqueueReplaceState(i,i.state,null),Si(e,t,i,r),i.state=e.memoizedState),typeof i.componentDidMount=="function"&&(e.flags|=4194308)}function Et(e,n){try{var t="",r=n;do t+=Hd(r),r=r.return;while(r);var i=t}catch(l){i=`
Error generating stack: `+l.message+`
`+l.stack}return{value:e,source:n,stack:i,digest:null}}function xl(e,n,t){return{value:e,source:null,stack:t??null,digest:n??null}}function ao(e,n){try{console.error(n.value)}catch(t){setTimeout(function(){throw t})}}var yp=typeof WeakMap=="function"?WeakMap:Map;function bc(e,n,t){t=fn(-1,t),t.tag=3,t.payload={element:null};var r=n.value;return t.callback=function(){Ci||(Ci=!0,yo=r),ao(e,n)},t}function Ec(e,n,t){t=fn(-1,t),t.tag=3;var r=e.type.getDerivedStateFromError;if(typeof r=="function"){var i=n.value;t.payload=function(){return r(i)},t.callback=function(){ao(e,n)}}var l=e.stateNode;return l!==null&&typeof l.componentDidCatch=="function"&&(t.callback=function(){ao(e,n),typeof r!="function"&&(Tn===null?Tn=new Set([this]):Tn.add(this));var o=n.stack;this.componentDidCatch(n.value,{componentStack:o!==null?o:""})}),t}function fs(e,n,t){var r=e.pingCache;if(r===null){r=e.pingCache=new yp;var i=new Set;r.set(n,i)}else i=r.get(n),i===void 0&&(i=new Set,r.set(n,i));i.has(t)||(i.add(t),e=Rp.bind(null,e,n,t),n.then(e,e))}function ps(e){do{var n;if((n=e.tag===13)&&(n=e.memoizedState,n=n!==null?n.dehydrated!==null:!0),n)return e;e=e.return}while(e!==null);return null}function ms(e,n,t,r,i){return e.mode&1?(e.flags|=65536,e.lanes=i,e):(e===n?e.flags|=65536:(e.flags|=128,t.flags|=131072,t.flags&=-52805,t.tag===1&&(t.alternate===null?t.tag=17:(n=fn(-1,1),n.tag=2,$n(t,n,1))),t.lanes|=1),e)}var xp=vn.ReactCurrentOwner,Ne=!1;function Se(e,n,t,r){n.child=e===null?ec(n,null,t,r):kt(n,e.child,t,r)}function hs(e,n,t,r,i){t=t.render;var l=n.ref;return yt(n,i),r=ea(e,n,t,r,l,i),t=na(),e!==null&&!Ne?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,gn(e,n,i)):(Y&&t&&Wo(n),n.flags|=1,Se(e,n,r,i),n.child)}function gs(e,n,t,r,i){if(e===null){var l=t.type;return typeof l=="function"&&!da(l)&&l.defaultProps===void 0&&t.compare===null&&t.defaultProps===void 0?(n.tag=15,n.type=l,Cc(e,n,l,r,i)):(e=ri(t.type,null,r,n,n.mode,i),e.ref=n.ref,e.return=n,n.child=e)}if(l=e.child,!(e.lanes&i)){var o=l.memoizedProps;if(t=t.compare,t=t!==null?t:ar,t(o,r)&&e.ref===n.ref)return gn(e,n,i)}return n.flags|=1,e=zn(l,r),e.ref=n.ref,e.return=n,n.child=e}function Cc(e,n,t,r,i){if(e!==null){var l=e.memoizedProps;if(ar(l,r)&&e.ref===n.ref)if(Ne=!1,n.pendingProps=r=l,(e.lanes&i)!==0)e.flags&131072&&(Ne=!0);else return n.lanes=e.lanes,gn(e,n,i)}return so(e,n,t,r,i)}function Fc(e,n,t){var r=n.pendingProps,i=r.children,l=e!==null?e.memoizedState:null;if(r.mode==="hidden")if(!(n.mode&1))n.memoizedState={baseLanes:0,cachePool:null,transitions:null},V(ft,ze),ze|=t;else{if(!(t&1073741824))return e=l!==null?l.baseLanes|t:t,n.lanes=n.childLanes=1073741824,n.memoizedState={baseLanes:e,cachePool:null,transitions:null},n.updateQueue=null,V(ft,ze),ze|=e,null;n.memoizedState={baseLanes:0,cachePool:null,transitions:null},r=l!==null?l.baseLanes:t,V(ft,ze),ze|=r}else l!==null?(r=l.baseLanes|t,n.memoizedState=null):r=t,V(ft,ze),ze|=r;return Se(e,n,i,t),n.child}function Nc(e,n){var t=n.ref;(e===null&&t!==null||e!==null&&e.ref!==t)&&(n.flags|=512,n.flags|=2097152)}function so(e,n,t,r,i){var l=$e(t)?Qn:ge.current;return l=St(n,l),yt(n,i),t=ea(e,n,t,r,l,i),r=na(),e!==null&&!Ne?(n.updateQueue=e.updateQueue,n.flags&=-2053,e.lanes&=~i,gn(e,n,i)):(Y&&r&&Wo(n),n.flags|=1,Se(e,n,t,i),n.child)}function vs(e,n,t,r,i){if($e(t)){var l=!0;gi(n)}else l=!1;if(yt(n,i),n.stateNode===null)ei(e,n),kc(n,t,r),oo(n,t,r,i),r=!0;else if(e===null){var o=n.stateNode,a=n.memoizedProps;o.props=a;var u=o.context,d=t.contextType;typeof d=="object"&&d!==null?d=Ve(d):(d=$e(t)?Qn:ge.current,d=St(n,d));var g=t.getDerivedStateFromProps,m=typeof g=="function"||typeof o.getSnapshotBeforeUpdate=="function";m||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==r||u!==d)&&ds(n,o,r,d),Sn=!1;var p=n.memoizedState;o.state=p,Si(n,r,o,i),u=n.memoizedState,a!==r||p!==u||Pe.current||Sn?(typeof g=="function"&&(lo(n,t,g,r),u=n.memoizedState),(a=Sn||cs(n,t,a,r,p,u,d))?(m||typeof o.UNSAFE_componentWillMount!="function"&&typeof o.componentWillMount!="function"||(typeof o.componentWillMount=="function"&&o.componentWillMount(),typeof o.UNSAFE_componentWillMount=="function"&&o.UNSAFE_componentWillMount()),typeof o.componentDidMount=="function"&&(n.flags|=4194308)):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),n.memoizedProps=r,n.memoizedState=u),o.props=r,o.state=u,o.context=d,r=a):(typeof o.componentDidMount=="function"&&(n.flags|=4194308),r=!1)}else{o=n.stateNode,tc(e,n),a=n.memoizedProps,d=n.type===n.elementType?a:Ke(n.type,a),o.props=d,m=n.pendingProps,p=o.context,u=t.contextType,typeof u=="object"&&u!==null?u=Ve(u):(u=$e(t)?Qn:ge.current,u=St(n,u));var v=t.getDerivedStateFromProps;(g=typeof v=="function"||typeof o.getSnapshotBeforeUpdate=="function")||typeof o.UNSAFE_componentWillReceiveProps!="function"&&typeof o.componentWillReceiveProps!="function"||(a!==m||p!==u)&&ds(n,o,r,u),Sn=!1,p=n.memoizedState,o.state=p,Si(n,r,o,i);var w=n.memoizedState;a!==m||p!==w||Pe.current||Sn?(typeof v=="function"&&(lo(n,t,v,r),w=n.memoizedState),(d=Sn||cs(n,t,d,r,p,w,u)||!1)?(g||typeof o.UNSAFE_componentWillUpdate!="function"&&typeof o.componentWillUpdate!="function"||(typeof o.componentWillUpdate=="function"&&o.componentWillUpdate(r,w,u),typeof o.UNSAFE_componentWillUpdate=="function"&&o.UNSAFE_componentWillUpdate(r,w,u)),typeof o.componentDidUpdate=="function"&&(n.flags|=4),typeof o.getSnapshotBeforeUpdate=="function"&&(n.flags|=1024)):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),n.memoizedProps=r,n.memoizedState=w),o.props=r,o.state=w,o.context=u,r=d):(typeof o.componentDidUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=4),typeof o.getSnapshotBeforeUpdate!="function"||a===e.memoizedProps&&p===e.memoizedState||(n.flags|=1024),r=!1)}return uo(e,n,t,r,l,i)}function uo(e,n,t,r,i,l){Nc(e,n);var o=(n.flags&128)!==0;if(!r&&!o)return i&&ts(n,t,!1),gn(e,n,l);r=n.stateNode,xp.current=n;var a=o&&typeof t.getDerivedStateFromError!="function"?null:r.render();return n.flags|=1,e!==null&&o?(n.child=kt(n,e.child,null,l),n.child=kt(n,null,a,l)):Se(e,n,a,l),n.memoizedState=r.state,i&&ts(n,t,!0),n.child}function Pc(e){var n=e.stateNode;n.pendingContext?ns(e,n.pendingContext,n.pendingContext!==n.context):n.context&&ns(e,n.context,!1),Yo(e,n.containerInfo)}function ys(e,n,t,r,i){return _t(),Ho(i),n.flags|=256,Se(e,n,t,r),n.child}var co={dehydrated:null,treeContext:null,retryLane:0};function fo(e){return{baseLanes:e,cachePool:null,transitions:null}}function $c(e,n,t){var r=n.pendingProps,i=Z.current,l=!1,o=(n.flags&128)!==0,a;if((a=o)||(a=e!==null&&e.memoizedState===null?!1:(i&2)!==0),a?(l=!0,n.flags&=-129):(e===null||e.memoizedState!==null)&&(i|=1),V(Z,i&1),e===null)return ro(n),e=n.memoizedState,e!==null&&(e=e.dehydrated,e!==null)?(n.mode&1?e.data==="$!"?n.lanes=8:n.lanes=1073741824:n.lanes=1,null):(o=r.children,e=r.fallback,l?(r=n.mode,l=n.child,o={mode:"hidden",children:o},!(r&1)&&l!==null?(l.childLanes=0,l.pendingProps=o):l=Wi(o,r,0,null),e=Gn(e,r,t,null),l.return=n,e.return=n,l.sibling=e,n.child=l,n.child.memoizedState=fo(t),n.memoizedState=co,e):ia(n,o));if(i=e.memoizedState,i!==null&&(a=i.dehydrated,a!==null))return wp(e,n,o,r,a,i,t);if(l){l=r.fallback,o=n.mode,i=e.child,a=i.sibling;var u={mode:"hidden",children:r.children};return!(o&1)&&n.child!==i?(r=n.child,r.childLanes=0,r.pendingProps=u,n.deletions=null):(r=zn(i,u),r.subtreeFlags=i.subtreeFlags&14680064),a!==null?l=zn(a,l):(l=Gn(l,o,t,null),l.flags|=2),l.return=n,r.return=n,r.sibling=l,n.child=r,r=l,l=n.child,o=e.child.memoizedState,o=o===null?fo(t):{baseLanes:o.baseLanes|t,cachePool:null,transitions:o.transitions},l.memoizedState=o,l.childLanes=e.childLanes&~t,n.memoizedState=co,r}return l=e.child,e=l.sibling,r=zn(l,{mode:"visible",children:r.children}),!(n.mode&1)&&(r.lanes=t),r.return=n,r.sibling=null,e!==null&&(t=n.deletions,t===null?(n.deletions=[e],n.flags|=16):t.push(e)),n.child=r,n.memoizedState=null,r}function ia(e,n){return n=Wi({mode:"visible",children:n},e.mode,0,null),n.return=e,e.child=n}function Ir(e,n,t,r){return r!==null&&Ho(r),kt(n,e.child,null,t),e=ia(n,n.pendingProps.children),e.flags|=2,n.memoizedState=null,e}function wp(e,n,t,r,i,l,o){if(t)return n.flags&256?(n.flags&=-257,r=xl(Error(k(422))),Ir(e,n,o,r)):n.memoizedState!==null?(n.child=e.child,n.flags|=128,null):(l=r.fallback,i=n.mode,r=Wi({mode:"visible",children:r.children},i,0,null),l=Gn(l,i,o,null),l.flags|=2,r.return=n,l.return=n,r.sibling=l,n.child=r,n.mode&1&&kt(n,e.child,null,o),n.child.memoizedState=fo(o),n.memoizedState=co,l);if(!(n.mode&1))return Ir(e,n,o,null);if(i.data==="$!"){if(r=i.nextSibling&&i.nextSibling.dataset,r)var a=r.dgst;return r=a,l=Error(k(419)),r=xl(l,r,void 0),Ir(e,n,o,r)}if(a=(o&e.childLanes)!==0,Ne||a){if(r=se,r!==null){switch(o&-o){case 4:i=2;break;case 16:i=8;break;case 64:case 128:case 256:case 512:case 1024:case 2048:case 4096:case 8192:case 16384:case 32768:case 65536:case 131072:case 262144:case 524288:case 1048576:case 2097152:case 4194304:case 8388608:case 16777216:case 33554432:case 67108864:i=32;break;case 536870912:i=268435456;break;default:i=0}i=i&(r.suspendedLanes|o)?0:i,i!==0&&i!==l.retryLane&&(l.retryLane=i,hn(e,i),Je(r,e,i,-1))}return ca(),r=xl(Error(k(421))),Ir(e,n,o,r)}return i.data==="$?"?(n.flags|=128,n.child=e.child,n=zp.bind(null,e),i._reactRetry=n,null):(e=l.treeContext,Me=Pn(i.nextSibling),De=n,Y=!0,Ze=null,e!==null&&(Be[We++]=cn,Be[We++]=dn,Be[We++]=Xn,cn=e.id,dn=e.overflow,Xn=n),n=ia(n,r.children),n.flags|=4096,n)}function xs(e,n,t){e.lanes|=n;var r=e.alternate;r!==null&&(r.lanes|=n),io(e.return,n,t)}function wl(e,n,t,r,i){var l=e.memoizedState;l===null?e.memoizedState={isBackwards:n,rendering:null,renderingStartTime:0,last:r,tail:t,tailMode:i}:(l.isBackwards=n,l.rendering=null,l.renderingStartTime=0,l.last=r,l.tail=t,l.tailMode=i)}function Tc(e,n,t){var r=n.pendingProps,i=r.revealOrder,l=r.tail;if(Se(e,n,r.children,t),r=Z.current,r&2)r=r&1|2,n.flags|=128;else{if(e!==null&&e.flags&128)e:for(e=n.child;e!==null;){if(e.tag===13)e.memoizedState!==null&&xs(e,t,n);else if(e.tag===19)xs(e,t,n);else if(e.child!==null){e.child.return=e,e=e.child;continue}if(e===n)break e;for(;e.sibling===null;){if(e.return===null||e.return===n)break e;e=e.return}e.sibling.return=e.return,e=e.sibling}r&=1}if(V(Z,r),!(n.mode&1))n.memoizedState=null;else switch(i){case"forwards":for(t=n.child,i=null;t!==null;)e=t.alternate,e!==null&&_i(e)===null&&(i=t),t=t.sibling;t=i,t===null?(i=n.child,n.child=null):(i=t.sibling,t.sibling=null),wl(n,!1,i,t,l);break;case"backwards":for(t=null,i=n.child,n.child=null;i!==null;){if(e=i.alternate,e!==null&&_i(e)===null){n.child=i;break}e=i.sibling,i.sibling=t,t=i,i=e}wl(n,!0,t,null,l);break;case"together":wl(n,!1,null,null,void 0);break;default:n.memoizedState=null}return n.child}function ei(e,n){!(n.mode&1)&&e!==null&&(e.alternate=null,n.alternate=null,n.flags|=2)}function gn(e,n,t){if(e!==null&&(n.dependencies=e.dependencies),Yn|=n.lanes,!(t&n.childLanes))return null;if(e!==null&&n.child!==e.child)throw Error(k(153));if(n.child!==null){for(e=n.child,t=zn(e,e.pendingProps),n.child=t,t.return=n;e.sibling!==null;)e=e.sibling,t=t.sibling=zn(e,e.pendingProps),t.return=n;t.sibling=null}return n.child}function Sp(e,n,t){switch(n.tag){case 3:Pc(n),_t();break;case 5:rc(n);break;case 1:$e(n.type)&&gi(n);break;case 4:Yo(n,n.stateNode.containerInfo);break;case 10:var r=n.type._context,i=n.memoizedProps.value;V(xi,r._currentValue),r._currentValue=i;break;case 13:if(r=n.memoizedState,r!==null)return r.dehydrated!==null?(V(Z,Z.current&1),n.flags|=128,null):t&n.child.childLanes?$c(e,n,t):(V(Z,Z.current&1),e=gn(e,n,t),e!==null?e.sibling:null);V(Z,Z.current&1);break;case 19:if(r=(t&n.childLanes)!==0,e.flags&128){if(r)return Tc(e,n,t);n.flags|=128}if(i=n.memoizedState,i!==null&&(i.rendering=null,i.tail=null,i.lastEffect=null),V(Z,Z.current),r)break;return null;case 22:case 23:return n.lanes=0,Fc(e,n,t)}return gn(e,n,t)}var Rc,po,zc,Lc;Rc=function(e,n){for(var t=n.child;t!==null;){if(t.tag===5||t.tag===6)e.appendChild(t.stateNode);else if(t.tag!==4&&t.child!==null){t.child.return=t,t=t.child;continue}if(t===n)break;for(;t.sibling===null;){if(t.return===null||t.return===n)return;t=t.return}t.sibling.return=t.return,t=t.sibling}};po=function(){};zc=function(e,n,t,r){var i=e.memoizedProps;if(i!==r){e=n.stateNode,Hn(on.current);var l=null;switch(t){case"input":i=Ll(e,i),r=Ll(e,r),l=[];break;case"select":i=J({},i,{value:void 0}),r=J({},r,{value:void 0}),l=[];break;case"textarea":i=jl(e,i),r=jl(e,r),l=[];break;default:typeof i.onClick!="function"&&typeof r.onClick=="function"&&(e.onclick=mi)}Ol(t,r);var o;t=null;for(d in i)if(!r.hasOwnProperty(d)&&i.hasOwnProperty(d)&&i[d]!=null)if(d==="style"){var a=i[d];for(o in a)a.hasOwnProperty(o)&&(t||(t={}),t[o]="")}else d!=="dangerouslySetInnerHTML"&&d!=="children"&&d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&d!=="autoFocus"&&(er.hasOwnProperty(d)?l||(l=[]):(l=l||[]).push(d,null));for(d in r){var u=r[d];if(a=i!=null?i[d]:void 0,r.hasOwnProperty(d)&&u!==a&&(u!=null||a!=null))if(d==="style")if(a){for(o in a)!a.hasOwnProperty(o)||u&&u.hasOwnProperty(o)||(t||(t={}),t[o]="");for(o in u)u.hasOwnProperty(o)&&a[o]!==u[o]&&(t||(t={}),t[o]=u[o])}else t||(l||(l=[]),l.push(d,t)),t=u;else d==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,a=a?a.__html:void 0,u!=null&&a!==u&&(l=l||[]).push(d,u)):d==="children"?typeof u!="string"&&typeof u!="number"||(l=l||[]).push(d,""+u):d!=="suppressContentEditableWarning"&&d!=="suppressHydrationWarning"&&(er.hasOwnProperty(d)?(u!=null&&d==="onScroll"&&G("scroll",e),l||a===u||(l=[])):(l=l||[]).push(d,u))}t&&(l=l||[]).push("style",t);var d=l;(n.updateQueue=d)&&(n.flags|=4)}};Lc=function(e,n,t,r){t!==r&&(n.flags|=4)};function jt(e,n){if(!Y)switch(e.tailMode){case"hidden":n=e.tail;for(var t=null;n!==null;)n.alternate!==null&&(t=n),n=n.sibling;t===null?e.tail=null:t.sibling=null;break;case"collapsed":t=e.tail;for(var r=null;t!==null;)t.alternate!==null&&(r=t),t=t.sibling;r===null?n||e.tail===null?e.tail=null:e.tail.sibling=null:r.sibling=null}}function me(e){var n=e.alternate!==null&&e.alternate.child===e.child,t=0,r=0;if(n)for(var i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags&14680064,r|=i.flags&14680064,i.return=e,i=i.sibling;else for(i=e.child;i!==null;)t|=i.lanes|i.childLanes,r|=i.subtreeFlags,r|=i.flags,i.return=e,i=i.sibling;return e.subtreeFlags|=r,e.childLanes=t,n}function _p(e,n,t){var r=n.pendingProps;switch(Uo(n),n.tag){case 2:case 16:case 15:case 0:case 11:case 7:case 8:case 12:case 9:case 14:return me(n),null;case 1:return $e(n.type)&&hi(),me(n),null;case 3:return r=n.stateNode,bt(),Q(Pe),Q(ge),qo(),r.pendingContext&&(r.context=r.pendingContext,r.pendingContext=null),(e===null||e.child===null)&&(Ar(n)?n.flags|=4:e===null||e.memoizedState.isDehydrated&&!(n.flags&256)||(n.flags|=1024,Ze!==null&&(So(Ze),Ze=null))),po(e,n),me(n),null;case 5:Zo(n);var i=Hn(fr.current);if(t=n.type,e!==null&&n.stateNode!=null)zc(e,n,t,r,i),e.ref!==n.ref&&(n.flags|=512,n.flags|=2097152);else{if(!r){if(n.stateNode===null)throw Error(k(166));return me(n),null}if(e=Hn(on.current),Ar(n)){r=n.stateNode,t=n.type;var l=n.memoizedProps;switch(r[rn]=n,r[cr]=l,e=(n.mode&1)!==0,t){case"dialog":G("cancel",r),G("close",r);break;case"iframe":case"object":case"embed":G("load",r);break;case"video":case"audio":for(i=0;i<Wt.length;i++)G(Wt[i],r);break;case"source":G("error",r);break;case"img":case"image":case"link":G("error",r),G("load",r);break;case"details":G("toggle",r);break;case"input":Na(r,l),G("invalid",r);break;case"select":r._wrapperState={wasMultiple:!!l.multiple},G("invalid",r);break;case"textarea":$a(r,l),G("invalid",r)}Ol(t,l),i=null;for(var o in l)if(l.hasOwnProperty(o)){var a=l[o];o==="children"?typeof a=="string"?r.textContent!==a&&(l.suppressHydrationWarning!==!0&&jr(r.textContent,a,e),i=["children",a]):typeof a=="number"&&r.textContent!==""+a&&(l.suppressHydrationWarning!==!0&&jr(r.textContent,a,e),i=["children",""+a]):er.hasOwnProperty(o)&&a!=null&&o==="onScroll"&&G("scroll",r)}switch(t){case"input":Pr(r),Pa(r,l,!0);break;case"textarea":Pr(r),Ta(r);break;case"select":case"option":break;default:typeof l.onClick=="function"&&(r.onclick=mi)}r=i,n.updateQueue=r,r!==null&&(n.flags|=4)}else{o=i.nodeType===9?i:i.ownerDocument,e==="http://www.w3.org/1999/xhtml"&&(e=su(t)),e==="http://www.w3.org/1999/xhtml"?t==="script"?(e=o.createElement("div"),e.innerHTML="<script><\/script>",e=e.removeChild(e.firstChild)):typeof r.is=="string"?e=o.createElement(t,{is:r.is}):(e=o.createElement(t),t==="select"&&(o=e,r.multiple?o.multiple=!0:r.size&&(o.size=r.size))):e=o.createElementNS(e,t),e[rn]=n,e[cr]=r,Rc(e,n,!1,!1),n.stateNode=e;e:{switch(o=Il(t,r),t){case"dialog":G("cancel",e),G("close",e),i=r;break;case"iframe":case"object":case"embed":G("load",e),i=r;break;case"video":case"audio":for(i=0;i<Wt.length;i++)G(Wt[i],e);i=r;break;case"source":G("error",e),i=r;break;case"img":case"image":case"link":G("error",e),G("load",e),i=r;break;case"details":G("toggle",e),i=r;break;case"input":Na(e,r),i=Ll(e,r),G("invalid",e);break;case"option":i=r;break;case"select":e._wrapperState={wasMultiple:!!r.multiple},i=J({},r,{value:void 0}),G("invalid",e);break;case"textarea":$a(e,r),i=jl(e,r),G("invalid",e);break;default:i=r}Ol(t,i),a=i;for(l in a)if(a.hasOwnProperty(l)){var u=a[l];l==="style"?du(e,u):l==="dangerouslySetInnerHTML"?(u=u?u.__html:void 0,u!=null&&uu(e,u)):l==="children"?typeof u=="string"?(t!=="textarea"||u!=="")&&nr(e,u):typeof u=="number"&&nr(e,""+u):l!=="suppressContentEditableWarning"&&l!=="suppressHydrationWarning"&&l!=="autoFocus"&&(er.hasOwnProperty(l)?u!=null&&l==="onScroll"&&G("scroll",e):u!=null&&No(e,l,u,o))}switch(t){case"input":Pr(e),Pa(e,r,!1);break;case"textarea":Pr(e),Ta(e);break;case"option":r.value!=null&&e.setAttribute("value",""+Mn(r.value));break;case"select":e.multiple=!!r.multiple,l=r.value,l!=null?mt(e,!!r.multiple,l,!1):r.defaultValue!=null&&mt(e,!!r.multiple,r.defaultValue,!0);break;default:typeof i.onClick=="function"&&(e.onclick=mi)}switch(t){case"button":case"input":case"select":case"textarea":r=!!r.autoFocus;break e;case"img":r=!0;break e;default:r=!1}}r&&(n.flags|=4)}n.ref!==null&&(n.flags|=512,n.flags|=2097152)}return me(n),null;case 6:if(e&&n.stateNode!=null)Lc(e,n,e.memoizedProps,r);else{if(typeof r!="string"&&n.stateNode===null)throw Error(k(166));if(t=Hn(fr.current),Hn(on.current),Ar(n)){if(r=n.stateNode,t=n.memoizedProps,r[rn]=n,(l=r.nodeValue!==t)&&(e=De,e!==null))switch(e.tag){case 3:jr(r.nodeValue,t,(e.mode&1)!==0);break;case 5:e.memoizedProps.suppressHydrationWarning!==!0&&jr(r.nodeValue,t,(e.mode&1)!==0)}l&&(n.flags|=4)}else r=(t.nodeType===9?t:t.ownerDocument).createTextNode(r),r[rn]=n,n.stateNode=r}return me(n),null;case 13:if(Q(Z),r=n.memoizedState,e===null||e.memoizedState!==null&&e.memoizedState.dehydrated!==null){if(Y&&Me!==null&&n.mode&1&&!(n.flags&128))qu(),_t(),n.flags|=98560,l=!1;else if(l=Ar(n),r!==null&&r.dehydrated!==null){if(e===null){if(!l)throw Error(k(318));if(l=n.memoizedState,l=l!==null?l.dehydrated:null,!l)throw Error(k(317));l[rn]=n}else _t(),!(n.flags&128)&&(n.memoizedState=null),n.flags|=4;me(n),l=!1}else Ze!==null&&(So(Ze),Ze=null),l=!0;if(!l)return n.flags&65536?n:null}return n.flags&128?(n.lanes=t,n):(r=r!==null,r!==(e!==null&&e.memoizedState!==null)&&r&&(n.child.flags|=8192,n.mode&1&&(e===null||Z.current&1?oe===0&&(oe=3):ca())),n.updateQueue!==null&&(n.flags|=4),me(n),null);case 4:return bt(),po(e,n),e===null&&sr(n.stateNode.containerInfo),me(n),null;case 10:return Qo(n.type._context),me(n),null;case 17:return $e(n.type)&&hi(),me(n),null;case 19:if(Q(Z),l=n.memoizedState,l===null)return me(n),null;if(r=(n.flags&128)!==0,o=l.rendering,o===null)if(r)jt(l,!1);else{if(oe!==0||e!==null&&e.flags&128)for(e=n.child;e!==null;){if(o=_i(e),o!==null){for(n.flags|=128,jt(l,!1),r=o.updateQueue,r!==null&&(n.updateQueue=r,n.flags|=4),n.subtreeFlags=0,r=t,t=n.child;t!==null;)l=t,e=r,l.flags&=14680066,o=l.alternate,o===null?(l.childLanes=0,l.lanes=e,l.child=null,l.subtreeFlags=0,l.memoizedProps=null,l.memoizedState=null,l.updateQueue=null,l.dependencies=null,l.stateNode=null):(l.childLanes=o.childLanes,l.lanes=o.lanes,l.child=o.child,l.subtreeFlags=0,l.deletions=null,l.memoizedProps=o.memoizedProps,l.memoizedState=o.memoizedState,l.updateQueue=o.updateQueue,l.type=o.type,e=o.dependencies,l.dependencies=e===null?null:{lanes:e.lanes,firstContext:e.firstContext}),t=t.sibling;return V(Z,Z.current&1|2),n.child}e=e.sibling}l.tail!==null&&ne()>Ct&&(n.flags|=128,r=!0,jt(l,!1),n.lanes=4194304)}else{if(!r)if(e=_i(o),e!==null){if(n.flags|=128,r=!0,t=e.updateQueue,t!==null&&(n.updateQueue=t,n.flags|=4),jt(l,!0),l.tail===null&&l.tailMode==="hidden"&&!o.alternate&&!Y)return me(n),null}else 2*ne()-l.renderingStartTime>Ct&&t!==1073741824&&(n.flags|=128,r=!0,jt(l,!1),n.lanes=4194304);l.isBackwards?(o.sibling=n.child,n.child=o):(t=l.last,t!==null?t.sibling=o:n.child=o,l.last=o)}return l.tail!==null?(n=l.tail,l.rendering=n,l.tail=n.sibling,l.renderingStartTime=ne(),n.sibling=null,t=Z.current,V(Z,r?t&1|2:t&1),n):(me(n),null);case 22:case 23:return ua(),r=n.memoizedState!==null,e!==null&&e.memoizedState!==null!==r&&(n.flags|=8192),r&&n.mode&1?ze&1073741824&&(me(n),n.subtreeFlags&6&&(n.flags|=8192)):me(n),null;case 24:return null;case 25:return null}throw Error(k(156,n.tag))}function kp(e,n){switch(Uo(n),n.tag){case 1:return $e(n.type)&&hi(),e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 3:return bt(),Q(Pe),Q(ge),qo(),e=n.flags,e&65536&&!(e&128)?(n.flags=e&-65537|128,n):null;case 5:return Zo(n),null;case 13:if(Q(Z),e=n.memoizedState,e!==null&&e.dehydrated!==null){if(n.alternate===null)throw Error(k(340));_t()}return e=n.flags,e&65536?(n.flags=e&-65537|128,n):null;case 19:return Q(Z),null;case 4:return bt(),null;case 10:return Qo(n.type._context),null;case 22:case 23:return ua(),null;case 24:return null;default:return null}}var Br=!1,he=!1,bp=typeof WeakSet=="function"?WeakSet:Set,$=null;function dt(e,n){var t=e.ref;if(t!==null)if(typeof t=="function")try{t(null)}catch(r){ee(e,n,r)}else t.current=null}function mo(e,n,t){try{t()}catch(r){ee(e,n,r)}}var ws=!1;function Ep(e,n){if(Yl=di,e=Ou(),Bo(e)){if("selectionStart"in e)var t={start:e.selectionStart,end:e.selectionEnd};else e:{t=(t=e.ownerDocument)&&t.defaultView||window;var r=t.getSelection&&t.getSelection();if(r&&r.rangeCount!==0){t=r.anchorNode;var i=r.anchorOffset,l=r.focusNode;r=r.focusOffset;try{t.nodeType,l.nodeType}catch{t=null;break e}var o=0,a=-1,u=-1,d=0,g=0,m=e,p=null;n:for(;;){for(var v;m!==t||i!==0&&m.nodeType!==3||(a=o+i),m!==l||r!==0&&m.nodeType!==3||(u=o+r),m.nodeType===3&&(o+=m.nodeValue.length),(v=m.firstChild)!==null;)p=m,m=v;for(;;){if(m===e)break n;if(p===t&&++d===i&&(a=o),p===l&&++g===r&&(u=o),(v=m.nextSibling)!==null)break;m=p,p=m.parentNode}m=v}t=a===-1||u===-1?null:{start:a,end:u}}else t=null}t=t||{start:0,end:0}}else t=null;for(Zl={focusedElem:e,selectionRange:t},di=!1,$=n;$!==null;)if(n=$,e=n.child,(n.subtreeFlags&1028)!==0&&e!==null)e.return=n,$=e;else for(;$!==null;){n=$;try{var w=n.alternate;if(n.flags&1024)switch(n.tag){case 0:case 11:case 15:break;case 1:if(w!==null){var x=w.memoizedProps,L=w.memoizedState,c=n.stateNode,s=c.getSnapshotBeforeUpdate(n.elementType===n.type?x:Ke(n.type,x),L);c.__reactInternalSnapshotBeforeUpdate=s}break;case 3:var f=n.stateNode.containerInfo;f.nodeType===1?f.textContent="":f.nodeType===9&&f.documentElement&&f.removeChild(f.documentElement);break;case 5:case 6:case 4:case 17:break;default:throw Error(k(163))}}catch(h){ee(n,n.return,h)}if(e=n.sibling,e!==null){e.return=n.return,$=e;break}$=n.return}return w=ws,ws=!1,w}function Yt(e,n,t){var r=n.updateQueue;if(r=r!==null?r.lastEffect:null,r!==null){var i=r=r.next;do{if((i.tag&e)===e){var l=i.destroy;i.destroy=void 0,l!==void 0&&mo(n,t,l)}i=i.next}while(i!==r)}}function Ii(e,n){if(n=n.updateQueue,n=n!==null?n.lastEffect:null,n!==null){var t=n=n.next;do{if((t.tag&e)===e){var r=t.create;t.destroy=r()}t=t.next}while(t!==n)}}function ho(e){var n=e.ref;if(n!==null){var t=e.stateNode;switch(e.tag){case 5:e=t;break;default:e=t}typeof n=="function"?n(e):n.current=e}}function Mc(e){var n=e.alternate;n!==null&&(e.alternate=null,Mc(n)),e.child=null,e.deletions=null,e.sibling=null,e.tag===5&&(n=e.stateNode,n!==null&&(delete n[rn],delete n[cr],delete n[eo],delete n[ap],delete n[sp])),e.stateNode=null,e.return=null,e.dependencies=null,e.memoizedProps=null,e.memoizedState=null,e.pendingProps=null,e.stateNode=null,e.updateQueue=null}function Dc(e){return e.tag===5||e.tag===3||e.tag===4}function Ss(e){e:for(;;){for(;e.sibling===null;){if(e.return===null||Dc(e.return))return null;e=e.return}for(e.sibling.return=e.return,e=e.sibling;e.tag!==5&&e.tag!==6&&e.tag!==18;){if(e.flags&2||e.child===null||e.tag===4)continue e;e.child.return=e,e=e.child}if(!(e.flags&2))return e.stateNode}}function go(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.nodeType===8?t.parentNode.insertBefore(e,n):t.insertBefore(e,n):(t.nodeType===8?(n=t.parentNode,n.insertBefore(e,t)):(n=t,n.appendChild(e)),t=t._reactRootContainer,t!=null||n.onclick!==null||(n.onclick=mi));else if(r!==4&&(e=e.child,e!==null))for(go(e,n,t),e=e.sibling;e!==null;)go(e,n,t),e=e.sibling}function vo(e,n,t){var r=e.tag;if(r===5||r===6)e=e.stateNode,n?t.insertBefore(e,n):t.appendChild(e);else if(r!==4&&(e=e.child,e!==null))for(vo(e,n,t),e=e.sibling;e!==null;)vo(e,n,t),e=e.sibling}var ue=null,Ye=!1;function xn(e,n,t){for(t=t.child;t!==null;)jc(e,n,t),t=t.sibling}function jc(e,n,t){if(ln&&typeof ln.onCommitFiberUnmount=="function")try{ln.onCommitFiberUnmount(Ri,t)}catch{}switch(t.tag){case 5:he||dt(t,n);case 6:var r=ue,i=Ye;ue=null,xn(e,n,t),ue=r,Ye=i,ue!==null&&(Ye?(e=ue,t=t.stateNode,e.nodeType===8?e.parentNode.removeChild(t):e.removeChild(t)):ue.removeChild(t.stateNode));break;case 18:ue!==null&&(Ye?(e=ue,t=t.stateNode,e.nodeType===8?pl(e.parentNode,t):e.nodeType===1&&pl(e,t),lr(e)):pl(ue,t.stateNode));break;case 4:r=ue,i=Ye,ue=t.stateNode.containerInfo,Ye=!0,xn(e,n,t),ue=r,Ye=i;break;case 0:case 11:case 14:case 15:if(!he&&(r=t.updateQueue,r!==null&&(r=r.lastEffect,r!==null))){i=r=r.next;do{var l=i,o=l.destroy;l=l.tag,o!==void 0&&(l&2||l&4)&&mo(t,n,o),i=i.next}while(i!==r)}xn(e,n,t);break;case 1:if(!he&&(dt(t,n),r=t.stateNode,typeof r.componentWillUnmount=="function"))try{r.props=t.memoizedProps,r.state=t.memoizedState,r.componentWillUnmount()}catch(a){ee(t,n,a)}xn(e,n,t);break;case 21:xn(e,n,t);break;case 22:t.mode&1?(he=(r=he)||t.memoizedState!==null,xn(e,n,t),he=r):xn(e,n,t);break;default:xn(e,n,t)}}function _s(e){var n=e.updateQueue;if(n!==null){e.updateQueue=null;var t=e.stateNode;t===null&&(t=e.stateNode=new bp),n.forEach(function(r){var i=Lp.bind(null,e,r);t.has(r)||(t.add(r),r.then(i,i))})}}function Xe(e,n){var t=n.deletions;if(t!==null)for(var r=0;r<t.length;r++){var i=t[r];try{var l=e,o=n,a=o;e:for(;a!==null;){switch(a.tag){case 5:ue=a.stateNode,Ye=!1;break e;case 3:ue=a.stateNode.containerInfo,Ye=!0;break e;case 4:ue=a.stateNode.containerInfo,Ye=!0;break e}a=a.return}if(ue===null)throw Error(k(160));jc(l,o,i),ue=null,Ye=!1;var u=i.alternate;u!==null&&(u.return=null),i.return=null}catch(d){ee(i,n,d)}}if(n.subtreeFlags&12854)for(n=n.child;n!==null;)Ac(n,e),n=n.sibling}function Ac(e,n){var t=e.alternate,r=e.flags;switch(e.tag){case 0:case 11:case 14:case 15:if(Xe(n,e),nn(e),r&4){try{Yt(3,e,e.return),Ii(3,e)}catch(x){ee(e,e.return,x)}try{Yt(5,e,e.return)}catch(x){ee(e,e.return,x)}}break;case 1:Xe(n,e),nn(e),r&512&&t!==null&&dt(t,t.return);break;case 5:if(Xe(n,e),nn(e),r&512&&t!==null&&dt(t,t.return),e.flags&32){var i=e.stateNode;try{nr(i,"")}catch(x){ee(e,e.return,x)}}if(r&4&&(i=e.stateNode,i!=null)){var l=e.memoizedProps,o=t!==null?t.memoizedProps:l,a=e.type,u=e.updateQueue;if(e.updateQueue=null,u!==null)try{a==="input"&&l.type==="radio"&&l.name!=null&&ou(i,l),Il(a,o);var d=Il(a,l);for(o=0;o<u.length;o+=2){var g=u[o],m=u[o+1];g==="style"?du(i,m):g==="dangerouslySetInnerHTML"?uu(i,m):g==="children"?nr(i,m):No(i,g,m,d)}switch(a){case"input":Ml(i,l);break;case"textarea":au(i,l);break;case"select":var p=i._wrapperState.wasMultiple;i._wrapperState.wasMultiple=!!l.multiple;var v=l.value;v!=null?mt(i,!!l.multiple,v,!1):p!==!!l.multiple&&(l.defaultValue!=null?mt(i,!!l.multiple,l.defaultValue,!0):mt(i,!!l.multiple,l.multiple?[]:"",!1))}i[cr]=l}catch(x){ee(e,e.return,x)}}break;case 6:if(Xe(n,e),nn(e),r&4){if(e.stateNode===null)throw Error(k(162));i=e.stateNode,l=e.memoizedProps;try{i.nodeValue=l}catch(x){ee(e,e.return,x)}}break;case 3:if(Xe(n,e),nn(e),r&4&&t!==null&&t.memoizedState.isDehydrated)try{lr(n.containerInfo)}catch(x){ee(e,e.return,x)}break;case 4:Xe(n,e),nn(e);break;case 13:Xe(n,e),nn(e),i=e.child,i.flags&8192&&(l=i.memoizedState!==null,i.stateNode.isHidden=l,!l||i.alternate!==null&&i.alternate.memoizedState!==null||(aa=ne())),r&4&&_s(e);break;case 22:if(g=t!==null&&t.memoizedState!==null,e.mode&1?(he=(d=he)||g,Xe(n,e),he=d):Xe(n,e),nn(e),r&8192){if(d=e.memoizedState!==null,(e.stateNode.isHidden=d)&&!g&&e.mode&1)for($=e,g=e.child;g!==null;){for(m=$=g;$!==null;){switch(p=$,v=p.child,p.tag){case 0:case 11:case 14:case 15:Yt(4,p,p.return);break;case 1:dt(p,p.return);var w=p.stateNode;if(typeof w.componentWillUnmount=="function"){r=p,t=p.return;try{n=r,w.props=n.memoizedProps,w.state=n.memoizedState,w.componentWillUnmount()}catch(x){ee(r,t,x)}}break;case 5:dt(p,p.return);break;case 22:if(p.memoizedState!==null){bs(m);continue}}v!==null?(v.return=p,$=v):bs(m)}g=g.sibling}e:for(g=null,m=e;;){if(m.tag===5){if(g===null){g=m;try{i=m.stateNode,d?(l=i.style,typeof l.setProperty=="function"?l.setProperty("display","none","important"):l.display="none"):(a=m.stateNode,u=m.memoizedProps.style,o=u!=null&&u.hasOwnProperty("display")?u.display:null,a.style.display=cu("display",o))}catch(x){ee(e,e.return,x)}}}else if(m.tag===6){if(g===null)try{m.stateNode.nodeValue=d?"":m.memoizedProps}catch(x){ee(e,e.return,x)}}else if((m.tag!==22&&m.tag!==23||m.memoizedState===null||m===e)&&m.child!==null){m.child.return=m,m=m.child;continue}if(m===e)break e;for(;m.sibling===null;){if(m.return===null||m.return===e)break e;g===m&&(g=null),m=m.return}g===m&&(g=null),m.sibling.return=m.return,m=m.sibling}}break;case 19:Xe(n,e),nn(e),r&4&&_s(e);break;case 21:break;default:Xe(n,e),nn(e)}}function nn(e){var n=e.flags;if(n&2){try{e:{for(var t=e.return;t!==null;){if(Dc(t)){var r=t;break e}t=t.return}throw Error(k(160))}switch(r.tag){case 5:var i=r.stateNode;r.flags&32&&(nr(i,""),r.flags&=-33);var l=Ss(e);vo(e,l,i);break;case 3:case 4:var o=r.stateNode.containerInfo,a=Ss(e);go(e,a,o);break;default:throw Error(k(161))}}catch(u){ee(e,e.return,u)}e.flags&=-3}n&4096&&(e.flags&=-4097)}function Cp(e,n,t){$=e,Oc(e)}function Oc(e,n,t){for(var r=(e.mode&1)!==0;$!==null;){var i=$,l=i.child;if(i.tag===22&&r){var o=i.memoizedState!==null||Br;if(!o){var a=i.alternate,u=a!==null&&a.memoizedState!==null||he;a=Br;var d=he;if(Br=o,(he=u)&&!d)for($=i;$!==null;)o=$,u=o.child,o.tag===22&&o.memoizedState!==null?Es(i):u!==null?(u.return=o,$=u):Es(i);for(;l!==null;)$=l,Oc(l),l=l.sibling;$=i,Br=a,he=d}ks(e)}else i.subtreeFlags&8772&&l!==null?(l.return=i,$=l):ks(e)}}function ks(e){for(;$!==null;){var n=$;if(n.flags&8772){var t=n.alternate;try{if(n.flags&8772)switch(n.tag){case 0:case 11:case 15:he||Ii(5,n);break;case 1:var r=n.stateNode;if(n.flags&4&&!he)if(t===null)r.componentDidMount();else{var i=n.elementType===n.type?t.memoizedProps:Ke(n.type,t.memoizedProps);r.componentDidUpdate(i,t.memoizedState,r.__reactInternalSnapshotBeforeUpdate)}var l=n.updateQueue;l!==null&&as(n,l,r);break;case 3:var o=n.updateQueue;if(o!==null){if(t=null,n.child!==null)switch(n.child.tag){case 5:t=n.child.stateNode;break;case 1:t=n.child.stateNode}as(n,o,t)}break;case 5:var a=n.stateNode;if(t===null&&n.flags&4){t=a;var u=n.memoizedProps;switch(n.type){case"button":case"input":case"select":case"textarea":u.autoFocus&&t.focus();break;case"img":u.src&&(t.src=u.src)}}break;case 6:break;case 4:break;case 12:break;case 13:if(n.memoizedState===null){var d=n.alternate;if(d!==null){var g=d.memoizedState;if(g!==null){var m=g.dehydrated;m!==null&&lr(m)}}}break;case 19:case 17:case 21:case 22:case 23:case 25:break;default:throw Error(k(163))}he||n.flags&512&&ho(n)}catch(p){ee(n,n.return,p)}}if(n===e){$=null;break}if(t=n.sibling,t!==null){t.return=n.return,$=t;break}$=n.return}}function bs(e){for(;$!==null;){var n=$;if(n===e){$=null;break}var t=n.sibling;if(t!==null){t.return=n.return,$=t;break}$=n.return}}function Es(e){for(;$!==null;){var n=$;try{switch(n.tag){case 0:case 11:case 15:var t=n.return;try{Ii(4,n)}catch(u){ee(n,t,u)}break;case 1:var r=n.stateNode;if(typeof r.componentDidMount=="function"){var i=n.return;try{r.componentDidMount()}catch(u){ee(n,i,u)}}var l=n.return;try{ho(n)}catch(u){ee(n,l,u)}break;case 5:var o=n.return;try{ho(n)}catch(u){ee(n,o,u)}}}catch(u){ee(n,n.return,u)}if(n===e){$=null;break}var a=n.sibling;if(a!==null){a.return=n.return,$=a;break}$=n.return}}var Fp=Math.ceil,Ei=vn.ReactCurrentDispatcher,la=vn.ReactCurrentOwner,He=vn.ReactCurrentBatchConfig,B=0,se=null,ie=null,ce=0,ze=0,ft=An(0),oe=0,gr=null,Yn=0,Bi=0,oa=0,Zt=null,Fe=null,aa=0,Ct=1/0,sn=null,Ci=!1,yo=null,Tn=null,Wr=!1,En=null,Fi=0,qt=0,xo=null,ni=-1,ti=0;function ke(){return B&6?ne():ni!==-1?ni:ni=ne()}function Rn(e){return e.mode&1?B&2&&ce!==0?ce&-ce:cp.transition!==null?(ti===0&&(ti=ku()),ti):(e=U,e!==0||(e=window.event,e=e===void 0?16:$u(e.type)),e):1}function Je(e,n,t,r){if(50<qt)throw qt=0,xo=null,Error(k(185));xr(e,t,r),(!(B&2)||e!==se)&&(e===se&&(!(B&2)&&(Bi|=t),oe===4&&kn(e,ce)),Te(e,r),t===1&&B===0&&!(n.mode&1)&&(Ct=ne()+500,ji&&On()))}function Te(e,n){var t=e.callbackNode;cf(e,n);var r=ci(e,e===se?ce:0);if(r===0)t!==null&&La(t),e.callbackNode=null,e.callbackPriority=0;else if(n=r&-r,e.callbackPriority!==n){if(t!=null&&La(t),n===1)e.tag===0?up(Cs.bind(null,e)):Ku(Cs.bind(null,e)),lp(function(){!(B&6)&&On()}),t=null;else{switch(bu(r)){case 1:t=zo;break;case 4:t=Su;break;case 16:t=ui;break;case 536870912:t=_u;break;default:t=ui}t=Qc(t,Ic.bind(null,e))}e.callbackPriority=n,e.callbackNode=t}}function Ic(e,n){if(ni=-1,ti=0,B&6)throw Error(k(327));var t=e.callbackNode;if(xt()&&e.callbackNode!==t)return null;var r=ci(e,e===se?ce:0);if(r===0)return null;if(r&30||r&e.expiredLanes||n)n=Ni(e,r);else{n=r;var i=B;B|=2;var l=Wc();(se!==e||ce!==n)&&(sn=null,Ct=ne()+500,Vn(e,n));do try{$p();break}catch(a){Bc(e,a)}while(!0);Go(),Ei.current=l,B=i,ie!==null?n=0:(se=null,ce=0,n=oe)}if(n!==0){if(n===2&&(i=Vl(e),i!==0&&(r=i,n=wo(e,i))),n===1)throw t=gr,Vn(e,0),kn(e,r),Te(e,ne()),t;if(n===6)kn(e,r);else{if(i=e.current.alternate,!(r&30)&&!Np(i)&&(n=Ni(e,r),n===2&&(l=Vl(e),l!==0&&(r=l,n=wo(e,l))),n===1))throw t=gr,Vn(e,0),kn(e,r),Te(e,ne()),t;switch(e.finishedWork=i,e.finishedLanes=r,n){case 0:case 1:throw Error(k(345));case 2:Bn(e,Fe,sn);break;case 3:if(kn(e,r),(r&130023424)===r&&(n=aa+500-ne(),10<n)){if(ci(e,0)!==0)break;if(i=e.suspendedLanes,(i&r)!==r){ke(),e.pingedLanes|=e.suspendedLanes&i;break}e.timeoutHandle=Jl(Bn.bind(null,e,Fe,sn),n);break}Bn(e,Fe,sn);break;case 4:if(kn(e,r),(r&4194240)===r)break;for(n=e.eventTimes,i=-1;0<r;){var o=31-qe(r);l=1<<o,o=n[o],o>i&&(i=o),r&=~l}if(r=i,r=ne()-r,r=(120>r?120:480>r?480:1080>r?1080:1920>r?1920:3e3>r?3e3:4320>r?4320:1960*Fp(r/1960))-r,10<r){e.timeoutHandle=Jl(Bn.bind(null,e,Fe,sn),r);break}Bn(e,Fe,sn);break;case 5:Bn(e,Fe,sn);break;default:throw Error(k(329))}}}return Te(e,ne()),e.callbackNode===t?Ic.bind(null,e):null}function wo(e,n){var t=Zt;return e.current.memoizedState.isDehydrated&&(Vn(e,n).flags|=256),e=Ni(e,n),e!==2&&(n=Fe,Fe=t,n!==null&&So(n)),e}function So(e){Fe===null?Fe=e:Fe.push.apply(Fe,e)}function Np(e){for(var n=e;;){if(n.flags&16384){var t=n.updateQueue;if(t!==null&&(t=t.stores,t!==null))for(var r=0;r<t.length;r++){var i=t[r],l=i.getSnapshot;i=i.value;try{if(!en(l(),i))return!1}catch{return!1}}}if(t=n.child,n.subtreeFlags&16384&&t!==null)t.return=n,n=t;else{if(n===e)break;for(;n.sibling===null;){if(n.return===null||n.return===e)return!0;n=n.return}n.sibling.return=n.return,n=n.sibling}}return!0}function kn(e,n){for(n&=~oa,n&=~Bi,e.suspendedLanes|=n,e.pingedLanes&=~n,e=e.expirationTimes;0<n;){var t=31-qe(n),r=1<<t;e[t]=-1,n&=~r}}function Cs(e){if(B&6)throw Error(k(327));xt();var n=ci(e,0);if(!(n&1))return Te(e,ne()),null;var t=Ni(e,n);if(e.tag!==0&&t===2){var r=Vl(e);r!==0&&(n=r,t=wo(e,r))}if(t===1)throw t=gr,Vn(e,0),kn(e,n),Te(e,ne()),t;if(t===6)throw Error(k(345));return e.finishedWork=e.current.alternate,e.finishedLanes=n,Bn(e,Fe,sn),Te(e,ne()),null}function sa(e,n){var t=B;B|=1;try{return e(n)}finally{B=t,B===0&&(Ct=ne()+500,ji&&On())}}function Zn(e){En!==null&&En.tag===0&&!(B&6)&&xt();var n=B;B|=1;var t=He.transition,r=U;try{if(He.transition=null,U=1,e)return e()}finally{U=r,He.transition=t,B=n,!(B&6)&&On()}}function ua(){ze=ft.current,Q(ft)}function Vn(e,n){e.finishedWork=null,e.finishedLanes=0;var t=e.timeoutHandle;if(t!==-1&&(e.timeoutHandle=-1,ip(t)),ie!==null)for(t=ie.return;t!==null;){var r=t;switch(Uo(r),r.tag){case 1:r=r.type.childContextTypes,r!=null&&hi();break;case 3:bt(),Q(Pe),Q(ge),qo();break;case 5:Zo(r);break;case 4:bt();break;case 13:Q(Z);break;case 19:Q(Z);break;case 10:Qo(r.type._context);break;case 22:case 23:ua()}t=t.return}if(se=e,ie=e=zn(e.current,null),ce=ze=n,oe=0,gr=null,oa=Bi=Yn=0,Fe=Zt=null,Un!==null){for(n=0;n<Un.length;n++)if(t=Un[n],r=t.interleaved,r!==null){t.interleaved=null;var i=r.next,l=t.pending;if(l!==null){var o=l.next;l.next=i,r.next=o}t.pending=r}Un=null}return e}function Bc(e,n){do{var t=ie;try{if(Go(),qr.current=bi,ki){for(var r=q.memoizedState;r!==null;){var i=r.queue;i!==null&&(i.pending=null),r=r.next}ki=!1}if(Kn=0,ae=le=q=null,Kt=!1,pr=0,la.current=null,t===null||t.return===null){oe=1,gr=n,ie=null;break}e:{var l=e,o=t.return,a=t,u=n;if(n=ce,a.flags|=32768,u!==null&&typeof u=="object"&&typeof u.then=="function"){var d=u,g=a,m=g.tag;if(!(g.mode&1)&&(m===0||m===11||m===15)){var p=g.alternate;p?(g.updateQueue=p.updateQueue,g.memoizedState=p.memoizedState,g.lanes=p.lanes):(g.updateQueue=null,g.memoizedState=null)}var v=ps(o);if(v!==null){v.flags&=-257,ms(v,o,a,l,n),v.mode&1&&fs(l,d,n),n=v,u=d;var w=n.updateQueue;if(w===null){var x=new Set;x.add(u),n.updateQueue=x}else w.add(u);break e}else{if(!(n&1)){fs(l,d,n),ca();break e}u=Error(k(426))}}else if(Y&&a.mode&1){var L=ps(o);if(L!==null){!(L.flags&65536)&&(L.flags|=256),ms(L,o,a,l,n),Ho(Et(u,a));break e}}l=u=Et(u,a),oe!==4&&(oe=2),Zt===null?Zt=[l]:Zt.push(l),l=o;do{switch(l.tag){case 3:l.flags|=65536,n&=-n,l.lanes|=n;var c=bc(l,u,n);os(l,c);break e;case 1:a=u;var s=l.type,f=l.stateNode;if(!(l.flags&128)&&(typeof s.getDerivedStateFromError=="function"||f!==null&&typeof f.componentDidCatch=="function"&&(Tn===null||!Tn.has(f)))){l.flags|=65536,n&=-n,l.lanes|=n;var h=Ec(l,a,n);os(l,h);break e}}l=l.return}while(l!==null)}Hc(t)}catch(S){n=S,ie===t&&t!==null&&(ie=t=t.return);continue}break}while(!0)}function Wc(){var e=Ei.current;return Ei.current=bi,e===null?bi:e}function ca(){(oe===0||oe===3||oe===2)&&(oe=4),se===null||!(Yn&268435455)&&!(Bi&268435455)||kn(se,ce)}function Ni(e,n){var t=B;B|=2;var r=Wc();(se!==e||ce!==n)&&(sn=null,Vn(e,n));do try{Pp();break}catch(i){Bc(e,i)}while(!0);if(Go(),B=t,Ei.current=r,ie!==null)throw Error(k(261));return se=null,ce=0,oe}function Pp(){for(;ie!==null;)Uc(ie)}function $p(){for(;ie!==null&&!ef();)Uc(ie)}function Uc(e){var n=Gc(e.alternate,e,ze);e.memoizedProps=e.pendingProps,n===null?Hc(e):ie=n,la.current=null}function Hc(e){var n=e;do{var t=n.alternate;if(e=n.return,n.flags&32768){if(t=kp(t,n),t!==null){t.flags&=32767,ie=t;return}if(e!==null)e.flags|=32768,e.subtreeFlags=0,e.deletions=null;else{oe=6,ie=null;return}}else if(t=_p(t,n,ze),t!==null){ie=t;return}if(n=n.sibling,n!==null){ie=n;return}ie=n=e}while(n!==null);oe===0&&(oe=5)}function Bn(e,n,t){var r=U,i=He.transition;try{He.transition=null,U=1,Tp(e,n,t,r)}finally{He.transition=i,U=r}return null}function Tp(e,n,t,r){do xt();while(En!==null);if(B&6)throw Error(k(327));t=e.finishedWork;var i=e.finishedLanes;if(t===null)return null;if(e.finishedWork=null,e.finishedLanes=0,t===e.current)throw Error(k(177));e.callbackNode=null,e.callbackPriority=0;var l=t.lanes|t.childLanes;if(df(e,l),e===se&&(ie=se=null,ce=0),!(t.subtreeFlags&2064)&&!(t.flags&2064)||Wr||(Wr=!0,Qc(ui,function(){return xt(),null})),l=(t.flags&15990)!==0,t.subtreeFlags&15990||l){l=He.transition,He.transition=null;var o=U;U=1;var a=B;B|=4,la.current=null,Ep(e,t),Ac(t,e),Zf(Zl),di=!!Yl,Zl=Yl=null,e.current=t,Cp(t),nf(),B=a,U=o,He.transition=l}else e.current=t;if(Wr&&(Wr=!1,En=e,Fi=i),l=e.pendingLanes,l===0&&(Tn=null),lf(t.stateNode),Te(e,ne()),n!==null)for(r=e.onRecoverableError,t=0;t<n.length;t++)i=n[t],r(i.value,{componentStack:i.stack,digest:i.digest});if(Ci)throw Ci=!1,e=yo,yo=null,e;return Fi&1&&e.tag!==0&&xt(),l=e.pendingLanes,l&1?e===xo?qt++:(qt=0,xo=e):qt=0,On(),null}function xt(){if(En!==null){var e=bu(Fi),n=He.transition,t=U;try{if(He.transition=null,U=16>e?16:e,En===null)var r=!1;else{if(e=En,En=null,Fi=0,B&6)throw Error(k(331));var i=B;for(B|=4,$=e.current;$!==null;){var l=$,o=l.child;if($.flags&16){var a=l.deletions;if(a!==null){for(var u=0;u<a.length;u++){var d=a[u];for($=d;$!==null;){var g=$;switch(g.tag){case 0:case 11:case 15:Yt(8,g,l)}var m=g.child;if(m!==null)m.return=g,$=m;else for(;$!==null;){g=$;var p=g.sibling,v=g.return;if(Mc(g),g===d){$=null;break}if(p!==null){p.return=v,$=p;break}$=v}}}var w=l.alternate;if(w!==null){var x=w.child;if(x!==null){w.child=null;do{var L=x.sibling;x.sibling=null,x=L}while(x!==null)}}$=l}}if(l.subtreeFlags&2064&&o!==null)o.return=l,$=o;else e:for(;$!==null;){if(l=$,l.flags&2048)switch(l.tag){case 0:case 11:case 15:Yt(9,l,l.return)}var c=l.sibling;if(c!==null){c.return=l.return,$=c;break e}$=l.return}}var s=e.current;for($=s;$!==null;){o=$;var f=o.child;if(o.subtreeFlags&2064&&f!==null)f.return=o,$=f;else e:for(o=s;$!==null;){if(a=$,a.flags&2048)try{switch(a.tag){case 0:case 11:case 15:Ii(9,a)}}catch(S){ee(a,a.return,S)}if(a===o){$=null;break e}var h=a.sibling;if(h!==null){h.return=a.return,$=h;break e}$=a.return}}if(B=i,On(),ln&&typeof ln.onPostCommitFiberRoot=="function")try{ln.onPostCommitFiberRoot(Ri,e)}catch{}r=!0}return r}finally{U=t,He.transition=n}}return!1}function Fs(e,n,t){n=Et(t,n),n=bc(e,n,1),e=$n(e,n,1),n=ke(),e!==null&&(xr(e,1,n),Te(e,n))}function ee(e,n,t){if(e.tag===3)Fs(e,e,t);else for(;n!==null;){if(n.tag===3){Fs(n,e,t);break}else if(n.tag===1){var r=n.stateNode;if(typeof n.type.getDerivedStateFromError=="function"||typeof r.componentDidCatch=="function"&&(Tn===null||!Tn.has(r))){e=Et(t,e),e=Ec(n,e,1),n=$n(n,e,1),e=ke(),n!==null&&(xr(n,1,e),Te(n,e));break}}n=n.return}}function Rp(e,n,t){var r=e.pingCache;r!==null&&r.delete(n),n=ke(),e.pingedLanes|=e.suspendedLanes&t,se===e&&(ce&t)===t&&(oe===4||oe===3&&(ce&130023424)===ce&&500>ne()-aa?Vn(e,0):oa|=t),Te(e,n)}function Vc(e,n){n===0&&(e.mode&1?(n=Rr,Rr<<=1,!(Rr&130023424)&&(Rr=4194304)):n=1);var t=ke();e=hn(e,n),e!==null&&(xr(e,n,t),Te(e,t))}function zp(e){var n=e.memoizedState,t=0;n!==null&&(t=n.retryLane),Vc(e,t)}function Lp(e,n){var t=0;switch(e.tag){case 13:var r=e.stateNode,i=e.memoizedState;i!==null&&(t=i.retryLane);break;case 19:r=e.stateNode;break;default:throw Error(k(314))}r!==null&&r.delete(n),Vc(e,t)}var Gc;Gc=function(e,n,t){if(e!==null)if(e.memoizedProps!==n.pendingProps||Pe.current)Ne=!0;else{if(!(e.lanes&t)&&!(n.flags&128))return Ne=!1,Sp(e,n,t);Ne=!!(e.flags&131072)}else Ne=!1,Y&&n.flags&1048576&&Yu(n,yi,n.index);switch(n.lanes=0,n.tag){case 2:var r=n.type;ei(e,n),e=n.pendingProps;var i=St(n,ge.current);yt(n,t),i=ea(null,n,r,e,i,t);var l=na();return n.flags|=1,typeof i=="object"&&i!==null&&typeof i.render=="function"&&i.$$typeof===void 0?(n.tag=1,n.memoizedState=null,n.updateQueue=null,$e(r)?(l=!0,gi(n)):l=!1,n.memoizedState=i.state!==null&&i.state!==void 0?i.state:null,Ko(n),i.updater=Oi,n.stateNode=i,i._reactInternals=n,oo(n,r,e,t),n=uo(null,n,r,!0,l,t)):(n.tag=0,Y&&l&&Wo(n),Se(null,n,i,t),n=n.child),n;case 16:r=n.elementType;e:{switch(ei(e,n),e=n.pendingProps,i=r._init,r=i(r._payload),n.type=r,i=n.tag=Dp(r),e=Ke(r,e),i){case 0:n=so(null,n,r,e,t);break e;case 1:n=vs(null,n,r,e,t);break e;case 11:n=hs(null,n,r,e,t);break e;case 14:n=gs(null,n,r,Ke(r.type,e),t);break e}throw Error(k(306,r,""))}return n;case 0:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ke(r,i),so(e,n,r,i,t);case 1:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ke(r,i),vs(e,n,r,i,t);case 3:e:{if(Pc(n),e===null)throw Error(k(387));r=n.pendingProps,l=n.memoizedState,i=l.element,tc(e,n),Si(n,r,null,t);var o=n.memoizedState;if(r=o.element,l.isDehydrated)if(l={element:r,isDehydrated:!1,cache:o.cache,pendingSuspenseBoundaries:o.pendingSuspenseBoundaries,transitions:o.transitions},n.updateQueue.baseState=l,n.memoizedState=l,n.flags&256){i=Et(Error(k(423)),n),n=ys(e,n,r,t,i);break e}else if(r!==i){i=Et(Error(k(424)),n),n=ys(e,n,r,t,i);break e}else for(Me=Pn(n.stateNode.containerInfo.firstChild),De=n,Y=!0,Ze=null,t=ec(n,null,r,t),n.child=t;t;)t.flags=t.flags&-3|4096,t=t.sibling;else{if(_t(),r===i){n=gn(e,n,t);break e}Se(e,n,r,t)}n=n.child}return n;case 5:return rc(n),e===null&&ro(n),r=n.type,i=n.pendingProps,l=e!==null?e.memoizedProps:null,o=i.children,ql(r,i)?o=null:l!==null&&ql(r,l)&&(n.flags|=32),Nc(e,n),Se(e,n,o,t),n.child;case 6:return e===null&&ro(n),null;case 13:return $c(e,n,t);case 4:return Yo(n,n.stateNode.containerInfo),r=n.pendingProps,e===null?n.child=kt(n,null,r,t):Se(e,n,r,t),n.child;case 11:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ke(r,i),hs(e,n,r,i,t);case 7:return Se(e,n,n.pendingProps,t),n.child;case 8:return Se(e,n,n.pendingProps.children,t),n.child;case 12:return Se(e,n,n.pendingProps.children,t),n.child;case 10:e:{if(r=n.type._context,i=n.pendingProps,l=n.memoizedProps,o=i.value,V(xi,r._currentValue),r._currentValue=o,l!==null)if(en(l.value,o)){if(l.children===i.children&&!Pe.current){n=gn(e,n,t);break e}}else for(l=n.child,l!==null&&(l.return=n);l!==null;){var a=l.dependencies;if(a!==null){o=l.child;for(var u=a.firstContext;u!==null;){if(u.context===r){if(l.tag===1){u=fn(-1,t&-t),u.tag=2;var d=l.updateQueue;if(d!==null){d=d.shared;var g=d.pending;g===null?u.next=u:(u.next=g.next,g.next=u),d.pending=u}}l.lanes|=t,u=l.alternate,u!==null&&(u.lanes|=t),io(l.return,t,n),a.lanes|=t;break}u=u.next}}else if(l.tag===10)o=l.type===n.type?null:l.child;else if(l.tag===18){if(o=l.return,o===null)throw Error(k(341));o.lanes|=t,a=o.alternate,a!==null&&(a.lanes|=t),io(o,t,n),o=l.sibling}else o=l.child;if(o!==null)o.return=l;else for(o=l;o!==null;){if(o===n){o=null;break}if(l=o.sibling,l!==null){l.return=o.return,o=l;break}o=o.return}l=o}Se(e,n,i.children,t),n=n.child}return n;case 9:return i=n.type,r=n.pendingProps.children,yt(n,t),i=Ve(i),r=r(i),n.flags|=1,Se(e,n,r,t),n.child;case 14:return r=n.type,i=Ke(r,n.pendingProps),i=Ke(r.type,i),gs(e,n,r,i,t);case 15:return Cc(e,n,n.type,n.pendingProps,t);case 17:return r=n.type,i=n.pendingProps,i=n.elementType===r?i:Ke(r,i),ei(e,n),n.tag=1,$e(r)?(e=!0,gi(n)):e=!1,yt(n,t),kc(n,r,i),oo(n,r,i,t),uo(null,n,r,!0,e,t);case 19:return Tc(e,n,t);case 22:return Fc(e,n,t)}throw Error(k(156,n.tag))};function Qc(e,n){return wu(e,n)}function Mp(e,n,t,r){this.tag=e,this.key=t,this.sibling=this.child=this.return=this.stateNode=this.type=this.elementType=null,this.index=0,this.ref=null,this.pendingProps=n,this.dependencies=this.memoizedState=this.updateQueue=this.memoizedProps=null,this.mode=r,this.subtreeFlags=this.flags=0,this.deletions=null,this.childLanes=this.lanes=0,this.alternate=null}function Ue(e,n,t,r){return new Mp(e,n,t,r)}function da(e){return e=e.prototype,!(!e||!e.isReactComponent)}function Dp(e){if(typeof e=="function")return da(e)?1:0;if(e!=null){if(e=e.$$typeof,e===$o)return 11;if(e===To)return 14}return 2}function zn(e,n){var t=e.alternate;return t===null?(t=Ue(e.tag,n,e.key,e.mode),t.elementType=e.elementType,t.type=e.type,t.stateNode=e.stateNode,t.alternate=e,e.alternate=t):(t.pendingProps=n,t.type=e.type,t.flags=0,t.subtreeFlags=0,t.deletions=null),t.flags=e.flags&14680064,t.childLanes=e.childLanes,t.lanes=e.lanes,t.child=e.child,t.memoizedProps=e.memoizedProps,t.memoizedState=e.memoizedState,t.updateQueue=e.updateQueue,n=e.dependencies,t.dependencies=n===null?null:{lanes:n.lanes,firstContext:n.firstContext},t.sibling=e.sibling,t.index=e.index,t.ref=e.ref,t}function ri(e,n,t,r,i,l){var o=2;if(r=e,typeof e=="function")da(e)&&(o=1);else if(typeof e=="string")o=5;else e:switch(e){case tt:return Gn(t.children,i,l,n);case Po:o=8,i|=8;break;case $l:return e=Ue(12,t,n,i|2),e.elementType=$l,e.lanes=l,e;case Tl:return e=Ue(13,t,n,i),e.elementType=Tl,e.lanes=l,e;case Rl:return e=Ue(19,t,n,i),e.elementType=Rl,e.lanes=l,e;case ru:return Wi(t,i,l,n);default:if(typeof e=="object"&&e!==null)switch(e.$$typeof){case nu:o=10;break e;case tu:o=9;break e;case $o:o=11;break e;case To:o=14;break e;case wn:o=16,r=null;break e}throw Error(k(130,e==null?e:typeof e,""))}return n=Ue(o,t,n,i),n.elementType=e,n.type=r,n.lanes=l,n}function Gn(e,n,t,r){return e=Ue(7,e,r,n),e.lanes=t,e}function Wi(e,n,t,r){return e=Ue(22,e,r,n),e.elementType=ru,e.lanes=t,e.stateNode={isHidden:!1},e}function Sl(e,n,t){return e=Ue(6,e,null,n),e.lanes=t,e}function _l(e,n,t){return n=Ue(4,e.children!==null?e.children:[],e.key,n),n.lanes=t,n.stateNode={containerInfo:e.containerInfo,pendingChildren:null,implementation:e.implementation},n}function jp(e,n,t,r,i){this.tag=n,this.containerInfo=e,this.finishedWork=this.pingCache=this.current=this.pendingChildren=null,this.timeoutHandle=-1,this.callbackNode=this.pendingContext=this.context=null,this.callbackPriority=0,this.eventTimes=tl(0),this.expirationTimes=tl(-1),this.entangledLanes=this.finishedLanes=this.mutableReadLanes=this.expiredLanes=this.pingedLanes=this.suspendedLanes=this.pendingLanes=0,this.entanglements=tl(0),this.identifierPrefix=r,this.onRecoverableError=i,this.mutableSourceEagerHydrationData=null}function fa(e,n,t,r,i,l,o,a,u){return e=new jp(e,n,t,a,u),n===1?(n=1,l===!0&&(n|=8)):n=0,l=Ue(3,null,null,n),e.current=l,l.stateNode=e,l.memoizedState={element:r,isDehydrated:t,cache:null,transitions:null,pendingSuspenseBoundaries:null},Ko(l),e}function Ap(e,n,t){var r=3<arguments.length&&arguments[3]!==void 0?arguments[3]:null;return{$$typeof:nt,key:r==null?null:""+r,children:e,containerInfo:n,implementation:t}}function Xc(e){if(!e)return Dn;e=e._reactInternals;e:{if(Jn(e)!==e||e.tag!==1)throw Error(k(170));var n=e;do{switch(n.tag){case 3:n=n.stateNode.context;break e;case 1:if($e(n.type)){n=n.stateNode.__reactInternalMemoizedMergedChildContext;break e}}n=n.return}while(n!==null);throw Error(k(171))}if(e.tag===1){var t=e.type;if($e(t))return Xu(e,t,n)}return n}function Kc(e,n,t,r,i,l,o,a,u){return e=fa(t,r,!0,e,i,l,o,a,u),e.context=Xc(null),t=e.current,r=ke(),i=Rn(t),l=fn(r,i),l.callback=n??null,$n(t,l,i),e.current.lanes=i,xr(e,i,r),Te(e,r),e}function Ui(e,n,t,r){var i=n.current,l=ke(),o=Rn(i);return t=Xc(t),n.context===null?n.context=t:n.pendingContext=t,n=fn(l,o),n.payload={element:e},r=r===void 0?null:r,r!==null&&(n.callback=r),e=$n(i,n,o),e!==null&&(Je(e,i,o,l),Zr(e,i,o)),o}function Pi(e){if(e=e.current,!e.child)return null;switch(e.child.tag){case 5:return e.child.stateNode;default:return e.child.stateNode}}function Ns(e,n){if(e=e.memoizedState,e!==null&&e.dehydrated!==null){var t=e.retryLane;e.retryLane=t!==0&&t<n?t:n}}function pa(e,n){Ns(e,n),(e=e.alternate)&&Ns(e,n)}function Op(){return null}var Yc=typeof reportError=="function"?reportError:function(e){console.error(e)};function ma(e){this._internalRoot=e}Hi.prototype.render=ma.prototype.render=function(e){var n=this._internalRoot;if(n===null)throw Error(k(409));Ui(e,n,null,null)};Hi.prototype.unmount=ma.prototype.unmount=function(){var e=this._internalRoot;if(e!==null){this._internalRoot=null;var n=e.containerInfo;Zn(function(){Ui(null,e,null,null)}),n[mn]=null}};function Hi(e){this._internalRoot=e}Hi.prototype.unstable_scheduleHydration=function(e){if(e){var n=Fu();e={blockedOn:null,target:e,priority:n};for(var t=0;t<_n.length&&n!==0&&n<_n[t].priority;t++);_n.splice(t,0,e),t===0&&Pu(e)}};function ha(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11)}function Vi(e){return!(!e||e.nodeType!==1&&e.nodeType!==9&&e.nodeType!==11&&(e.nodeType!==8||e.nodeValue!==" react-mount-point-unstable "))}function Ps(){}function Ip(e,n,t,r,i){if(i){if(typeof r=="function"){var l=r;r=function(){var d=Pi(o);l.call(d)}}var o=Kc(n,r,e,0,null,!1,!1,"",Ps);return e._reactRootContainer=o,e[mn]=o.current,sr(e.nodeType===8?e.parentNode:e),Zn(),o}for(;i=e.lastChild;)e.removeChild(i);if(typeof r=="function"){var a=r;r=function(){var d=Pi(u);a.call(d)}}var u=fa(e,0,!1,null,null,!1,!1,"",Ps);return e._reactRootContainer=u,e[mn]=u.current,sr(e.nodeType===8?e.parentNode:e),Zn(function(){Ui(n,u,t,r)}),u}function Gi(e,n,t,r,i){var l=t._reactRootContainer;if(l){var o=l;if(typeof i=="function"){var a=i;i=function(){var u=Pi(o);a.call(u)}}Ui(n,o,e,i)}else o=Ip(t,n,e,i,r);return Pi(o)}Eu=function(e){switch(e.tag){case 3:var n=e.stateNode;if(n.current.memoizedState.isDehydrated){var t=Bt(n.pendingLanes);t!==0&&(Lo(n,t|1),Te(n,ne()),!(B&6)&&(Ct=ne()+500,On()))}break;case 13:Zn(function(){var r=hn(e,1);if(r!==null){var i=ke();Je(r,e,1,i)}}),pa(e,1)}};Mo=function(e){if(e.tag===13){var n=hn(e,134217728);if(n!==null){var t=ke();Je(n,e,134217728,t)}pa(e,134217728)}};Cu=function(e){if(e.tag===13){var n=Rn(e),t=hn(e,n);if(t!==null){var r=ke();Je(t,e,n,r)}pa(e,n)}};Fu=function(){return U};Nu=function(e,n){var t=U;try{return U=e,n()}finally{U=t}};Wl=function(e,n,t){switch(n){case"input":if(Ml(e,t),n=t.name,t.type==="radio"&&n!=null){for(t=e;t.parentNode;)t=t.parentNode;for(t=t.querySelectorAll("input[name="+JSON.stringify(""+n)+'][type="radio"]'),n=0;n<t.length;n++){var r=t[n];if(r!==e&&r.form===e.form){var i=Di(r);if(!i)throw Error(k(90));lu(r),Ml(r,i)}}}break;case"textarea":au(e,t);break;case"select":n=t.value,n!=null&&mt(e,!!t.multiple,n,!1)}};mu=sa;hu=Zn;var Bp={usingClientEntryPoint:!1,Events:[Sr,ot,Di,fu,pu,sa]},At={findFiberByHostInstance:Wn,bundleType:0,version:"18.3.1",rendererPackageName:"react-dom"},Wp={bundleType:At.bundleType,version:At.version,rendererPackageName:At.rendererPackageName,rendererConfig:At.rendererConfig,overrideHookState:null,overrideHookStateDeletePath:null,overrideHookStateRenamePath:null,overrideProps:null,overridePropsDeletePath:null,overridePropsRenamePath:null,setErrorHandler:null,setSuspenseHandler:null,scheduleUpdate:null,currentDispatcherRef:vn.ReactCurrentDispatcher,findHostInstanceByFiber:function(e){return e=yu(e),e===null?null:e.stateNode},findFiberByHostInstance:At.findFiberByHostInstance||Op,findHostInstancesForRefresh:null,scheduleRefresh:null,scheduleRoot:null,setRefreshHandler:null,getCurrentFiber:null,reconcilerVersion:"18.3.1-next-f1338f8080-20240426"};if(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__<"u"){var Ur=__REACT_DEVTOOLS_GLOBAL_HOOK__;if(!Ur.isDisabled&&Ur.supportsFiber)try{Ri=Ur.inject(Wp),ln=Ur}catch{}}Ae.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED=Bp;Ae.createPortal=function(e,n){var t=2<arguments.length&&arguments[2]!==void 0?arguments[2]:null;if(!ha(n))throw Error(k(200));return Ap(e,n,null,t)};Ae.createRoot=function(e,n){if(!ha(e))throw Error(k(299));var t=!1,r="",i=Yc;return n!=null&&(n.unstable_strictMode===!0&&(t=!0),n.identifierPrefix!==void 0&&(r=n.identifierPrefix),n.onRecoverableError!==void 0&&(i=n.onRecoverableError)),n=fa(e,1,!1,null,null,t,!1,r,i),e[mn]=n.current,sr(e.nodeType===8?e.parentNode:e),new ma(n)};Ae.findDOMNode=function(e){if(e==null)return null;if(e.nodeType===1)return e;var n=e._reactInternals;if(n===void 0)throw typeof e.render=="function"?Error(k(188)):(e=Object.keys(e).join(","),Error(k(268,e)));return e=yu(n),e=e===null?null:e.stateNode,e};Ae.flushSync=function(e){return Zn(e)};Ae.hydrate=function(e,n,t){if(!Vi(n))throw Error(k(200));return Gi(null,e,n,!0,t)};Ae.hydrateRoot=function(e,n,t){if(!ha(e))throw Error(k(405));var r=t!=null&&t.hydratedSources||null,i=!1,l="",o=Yc;if(t!=null&&(t.unstable_strictMode===!0&&(i=!0),t.identifierPrefix!==void 0&&(l=t.identifierPrefix),t.onRecoverableError!==void 0&&(o=t.onRecoverableError)),n=Kc(n,null,e,1,t??null,i,!1,l,o),e[mn]=n.current,sr(e),r)for(e=0;e<r.length;e++)t=r[e],i=t._getVersion,i=i(t._source),n.mutableSourceEagerHydrationData==null?n.mutableSourceEagerHydrationData=[t,i]:n.mutableSourceEagerHydrationData.push(t,i);return new Hi(n)};Ae.render=function(e,n,t){if(!Vi(n))throw Error(k(200));return Gi(null,e,n,!1,t)};Ae.unmountComponentAtNode=function(e){if(!Vi(e))throw Error(k(40));return e._reactRootContainer?(Zn(function(){Gi(null,null,e,!1,function(){e._reactRootContainer=null,e[mn]=null})}),!0):!1};Ae.unstable_batchedUpdates=sa;Ae.unstable_renderSubtreeIntoContainer=function(e,n,t,r){if(!Vi(t))throw Error(k(200));if(e==null||e._reactInternals===void 0)throw Error(k(38));return Gi(e,n,t,!1,r)};Ae.version="18.3.1-next-f1338f8080-20240426";function Zc(){if(!(typeof __REACT_DEVTOOLS_GLOBAL_HOOK__>"u"||typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE!="function"))try{__REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(Zc)}catch(e){console.error(e)}}Zc(),Zs.exports=Ae;var Up=Zs.exports,$s=Up;Nl.createRoot=$s.createRoot,Nl.hydrateRoot=$s.hydrateRoot;const Hp=`version: 0.3

relativeLayouts {
    #statesDropdowns sequence($i:0..10) point: 60 + $i * 150, 5
    #animGrid sequence($i:0..100) point: 80 + (($i % 8) * 150), 120 + (($i div 8) * 120)
}

#ui programmable() {
    // Title
    text(dd, "Animation Viewer", #ffffff, left, 400): 10, 5

    // Load button
    placeholder(generated(cross(80, 25)), builderParameter("load")): 1100, 5

    // Speed slider
    placeholder(generated(cross(150, 20)), builderParameter("speedSlider")) {
        pos: 750, 10
        text(m6x11, "Speed", #ffffffff): 0, -15
    }

    // Scale slider
    placeholder(generated(cross(150, 20)), builderParameter("scaleSlider")) {
        pos: 920, 10
        text(m6x11, "Scale", #ffffffff): 0, -15
    }

    // Separator line
    graphics (
        line(#555555, 1, 0, 0, 1260, 0);
    ): 10, 45

    // Instructions
    text(m6x11, "Select state values to change all animations. Click Load to switch .anim files.", #888888, left, 600): 10, 55
}
`,Vp=`version: 0.3

#atlasGrid programmable(columns:int=8, sheetName="", sheetLength:int, tileWidth:int=120, tileHeight:int=80, indexY:int) {
  // Use "ui" or "fx" for sheetName to see the difference
  @(sheetName=>crew2) repeatable($index, step($sheetLength, dx:0)) {
          pos: 5, 20

          @alpha(0.9) text(default, "sheet:" + $sheetName + ' yindex \${$indexY}', white, left, 200):10,-20
          bitmap(sheet($sheetName, callback($sheetName, $index))) {
            pos: ($index % $columns)*$tileWidth, ($index div $columns) * $tileHeight
            @alpha(0.9) text(f7x5, callback($sheetName, $index),  white, left, 200):0,40
          }
        }
}

  `,Gp=`version: 0.3

// Autotile Example
// Autotiles are root-level elements used for procedural terrain generation.
// They are built using MultiAnimBuilder.buildAutotile(name, grid) which returns a TileGroup.

// Cross format: 13 tiles for standard terrain
// Tile layout: 0=N, 1=W, 2=C, 3=E, 4=S, 5-8=outer corners, 9-12=inner corners
#grassPath autotile {
    format: cross
    sheet: "terrain"
    prefix: "grass_"
    tileSize: 16
}

// Cross format: For isometric elevation tiles with depth
// Tile layout: 0=N, 1=W, 2=C, 3=E, 4=S, 5-8=outer corners, 9-12=inner corners
#elevation autotile {
    format: cross
    file: "elevation.png"
    tileSize: 16
    depth: 8
}

// Blob47 format: Full 47-tile autotile with all edge/corner combinations
// Uses 8-direction neighbor detection for seamless transitions
#riverBank autotile {
    format: blob47
    sheet: "terrain"
    prefix: "river_"
    tileSize: 16
}

// With custom mapping: Remap tile indices if your tileset uses a different order
#customTerrain autotile {
    format: cross
    sheet: "terrain"
    prefix: "custom_"
    tileSize: 16
    mapping: [4, 1, 5, 3, 0, 2, 7, 8, 6, 9, 10, 11, 12]
}

// Region-based: Extract tiles from a specific region of an image
#regionTerrain autotile {
    format: cross
    sheet: "tileset.png"
    region: [0, 64, 64, 64]
    tileSize: 16
}

// Explicit tiles: Full control over each tile source
// Each tile can be from different sheets, files, or generated
// Cross layout: 0=N, 1=W, 2=C, 3=E, 4=S, 5=NW, 6=NE, 7=SW, 8=SE, 9-12=inner
#explicitTiles autotile {
    format: cross
    tileSize: 16
    tiles:
        sheet("terrain", "grass_n") sheet("terrain", "grass_w") sheet("terrain", "grass_c")
        sheet("terrain", "grass_e") sheet("terrain", "grass_s")
        sheet("terrain", "grass_nw") sheet("terrain", "grass_ne")
        sheet("terrain", "grass_sw") sheet("terrain", "grass_se")
        sheet("terrain", "grass_inner_ne") sheet("terrain", "grass_inner_nw")
        sheet("terrain", "grass_inner_se") sheet("terrain", "grass_inner_sw")
}

// Generated tiles: For testing/prototyping without assets (manual method)
// Cross layout: 0=N, 1=W, 2=C, 3=E, 4=S, 5=NW, 6=NE, 7=SW, 8=SE, 9-12=inner
#generatedDemo autotile {
    format: cross
    tileSize: 16
    tiles:
        generated(color(16, 16, 0xFF9955))   // 0: N edge
        generated(color(16, 16, 0xFFBB77))   // 1: W edge
        generated(color(16, 16, 0x44AA44))   // 2: C (center - green)
        generated(color(16, 16, 0xFFDD99))   // 3: E edge
        generated(color(16, 16, 0xFFFFBB))   // 4: S edge
        generated(color(16, 16, 0xFF8844))   // 5: NW outer corner
        generated(color(16, 16, 0xFFAA66))   // 6: NE outer corner
        generated(color(16, 16, 0xFFEEAA))   // 7: SW outer corner
        generated(color(16, 16, 0xEEEECC))   // 8: SE outer corner
        generated(color(16, 16, 0x66CC66))   // 9: inner NE
        generated(color(16, 16, 0x77DD77))   // 10: inner NW
        generated(color(16, 16, 0x88EE88))   // 11: inner SE
        generated(color(16, 16, 0x99FF99))   // 12: inner SW
}

// ============================================================================
// DEMO TILES: Auto-generated tiles with edge visualization
// ============================================================================
// The demo: syntax automatically generates tiles that show edge/fill visualization.
// Great for testing autotile logic without actual assets.

// Cross demo - generates 13 tiles for standard terrain
#demoCross autotile {
    format: cross
    tileSize: 16
    demo: 0x4444FF, 0xFFFF44    // edge color (blue), fill color (yellow)
}

// Blob47 demo - generates all 47 tiles for full autotiling
#demoBlob47 autotile {
    format: blob47
    tileSize: 16
    demo: 0xFF8800, 0x0088FF    // edge color (orange), fill color (blue)
}

// ============================================================================
// USAGE EXAMPLE (Haxe code):
// ============================================================================
//
// var builder = MultiAnimBuilder.load(content, resourceLoader, "autotile.manim");
//
// // Define terrain grid (1 = terrain present, 0 = empty)
// var grid = [
//     [0, 0, 1, 1, 1, 0],
//     [0, 1, 1, 1, 1, 1],
//     [1, 1, 1, 1, 1, 1],
//     [1, 1, 1, 0, 1, 1],
//     [0, 1, 1, 0, 0, 0]
// ];
//
// // Build terrain TileGroup
// var terrain = builder.buildAutotile("grassPath", grid);
// scene.addChild(terrain);
//
// // For elevation with depth rendering:
// var elevationGrid = [
//     [0, 0, 0, 0, 0],
//     [0, 1, 1, 1, 0],
//     [0, 1, 1, 1, 0],
//     [0, 0, 0, 0, 0]
// ];
// var elevation = builder.buildAutotileElevation("elevation", elevationGrid, 0);
// scene.addChild(elevation);
`,Qp=`version: 0.3

// =============================================================================
// AUTOTILE DEMO - Cross Format Visualization
// =============================================================================
// This demo shows all 13 tiles and how they should be configured.
// Red = no neighbor expected (empty)
// Blue = neighbor expected (terrain present)
// =============================================================================

// Demo using explicit generated tiles with color-coded edges
// Cross layout: 0=N, 1=W, 2=C, 3=E, 4=S, 5=NW, 6=NE, 7=SW, 8=SE, 9-12=inner
#demoGenerated autotile {
    format: cross
    tileSize: 16
    tiles:
        // Edges (0-4)
        generated(color(16, 16, 0xFF9955))    // 0: N edge
        generated(color(16, 16, 0xFFBB77))    // 1: W edge
        generated(color(16, 16, 0x44AA44))    // 2: Center - green (fully surrounded)
        generated(color(16, 16, 0xFFDD99))    // 3: E edge
        generated(color(16, 16, 0xFFFFBB))    // 4: S edge
        // Outer corners (5-8)
        generated(color(16, 16, 0xFF8844))    // 5: NW outer corner
        generated(color(16, 16, 0xFFAA66))    // 6: NE outer corner
        generated(color(16, 16, 0xFFEEAA))    // 7: SW outer corner
        generated(color(16, 16, 0xEEEECC))    // 8: SE outer corner
        // Inner corners (9-12): for L-shaped terrain
        generated(color(16, 16, 0x66CC66))    // 9: inner NE - missing NE diagonal
        generated(color(16, 16, 0x77DD77))    // 10: inner NW - missing NW diagonal
        generated(color(16, 16, 0x88EE88))    // 11: inner SE - missing SE diagonal
        generated(color(16, 16, 0x99FF99))    // 12: inner SW - missing SW diagonal
}

// =============================================================================
// VISUAL DEMO LAYOUT
// =============================================================================

#autotileDemo programmable() {
    pos: 10, 10
    grid: 500, 400

    // Background
    @alpha(0.1) bitmap(generated(color(function(gridWidth), function(gridHeight), black)));

    // Title
    text(dd, "AUTOTILE CROSS FORMAT", white, left, 400):5,5

    // ==========================================================================
    // TILE CATALOG - Show all 13 tiles with indices
    // ==========================================================================
    text(dd, "TILE CATALOG:", 0xAAAAFF, left, 200):5,30

    // Cross format edges (0-4)
    text(dd, "Edges:", 0x888888, left, 50):5,55

    point {
        pos: 60, 50
        bitmap(generated(color(20, 20, 0xFF9955))):0,0    // 0: N
        text(dd, "0:N", white, center, 30):10,22
        bitmap(generated(color(20, 20, 0xFFBB77))):35,0   // 1: W
        text(dd, "1:W", white, center, 30):45,22
        bitmap(generated(color(20, 20, 0x44AA44))):70,0   // 2: C
        text(dd, "2:C", white, center, 30):80,22
        bitmap(generated(color(20, 20, 0xFFDD99))):105,0  // 3: E
        text(dd, "3:E", white, center, 30):115,22
        bitmap(generated(color(20, 20, 0xFFFFBB))):140,0  // 4: S
        text(dd, "4:S", white, center, 30):150,22
    }

    // Outer corners (5-8)
    text(dd, "Outer:", 0x888888, left, 50):5,95

    point {
        pos: 60, 90
        bitmap(generated(color(20, 20, 0xFF8844))):0,0    // 5: NW outer
        text(dd, "5:NW", white, center, 35):10,22
        bitmap(generated(color(20, 20, 0xFFAA66))):40,0   // 6: NE outer
        text(dd, "6:NE", white, center, 35):50,22
        bitmap(generated(color(20, 20, 0xFFEEAA))):80,0   // 7: SW outer
        text(dd, "7:SW", white, center, 35):90,22
        bitmap(generated(color(20, 20, 0xEEEECC))):120,0  // 8: SE outer
        text(dd, "8:SE", white, center, 35):130,22
    }

    // Inner corners - indices 9-12
    text(dd, "Inner:", 0x888888, left, 50):5,135
    point {
        pos: 60, 130
        bitmap(generated(color(20, 20, 0x66CC66))):0,0    // 9: inner NE
        text(dd, "9", white, center, 20):10,22
        bitmap(generated(color(20, 20, 0x77DD77))):25,0   // 10: inner NW
        text(dd, "10", white, center, 20):35,22
        bitmap(generated(color(20, 20, 0x88EE88))):50,0   // 11: inner SE
        text(dd, "11", white, center, 20):60,22
        bitmap(generated(color(20, 20, 0x99FF99))):75,0   // 12: inner SW
        text(dd, "12", white, center, 20):85,22
    }

    // ==========================================================================
    // NEIGHBOR EXPECTATIONS - Red/Blue indicators
    // ==========================================================================
    text(dd, "NEIGHBOR PATTERN:", 0xAAAAFF, left, 200):5,170

    // Legend
    point {
        pos: 5, 190
        bitmap(generated(color(12, 12, 0xFF4444))):0,0
        text(dd, "= No neighbor (red)", 0xFFAAAA, left, 150):15,0
        bitmap(generated(color(12, 12, 0x4444FF))):0,15
        text(dd, "= Has neighbor (blue)", 0xAAAAFF, left, 150):15,15
    }

    // ==========================================================================
    // EXAMPLE TERRAIN - Full grid showing tile connections
    // ==========================================================================
    text(dd, "EXAMPLE TERRAIN:", 0xAAAAFF, left, 200):250,30

    // Show a 5x4 terrain grid with proper tile placement
    // Grid pattern (1=terrain, 0=empty):
    //   0 1 1 1 0
    //   1 1 1 1 1
    //   1 1 1 1 1
    //   0 1 1 1 0

    point {
        pos: 250, 55
        // Row 0:     empty, NW(5), N(0),  NE(6), empty
        bitmap(generated(color(20, 20, 0x222222))):0,0     // empty
        bitmap(generated(color(20, 20, 0xFF8844))):22,0    // 5: NW outer
        bitmap(generated(color(20, 20, 0xFF9955))):44,0    // 0: N
        bitmap(generated(color(20, 20, 0xFFAA66))):66,0    // 6: NE outer
        bitmap(generated(color(20, 20, 0x222222))):88,0    // empty

        // Row 1:     W(1),  C(2),  C(2),  C(2),  E(3)
        bitmap(generated(color(20, 20, 0xFFBB77))):0,22    // 1: W
        bitmap(generated(color(20, 20, 0x44AA44))):22,22   // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):44,22   // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):66,22   // 2: C
        bitmap(generated(color(20, 20, 0xFFDD99))):88,22   // 3: E

        // Row 2:     W(1),  C(2),  C(2),  C(2),  E(3)
        bitmap(generated(color(20, 20, 0xFFBB77))):0,44    // 1: W
        bitmap(generated(color(20, 20, 0x44AA44))):22,44   // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):44,44   // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):66,44   // 2: C
        bitmap(generated(color(20, 20, 0xFFDD99))):88,44   // 3: E

        // Row 3:     empty, SW(7), S(4),  SE(8), empty
        bitmap(generated(color(20, 20, 0x222222))):0,66    // empty
        bitmap(generated(color(20, 20, 0xFFEEAA))):22,66   // 7: SW outer
        bitmap(generated(color(20, 20, 0xFFFFBB))):44,66   // 4: S
        bitmap(generated(color(20, 20, 0xEEEECC))):66,66   // 8: SE outer
        bitmap(generated(color(20, 20, 0x222222))):88,66   // empty
    }

    // Label the grid
    text(dd, "Grid: 0=empty, 1=terrain", 0x888888, left, 200):250,150
    text(dd, "  0 1 1 1 0", 0x666666, left, 200):250,165
    text(dd, "  1 1 1 1 1", 0x666666, left, 200):250,178
    text(dd, "  1 1 1 1 1", 0x666666, left, 200):250,191
    text(dd, "  0 1 1 1 0", 0x666666, left, 200):250,204

    // ==========================================================================
    // INNER CORNER EXAMPLE
    // ==========================================================================
    text(dd, "INNER CORNERS:", 0xAAAAFF, left, 200):250,230

    // L-shaped terrain showing inner corners
    // Grid:
    //   1 1 0
    //   1 1 1
    //   0 1 1
    point {
        pos: 250, 255
        // Row 0: C(2), inner-NE(9), empty
        bitmap(generated(color(20, 20, 0x44AA44))):0,0     // 2: C
        bitmap(generated(color(20, 20, 0x66CC66))):22,0    // 9: inner NE (missing NE diagonal)
        bitmap(generated(color(20, 20, 0x222222))):44,0    // empty

        // Row 1: C(2), C(2), C(2)
        bitmap(generated(color(20, 20, 0x44AA44))):0,22    // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):22,22   // 2: C
        bitmap(generated(color(20, 20, 0x44AA44))):44,22   // 2: C

        // Row 2: empty, inner-SW(12), C(2)
        bitmap(generated(color(20, 20, 0x222222))):0,44    // empty
        bitmap(generated(color(20, 20, 0x99FF99))):22,44   // 12: inner SW
        bitmap(generated(color(20, 20, 0x44AA44))):44,44   // 2: C
    }

    text(dd, "Inner corners fill", 0x888888, left, 200):250,325
    text(dd, "L-shaped gaps", 0x888888, left, 200):250,340
}
`,Xp=`version: 0.3

// Button Test
// Demonstrates a custom button with ninepatch states and a disable toggle.
// The button_custom programmable defines 4 visual states:
//   normal, hover, pressed (when enabled) + disabled state.

#button_custom programmable(status:[hover, pressed, normal], disabled:[true, false], buttonText="Button") {
      @(status=>normal, disabled=>false) ninepatch("ui", "button-idle", 200, 30):     0, 1
      @(status=>hover, disabled=>false) ninepatch("ui", "button-hover", 200, 30):     0, 0
      @(status=>pressed, disabled=>false) ninepatch("ui", "button-pressed", 200, 30): 0, 0
      @(status=>*, disabled=>true) ninepatch("ui", "button-disabled", 200, 30):       0, 0

      @(status=>normal, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0, 10
      @(status=>hover, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0, 10
      @(status=>pressed, disabled=>false) text(dd, $buttonText, 0xffffff12, center, 200): 0, 10
      @(status=>*, disabled=>true) text(dd, $buttonText, 0xffffff12, center, 200): 0, 10
}

#ui programmable() {
      pos: 100, 300

      text(dd, "Button Demo", #ffffffcc): 10, -30

      // Click status display
      #buttonVal(updatable) text(dd, "Click the button!", #ffffffaa): 10, 50

      // Button placeholder - uses button_custom programmable defined above
      placeholder(generated(cross(200, 20)), builderParameter("button")) {
            settings{builderName=>button_custom}
      }

      // Disable toggle checkbox
      placeholder(generated(cross(200, 20)), builderParameter("disableCheckbox")) {
            pos: 10, 100
      }
      text(dd, "Disable Button", #ffffffaa): 30, 100
}
`,Kp=`version: 0.3

// Checkbox Test
// Demonstrates a checkbox component with toggle state display.
// Uses checkbox2 style (overridden via settings).
// See also: components.manim for all 5 checkbox variants.

#ui programmable() {
      pos: 100, 300

      text(dd, "Checkbox Demo", #ffffffcc): 10, -30

      // Toggle state display
      #checkboxVal(updatable) text(dd, "Toggle the checkbox!", #ffffffaa): 10, 50

      // Checkbox placeholder - uses checkbox2 style from std.manim
      placeholder(generated(cross(200, 20)), builderParameter("checkbox")) {
            settings{checkboxBuildName=>checkbox2}
      }
}
`,Yp=`version: 0.3

// Components Test
// Demonstrates: tileGroups, macro builder placeholders, checkbox variants,
// scrollable lists, and repeatable grids

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

// Macro placeholder test - 4 types of builder parameters:
//   element: pre-created UI element
//   factoryElement: factory function returning UI element
//   h2dObject: pre-created h2d.Object
//   h2dObjectFactory: factory function returning h2d.Object
#macroTest programmable() {
      pos:600,200
      text(dd, "Macro Placeholders", #ffffffcc): 0,0
      placeholder(generated(cross(10, 10)), builderParameter("element")):0,25
      placeholder(generated(cross(10, 10)), builderParameter("factoryElement")):0,50
      placeholder(generated(cross(10, 10)), builderParameter("h2dObject")):0,75
      placeholder(generated(cross(10, 10)), builderParameter("h2dObjectFactory")):0,100
}

// TileGroup examples - bitmap alignment
// Shows left/top, left/center, left/bottom alignment
#testTileGroup3 programmable() {
      pos:600,100
      point {
            text(dd, "Bitmap Alignment", #ffffffcc): 0,0
            bitmap(generated(color(20, 20, white)), left, top):0,50
            bitmap(generated(color(20, 20, white)), left, center):40,50
            bitmap(generated(color(20, 20, white)), left, bottom):80,50
      }
}

// TileGroup with pos offset inside point
#testTileGroup2 programmable tileGroup() {
      pos:600,100
      point {
            pos:5,5
            bitmap(generated(color(20, 20, red)), left, top):0,50
            bitmap(generated(color(20, 20, red)), left, center):40,50
            bitmap(generated(color(20, 20, red)), left, bottom):80,50
      }
}

// TileGroup with absolute pixel positions
#testTileGroup1 programmable tileGroup() {
      point {
            bitmap(generated(color(20, 20, gray)), left, top):610, 160
            bitmap(generated(color(20, 20, gray)), left, center):650, 160
            bitmap(generated(color(20, 20, gray)), left, bottom):690, 160
      }
}

// TileGroup with repeatable grid layout
#testTileGroup4 programmable tileGroup() {
      pos:800,100
      repeatable($index, step(3, dx:40)) {
            bitmap(generated(color(20, 20, white)), left, top);
      }
}

// Repeatable grid without tileGroup (for comparison)
#testTileGroup5 programmable() {
      pos:805,105
      repeatable($index, step(3, dx:40)) {
            bitmap(generated(color(20, 20, orange)), left, top);
      }
}

// TileGroup repeatable with variable iterator
#testTileGroup6 programmable tileGroup() {
      repeatable($item, step(3, dx:40)) {
            pos:810,110
            bitmap(generated(color(20, 20, red)), left, top);
      }
}


// Main UI - interactive components
// Checkbox variants: checkbox2, radio, radio2, tickbox, toggle
// Scrollable lists with different item counts and settings
// Checkbox with label text
#ui programmable() {
      pos:100,300

      // 5 checkbox style variants (overriding the build name via settings)
      placeholder(generated(cross(200, 20)), builderParameter("checkbox1")) {
            settings{checkboxBuildName=>checkbox2}
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

      // 4 scrollable lists with different configurations
      placeholder(generated(cross(200, 20)), builderParameter("scroll1")) {
            pos:400,100
            settings{height=>200, topClearance=>60}
      }
      placeholder(generated(cross(200, 20)), builderParameter("scroll2")):550,100;
      placeholder(generated(cross(200, 20)), builderParameter("scroll3")):700,100;
      placeholder(generated(cross(200, 20)), builderParameter("scroll4")):850,100;

      // Checkbox with label text
      placeholder(generated(cross(200, 20)), builderParameter("checkboxWithLabel")) {
            pos:610,50;
            settings{font=>dd}
      }
}
`,Zp=`version: 0.3


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

      



    `,qp=`version: 0.3


#ui programmable() {
      pos:400,200
      
      #selectedFileText(updatable) text(dd, "No file selected", #ffffff00, center, 400): 0,50
      
      point {
      
        placeholder(generated(cross(20, 20)), builderParameter("openDialog1button"));
        placeholder(generated(cross(200, 20)), builderParameter("openDialog2button")):250,0;
        
      }
}


      



    `,Jp=`version: 0.3

// Drag & Drop Test
// Demonstrates draggable UI elements.
// Draggable objects are created programmatically by DraggableTestScreen.hx.
// This file defines the static background: title, drop zones, and labels.

#ui programmable() {
    text(dd, "Drag & Drop Test", #ffffffcc, center, 800): 0, 10

    // Drop zone 1 - large target area
    ninepatch("ui", "Window_3x3_idle", 180, 180): 300, 200
    text(dd, "Drop Zone 1", #ffffffaa, center, 180): 300, 395

    // Drop zone 2 - smaller target area
    ninepatch("ui", "Window_3x3_idle", 120, 120): 550, 240
    text(dd, "Drop Zone 2", #ffffffaa, center, 120): 550, 375

    // Instructions
    text(dd, "Drag the colored rectangles around the screen", #ffffff88): 100, 500
}
`,e0=`version: 0.3

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

          repeatable($index, step(5, dx:5, dy:1)) {
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

        repeatable($row, step(3, dy:25)) {
          repeatable($index, step(16, dx:12)) {
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
                repeatable($index, step(5, dx:5, dy:1)) {
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
        repeatable($index, step(25, dx:0)) {
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



                

      

      
`,n0=`version: 0.3

// Font Browser
// Displays all registered fonts with sample text.
// Font names on left (#fontNames), sample text on right (#fonts).
// Content is populated programmatically by FontsScreen.hx.

relativeLayouts {
  #fontNames sequence($i: 1..40) point: 100, 20 + 20 * $i
  #fonts sequence($i: 1..40) point: 200, 20 + 20 * $i
}
`,t0=`version: 0.3

relativeLayouts {
    #controlRows sequence($i: 0..5) point: 10, 55 + $i * 40
}

// Advanced Particle System Examples
// Demonstrates all particle features including:
// - Emit modes: point, cone, box, circle, path
// - Color interpolation with start/mid/end colors
// - Force fields: attractor, repulsor, vortex, wind, turbulence
// - Velocity and size curves over lifetime
// - Bounds modes: kill, bounce, wrap
// - Rotation options
// - Animation and multi-tile support

// =============================================================================
// FIRE EFFECT - Upward flames with color gradient and size curve
// =============================================================================
#fire particles {
    count: 100
    emit: cone(0, 10, -90, 30)
    maxLife: 2.0
    lifeRandom: 0.3
    speed: 80
    speedRandom: 0.3
    tiles: file("circle_soft.png")
    loop: true
    size: 0.8
    sizeRandom: 0.4
    emitSync: 0.2
    blendMode: add
    fadeIn: 0.1
    fadeOut: 0.6
    fadePower: 1.5

    // Color gradient: orange -> yellow -> white
    colorStart: #FF4400
    colorMid: #FFAA00
    colorMidPos: 0.4
    colorEnd: #FFFF88

    // Size grows then shrinks
    sizeCurve: [(0, 0.5), (0.3, 1.2), (1.0, 0.2)]

    // Slight turbulence for flickering
    forceFields: [turbulence(30, 0.02, 2.0)]
}

// =============================================================================
// SMOKE EFFECT - Rising smoke with turbulence and fade
// =============================================================================
#smoke particles {
    count: 80
    emit: box(60, 10, -90, 25)
    maxLife: 4.0
    lifeRandom: 0.5
    speed: 25
    speedRandom: 0.3
    speedIncrease: -0.3
    tiles: file("smoke.png")
    loop: true
    size: 0.4
    sizeRandom: 0.2
    emitSync: 0.3
    blendMode: alpha
    fadeIn: 0.2
    fadeOut: 0.5
    fadePower: 2.0

    // Gray to transparent
    colorStart: #888888
    colorEnd: #444444

    // Size increases over lifetime
    sizeCurve: [(0, 0.3), (0.5, 1.0), (1.0, 1.8)]

    // Turbulence and slight wind
    forceFields: [turbulence(20, 0.015, 1.0), wind(15, 0)]

    // Rotation
    rotationInitial: 180
    rotationSpeed: 20
    rotationSpeedRandom: 40
}

// =============================================================================
// SPARKLES - Falling stars with gravity and bounce
// =============================================================================
#sparkles particles {
    count: 60
    emit: box(200, 10, 0, 180)
    maxLife: 3.0
    lifeRandom: 0.5
    speed: 120
    speedRandom: 0.5
    tiles: file("star.png")
    loop: true
    size: 0.4
    sizeRandom: 0.3
    emitSync: 0.1
    blendMode: add
    fadeIn: 0.05
    fadeOut: 0.7
    fadePower: 1.0

    // Gravity pulling down
    gravity: 150
    gravityAngle: 90

    // Color: white -> gold -> dim
    colorStart: #FFFFFF
    colorMid: #FFDD44
    colorMidPos: 0.5
    colorEnd: #886622

    // Bounce off bottom
    boundsMode: bounce(0.6)
    boundsMinX: -100
    boundsMaxX: 300
    boundsMinY: -50
    boundsMaxY: 250

    // Spin as they fall
    rotationSpeed: 180
    rotationSpeedRandom: 360
}

// =============================================================================
// VORTEX EFFECT - Swirling particles with attractor
// =============================================================================
#vortex particles {
    count: 150
    emit: circle(150, 50, 0, 0)
    maxLife: 4.0
    lifeRandom: 0.3
    speed: 30
    speedRandom: 0.5
    tiles: file("dot.png")
    loop: true
    size: 0.3
    sizeRandom: 0.2
    emitSync: 0.1
    blendMode: add
    fadeIn: 0.1
    fadeOut: 0.8

    // Cyan to purple gradient
    colorStart: #00FFFF
    colorMid: #FF00FF
    colorMidPos: 0.6
    colorEnd: #4400AA

    // Vortex force field at center + attractor
    forceFields: [vortex(0, 0, 200, 200), attractor(0, 0, 50, 180)]

    // Speed increases as particles spiral in
    velocityCurve: [(0, 0.5), (0.5, 1.0), (1.0, 2.0)]
}

// =============================================================================
// EXPLOSION - Burst with velocity decay
// =============================================================================
#explosion particles {
    count: 80
    emit: point(0, 20)
    maxLife: 1.2
    lifeRandom: 0.3
    speed: 300
    speedRandom: 0.5
    speedIncrease: -0.8
    tiles: file("flare.png") file("spark.png")
    loop: true
    size: 0.8
    sizeRandom: 0.4
    emitSync: 0.95
    emitDelay: 0.0
    blendMode: add
    fadeIn: 0.0
    fadeOut: 0.5
    fadePower: 1.0

    // White -> orange -> red
    colorStart: #FFFFFF
    colorMid: #FF8800
    colorMidPos: 0.3
    colorEnd: #FF2200

    // Velocity decays quickly
    velocityCurve: [(0, 1.0), (0.2, 0.5), (1.0, 0.1)]

    // Size shrinks
    sizeCurve: [(0, 1.0), (0.5, 0.6), (1.0, 0.1)]

    // Direction-based rotation
    rotateAuto: true

    // Random tile animation
    animationRepeat: 0
}

// =============================================================================
// RAIN - Falling streaks with wrap bounds
// =============================================================================
#rain particles {
    count: 200
    emit: box(500, 10, 100, 5)
    maxLife: 1.5
    lifeRandom: 0.2
    speed: 400
    speedRandom: 0.15
    tiles: file("spark.png")
    loop: true
    size: 0.2
    sizeRandom: 0.1
    emitSync: 0.0
    blendMode: alpha
    fadeIn: 0.1
    fadeOut: 0.9

    // Blue-ish rain
    colorStart: #AACCFF
    colorEnd: #6688CC

    // Gravity adds to downward motion
    gravity: 100
    gravityAngle: 90

    // Wrap around when hitting bounds
    boundsMode: wrap
    boundsMinX: -50
    boundsMaxX: 450
    boundsMinY: -20
    boundsMaxY: 350

    // Stretch in direction of motion
    rotateAuto: true
}

// =============================================================================
// MAGIC TRAIL - Path emitter with color pulse
// =============================================================================
#magicTrail particles {
    count: 60
    emit: circle(30, 20, 0, 0)
    maxLife: 2.5
    lifeRandom: 0.3
    speed: 40
    speedRandom: 0.4
    tiles: file("comet.png") file("glow.png")
    loop: true
    size: 0.5
    sizeRandom: 0.3
    emitSync: 0.15
    blendMode: add
    fadeIn: 0.1
    fadeOut: 0.6
    fadePower: 1.2

    // Magical purple/cyan colors
    colorStart: #AA44FF
    colorMid: #44FFFF
    colorMidPos: 0.5
    colorEnd: #FF44AA

    // Pulsing size
    sizeCurve: [(0, 0.5), (0.25, 1.2), (0.5, 0.8), (0.75, 1.1), (1.0, 0.3)]

    // Gentle turbulence
    forceFields: [turbulence(25, 0.025, 1.5)]

    // Slow rotation
    rotationSpeed: 30
    rotationSpeedRandom: 60
}

// =============================================================================
// CONFETTI - Animated falling pieces with wind and bounce
// =============================================================================
#confetti particles {
    count: 100
    emit: box(400, 0, 90, 50)
    maxLife: 6.0
    lifeRandom: 1.0
    speed: 40
    speedRandom: 0.6
    tiles: file("star.png") file("ring.png") file("dot.png")
    loop: true
    size: 0.4
    sizeRandom: 0.3
    emitSync: 0.05
    blendMode: alpha
    fadeIn: 0.0
    fadeOut: 0.85
    fadePower: 1.0

    // Gravity
    gravity: 80
    gravityAngle: 90

    // Spin wildly
    rotationSpeed: 120
    rotationSpeedRandom: 240

    // Cycle through tiles
    animationRepeat: 5

    // Bright party colors
    colorStart: #FF66CC
    colorMid: #66FF66
    colorMidPos: 0.5
    colorEnd: #6666FF

    // Wind and turbulence for flutter
    forceFields: [wind(30, 0), turbulence(20, 0.015, 0.5)]

    // Bounce at bottom
    boundsMode: bounce(0.5)
    boundsMinX: -50
    boundsMaxX: 450
    boundsMinY: -50
    boundsMaxY: 350
}

// =============================================================================
// PLASMA - Soft pulsing energy with repulsor
// =============================================================================
#plasma particles {
    count: 120
    emit: point(0, 80)
    maxLife: 3.0
    lifeRandom: 0.4
    speed: 60
    speedRandom: 0.5
    tiles: file("electric-small.png") file("circle_soft.png")
    loop: true
    size: 0.6
    sizeRandom: 0.4
    emitSync: 0.1
    blendMode: add
    fadeIn: 0.15
    fadeOut: 0.5
    fadePower: 1.5

    // Electric blue to pink
    colorStart: #0088FF
    colorMid: #FF00FF
    colorMidPos: 0.5
    colorEnd: #FF4488

    // Repulsor pushes particles outward, then they slow
    forceFields: [repulsor(0, 0, 100, 120), turbulence(15, 0.02, 2.0)]

    // Velocity curve: fast start, slow end
    velocityCurve: [(0, 1.5), (0.3, 1.0), (1.0, 0.3)]

    // Size pulses
    sizeCurve: [(0, 0.3), (0.2, 1.0), (0.5, 0.7), (0.8, 1.1), (1.0, 0.4)]
}

// =============================================================================
// UI DEMONSTRATION - Dropdown, Sliders, Checkboxes, Radio Buttons
// =============================================================================
#ui programmable() {
    text(pixellari, "Particles Demo", #ffffff, left, 800): 5, 5
    #effectName(updatable) text(pixellari, "Effect: fire", #ffff00, left, 800): 5, 25

    // Effect selector dropdown
    text(pixellari, "Effect:", #aaaaaa): 10, 58
    placeholder(generated(cross(150, 25)), builderParameter("effectDropdown")): 80, 50

    // Speed slider
    text(pixellari, "Speed:", #aaaaaa): 10, 105
    placeholder(generated(cross(200, 20)), builderParameter("speedSlider")): 80, 100
    #speedVal(updatable) text(pixellari, "100%", #ffff00): 300, 105

    // Size slider
    text(pixellari, "Size:", #aaaaaa): 10, 140
    placeholder(generated(cross(200, 20)), builderParameter("sizeSlider")): 80, 135
    #sizeVal(updatable) text(pixellari, "100%", #ffff00): 300, 140

    // Gravity slider
    text(pixellari, "Gravity:", #aaaaaa): 10, 175
    placeholder(generated(cross(200, 20)), builderParameter("gravitySlider")): 80, 170
    #gravityVal(updatable) text(pixellari, "100%", #ffff00): 300, 175

    // FadeOut slider
    text(pixellari, "FadeOut:", #aaaaaa): 10, 210
    placeholder(generated(cross(200, 20)), builderParameter("fadeOutSlider")): 80, 205
    #fadeOutVal(updatable) text(pixellari, "100%", #ffff00): 300, 210

    // Loop checkbox
    placeholder(generated(cross(20, 20)), builderParameter("loopCheckbox")): 10, 250
    text(pixellari, "Loop", #aaaaaa): 35, 253

    // Rotate Auto checkbox
    placeholder(generated(cross(20, 20)), builderParameter("rotateCheckbox")): 130, 250
    text(pixellari, "Rotate Auto", #aaaaaa): 155, 253

    // Relative checkbox
    placeholder(generated(cross(20, 20)), builderParameter("relativeCheckbox")): 280, 250
    text(pixellari, "Relative", #aaaaaa): 305, 253

    // Blend mode radio buttons
    text(pixellari, "Blend:", #aaaaaa): 10, 290
    placeholder(generated(cross(260, 25)), builderParameter("blendRadio")): 80, 285

    // Count radio buttons
    text(pixellari, "Count:", #aaaaaa): 10, 325
    placeholder(generated(cross(260, 25)), builderParameter("countRadio")): 80, 320

    // Restart button
    placeholder(generated(cross(200, 25)), builderParameter("restartButton")): 10, 360

    // Particle display area
    #particles1(updatable) point: 640, 400
}
`,r0=`version: 0.3



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
`,i0=`version: 0.3




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
      #ref1 point {
        bitmap(generated(cross(10, 10)));
        text(pixellari, "ref #1", yellow);
        #ref2 point {
          bitmap(generated(cross(10, 10)));
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
}`,l0=`version: 0.3

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
        repeatable($i, step(10, dx:10, dy:10)) {
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
        repeatable($i, step(10, dx:10, dy:10)) {
            pixels (
                pixel 0,0, #ff0
            ) {
                scale: 10
                pos: $i, $i
            }
        }
        text(pixellari, "Pixel staircase (1x1 px, offset 10px)", #ff0, left, grid): 0, -40
    }
} `,o0=`version: 0.3


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



    `,a0=`version: 0.3

// Scrollable List Test
// Demonstrates a scrollable list with item selection.
// Uses list-panel and list-item-120 components from std.manim.
// List items and scroll behavior are configured in ScrollableListTestScreen.hx.

#ui programmable() {
      pos: 100, 300

      text(dd, "Scrollable List Demo", #ffffffcc): 10, -30

      // Selected item display
      #listVal(updatable) text(dd, "Select an item from the list!", #ffffffaa): 10, 50

      // Scrollable list placeholder
      placeholder(generated(cross(200, 150)), builderParameter("scrollableList")) {
            pos: 10, 80
            settings{panelBuilder=>list-panel, itemBuilder=>list-item-120}
      }
}
`,s0=`version: 0.3

// Settings Screen
// Demonstrates display settings: fullscreen toggle, resolution picker,
// background color, and monitor selection.
// Components are added programmatically via the #resolution layout iterator.

relativeLayouts {
  #resolution list {
        point: 30, 120
        point: 30, 160
        point: 30, 320
        point: 30, 420
  }
}

#ui programmable() {
      text(dd, "Display Settings", #ffffffcc): 30, 30

      // Labels for each setting row
      text(dd, "Fullscreen", #ffffffaa): 60, 125
      #resolution(updatable) text(dd, "Resolution", #ffffffaa): 160, 166

      text(dd, "Background Color", #ffffffaa): 60, 285
      text(dd, "Monitor", #ffffffaa): 60, 385
}
`,u0=`version: 0.3

// Slider Test
// Demonstrates a slider component with real-time value display.
// Slider programmable is defined in std.manim with 3 size variants (100/200/300).

#ui programmable() {
      pos: 100, 300

      text(dd, "Slider Demo", #ffffffcc): 10, -30

      // Current value display
      #sliderVal(updatable) text(dd, "Drag the slider!", #ffffffaa): 10, 50

      // Slider placeholder
      placeholder(generated(cross(200, 20)), builderParameter("slider")) {
            pos: 10, 30
      }
}
`,c0=`version: 0.3


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


`,d0=`version: 0.3

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
      repeatable($index, step($count, dy:20)) {
            placeholder(generated(cross(15, 15)), callback("checkbox", $index)):0,0
            text(m6x11, callback("label", $index), 0xffffff12, left, 120): 24,4
            
      }
}

#radioButtonsHorizontal programmable(count:int){
      repeatable($index, step($count, dx:120 )) {
            placeholder(generated(cross(15, 15)), callback("checkbox", $index)):0,0
            text(m6x11, callback("label", $index), 0xffffff12, left, 120): 24,4
            
      }
}

#radioButtonsVertical programmable(count:int){
      repeatable($index, step($count, dy:30 )) {
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
      settings{transitionTimer:float=>0.2}
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
        settings{height:float=>20}
}

#list-panel programmable(width:uint=200, height:uint=200, topClearance:uint = 0) {
  
  ninepatch("ui", "Window_3x3_idle", $width+4, $height+8+$topClearance): -2,-4-$topClearance
  placeholder(generated(cross($width, $height)), builderParameter("mask")):0,0
  #scrollbar @layer(100) point: $width - 4, 0
}

#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint = 0) {

ninepatch("ui", "scrollbar-1", 4, $panelHeight * $panelHeight / $scrollableHeight): 0, $scrollPosition*$panelHeight/$scrollableHeight
  settings{scrollSpeed:float=>250}
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
}`,f0=`sheet: crew2
allowedExtraPoints: ["point", "text"]
center: 64,64


animation {
    name: dir0
    fps: 10
    loop: yes
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
    fps: 10
    loop: yes
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
    fps: 10
    loop: yes
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
    fps: 10
    loop: yes
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
    fps: 10
    loop: yes
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
    fps: 10
    loop: yes
    playlist {
        sheet: "Arrow_dir5"
    }
    extrapoints {
        point: 0,0
        text: -25,-60
    }
}

`,p0=`sheet: crew2
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


`,m0=`sheet: crew2
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

`,h0=`sheet: crew2
allowedExtraPoints: ["line_TR", "line_BR", "line_TL", "line_BL"]
states: direction(l, r)
center: 32,48


animation {
    name: idle_0
    fps: 4
    loop: yes
    playlist {
        sheet: "shield_$$direction$$_layer0"
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
    fps: 10
    loop: yes
    playlist {
        sheet: "shield_$$direction$$_layer2_impact fast"
    }
}

animation {
    name: idle_1
    fps: 10
    loop: yes
    playlist {
        sheet: "shield_$$direction$$_layer1"
    }
}



`,g0=`sheet: crew2
center: 32,48


animation {
    name: explode
    fps: 16
    playlist {
        sheet: "Turret_Explode_SW"
    }
}

animation {
    name: hit
    fps: 10
    loop: yes
    playlist {
        sheet: "Turret_Idle_SW_A" frames: 2..6
    }
}

animation {
    name: idle
    fps: 14
    loop: yes
    playlist {
        sheet: "Turret_Idle_SW_B"
    }
}

animation {
    name: shoot
    fps: 16
    loop: yes
    playlist {
        sheet: "Turret_Shoot_SW"
    }
}

animation {
    name: destroyed
    fps: 1
    playlist {
        sheet: "Turret_Destroyed_SW"
    }
}
`,v0=Object.assign({"../public/assets/animviewer.manim":Hp,"../public/assets/atlas-test.manim":Vp,"../public/assets/autotile.manim":Gp,"../public/assets/autotileDemo.manim":Qp,"../public/assets/button.manim":Xp,"../public/assets/checkbox.manim":Kp,"../public/assets/components.manim":Yp,"../public/assets/dialog-base.manim":Zp,"../public/assets/dialog-start.manim":qp,"../public/assets/draggable.manim":Jp,"../public/assets/examples1.manim":e0,"../public/assets/fonts.manim":n0,"../public/assets/particles-advanced.manim":t0,"../public/assets/particles.manim":r0,"../public/assets/paths.manim":i0,"../public/assets/pixels.manim":l0,"../public/assets/room1.manim":o0,"../public/assets/scrollable-list.manim":a0,"../public/assets/settings.manim":s0,"../public/assets/slider.manim":u0,"../public/assets/stateanim.manim":c0,"../public/assets/std.manim":d0}),y0=Object.assign({"../public/assets/arrows.anim":f0,"../public/assets/dice.anim":p0,"../public/assets/marine.anim":m0,"../public/assets/shield.anim":h0,"../public/assets/turret.anim":g0}),ga=Object.fromEntries([...Object.entries(v0).map(([e,n])=>[e.split("/").pop(),n]),...Object.entries(y0).map(([e,n])=>[e.split("/").pop(),n])]),kl=e=>ga[e]||null,ii=(e,n)=>{ga[e]=n},x0=e=>e in ga,bl=[{name:"scrollableList",displayName:"Scrollable List Test",description:"Scrollable list component test screen with interactive list selection and scrolling functionality.",manimFile:"scrollable-list.manim",haxeFile:"ScrollableListTestScreen.hx"},{name:"button",displayName:"Button Test",description:"Button component test screen with interactive button controls and click feedback.",manimFile:"button.manim",haxeFile:"ButtonTestScreen.hx"},{name:"checkbox",displayName:"Checkbox Test",description:"Checkbox component test screen with interactive checkbox controls and state display.",manimFile:"checkbox.manim",haxeFile:"CheckboxTestScreen.hx"},{name:"slider",displayName:"Slider Test",description:"Slider component test screen with interactive slider controls and screen selection functionality.",manimFile:"slider.manim",haxeFile:"SliderTestScreen.hx"},{name:"particlesAdvanced",displayName:"Particles",description:"Particle system examples demonstrating color gradients, force fields, bounds modes, trails, and various emission patterns.",manimFile:"particles-advanced.manim",haxeFile:"ParticlesAdvancedScreen.hx"},{name:"pixels",displayName:"Pixels",description:"Pixel art and static pixel demo screen.",manimFile:"pixels.manim",haxeFile:"PixelsScreen.hx"},{name:"components",displayName:"Components",description:"Interactive UI components showcase featuring buttons, checkboxes, sliders, and other form elements with hover and press animations.",manimFile:"components.manim",haxeFile:"ComponentsTestScreen.hx"},{name:"examples1",displayName:"Examples 1",description:"Basic animation examples demonstrating fundamental hx-multianim features including sprite animations, transitions, and simple UI elements.",manimFile:"examples1.manim",haxeFile:"Examples1Screen.hx"},{name:"paths",displayName:"Paths",description:"Path-based animations showing objects following complex paths, motion trails, and smooth movement animations.",manimFile:"paths.manim",haxeFile:"PathsScreen.hx"},{name:"fonts",displayName:"Fonts",description:"Font rendering demonstrations with various font types, sizes, and text effects including SDF (Signed Distance Field) fonts.",manimFile:"fonts.manim",haxeFile:"FontsScreen.hx"},{name:"room1",displayName:"Room 1",description:"3D room environment with spatial animations, depth effects, and immersive 3D scene demonstrations.",manimFile:"room1.manim",haxeFile:"Room1Screen.hx"},{name:"stateAnim",displayName:"State Animation",description:"Complex state-based animations demonstrating transitions between different UI states and conditional animations.",manimFile:"stateanim.manim",haxeFile:"StateAnimScreen.hx"},{name:"dialogStart",displayName:"Dialog Start",description:"Dialog startup animations and initial dialog states with smooth entrance effects and loading sequences.",manimFile:"dialog-start.manim",haxeFile:"DialogStartScreen.hx"},{name:"settings",displayName:"Settings",description:"Settings interface with configuration options, preference panels, and settings-specific UI animations.",manimFile:"settings.manim",haxeFile:"SettingsScreen.hx"},{name:"atlasTest",displayName:"Atlas Test",description:"Atlas texture testing screen demonstrating sprite sheet loading, grid layouts, and atlas-based animations.",manimFile:"atlas-test.manim",haxeFile:"AtlasTestScreen.hx"},{name:"draggable",displayName:"Draggable Test",description:"Drag and drop functionality demonstration with free dragging, bounds-constrained dragging, and zone-restricted dropping.",manimFile:"draggable.manim",haxeFile:"DraggableTestScreen.hx"},{name:"animViewer",displayName:"Animation Viewer",description:"Animation viewer for .anim files. Displays all animations from the selected .anim file in a grid layout.",manimFile:"animviewer.manim",haxeFile:"AnimViewerScreen.hx"}],w0=[{filename:"dialog-base.manim",displayName:"Dialog Base",description:"Dialog system foundation with base dialog layouts, text rendering, and dialog-specific animations and transitions."},{filename:"std.manim",displayName:"Standard Library",description:"Standard library components and utilities for hx-multianim including common animations, effects, and helper functions."}],S0=["arrows.anim","dice.anim","marine.anim","shield.anim","turret.anim"];class _0{constructor(){fe(this,"screens");fe(this,"manimFiles");fe(this,"animFiles");fe(this,"currentFile",null);fe(this,"currentExample",null);fe(this,"currentScreen",null);fe(this,"reloadTimeout",null);fe(this,"reloadDelay",1e3);fe(this,"mainApp",null);fe(this,"baseUrl","");this.screens=bl.map(n=>({name:n.name,displayName:n.displayName,description:n.description,manimFile:n.manimFile})),this.manimFiles=[...bl.map(n=>({filename:n.manimFile,displayName:n.displayName,description:n.description,content:null})),...w0.map(n=>({filename:n.filename,displayName:n.displayName,description:n.description,content:null,isLibrary:!0}))],this.animFiles=S0.map(n=>({filename:n,content:null})),this.init()}getScreenHaxeFile(n){const t=bl.find(r=>r.name===n);return t?t.haxeFile:`${n.charAt(0).toUpperCase()+n.slice(1)}Screen.hx`}init(){this.setupFileLoader(),this.loadFilesFromMap(),this.waitForMainApp()}loadFilesFromMap(){this.manimFiles.forEach(n=>{const t=kl(n.filename);t&&(n.content=t)}),this.animFiles.forEach(n=>{const t=kl(n.filename);t&&(n.content=t)})}waitForMainApp(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?this.mainApp=window.PlaygroundMain.instance:setTimeout(()=>this.waitForMainApp(),100)}setupFileLoader(){this.baseUrl=typeof window<"u"&&window.location?window.location.href:"",window.FileLoader={baseUrl:this.baseUrl,resolveUrl:n=>this.resolveUrl(n),load:n=>this.loadFile(n),stringToArrayBuffer:this.stringToArrayBuffer}}resolveUrl(n){if(n.startsWith("http://")||n.startsWith("https://")||n.startsWith("//")||n.startsWith("file://")||!this.baseUrl)return n;try{return new URL(n,this.baseUrl).href}catch{const r=this.baseUrl.endsWith("/")?this.baseUrl:this.baseUrl+"/",i=n.startsWith("/")?n.substring(1):n;return r+i}}stringToArrayBuffer(n){const t=new ArrayBuffer(n.length),r=new Uint8Array(t);for(let i=0,l=n.length;i<l;i++)r[i]=n.charCodeAt(i);return t}loadFile(n){const t=this.extractFilenameFromUrl(n);if(t&&x0(t)){const l=kl(t);if(l)return this.stringToArrayBuffer(l)}if(typeof window.hxd<"u"&&window.hxd.res&&window.hxd.res.load)try{const l=window.hxd.res.load(n);if(l&&l.entry&&l.entry.getBytes){const o=l.entry.getBytes();return this.stringToArrayBuffer(o.toString())}}catch{}const r=this.resolveUrl(n),i=new XMLHttpRequest;return i.open("GET",r,!1),i.send(),i.status===200?this.stringToArrayBuffer(i.response):new ArrayBuffer(0)}extractFilenameFromUrl(n){const r=n.split("?")[0].split("#")[0].split("/"),i=r[r.length-1];return i&&(i.endsWith(".manim")||i.endsWith(".anim")||i.endsWith(".png")||i.endsWith(".atlas2")||i.endsWith(".fnt")||i.endsWith(".tps"))?i:null}onContentChanged(n){if(this.currentFile){const t=this.manimFiles.find(i=>i.filename===this.currentFile);t&&(t.content=n,ii(this.currentFile,n));const r=this.animFiles.find(i=>i.filename===this.currentFile);r&&(r.content=n,ii(this.currentFile,n))}this.reloadTimeout&&clearTimeout(this.reloadTimeout),this.reloadTimeout=setTimeout(()=>{this.reloadPlayground()},this.reloadDelay)}reloadPlayground(n){var r;const t=n||this.currentScreen||"particles";if(this.currentScreen=t,(r=window.PlaygroundMain)!=null&&r.instance)try{return window.PlaygroundMain.instance.reload(t,!0)}catch(i){return{__nativeException:i}}return null}getCurrentFile(){return this.currentFile}getEditedContent(n){const t=this.manimFiles.find(i=>i.filename===n);if(t)return t.content;const r=this.animFiles.find(i=>i.filename===n);return r?r.content:null}updateContent(n,t){const r=this.manimFiles.find(i=>i.filename===n);r&&(r.content=t,ii(n,t))}dispose(){this.mainApp&&typeof this.mainApp.dispose=="function"&&this.mainApp.dispose()}static getDefaultScreen(){return li}}function k0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Ts(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Rs(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Ts(Object(t),!0).forEach(function(r){k0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Ts(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function b0(e,n){if(e==null)return{};var t={},r=Object.keys(e),i,l;for(l=0;l<r.length;l++)i=r[l],!(n.indexOf(i)>=0)&&(t[i]=e[i]);return t}function E0(e,n){if(e==null)return{};var t=b0(e,n),r,i;if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(i=0;i<l.length;i++)r=l[i],!(n.indexOf(r)>=0)&&Object.prototype.propertyIsEnumerable.call(e,r)&&(t[r]=e[r])}return t}function C0(e,n){return F0(e)||N0(e,n)||P0(e,n)||$0()}function F0(e){if(Array.isArray(e))return e}function N0(e,n){if(!(typeof Symbol>"u"||!(Symbol.iterator in Object(e)))){var t=[],r=!0,i=!1,l=void 0;try{for(var o=e[Symbol.iterator](),a;!(r=(a=o.next()).done)&&(t.push(a.value),!(n&&t.length===n));r=!0);}catch(u){i=!0,l=u}finally{try{!r&&o.return!=null&&o.return()}finally{if(i)throw l}}return t}}function P0(e,n){if(e){if(typeof e=="string")return zs(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);if(t==="Object"&&e.constructor&&(t=e.constructor.name),t==="Map"||t==="Set")return Array.from(e);if(t==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return zs(e,n)}}function zs(e,n){(n==null||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function $0(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function T0(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function Ls(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter(function(i){return Object.getOwnPropertyDescriptor(e,i).enumerable})),t.push.apply(t,r)}return t}function Ms(e){for(var n=1;n<arguments.length;n++){var t=arguments[n]!=null?arguments[n]:{};n%2?Ls(Object(t),!0).forEach(function(r){T0(e,r,t[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):Ls(Object(t)).forEach(function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))})}return e}function R0(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];return function(r){return n.reduceRight(function(i,l){return l(i)},r)}}function Ut(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function $i(e){return{}.toString.call(e).includes("Object")}function z0(e){return!Object.keys(e).length}function vr(e){return typeof e=="function"}function L0(e,n){return Object.prototype.hasOwnProperty.call(e,n)}function M0(e,n){return $i(n)||Ln("changeType"),Object.keys(n).some(function(t){return!L0(e,t)})&&Ln("changeField"),n}function D0(e){vr(e)||Ln("selectorType")}function j0(e){vr(e)||$i(e)||Ln("handlerType"),$i(e)&&Object.values(e).some(function(n){return!vr(n)})&&Ln("handlersType")}function A0(e){e||Ln("initialIsRequired"),$i(e)||Ln("initialType"),z0(e)&&Ln("initialContent")}function O0(e,n){throw new Error(e[n]||e.default)}var I0={initialIsRequired:"initial state is required",initialType:"initial state should be an object",initialContent:"initial state shouldn't be an empty object",handlerType:"handler should be an object or a function",handlersType:"all handlers should be a functions",selectorType:"selector should be a function",changeType:"provided value of changes should be an object",changeField:'it seams you want to change a field in the state which is not specified in the "initial" state',default:"an unknown error accured in `state-local` package"},Ln=Ut(O0)(I0),Hr={changes:M0,selector:D0,handler:j0,initial:A0};function B0(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};Hr.initial(e),Hr.handler(n);var t={current:e},r=Ut(H0)(t,n),i=Ut(U0)(t),l=Ut(Hr.changes)(e),o=Ut(W0)(t);function a(){var d=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(g){return g};return Hr.selector(d),d(t.current)}function u(d){R0(r,i,l,o)(d)}return[a,u]}function W0(e,n){return vr(n)?n(e.current):n}function U0(e,n){return e.current=Ms(Ms({},e.current),n),n}function H0(e,n,t){return vr(n)?n(e.current):Object.keys(t).forEach(function(r){var i;return(i=n[r])===null||i===void 0?void 0:i.call(n,e.current[r])}),t}var V0={create:B0},G0={paths:{vs:"https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs"}};function Q0(e){return function n(){for(var t=this,r=arguments.length,i=new Array(r),l=0;l<r;l++)i[l]=arguments[l];return i.length>=e.length?e.apply(this,i):function(){for(var o=arguments.length,a=new Array(o),u=0;u<o;u++)a[u]=arguments[u];return n.apply(t,[].concat(i,a))}}}function X0(e){return{}.toString.call(e).includes("Object")}function K0(e){return e||Ds("configIsRequired"),X0(e)||Ds("configType"),e.urls?(Y0(),{paths:{vs:e.urls.monacoBase}}):e}function Y0(){console.warn(qc.deprecation)}function Z0(e,n){throw new Error(e[n]||e.default)}var qc={configIsRequired:"the configuration object is required",configType:"the configuration object should be an object",default:"an unknown error accured in `@monaco-editor/loader` package",deprecation:`Deprecation warning!
    You are using deprecated way of configuration.

    Instead of using
      monaco.config({ urls: { monacoBase: '...' } })
    use
      monaco.config({ paths: { vs: '...' } })

    For more please check the link https://github.com/suren-atoyan/monaco-loader#config
  `},Ds=Q0(Z0)(qc),q0={config:K0},J0=function(){for(var n=arguments.length,t=new Array(n),r=0;r<n;r++)t[r]=arguments[r];return function(i){return t.reduceRight(function(l,o){return o(l)},i)}};function Jc(e,n){return Object.keys(n).forEach(function(t){n[t]instanceof Object&&e[t]&&Object.assign(n[t],Jc(e[t],n[t]))}),Rs(Rs({},e),n)}var em={type:"cancelation",msg:"operation is manually canceled"};function El(e){var n=!1,t=new Promise(function(r,i){e.then(function(l){return n?i(em):r(l)}),e.catch(i)});return t.cancel=function(){return n=!0},t}var nm=V0.create({config:G0,isInitialized:!1,resolve:null,reject:null,monaco:null}),ed=C0(nm,2),kr=ed[0],Qi=ed[1];function tm(e){var n=q0.config(e),t=n.monaco,r=E0(n,["monaco"]);Qi(function(i){return{config:Jc(i.config,r),monaco:t}})}function rm(){var e=kr(function(n){var t=n.monaco,r=n.isInitialized,i=n.resolve;return{monaco:t,isInitialized:r,resolve:i}});if(!e.isInitialized){if(Qi({isInitialized:!0}),e.monaco)return e.resolve(e.monaco),El(Cl);if(window.monaco&&window.monaco.editor)return nd(window.monaco),e.resolve(window.monaco),El(Cl);J0(im,om)(am)}return El(Cl)}function im(e){return document.body.appendChild(e)}function lm(e){var n=document.createElement("script");return e&&(n.src=e),n}function om(e){var n=kr(function(r){var i=r.config,l=r.reject;return{config:i,reject:l}}),t=lm("".concat(n.config.paths.vs,"/loader.js"));return t.onload=function(){return e()},t.onerror=n.reject,t}function am(){var e=kr(function(t){var r=t.config,i=t.resolve,l=t.reject;return{config:r,resolve:i,reject:l}}),n=window.require;n.config(e.config),n(["vs/editor/editor.main"],function(t){nd(t),e.resolve(t)},function(t){e.reject(t)})}function nd(e){kr().monaco||Qi({monaco:e})}function sm(){return kr(function(e){var n=e.monaco;return n})}var Cl=new Promise(function(e,n){return Qi({resolve:e,reject:n})}),td={config:tm,init:rm,__getMonacoInstance:sm},um={wrapper:{display:"flex",position:"relative",textAlign:"initial"},fullWidth:{width:"100%"},hide:{display:"none"}},Fl=um,cm={container:{display:"flex",height:"100%",width:"100%",justifyContent:"center",alignItems:"center"}},dm=cm;function fm({children:e}){return _e.createElement("div",{style:dm.container},e)}var pm=fm,mm=pm;function hm({width:e,height:n,isEditorReady:t,loading:r,_ref:i,className:l,wrapperProps:o}){return _e.createElement("section",{style:{...Fl.wrapper,width:e,height:n},...o},!t&&_e.createElement(mm,null,r),_e.createElement("div",{ref:i,style:{...Fl.fullWidth,...!t&&Fl.hide},className:l}))}var gm=hm,rd=F.memo(gm);function vm(e){F.useEffect(e,[])}var id=vm;function ym(e,n,t=!0){let r=F.useRef(!0);F.useEffect(r.current||!t?()=>{r.current=!1}:e,n)}var Le=ym;function Jt(){}function pt(e,n,t,r){return xm(e,r)||wm(e,n,t,r)}function xm(e,n){return e.editor.getModel(ld(e,n))}function wm(e,n,t,r){return e.editor.createModel(n,t,r?ld(e,r):void 0)}function ld(e,n){return e.Uri.parse(n)}function Sm({original:e,modified:n,language:t,originalLanguage:r,modifiedLanguage:i,originalModelPath:l,modifiedModelPath:o,keepCurrentOriginalModel:a=!1,keepCurrentModifiedModel:u=!1,theme:d="light",loading:g="Loading...",options:m={},height:p="100%",width:v="100%",className:w,wrapperProps:x={},beforeMount:L=Jt,onMount:c=Jt}){let[s,f]=F.useState(!1),[h,S]=F.useState(!0),b=F.useRef(null),C=F.useRef(null),E=F.useRef(null),j=F.useRef(c),P=F.useRef(L),H=F.useRef(!1);id(()=>{let M=td.init();return M.then(W=>(C.current=W)&&S(!1)).catch(W=>(W==null?void 0:W.type)!=="cancelation"&&console.error("Monaco initialization: error:",W)),()=>b.current?Ie():M.cancel()}),Le(()=>{if(b.current&&C.current){let M=b.current.getOriginalEditor(),W=pt(C.current,e||"",r||t||"text",l||"");W!==M.getModel()&&M.setModel(W)}},[l],s),Le(()=>{if(b.current&&C.current){let M=b.current.getModifiedEditor(),W=pt(C.current,n||"",i||t||"text",o||"");W!==M.getModel()&&M.setModel(W)}},[o],s),Le(()=>{let M=b.current.getModifiedEditor();M.getOption(C.current.editor.EditorOption.readOnly)?M.setValue(n||""):n!==M.getValue()&&(M.executeEdits("",[{range:M.getModel().getFullModelRange(),text:n||"",forceMoveMarkers:!0}]),M.pushUndoStop())},[n],s),Le(()=>{var M,W;(W=(M=b.current)==null?void 0:M.getModel())==null||W.original.setValue(e||"")},[e],s),Le(()=>{let{original:M,modified:W}=b.current.getModel();C.current.editor.setModelLanguage(M,r||t||"text"),C.current.editor.setModelLanguage(W,i||t||"text")},[t,r,i],s),Le(()=>{var M;(M=C.current)==null||M.editor.setTheme(d)},[d],s),Le(()=>{var M;(M=b.current)==null||M.updateOptions(m)},[m],s);let ve=F.useCallback(()=>{var Ce;if(!C.current)return;P.current(C.current);let M=pt(C.current,e||"",r||t||"text",l||""),W=pt(C.current,n||"",i||t||"text",o||"");(Ce=b.current)==null||Ce.setModel({original:M,modified:W})},[t,n,i,e,r,l,o]),ye=F.useCallback(()=>{var M;!H.current&&E.current&&(b.current=C.current.editor.createDiffEditor(E.current,{automaticLayout:!0,...m}),ve(),(M=C.current)==null||M.editor.setTheme(d),f(!0),H.current=!0)},[m,d,ve]);F.useEffect(()=>{s&&j.current(b.current,C.current)},[s]),F.useEffect(()=>{!h&&!s&&ye()},[h,s,ye]);function Ie(){var W,Ce,N,z;let M=(W=b.current)==null?void 0:W.getModel();a||((Ce=M==null?void 0:M.original)==null||Ce.dispose()),u||((N=M==null?void 0:M.modified)==null||N.dispose()),(z=b.current)==null||z.dispose()}return _e.createElement(rd,{width:v,height:p,isEditorReady:s,loading:g,_ref:E,className:w,wrapperProps:x})}var _m=Sm;F.memo(_m);function km(e){let n=F.useRef();return F.useEffect(()=>{n.current=e},[e]),n.current}var bm=km,Vr=new Map;function Em({defaultValue:e,defaultLanguage:n,defaultPath:t,value:r,language:i,path:l,theme:o="light",line:a,loading:u="Loading...",options:d={},overrideServices:g={},saveViewState:m=!0,keepCurrentModel:p=!1,width:v="100%",height:w="100%",className:x,wrapperProps:L={},beforeMount:c=Jt,onMount:s=Jt,onChange:f,onValidate:h=Jt}){let[S,b]=F.useState(!1),[C,E]=F.useState(!0),j=F.useRef(null),P=F.useRef(null),H=F.useRef(null),ve=F.useRef(s),ye=F.useRef(c),Ie=F.useRef(),M=F.useRef(r),W=bm(l),Ce=F.useRef(!1),N=F.useRef(!1);id(()=>{let R=td.init();return R.then(D=>(j.current=D)&&E(!1)).catch(D=>(D==null?void 0:D.type)!=="cancelation"&&console.error("Monaco initialization: error:",D)),()=>P.current?A():R.cancel()}),Le(()=>{var D,te,xe,Re;let R=pt(j.current,e||r||"",n||i||"",l||t||"");R!==((D=P.current)==null?void 0:D.getModel())&&(m&&Vr.set(W,(te=P.current)==null?void 0:te.saveViewState()),(xe=P.current)==null||xe.setModel(R),m&&((Re=P.current)==null||Re.restoreViewState(Vr.get(l))))},[l],S),Le(()=>{var R;(R=P.current)==null||R.updateOptions(d)},[d],S),Le(()=>{!P.current||r===void 0||(P.current.getOption(j.current.editor.EditorOption.readOnly)?P.current.setValue(r):r!==P.current.getValue()&&(N.current=!0,P.current.executeEdits("",[{range:P.current.getModel().getFullModelRange(),text:r,forceMoveMarkers:!0}]),P.current.pushUndoStop(),N.current=!1))},[r],S),Le(()=>{var D,te;let R=(D=P.current)==null?void 0:D.getModel();R&&i&&((te=j.current)==null||te.editor.setModelLanguage(R,i))},[i],S),Le(()=>{var R;a!==void 0&&((R=P.current)==null||R.revealLine(a))},[a],S),Le(()=>{var R;(R=j.current)==null||R.editor.setTheme(o)},[o],S);let z=F.useCallback(()=>{var R;if(!(!H.current||!j.current)&&!Ce.current){ye.current(j.current);let D=l||t,te=pt(j.current,r||e||"",n||i||"",D||"");P.current=(R=j.current)==null?void 0:R.editor.create(H.current,{model:te,automaticLayout:!0,...d},g),m&&P.current.restoreViewState(Vr.get(D)),j.current.editor.setTheme(o),a!==void 0&&P.current.revealLine(a),b(!0),Ce.current=!0}},[e,n,t,r,i,l,d,g,m,o,a]);F.useEffect(()=>{S&&ve.current(P.current,j.current)},[S]),F.useEffect(()=>{!C&&!S&&z()},[C,S,z]),M.current=r,F.useEffect(()=>{var R,D;S&&f&&((R=Ie.current)==null||R.dispose(),Ie.current=(D=P.current)==null?void 0:D.onDidChangeModelContent(te=>{N.current||f(P.current.getValue(),te)}))},[S,f]),F.useEffect(()=>{if(S){let R=j.current.editor.onDidChangeMarkers(D=>{var xe;let te=(xe=P.current.getModel())==null?void 0:xe.uri;if(te&&D.find(Re=>Re.path===te.path)){let Re=j.current.editor.getModelMarkers({resource:te});h==null||h(Re)}});return()=>{R==null||R.dispose()}}return()=>{}},[S,h]);function A(){var R,D;(R=Ie.current)==null||R.dispose(),p?m&&Vr.set(l,P.current.saveViewState()):(D=P.current.getModel())==null||D.dispose(),P.current.dispose()}return _e.createElement(rd,{width:v,height:w,isEditorReady:S,loading:u,_ref:H,className:x,wrapperProps:L})}var Cm=Em,Fm=F.memo(Cm),Nm=Fm;const Pm=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{include:"#keywords"}],$m={keywords:{patterns:[{name:"entity.name.class",match:"\\b(sheet|allowedExtraPoints|states|center)\\b"},{name:"keyword",match:"\\b(animation)\\b"},{name:"entity.name.type",match:"\\b(name|fps|playlist|sheet|extrapoints|playlist|loop|event|goto|hit|random|trigger|command|frames|untilCommand|duration|file)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},Tm={patterns:Pm,repository:$m},Rm=[{include:"#strings"},{name:"comment.line.double-slash",match:"//.*$"},{name:"variable.name",match:"\\$[A-Za-z][A-Za-z0-9]*"},{name:"entity.name.tag",match:"#[A-Za-z][A-Za-z0-9\\-]*\\b"},{begin:"(@|@if|@ifstrict)\\(",beginCaptures:{0:{name:"keyword.control.at-sign"}},end:"\\)",endCaptures:{0:{name:"keyword.control.parenthesis"}},name:"meta.condition-block",contentName:"meta.condition-content",patterns:[{match:"\\b([A-Za-z_][A-Za-z0-9_]*)\\s*=>",name:"meta.condition-pair",captures:{0:{name:"keyword.other"},1:{name:"variable.other.key"}}},{match:"([A-Za-z_][A-Za-z0-9_]*)",name:"constant.other.value"},{match:",",name:"punctuation.separator.comma"}]},{name:"entity.name.method",match:"\\b@[A-Za-z][A-Za-z0-9]*\\b"},{include:"#keywords"}],zm={keywords:{patterns:[{name:"entity.name.class",match:"\\b(animatedPath|particles|programmable|stateanim|flow|apply|text|tilegroup|repeatable|ninepatch|layers|placeholder|reference|bitmap|point|interactive|pixels|relativeLayouts|palettes|paths)\\b"},{name:"keyword",match:"\\b(external|path|debug|version|nothing|list|line|flat|pointy|layer|layout|callback|builderParam|tileSource|sheet|file|generated|hex|hexCorner|hexEdge|grid|settings|pos|alpha|blendMode|scale|updatable|cross|function|gridWidth|gridHeight|center|left|right|top|bottom|offset|construct|palette|position|import|filter)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"},{name:"entity.name.type",match:"\\b(int|uint|flags|string|hexdirection|griddirection|bool|color)\\b"}]},strings:{name:"string.quoted.double",begin:'"',end:'"',patterns:[{name:"constant.character.escape.multianim",match:"\\\\."}]}},Lm={patterns:Rm,repository:zm},js=e=>{const n={root:[]};return e.patterns&&e.patterns.forEach(t=>{if(t.include){const r=t.include.replace("#","");e.repository&&e.repository[r]&&e.repository[r].patterns.forEach(l=>{l.match&&n.root.push([new RegExp(l.match),l.name||"identifier"])})}else t.match&&n.root.push([new RegExp(t.match),t.name||"identifier"])}),e.repository&&Object.keys(e.repository).forEach(t=>{const r=e.repository[t];r.patterns&&(n[t]=r.patterns.map(i=>i.match?[new RegExp(i.match),i.name||"identifier"]:["",""]).filter(([i])=>i!==""))}),n},od=F.forwardRef(({value:e,onChange:n,language:t="text",disabled:r=!1,placeholder:i,onSave:l,errorLine:o,errorColumn:a,errorStart:u,errorEnd:d},g)=>{const m=F.useRef(null),p=F.useRef(),v=F.useRef([]);F.useEffect(()=>{p.current=l},[l]),F.useEffect(()=>{if(m.current&&(v.current.length>0&&(m.current.deltaDecorations(v.current,[]),v.current=[]),o)){const c=[];if(c.push({range:{startLineNumber:o,startColumn:1,endLineNumber:o,endColumn:1},options:{isWholeLine:!0,className:"error-line",glyphMarginClassName:"error-glyph",linesDecorationsClassName:"error-line-decoration"}}),u!==void 0&&d!==void 0){const s=m.current.getModel();if(s)try{const f=s.getPositionAt(u),h=s.getPositionAt(d);c.push({range:{startLineNumber:f.lineNumber,startColumn:f.column,endLineNumber:h.lineNumber,endColumn:h.column},options:{className:"error-token",hoverMessage:{value:"Parse error at this position"}}})}catch(f){console.log("Error calculating character position:",f)}}v.current=m.current.deltaDecorations([],c)}},[o,a,u,d]);const w=(c,s)=>{m.current=c,s.languages.register({id:"haxe-anim"}),s.languages.register({id:"haxe-manim"});const f=js(Tm);s.languages.setMonarchTokensProvider("haxe-anim",{tokenizer:f});const h=js(Lm);s.languages.setMonarchTokensProvider("haxe-manim",{tokenizer:h}),c.addAction({id:"save-file",label:"Save File",keybindings:[s.KeyMod.CtrlCmd|s.KeyCode.KeyS],run:()=>{p.current&&p.current()}}),c.focus()},x=c=>{c!==void 0&&n(c)},L=()=>t==="typescript"&&(e.includes("class")||e.includes("function")||e.includes("var"))?"haxe-manim":t;return _.jsxs("div",{ref:g,className:"w-full h-full min-h-[200px] border border-zinc-700 rounded overflow-hidden",style:{minHeight:200},children:[_.jsx("style",{children:`
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
        `}),_.jsx(Nm,{height:"100%",defaultLanguage:L(),value:e,onChange:x,onMount:w,options:{readOnly:r,minimap:{enabled:!1},scrollBeyondLastLine:!1,fontSize:12,fontFamily:'Consolas, Monaco, "Courier New", monospace',lineNumbers:"on",roundedSelection:!1,scrollbar:{vertical:"visible",horizontal:"visible",verticalScrollbarSize:8,horizontalScrollbarSize:8},automaticLayout:!0,wordWrap:"on",theme:"vs-dark",tabSize:2,insertSpaces:!0,detectIndentation:!1,trimAutoWhitespace:!0,largeFileOptimizations:!1,placeholder:i,suggest:{showKeywords:!0,showSnippets:!0,showClasses:!0,showFunctions:!0,showVariables:!0},quickSuggestions:{other:!0,comments:!1,strings:!1}},theme:"vs-dark"})]})});od.displayName="CodeEditor";function Mm(e){var n,t,r,i,l,o,a;if(!e)return null;if(e.__nativeException){const u=e.__nativeException;return{message:u.message||((n=u.toString)==null?void 0:n.call(u))||"Unknown error occurred",pos:(t=u.value)==null?void 0:t.pos,token:(r=u.value)==null?void 0:r.token}}if((i=e.value)!=null&&i.__nativeException){const u=e.value.__nativeException;return{message:u.message||((l=u.toString)==null?void 0:l.call(u))||"Unknown error occurred",pos:(o=u.value)==null?void 0:o.pos,token:(a=u.value)==null?void 0:a.token}}return e.error?{message:e.error,pos:e.pos,token:e.token}:e.success===!1?{message:e.error||"Operation failed",pos:e.pos,token:e.token}:null}function Dm(e){var t;let n="Unknown error occurred";try{if(e instanceof Error)n=e.message;else if(typeof e=="string")n=e;else if(e&&typeof e=="object"){const r=e;n=r.message||((t=r.toString)==null?void 0:t.call(r))||"Error occurred"}}catch{n="Error occurred (could not serialize)"}return{message:n}}const li="draggable";function jm(){var wa;const[e,n]=F.useState(li),[t,r]=F.useState(""),[i,l]=F.useState(""),[o,a]=F.useState(!1),[u,d]=F.useState(""),[g,m]=F.useState(!1),[p,v]=F.useState(null),[w,x]=F.useState(null),[L,c]=F.useState(!0),[s]=F.useState(()=>new _0),[f,h]=F.useState(250),[S,b]=F.useState(400),[C,E]=F.useState(180),[j,P]=F.useState(!1),[H,ve]=F.useState([]),ye=F.useRef(null),Ie=F.useRef(null),M=F.useRef(!1),W=F.useRef(null),Ce=F.useRef(null),N=F.useRef(!1),z=F.useRef("");F.useEffect(()=>{L&&w&&x(null)},[L,w]),F.useEffect(()=>{const y=console.log,T=console.error,I=console.warn,X=console.info,re=(K,...br)=>{const $t=br.map(Qe=>{var Er;if(typeof Qe=="object")try{return JSON.stringify(Qe,null,2)}catch{return((Er=Qe.toString)==null?void 0:Er.call(Qe))||"[Circular Object]"}return String(Qe)}).join(" ");ve(Qe=>[...Qe,{type:K,message:$t,timestamp:new Date}])};return console.log=(...K)=>{y(...K),re("log",...K)},console.error=(...K)=>{T(...K),re("error",...K)},console.warn=(...K)=>{I(...K),re("warn",...K)},console.info=(...K)=>{X(...K),re("info",...K)},()=>{console.log=y,console.error=T,console.warn=I,console.info=X}},[]),F.useEffect(()=>{ye.current&&(ye.current.scrollTop=ye.current.scrollHeight)},[H]);const A=()=>{ve([])},R=_e.useMemo(()=>{const y=new Map;return s.screens.forEach(T=>{T.manimFile&&y.set(T.manimFile,T.name)}),y},[s.screens]),D=_e.useCallback(y=>{if(!y.endsWith(".manim")){x(null);return}const T=R.get(y);T&&T!==e?L?n(T):x({file:y,screen:T}):x(null)},[R,e,L,s]),te=()=>{w&&(n(w.screen),x(null))},xe=()=>{x(null)},Re=y=>{switch(y){case"error":return"text-red-400";case"warn":return"text-yellow-400";case"info":return"text-blue-400";default:return"text-gray-300"}},an=y=>{switch(y){case"error":return"[ERR]";case"warn":return"[WRN]";case"info":return"[INF]";default:return"[LOG]"}};F.useEffect(()=>{const y=()=>{var I;(I=window.PlaygroundMain)!=null&&I.defaultScreen&&n(window.PlaygroundMain.defaultScreen)};y();const T=setTimeout(y,100);return()=>clearTimeout(T)},[]),F.useEffect(()=>(window.playgroundLoader=s,window.defaultScreen=li,s.onContentChanged=y=>{l(y)},()=>{s.dispose()}),[s]);function yn(y){try{const T=s.reloadPlayground(y);v(Mm(T))}catch(T){v(Dm(T))}}F.useEffect(()=>{if(s.manimFiles.length===0||!e)return;if(M.current){M.current=!1;return}const y=s.screens.find(T=>T.name===e);if(y&&y.manimFile){const T=s.manimFiles.find(I=>I.filename===y.manimFile);T&&(r(y.manimFile),l(T.content||""),d(T.description),a(!0),s.currentFile=y.manimFile,s.currentExample=y.manimFile,m(!1),yn(e))}},[e,s.manimFiles]);const ud=()=>{if(t&&s.manimFiles.find(y=>y.filename===t))return t;if(e&&s.manimFiles.length>0){const y=s.screens.find(I=>I.name===e);if(y&&y.manimFile){const I=s.manimFiles.find(X=>X.filename===y.manimFile);if(I)return r(y.manimFile),(!i||i.trim()==="")&&l(I.content||""),d(I.description),a(!0),s.currentFile=y.manimFile,s.currentExample=y.manimFile,y.manimFile}const T=s.manimFiles[0];return r(T.filename),(!i||i.trim()==="")&&l(T.content||""),d(T.description),a(!0),s.currentFile=T.filename,s.currentExample=T.filename,T.filename}if(s.manimFiles.length>0){const y=s.manimFiles[0];return r(y.filename),s.currentFile=y.filename,s.currentExample=y.filename,y.filename}return null},cd=y=>{const T=y.target.value;n(T),x(null)},va=_e.useMemo(()=>{const y=new Map;return s.manimFiles.forEach(T=>y.set(T.filename,T)),y},[s.manimFiles]),ya=_e.useMemo(()=>{const y=new Map;return s.animFiles.forEach(T=>y.set(T.filename,T)),y},[s.animFiles]),Xi=_e.useCallback(y=>{const T=y.target.value;if(r(T),T){if(T.endsWith(".manim")){const I=va.get(T);I&&(l(I.content||""),d(I.description),a(!0),s.currentFile=T,s.currentExample=T,m(!1),D(T))}else if(T.endsWith(".anim")){const I=ya.get(T);I&&(l(I.content||""),d("Animation file - viewing in Animation Viewer"),a(!0),s.currentFile=T,s.currentExample=T,m(!1),x(null),M.current=!0,n("animViewer"),yn("animViewer"))}}else l(""),a(!1),s.currentFile=null,s.currentExample=null,m(!1),x(null)},[va,ya,D,s]),dd=_e.useCallback(y=>{l(y),m(!0)},[]),fd=()=>{const y=ud();y&&(s.updateContent(y,i),ii(y,i),m(!1),e&&yn(e))},xa=_e.useCallback(()=>{fd()},[t,i,e,s]),we=_e.useMemo(()=>{if(!(p!=null&&p.pos))return null;const{pmin:y,pmax:T}=p.pos,I=i;let X=1,re=1;for(let K=0;K<y&&K<I.length;K++)I[K]===`
`?(X++,re=1):re++;return{line:X,column:re,start:y,end:T}},[p==null?void 0:p.pos,i]),Ki=y=>T=>{N.current=!0,z.current=y,T.preventDefault()};return F.useEffect(()=>{const y=I=>{if(N.current){if(z.current==="file"){const X=I.clientX;X>150&&X<window.innerWidth-300&&h(X)}else if(z.current==="editor"){const X=I.clientX-f;X>200&&X<window.innerWidth-f-200&&b(X)}else if(z.current==="console"&&Ie.current){const X=Ie.current.getBoundingClientRect(),re=X.bottom-I.clientY;re>50&&re<X.height-100&&E(re)}}},T=()=>{N.current=!1,z.current=""};return document.addEventListener("mousemove",y),document.addEventListener("mouseup",T),()=>{document.removeEventListener("mousemove",y),document.removeEventListener("mouseup",T)}},[f,S]),F.useEffect(()=>{window.PlaygroundMain||(window.PlaygroundMain={}),window.PlaygroundMain.defaultScreen=li},[]),F.useEffect(()=>{function y(I){var br;const X=((br=I.error)==null?void 0:br.message)||I.message||"Unknown error",re=X.match(/at ([^:]+):(\d+): characters (\d+)-(\d+)/);let K;if(re){const $t=parseInt(re[2],10),Qe=parseInt(re[3],10),Er=parseInt(re[4],10),Sa=i.split(`
`);let Cr=0;for(let Yi=0;Yi<$t-1;Yi++)Cr+=Sa[Yi].length+1;Cr+=Qe;let pd=Cr+(Er-Qe);K={psource:"",pmin:Cr,pmax:pd}}K&&v({message:X,pos:K,token:void 0}),ve($t=>[...$t,{type:"error",message:X,timestamp:new Date}])}function T(I){var re;const X=((re=I.reason)==null?void 0:re.message)||String(I.reason)||"Unhandled promise rejection";ve(K=>[...K,{type:"error",message:X,timestamp:new Date}])}return window.addEventListener("error",y),window.addEventListener("unhandledrejection",T),()=>{window.removeEventListener("error",y),window.removeEventListener("unhandledrejection",T)}},[i]),_.jsxs("div",{className:"flex h-screen w-screen bg-gray-900 text-white",children:[_.jsxs("div",{ref:W,className:"bg-gray-800 border-r border-gray-700 flex flex-col",style:{width:f},children:[_.jsxs("div",{className:"p-3 border-b border-gray-700",children:[_.jsxs("div",{className:"mb-3",children:[_.jsx("label",{className:"block mb-1 text-xs font-medium text-gray-300",children:"Screen:"}),_.jsx("select",{className:"w-full p-1.5 bg-gray-700 border border-gray-600 text-white text-xs rounded focus:outline-none focus:border-blue-500",value:e,onChange:cd,children:s.screens.map(y=>_.jsx("option",{value:y.name,children:y.displayName},y.name))})]}),o&&_.jsxs("div",{className:"p-2 bg-gray-700 border border-gray-600 rounded text-xs text-gray-300 leading-relaxed",children:[_.jsx("p",{className:"mb-1 line-clamp-3",children:u}),_.jsx("a",{href:`https://github.com/bh213/hx-multianim/blob/main/playground/src/screens/${s.getScreenHaxeFile(e)}`,target:"_blank",rel:"noopener noreferrer",className:"text-blue-400 hover:text-blue-300 transition-colors",children:"View source on GitHub"})]})]}),_.jsxs("div",{className:"flex-1 p-3 min-h-0",children:[_.jsx("div",{className:"text-xs text-gray-400 mb-2 font-medium",children:"Files"}),_.jsxs("div",{className:"space-y-0.5 scrollable",style:{maxHeight:"calc(100vh - 250px)"},children:[s.manimFiles.filter(y=>!y.isLibrary).map(y=>_.jsx("div",{className:`px-2 py-1.5 rounded cursor-pointer text-xs ${t===y.filename?"bg-blue-600 text-white":"text-gray-300 hover:bg-gray-700"}`,onClick:()=>Xi({target:{value:y.filename}}),children:y.filename},y.filename)),s.manimFiles.some(y=>y.isLibrary)&&_.jsxs("div",{className:"border-t border-gray-600 my-1 pt-1",children:[_.jsx("div",{className:"text-xs text-gray-500 px-2 py-0.5 mb-0.5",children:"Library"}),s.manimFiles.filter(y=>y.isLibrary).map(y=>_.jsx("div",{className:`px-2 py-1.5 rounded cursor-pointer text-xs italic ${t===y.filename?"bg-blue-600 text-white":"text-gray-500 hover:bg-gray-700"}`,onClick:()=>Xi({target:{value:y.filename}}),children:y.filename},y.filename))]}),s.animFiles.length>0&&_.jsxs("div",{className:"border-t border-gray-600 my-1 pt-1",children:[_.jsx("div",{className:"text-xs text-gray-500 px-2 py-0.5 mb-0.5",children:"Animations"}),s.animFiles.map(y=>_.jsx("div",{className:`px-2 py-1.5 rounded cursor-pointer text-xs ${t===y.filename?"bg-blue-600 text-white":"text-gray-400 hover:bg-gray-700"}`,onClick:()=>Xi({target:{value:y.filename}}),children:y.filename},y.filename))]})]})]})]}),_.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Ki("file")}),_.jsxs("div",{ref:Ce,className:"bg-gray-900 flex flex-col",style:{width:S},children:[_.jsxs("div",{className:"p-3 border-b border-gray-700",children:[_.jsxs("div",{className:"flex items-center justify-between mb-1",children:[_.jsxs("div",{className:"flex items-center space-x-3",children:[_.jsx("h2",{className:"text-sm font-semibold text-gray-200",children:"Editor"}),_.jsxs("label",{className:"flex items-center space-x-1.5 text-xs text-gray-400",children:[_.jsx("input",{type:"checkbox",checked:L,onChange:y=>c(y.target.checked),className:"w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-1"}),_.jsx("span",{children:"Auto sync"})]})]}),g&&_.jsx("button",{className:"px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition",onClick:xa,title:"Save changes and reload playground (Ctrl+S)",children:"Apply (Ctrl+S)"})]}),g&&!p&&_.jsx("div",{className:"text-xs text-orange-400",children:"Unsaved changes"}),p&&_.jsxs("div",{className:"p-2 bg-red-900/20 border border-red-700 rounded mt-1",children:[_.jsxs("div",{className:"flex justify-between items-start",children:[_.jsx("div",{className:"text-red-300 text-xs",children:p.message}),_.jsx("button",{className:"text-red-300 hover:text-red-100 text-xs ml-2",onClick:()=>v(null),title:"Clear error",children:"✕"})]}),we&&_.jsxs("div",{className:"text-red-400 text-xs mt-1",children:["Line ",we.line,", Column ",we.column]})]})]}),_.jsx("div",{className:"flex-1 scrollable",children:_.jsx(od,{value:i,onChange:dd,language:"haxe-manim",disabled:!t,placeholder:"Select a manim file to load its content here...",onSave:xa,errorLine:we==null?void 0:we.line,errorColumn:we==null?void 0:we.column,errorStart:we==null?void 0:we.start,errorEnd:we==null?void 0:we.end})}),w&&_.jsxs("div",{className:"p-2 bg-blue-900/20 border-t border-blue-700",children:[_.jsxs("div",{className:"text-blue-300 text-xs mb-2",children:["Switch to ",_.jsx("strong",{children:((wa=s.screens.find(y=>y.name===w.screen))==null?void 0:wa.displayName)||w.screen}),"?"]}),_.jsxs("div",{className:"flex space-x-2",children:[_.jsx("button",{onClick:te,className:"px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded transition-colors",children:"Switch"}),_.jsx("button",{onClick:xe,className:"px-2 py-1 bg-gray-600 hover:bg-gray-700 text-white text-xs rounded transition-colors",children:"Keep"})]})]})]}),_.jsx("div",{className:"w-1 bg-gray-700 cursor-col-resize hover:bg-blue-500 transition-colors",onMouseDown:Ki("editor")}),_.jsxs("div",{ref:Ie,className:"flex-1 bg-gray-900 flex flex-col h-full min-h-0",children:[_.jsxs("div",{className:"border-b border-gray-700 flex-shrink-0 flex items-center justify-between px-3 py-1.5",children:[_.jsx("span",{className:"text-xs font-medium text-gray-200",children:"Playground"}),_.jsx("button",{onClick:()=>P(!0),className:"text-xs text-gray-400 hover:text-white transition-colors",title:"About this playground",children:"Info"})]}),_.jsx("div",{className:"flex-1 min-h-0",children:_.jsx("canvas",{id:"webgl",className:"w-full h-full block"})}),_.jsx("div",{className:"h-1 bg-gray-700 cursor-row-resize hover:bg-blue-500 transition-colors flex-shrink-0",onMouseDown:Ki("console")}),_.jsxs("div",{className:"flex flex-col flex-shrink-0",style:{height:C},children:[_.jsxs("div",{className:"px-3 py-1.5 border-b border-gray-700 flex justify-between items-center flex-shrink-0",children:[_.jsxs("h3",{className:"text-xs font-medium text-gray-200",children:["Console",H.some(y=>y.type==="error")&&_.jsxs("span",{className:"ml-1.5 text-red-400",children:["(",H.filter(y=>y.type==="error").length," errors)"]})]}),_.jsx("button",{onClick:A,className:"px-1.5 py-0.5 text-xs text-gray-400 hover:text-gray-200 rounded transition-colors",title:"Clear console",children:"Clear"})]}),_.jsx("div",{ref:ye,className:"flex-1 px-3 py-2 bg-gray-800 text-xs font-mono overflow-y-auto overflow-x-hidden min-h-0",children:H.length===0?_.jsx("div",{className:"text-gray-500 text-center py-4",children:"Console output will appear here."}):_.jsx("div",{className:"space-y-0.5",children:H.map((y,T)=>_.jsxs("div",{className:"flex items-start space-x-1.5",children:[_.jsx("span",{className:"text-gray-600 whitespace-nowrap",children:y.timestamp.toLocaleTimeString()}),_.jsx("span",{className:`${Re(y.type)} whitespace-nowrap`,children:an(y.type)}),_.jsx("span",{className:`${Re(y.type)} break-all`,children:y.message})]},T))})})]})]}),j&&_.jsx("div",{className:"fixed inset-0 z-50 flex items-center justify-center bg-black/50",onClick:()=>P(!1),children:_.jsxs("div",{className:"bg-gray-800 border border-gray-600 rounded-lg p-5 max-w-md w-full mx-4",onClick:y=>y.stopPropagation(),children:[_.jsxs("div",{className:"flex justify-between items-center mb-4",children:[_.jsx("h3",{className:"text-sm font-semibold text-gray-200",children:"About hx-multianim Playground"}),_.jsx("button",{onClick:()=>P(!1),className:"text-gray-400 hover:text-white text-sm",children:"✕"})]}),_.jsxs("div",{className:"space-y-4",children:[_.jsxs("div",{children:[_.jsx("h4",{className:"text-xs font-medium text-gray-300 mb-2",children:"Links"}),_.jsxs("div",{className:"space-y-1.5",children:[_.jsxs("a",{href:"https://github.com/bh213/hx-multianim",target:"_blank",rel:"noopener noreferrer",className:"block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs",children:[_.jsx("span",{className:"text-blue-400",children:"hx-multianim"}),_.jsx("span",{className:"text-gray-400 ml-2",children:"- Animation library for Haxe"})]}),_.jsxs("a",{href:"https://github.com/HeapsIO/heaps",target:"_blank",rel:"noopener noreferrer",className:"block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs",children:[_.jsx("span",{className:"text-blue-400",children:"Heaps"}),_.jsx("span",{className:"text-gray-400 ml-2",children:"- Cross-platform graphics framework"})]}),_.jsxs("a",{href:"https://haxe.org",target:"_blank",rel:"noopener noreferrer",className:"block p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors text-xs",children:[_.jsx("span",{className:"text-blue-400",children:"Haxe"}),_.jsx("span",{className:"text-gray-400 ml-2",children:"- Cross-platform programming language"})]})]})]}),_.jsxs("div",{children:[_.jsx("h4",{className:"text-xs font-medium text-gray-300 mb-2",children:"Tips"}),_.jsxs("ul",{className:"text-xs text-gray-400 space-y-1",children:[_.jsx("li",{children:"Ctrl+S to apply changes and reload"}),_.jsx("li",{children:"Drag dividers to resize panels"}),_.jsx("li",{children:"Select files from the sidebar to edit"}),_.jsx("li",{children:"Errors show inline in the editor"})]})]})]})]})})]})}var ad={exports:{}};(function(e,n){(function(t,r){e.exports=r()})(gd,function(){var t=function(){},r={},i={},l={};function o(p,v){p=p.push?p:[p];var w=[],x=p.length,L=x,c,s,f,h;for(c=function(S,b){b.length&&w.push(S),L--,L||v(w)};x--;){if(s=p[x],f=i[s],f){c(s,f);continue}h=l[s]=l[s]||[],h.push(c)}}function a(p,v){if(p){var w=l[p];if(i[p]=v,!!w)for(;w.length;)w[0](p,v),w.splice(0,1)}}function u(p,v){p.call&&(p={success:p}),v.length?(p.error||t)(v):(p.success||t)(p)}function d(p,v,w,x){var L=document,c=w.async,s=(w.numRetries||0)+1,f=w.before||t,h=p.replace(/[\?|#].*$/,""),S=p.replace(/^(css|img|module|nomodule)!/,""),b,C,E;if(x=x||0,/(^css!|\.css$)/.test(h))E=L.createElement("link"),E.rel="stylesheet",E.href=S,b="hideFocus"in E,b&&E.relList&&(b=0,E.rel="preload",E.as="style");else if(/(^img!|\.(png|gif|jpg|svg|webp)$)/.test(h))E=L.createElement("img"),E.src=S;else if(E=L.createElement("script"),E.src=S,E.async=c===void 0?!0:c,C="noModule"in E,/^module!/.test(h)){if(!C)return v(p,"l");E.type="module"}else if(/^nomodule!/.test(h)&&C)return v(p,"l");E.onload=E.onerror=E.onbeforeload=function(j){var P=j.type[0];if(b)try{E.sheet.cssText.length||(P="e")}catch(H){H.code!=18&&(P="e")}if(P=="e"){if(x+=1,x<s)return d(p,v,w,x)}else if(E.rel=="preload"&&E.as=="style")return E.rel="stylesheet";v(p,P,j.defaultPrevented)},f(p,E)!==!1&&L.head.appendChild(E)}function g(p,v,w){p=p.push?p:[p];var x=p.length,L=x,c=[],s,f;for(s=function(h,S,b){if(S=="e"&&c.push(h),S=="b")if(b)c.push(h);else return;x--,x||v(c)},f=0;f<L;f++)d(p[f],s,w)}function m(p,v,w){var x,L;if(v&&v.trim&&(x=v),L=(x?w:v)||{},x){if(x in r)throw"LoadJS";r[x]=!0}function c(s,f){g(p,function(h){u(L,h),s&&u({success:s,error:f},h),a(x,h)},L)}if(L.returnPromise)return new Promise(c);c()}return m.ready=function(v,w){return o(v,function(x){u(w,x)}),m},m.done=function(v){a(v,[])},m.reset=function(){r={},i={},l={}},m.isDefined=function(v){return v in r},m})})(ad);var Am=ad.exports;const As=Os(Am);class Om{constructor(n={}){fe(this,"maxRetries");fe(this,"retryDelay");fe(this,"timeout");fe(this,"retryCount",0);fe(this,"isLoaded",!1);this.maxRetries=n.maxRetries||5,this.retryDelay=n.retryDelay||2e3,this.timeout=n.timeout||1e4}waitForReactApp(){document.getElementById("root")&&window.playgroundLoader?(console.log("React app ready, loading Haxe application..."),this.loadHaxeApp()):setTimeout(()=>this.waitForReactApp(),300)}loadHaxeApp(){console.log(`Attempting to load playground.js (attempt ${this.retryCount+1}/${this.maxRetries+1})`);const n=setTimeout(()=>{console.error("Timeout loading playground.js"),this.handleLoadError()},this.timeout);As("playground.js",{success:()=>{clearTimeout(n),console.log("playground.js loaded successfully"),this.isLoaded=!0,this.waitForHaxeApp()},error:t=>{clearTimeout(n),console.error("Failed to load playground.js:",t),this.handleLoadError()}})}handleLoadError(){this.retryCount++,this.retryCount<=this.maxRetries?(console.log(`Retrying in ${this.retryDelay}ms... (${this.retryCount}/${this.maxRetries})`),setTimeout(()=>{this.loadHaxeApp()},this.retryDelay)):(console.error(`Failed to load playground.js after ${this.maxRetries} retries`),this.showErrorUI())}showErrorUI(){const n=document.createElement("div");n.style.cssText=`
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
    `,document.body.appendChild(n)}waitForHaxeApp(){As.ready("playground.js",()=>{console.log("playground.js is ready and executed"),this.waitForPlaygroundMain()})}waitForPlaygroundMain(){typeof window.PlaygroundMain<"u"&&window.PlaygroundMain.instance?(console.log("Haxe application initialized successfully"),window.playgroundLoader&&window.playgroundLoader.mainApp===null&&(window.playgroundLoader.mainApp=window.PlaygroundMain.instance)):setTimeout(()=>this.waitForPlaygroundMain(),100)}start(){document.readyState==="loading"?document.addEventListener("DOMContentLoaded",()=>this.waitForReactApp()):this.waitForReactApp()}isScriptLoaded(){return this.isLoaded}getRetryCount(){return this.retryCount}}const sd=new Om({maxRetries:5,retryDelay:2e3,timeout:1e4});sd.start();window.haxeLoader=sd;Nl.createRoot(document.getElementById("root")).render(_.jsx(_e.StrictMode,{children:_.jsx(jm,{})}));
//# sourceMappingURL=index-CXNebjDk.js.map
