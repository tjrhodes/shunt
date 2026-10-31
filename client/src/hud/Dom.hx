package hud;

import js.Browser;
import js.html.Element;

/** Making page elements, and changing their text only when it changes (so the browser isn't asked to redraw for nothing). */
class Dom {
	/** A new element with a class, perhaps some text, put inside a parent. */
	public static function make(tag:String, className:String, ?text:String, ?parent:Element):Element {
		var element = Browser.document.createElement(tag);
		element.className = className;
		if (text != null) element.textContent = text;
		if (parent != null) parent.appendChild(element);
		return element;
	}

	/** A button that does something when pressed. */
	public static function button(label:String, className:String, parent:Element, whenPressed:() -> Void):Element {
		var pressable = make("button", className, label, parent);
		pressable.setAttribute("type", "button");
		pressable.addEventListener("click", whenPressed);
		return pressable;
	}

	public static function setText(element:Element, text:String) {
		if (element.textContent != text) element.textContent = text;
	}
}
