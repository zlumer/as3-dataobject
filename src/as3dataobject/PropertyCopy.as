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
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	/**
	 * ...
	 * @author zlumer
	 */
	public class PropertyCopy
	{
		private static var _classVariables:Object = { };
		
		public static function copy(to:*, from:*, relations:Object, arrayRelations:Object):void
		{
			if (!to || !from)
				return;
			
			var className:String = getQualifiedClassName(to);
			var variables:Object = (_classVariables[className] ||= __createVariables(to));
			
			for (var name:String in variables)
			{
				// is writeable
				if (variables[name].indexOf("w") != -1)
				// and is included in import
					if (from.hasOwnProperty(name) && from[name] !== to[name])
						if (name in relations)
							// apply relationship
							to[name] = relations[name](from[name]);
						else if (name in arrayRelations)
							// apply one-to-many relationship[
							to[name] = blessArray(from[name], arrayRelations[name]);
						else
							// just copy value
							to[name] = from[name];
			}
		}
		public static function getVariables(obj:*, className:String = null):Object
		{
			className ||= getQualifiedClassName(obj);
			return (_classVariables[className] ||= __createVariables(obj));
		}
		internal static function blessArray(array:Array, bless:Function):Array
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
		private static function __createVariables(type:*):Object
		{
			// partially based on JSONEncoder by Adobe.
			
			var variables:Object = {};
			
			var classInfo:XML = describeType(type);
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
	}
}