package br.com.kerubin.dsl.mkl.util

import java.util.Arrays

class Param {
	public var String name;
	public var String type;
	public var String value;
	
	new(String name, String type) {
		this.name = name
		this.type = type
	}
	
	new(String name, String type, String value) {
		this.name = name
		this.type = type
		this.value = value
	}
	
	def static of(String name, String type) {
		new Param(name, type)
	}
	
	def static of(String name, String type, String value) {
		new Param(name, type, value)
	}
	
	def static buildParamsSignature(Param... paramArray) {
		val params = Arrays.asList(paramArray).toList.filter[it !== null]
		params.map[it.type + ' ' + it.name].join(', ')
	}
	
	def static buildParamsCall(Param... paramArray) {
		val params = Arrays.asList(paramArray).toList.filter[it !== null]
		params.map[it.name].join(', ')
	}
}