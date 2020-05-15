package br.com.kerubin.dsl.mkl.generator

import java.util.List
import br.com.kerubin.dsl.mkl.model.Entity
import java.util.LinkedHashSet

class ActionConfig {
	public Entity entity;
	public String customServiceName; 
	public String action;
	public String prefix 
	public List<String> params; 
	public List<String> paramsTypes; 
	public boolean isVoid;
	public LinkedHashSet<String> customActions = newLinkedHashSet
	
	def ActionConfig setCustomActions(LinkedHashSet<String> customActions) {
		this.customActions = customActions
		return this
	}
	
	def ActionConfig setEntity(Entity entity) {
		this.entity = entity;
		this;
	}
	
	def ActionConfig setCustomServiceName(String customServiceName) {
		this.customServiceName = customServiceName;
		this;
	}
	
	def ActionConfig setAction(String action) {
		this.action = action;
		this;
	}
	
	def ActionConfig setPrefix(String prefix) {
		this.prefix = prefix;
		this;
	}
	
	def ActionConfig setParams(List<String> params) {
		this.params = params;
		this;
	}
	
	def ActionConfig setParamsTypes(List<String> paramsTypes) {
		this.paramsTypes = paramsTypes;
		this;
	}
	
	def ActionConfig setIsVoid(boolean isVoid) {
		this.isVoid = isVoid;
		this;
	}
	
	
}

