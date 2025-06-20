package wt.base;

import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.Tools;


class MacroUtils {

	public static macro function identToString(i:Expr) {
		switch i.expr {
			case EConst(CIdent(name)):
				return {
					pos: i.pos,
					expr: EConst(CString(name))
				};
			case EField(_, name):
				return {
					pos: i.pos,
					expr: EConst(CString(name))
				};

			default:
				throw 'invalid input ${i} for identToString';
		}
	}

    public static macro function optionsSetIfNotNull(input:Expr, map:ExprOf<Map<String, Dynamic>>) {
        final val = macro if ($map.exists(MacroUtils.identToString($input))) $input = $map[MacroUtils.identToString($input)];
        return val;
    }

    public static macro function optionsGetPresentOrDefault(input:Expr, map:ExprOf<Map<String, Dynamic>>, defaultValue:Expr) {
        return macro if ($map.exists(MacroUtils.identToString($input))) $map[MacroUtils.identToString($input)] else $defaultValue;
    }



    static function getString(e:Expr):String {
        return switch e.expr {
            case EConst(CIdent(name)): name;
            case EConst(CString(name)): name;
            default:  throw 'expected "string" or ident';
        }

    }


    // This function automates adding UIElements to multianimbuilder as placeholder. It supports adding fields, instance fields and factory methods.
    // It will generate local function that will call buildWithParameters and return new anon structure with UIElement inputs resolved (for factory/new()).
    //
    // var res = MacroUtils.macroBuildWithParameters(builder, "ui", [], [dialog1=>yesNoDialog, dialog2=> fileDialog]);
    // This code will add yesNoDialog & fileDialog to screen (this method must be run inside UIScreen), convert them to appropriate MultiAnimBuilder.buildWithParameters properties and then return
    // built result and all passed inputs. For example above, res would be:
    //  res == { dialog1: yesNoDialog, dialog2=>fileDialog, buildingResults: <result of MultiAnimBuilder.buildWithParameters>}. fileDialog & yesNoDialog returned are the same instance as passed in.

    public static macro function macroBuildWithParameters(builder:Expr, builderName:ExprOf<String>, inputParams:Expr, builderParams:Expr):Expr {
    #if macro        
        final clazz = Context.getLocalType();
        
        final uiScreenBase = haxe.macro.ComplexTypeTools.toType(macro:wt.ui.screens.UIScreen.UIScreenBase);
        if (clazz == null || TypeTools.unify(clazz, uiScreenBase) == false)  throw '${clazz} should implement UIScreenBase';

        var factoryFunctionsUIElements:Map<String, Expr> = [];
        var factoryFunctionsH2dObjects:Map<String, Expr> = [];
        var providedValues:Map<String, Expr> = [];
        var newValues:Map<String, Expr> = [];
        final h2dObjectType = haxe.macro.ComplexTypeTools.toType(macro:h2d.Object);
        final uiElementType = haxe.macro.ComplexTypeTools.toType(macro:wt.ui.UIElement);


        switch builderParams.expr {
            case EArrayDecl(values): 
                for (v in values) {
                    switch (v.expr) {
                        case EBinop(op, name, funcExpr):  
                            switch op {
                                case OpArrow:
                                    switch funcExpr.expr {
                                        case ECall(e, callParams):
                                            
                                            var funcType = Context.typeof(e);
                                            switch funcType {
                                                case TFun(args, ret):
                                                        
                                                    switch ret {
                                                        case TInst(t, params):
                                                            if (TypeTools.unify(ret, uiElementType)) {
                                                                factoryFunctionsUIElements.set(getString(name), funcExpr);
                                                            }
                                                            else if (TypeTools.unify(ret, h2dObjectType)) {
                                                                factoryFunctionsH2dObjects.set(getString(name), funcExpr);
                                                            }
                                                            else throw '${ExprTools.toString(e)} should have UIElement or h2d.Object return value';
                                                            
                                                        default: throw '${ExprTools.toString(e)} should have UIElement or h2d.Object return value';
                                                    }
                                                    for (index => value in args) {
                                                        switch value.t {
                                                            case TType(t, params):
                                                                var settings = haxe.macro.Context.getType("wt.multianim.MultiAnimParser.ResolvedSettings");
                                                                    if (TypeTools.unify(value.t, settings)) {
                                                                        callParams.insert(index,  macro settings );
                                                                    }
                                                            default: 
                                                        }
                                                    }
                                                    if (args.length != callParams.length) {
                                                        var errorText = '${ExprTools.toString(e)}\n';
                                                        errorText += args.map(x->'${x.name}${x.opt ? " opt":""}').join(",");
                                                        errorText+="\n";
                                                        errorText += callParams.map(x->'${ExprTools.toString(x)}').join(",");

                                                        Context.fatalError('error adding ResolvedSettings to function ${ExprTools.toString(e)}: ${args.length} != ${callParams.length}\n${errorText}', e.pos);
                                                    }
                                                default: throw 'function required, got $funcType';
                                            }
                                        case EConst(CIdent(el)):
                                            providedValues.set(getString(name), funcExpr);
                                        case ENew(_, _):
                                            newValues.set(getString(name), funcExpr);
                                        case EField(e, field, kind):
                                            providedValues.set(getString(name), macro $e.$field);
                                        default:
                                            Context.fatalError('expected: value | call, got ${ExprTools.toString(funcExpr)}', v.pos);
                                    }
                                default: Context.fatalError('expected: name|"name" => value | call', v.pos);
                            }
                        default: Context.fatalError('expected: name => value, $v', v.pos);
                    }
                }
            case _: Context.fatalError('expected: name => value, ..., got $builderParams', builderParams.pos);
        }
        
        var retValFields = [];  // Fields in anon struct that will be returned
        var addElementsBlock = [];  // block that adds inputs as UIScreen.addElement
        var localVars = []; // Block that declares local vars for elements that are factories or new UIElement or UIElementDerived.create(...)
        var inputFields:Map<String, Expr> = []; // buildParams fields for MultiAnimBuilder.buildWithParameters
        var checkIfNullBlock = []; // Block that checks if retVal values are not null (e.g. factory methods is not called)

        for (key => value in providedValues) {
            var isUIElementType = TypeTools.unify(Context.typeof(value), uiElementType);
            var isH2dObjectType = TypeTools.unify(Context.typeof(value), h2dObjectType);

            retValFields.push({field: key, expr: value });
            if (isUIElementType) {
                addElementsBlock.push(macro addElement(retVal.$key, null)); // TODO: Add layer name/index
                inputFields.set(key, macro PVObject($value.getObject()));
            } else if (isH2dObjectType){
                inputFields.set(key, macro PVObject($value));
            } else throw 'unexpected type, h2d.Object or UIElement or descendant expected';
        }
        // for (key => value in providedValues) {
        //     retValFields.push({field: key, expr: value });
        //     addElementsBlock.push(macro addElement(retVal.$key, false));
        //     inputFields.set(key, macro PVObject($value.getObject()));
        // }

        for (key => value in newValues) {
            retValFields.push({field: key, expr: macro $i{key}});
            localVars.push(macro var $key = $value);
            addElementsBlock.push(macro addElement(macro key, false));
            inputFields.set(key, macro PVObject($i{key}.getObject()));
        }

        for (key => value in factoryFunctionsUIElements) {
            localVars.push(macro var $key);
            retValFields.push({field: key, expr: macro $i{key}});
            checkIfNullBlock.push(macro if (retVal.$key == null) {throw 'macroBuildWithParameters UIElement value  ' + $v{key} + ' is null (check if placeholder object is named correctly)';});
            final updated = macro (settings:wt.multianim.MultiAnimParser.ResolvedSettings)->{
                final element = $value;
                addElement(element, null); // TODO: Add layer name/index
                $i{key} = element;
                return element.getObject();
            }

            inputFields.set(key, macro PVFactory($updated));
        }

        for (key => value in factoryFunctionsH2dObjects) {
            localVars.push(macro var $key);
            retValFields.push({field: key, expr: macro $i{key}});
            checkIfNullBlock.push(macro if (retVal.$key == null) {throw 'macroBuildWithParameters h2d.Object value ' + $v{key} + ' is null (check if placeholder object is named correctly)';});
            final updated = macro (settings:wt.multianim.MultiAnimParser.ResolvedSettings)->{
                final element = $value;
                $i{key} = element;
                return element;
            }

            inputFields.set(key, macro PVFactory($updated));
        }



        // for (key => value in factoryFunctions) {
        //     localVars.push(macro var $key);
        //     retValFields.push({field: key, expr: macro $i{key}});

            
        //     final isUIElement = TypeTools.unify(Context.typeof(value), uiElementType);
        //     final isH2dObject = TypeTools.unify(Context.typeof(value), h2dObjectType);
        //     trace(isUIElement, isH2dObject);
            
        //     if (isUIElement) {
        //         final updated = macro (settings:wt.multianim.MultiAnimParser.ResolvedSettings)->{
        //             final element = $value;
        //             addElement(element, false);
        //             $i{key} = element;
        //             return element.getObject();
        //         }

        //         inputFields.set(key, macro PVFactory($updated));
        //     }
        //     // else {
        //     //     inputFields.set(key, macro PVFactory($value));
        //     // }
        // }
        function buildBuildWithParams() {
            var map : Array<Expr> = [];
            for (name => expr in inputFields) {
              map.push(macro $v{name} => $expr);
            }
            return macro @:nullSafety(Off) final builderResults = $builder.buildWithParameters($builderName, $inputParams, {placeholderObjects:$a{map}});

        }

        var retAnonStructure =  {
            pos: builder.pos, // re-use input position
            expr: EObjectDecl(retValFields) // pass to EObjectDecl
          };
        
        var funcName = 'generatedByMacroBuildWithParameters${Context.getLocalMethod()}${builder.pos.getInfos().max}Builder';



        retValFields.push({field: "builderResults", expr: macro builderResults });

        var funcBody = macro {
              ${buildBuildWithParams()}
              var retVal = $e{retAnonStructure};
              $b{addElementsBlock}
              $b{checkIfNullBlock}
              //getSceneRoot().addChild(builderResults.object); 
              return retVal;
          }
          funcBody = switch funcBody.expr { // Append localVars in the same scope
            case EBlock(exprs):
                {expr:EBlock(localVars.concat(exprs)), pos:funcBody.pos}
            default: throw "internal error";
          }
    
        var buildFunc = macro function $funcName() $funcBody; // append variables to func body


        var generatedExpression = macro {
            $buildFunc;
            $i{funcName}();
         }

 //          trace(ExprTools.toString(generatedExpression)); //Uncomment this if you'd like to see generated code (at COMPILE time, just run haxe project.hxml)
           
         
         return generatedExpression;
        //  return macro 2;
#else 
return null;
#end         
    }

}