package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityRoutingModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateSecurityRoutingModule
	}
	
	def generateSecurityRoutingModule(String securityPath) {
		val name = securityPath + 'security-routing.module'
		name.generateSecurityRoutingModuleTS
	}
	
	def generateSecurityRoutingModuleTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateSecurityRoutingModuleTSContent)
	}
	
	def CharSequence generateSecurityRoutingModuleTSContent() {
		'''
		import { NgModule } from '@angular/core';
		import { CommonModule } from '@angular/common';
		
		@NgModule({
		  imports: [
		    CommonModule
		  ],
		  declarations: []
		})
		export class SecurityRoutingModule { }
		'''
	}
	
}