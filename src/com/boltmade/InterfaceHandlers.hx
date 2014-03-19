package com.boltmade;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class InterfaceHandlers {
	static private var count = 0;
	macro public static function toHandler(f, to) {
		var method,klass;
		var isIface = true;

		switch(to.expr) {
			case EField({expr: i}, m):
				switch(Context.typeof({expr: i, pos: Context.currentPos()})) {
					case TType(ti, []):
						var iface;
						var sub = ti.get().name.replace("#", "");
						var module = ti.get().module.split(".");
						var name = module.pop();

						// Handling nested classes, which requires some mangling
						if(name.substr(0,1).toUpperCase() == name.substr(0,1)) {
							iface = {pack: module, name: name, sub: sub, params: []};
						} else {
							iface = {pack: module.concat([name]), name: sub, sub: null, params: []};
						}

						try {
							// If we can new this, it is a class, not an interface
							Context.typeof({expr: ENew(iface, []), pos: Context.currentPos()});

							klass = macro class Handler {
								private var fun = null;

								public function new(f) {
									super();
									fun = f;
								}
							};

							klass.kind = TDClass(iface, [], false);
							isIface = false;
						} catch(e:haxe.macro.Error) {
							klass = macro class Handler {
								private var fun = null;

								public function new(f) {
									fun = f;
								}
							};

							klass.kind = TDClass(null, [iface], false);
						}

						method = m;
					case _:
						return Context.error("toHandler expects Interface.method", Context.currentPos());
				}
			case _:
				return Context.error("toHandler expects Interface.method", Context.currentPos());
		}

		klass.name = Context.getLocalClass().get().name + "_" + Context.getLocalMethod() + "_" + count;
		count++;

		switch(Context.typeof(f)) {
			case TFun(args, ret):
				var body = {expr: ECall(
					{expr: EConst(CIdent("fun")), pos: Context.currentPos()},
					args.map(function(a) { return {expr: EConst(CIdent(a.name)), pos: Context.currentPos()}})
				), pos: Context.currentPos()};

				klass.fields.push({
					name: method,
					kind: FFun({
						args: args.map(function(a) {return {name: a.name, opt: a.opt, type: Context.toComplexType(a.t), value: null};}),
						ret: Context.toComplexType(ret),
						expr: isVoid(ret) ? body : {expr: EReturn(body), pos: Context.currentPos()},
						params: []
					}),
					access: [APublic],
					meta: isIface ? [] : [{name: ":overload", params: [], pos: Context.currentPos()}],
					pos: Context.currentPos()
				});
			case _:
				return Context.error("toHandler expects to be given a function", Context.currentPos());
		}

		Context.defineType(klass);

		return {expr: ENew({name: klass.name, params: [], pack: []}, [f]), pos: Context.currentPos()};
	}

	private static function isVoid(t:Type) {
		switch(t) {
			case TAbstract(t, _):
				return t.get().module == "StdTypes" && t.get().name == "Void";
			case _:
				return false;
		}
	}
}
