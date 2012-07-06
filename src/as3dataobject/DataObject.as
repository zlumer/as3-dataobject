/**
* Licensed under the MIT License
*
* Copyright (c) 2011-2012 Dmitry Radkovskiy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of
* this software and associated documentation files (the "Software"), to deal in
* the Software without restriction, including without limitation the rights to
* use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
* the Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
* FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
* IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
* http://www.opensource.org/licenses/mit-license.php
*
* https://github.com/zlumer/as3-dataobject
*
*/
package as3dataobject
{
	import avmplus.getQualifiedClassName;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	public class DataObject
	{
		private var __variables:Object;
		
		/**
		 * map "property"=>"function(obj)"
		 * used to maintain relations between objects in the model
		*/
		protected var __relations:Object;
		/** one-to-many relationships */
		protected var __arrayRelations:Object;
		
		public var id:String;
		
		private static var _classVariables:Object = { };
		
		public function DataObject(_import:Object = null)
		{
			__relations ||= { };
			__arrayRelations ||= { };
			
			// get saved declaration of the class
			var className:String = getQualifiedClassName(this);
			__variables = _classVariables[className];
			
			if (!__variables) // first object of that class is created
			{
				___test();
				__variables = _classVariables[className] = __createVariables();
			}
			
			if (_import)
				update(_import);
		}
		public function update(_import:Object):void
		{
			if (!_import)
				return;
			
			for (var name:* in _import)
			{
				copyProp(name, _import);
			}
			for (name in __variables)
			{
				// is readable
				if (name in __variables && __variables[name].indexOf("r") != -1)
				// and is included in import
					if (_import.hasOwnProperty(name))
						copyProp(name, _import);
			}
		}
		private function copyProp(name:String, _import:Object):void
		{
			// not writeable
			if (name in __variables && (__variables[name].indexOf("w") == -1))
				return;
			
			// already have one
			if (this[name] === _import[name])
				return;
			
			if (name in __relations)
				this[name] = __relations[name](DataObject.id(_import[name]));
			else if (name in __arrayRelations)
				this[name] = blessArray(_import[name], __arrayRelations[name]);
			else
				this[name] = _import[name];
		}
		public function export():Object
		{
			var obj:Object = {};
			
			// class members
			for (var item:* in __variables)
			{
				if (__variables[item].indexOf("r") != -1)
					obj[item] = this[item];
			}
			// dynamic fields
			for (var name:String in this)
			{
				obj[name] = this[name];
			}
			for (name in __relations)
			{
				if (obj[name])
					obj[name] = obj[name]["id"]
			}
			for (name in __arrayRelations)
			{
				if (obj[name])
					obj[name] = unblessArray(obj[name]);
			}
			return obj;
		}
		public function clone():DataObject
		{
			return new (getDefinitionByName(getQualifiedClassName(this)))(this);
		}
		// uncomment if you want to have nice traces
		/*public function toString():String
		{
			return JSON.stringify(export());
		}*/
		
		private function __createVariables():Object
		{
			// partially based on JSONEncoder by Adobe.
			
			var variables:Object = {};
			
			
			var classInfo:XML = describeType( this );
			for each ( var v:XML in classInfo..*.(name() == "variable" || (name() == "accessor")))
			{
				// Issue #110 - If [Transient] metadata exists, then we should skip
				if ( v.metadata && v.metadata.( @name == "Transient" ).length() > 0 )
				{
					continue;
				}
				var access:String = v.attribute("access");
				if (v.name() == "accessor")
				{
					variables[v.@name] = "";
					// Make sure accessors are readable
					if (access.charAt( 0 ) == "r")
					{
						variables[v.@name] += "r";
					}
					// Make sure accessors are writeable
					if (access.charAt( 0 ) == "w" || access.charAt( 4 ) == "w")
					{
						variables[v.@name] += "w";
					}
				}
				else
					variables[v.@name] = "rw";
			}
			
			return variables;
		}
		
		private static function blessArray(array:Array, bless:Function):Array
		{
			if (!array)
				return array;
			
			array = array.slice();
			
			if (!array.length)
				return array;
			
			for (var i:int = 0; i < array.length; i++)
			{
				array[i] = bless(array[i]);
			}
			return array;
		}
		private static function unblessArray(array:Array):Array
		{
			array = array.slice();
			
			if (!array || !array.length)
				return array;
			
			for (var i:int = 0; i < array.length; i++)
			{
				array[i] = array[i]["id"];
			}
			return array;
		}
		// safely make minimal object from id
		public static function id(data:*):*
		{
			if (data == null)
				return null; // DataObject.id(null) == null
			
			if (typeof(data) == "number")
				return { id:data };
			
			return data;
		}
		public static function entity(data:*, map:Object, defaultClass:Class, onUpdate:String = null /*unused*/):*
		{
			if (data == null)
				return null; // DataObject.user(null) == null
			
			if (typeof(data) == "number")
			{
				// we don't need to update anything
				return map[int(data)];
			}
			else
			{
				// get id
				var id:int = data["id"];
				if (id > 0)
				{
					var _entity:DataObject = map[id];
					if (_entity)
					{
						// update already existing entity with new data
						_entity.update(data);
					}
					else
					{
						// create non-existing entity with all known data
						_entity = new defaultClass(data);
						map[id] = _entity;
					}
					return _entity;
				}
			}
			return null;
		}
		public static function remove(data:*, map:Object):void
		{
			var e:* = id(data);
			if (e && (e["id"] in map))
				delete map[e["id"]];
		}
		
		
		private function ___test():void
		{
			// test if the class is dynamic
			
			var rnd:String = Math.random() + "_" + Math.random() + "_" + Math.random();
			try
			{
				this[rnd] = rnd;
				delete this[rnd];
			}
			catch (err:Error)
			{
				throw new Error("Class [" + getQualifiedClassName(this) + "] should be dynamic!");
			}
		}
	}
}