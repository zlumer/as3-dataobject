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
		/**
		 * map "property"=>"function(obj)"
		 * used to maintain relations between objects in the model
		*/
		protected var __relations:Object;
		/** one-to-many relationships */
		protected var __arrayRelations:Object;
		
		public var id:String;
		
		public function DataObject(_import:Object = null)
		{
			__relations ||= { };
			__arrayRelations ||= { };
			
			if (_import)
				update(_import);
		}
		public function update(_import:Object):void
		{
			PropertyCopy.copy(this, _import, __relations, __arrayRelations);
		}
		public function export():Object
		{
			var obj:Object = {};
			
			// class members
			var __variables:Object = PropertyCopy.getVariables(this);
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
					obj[name] = getId(obj[name]);
			}
			for (name in __arrayRelations)
			{
				if (obj[name])
					obj[name] = unblessArray(obj[name]);
			}
			return obj;
		}
		/**
		 * Clones this object.
		 * Override to customize behavior or improve performance.
		 */
		public function clone():DataObject
		{
			return new (getDefinitionByName(getQualifiedClassName(this)))(this);
		}
		// uncomment if you want to have nice traces
		/*public function toString():String
		{
			return JSON.stringify(export());
		}*/
		
		private static function getId(obj:Object):int
		{
			return obj["id"];
		}
		private static function unblessArray(array:Array):Array
		{
			return PropertyCopy.blessArray(array, getId);
		}
		// safely make minimal object from id
		public static function id(data:*):*
		{
			if (data == null)
				return null; // DataObject.id(null) == null
			
			switch(typeof(data))
			{
				case "number":
				case "string":
					return { id:data };
				default:
					return data;
			}
				
			
			return data;
		}
		public static function entity(data:*, map:Object, defaultClass:Class):*
		{
			if (data == null)
				return null; // DataObject.user(null) == null
			
			var t:String = typeof(data);
			if (t == "number" || t == "string")
			{
				// we don't need to update anything
				return map[data];
			}
			else
			{
				// get id
				var id:String = data["id"];
				if (id)
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
				else
				{
					return new defaultClass(data);
				}
			}
			return null;
		}
		public static function justGet(data:*, map:Object, defaultClass:Class):*
		{
			var id:String = id(data)["id"];
			return id ? map[id] : null;
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