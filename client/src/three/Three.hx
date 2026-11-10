package three;

import js.html.CanvasElement;

/*
 * Haxe descriptions ("externs") of the parts of three.js the game uses,
 * and only those (SPEC.md §10). three.js itself is loaded by the page as
 * the global `THREE` (version r128, its last build with a global).
 */

@:native("THREE.Vector3") extern class Vector3 {
	var x:Float;
	var y:Float;
	var z:Float;
	function new(?x:Float, ?y:Float, ?z:Float);
	function set(x:Float, y:Float, z:Float):Vector3;
}

@:native("THREE.Euler") extern class Euler {
	var x:Float;
	var y:Float;
	var z:Float;
}

@:native("THREE.Color") extern class Color {
	function new(colour:Int);
	function setHex(colour:Int):Color;
}

@:native("THREE.Matrix4") extern class Matrix4 {
	function new();
}

@:native("THREE.Object3D") extern class Object3D {
	function new();
	var position(default, null):Vector3;
	var rotation(default, null):Euler;
	var scale(default, null):Vector3;
	var matrix(default, null):Matrix4;
	var visible:Bool;
	var castShadow:Bool;
	var receiveShadow:Bool;
	var parent(default, null):Null<Object3D>;
	function add(child:Object3D):Void;
	function remove(child:Object3D):Void;
	function updateMatrix():Void;
	function lookAt(x:Float, y:Float, z:Float):Void;

	/** Visits this and everything inside it. */
	function traverse(visit:Object3D -> Void):Void;
}

@:native("THREE.Scene") extern class Scene extends Object3D {
	var background:Color;
}

@:native("THREE.Group") extern class Group extends Object3D {}

/** Any camera: something the renderer can look through. */
@:native("THREE.Camera") extern class Camera extends Object3D {}

/** A camera that sees as an eye does: further things smaller. */
@:native("THREE.PerspectiveCamera") extern class PerspectiveCamera extends Camera {
	function new(fieldOfView:Float, aspect:Float, near:Float, far:Float);
	var aspect:Float;
	function updateProjectionMatrix():Void;
}

/** Finds what is under a point on the screen, by casting a ray from the camera through it. */
@:native("THREE.Raycaster") extern class Raycaster {
	function new();
	function setFromCamera(screenPoint:Vector2, camera:Camera):Void;
	function intersectObjects(objects:Array<Object3D>, ?recursive:Bool):Array<{object:Object3D}>;
}

@:native("THREE.Vector2") extern class Vector2 {
	function new(x:Float, y:Float);
}

@:native("THREE.OrthographicCamera") extern class OrthographicCamera extends Camera {
	function new(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float);
	var left:Float;
	var right:Float;
	var top:Float;
	var bottom:Float;
	var near:Float;
	var far:Float;
	function updateProjectionMatrix():Void;
}

@:native("THREE.WebGLRenderer") extern class WebGLRenderer {
	function new(options:{antialias:Bool, ?alpha:Bool});
	var domElement(default, null):CanvasElement;
	var shadowMap(default, null):{enabled:Bool};
	function setSize(width:Float, height:Float, ?updateStyle:Bool):Void;
	function setPixelRatio(ratio:Float):Void;
	function render(scene:Scene, camera:Camera):Void;
}

@:native("THREE.BufferAttribute") extern class BufferAttribute {
	var needsUpdate:Bool;
}

@:native("THREE.Float32BufferAttribute") extern class Float32BufferAttribute extends BufferAttribute {
	function new(values:Array<Float>, itemSize:Int);

	/** The numbers themselves, three to a corner for positions. */
	var array(default, null):js.lib.Float32Array;

	/** How many corners (items) there are. */
	var count(default, null):Int;
}

@:native("THREE.BufferGeometry") extern class BufferGeometry {
	function new();
	function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry;
	function setIndex(index:Array<Int>):BufferGeometry;
	function computeVertexNormals():Void;

	/** The shape's corners and other per-corner numbers, by name ("position" is where each corner is). */
	var attributes(default, null):{position:Float32BufferAttribute};

	function rotateX(angle:Float):BufferGeometry;
	function rotateZ(angle:Float):BufferGeometry;
	function translate(x:Float, y:Float, z:Float):BufferGeometry;
}

@:native("THREE.BoxGeometry") extern class BoxGeometry extends BufferGeometry {
	function new(width:Float, height:Float, depth:Float, ?widthPieces:Int, ?heightPieces:Int, ?depthPieces:Int);
}

@:native("THREE.PlaneGeometry") extern class PlaneGeometry extends BufferGeometry {
	function new(width:Float, height:Float);
}

@:native("THREE.CircleGeometry") extern class CircleGeometry extends BufferGeometry {
	function new(radius:Float, segments:Int);
}

@:native("THREE.CylinderGeometry") extern class CylinderGeometry extends BufferGeometry {
	function new(radiusTop:Float, radiusBottom:Float, height:Float, segments:Int);
}

@:native("THREE.ConeGeometry") extern class ConeGeometry extends BufferGeometry {
	function new(radius:Float, height:Float, segments:Int);
}

/** A flat outline, drawn point to point (x across, y up), to fill as a shape. */
@:native("THREE.Shape") extern class Shape {
	function new();
	function moveTo(x:Float, y:Float):Shape;
	function lineTo(x:Float, y:Float):Shape;
}

@:native("THREE.ShapeGeometry") extern class ShapeGeometry extends BufferGeometry {
	function new(shape:Shape);
}

@:native("THREE.CanvasTexture") extern class CanvasTexture {
	function new(canvas:CanvasElement);
}

@:native("THREE.Material") extern class Material {
	var opacity:Float;
	var transparent:Bool;
}

@:native("THREE.MeshLambertMaterial") extern class MeshLambertMaterial extends Material {
	function new(options:{color:Int});
}

@:native("THREE.MeshBasicMaterial") extern class MeshBasicMaterial extends Material {
	function new(options:{?color:Int, ?map:CanvasTexture, ?transparent:Bool, ?opacity:Float, ?depthWrite:Bool});
}

@:native("THREE.Mesh") extern class Mesh extends Object3D {
	function new(geometry:BufferGeometry, material:Material);
	var material:Material;
	var geometry(default, null):BufferGeometry;
}

@:native("THREE.InstancedMesh") extern class InstancedMesh extends Mesh {
	function new(geometry:BufferGeometry, material:Material, count:Int);
	var instanceMatrix(default, null):BufferAttribute;
	var instanceColor(default, null):Null<BufferAttribute>;
	function setMatrixAt(index:Int, matrix:Matrix4):Void;
	function setColorAt(index:Int, colour:Color):Void;
}

@:native("THREE.HemisphereLight") extern class HemisphereLight extends Object3D {
	function new(sky:Int, ground:Int, intensity:Float);
}

/** A light like the sun: parallel rays from one direction, casting shadows. */
@:native("THREE.DirectionalLight") extern class DirectionalLight extends Object3D {
	function new(colour:Int, intensity:Float);

	/** What it shines at: it must be in the scene for a move to count. */
	var target(default, null):Object3D;

	var shadow(default, null):{
		mapSize:{width:Int, height:Int},
		camera:OrthographicCamera
	};
}
