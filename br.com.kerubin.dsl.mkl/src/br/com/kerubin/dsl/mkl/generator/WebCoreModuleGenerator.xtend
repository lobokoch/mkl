package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebCoreModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebCoreDir
		path.generateCoreModule
	}
	
	def generateCoreModule(String securityPath) {
		val name = securityPath + 'core.module'
		name.generateCoreModuleTS
	}
	
	def generateCoreModuleTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateCoreModuleTSContent)
	}
	
	def CharSequence generateCoreModuleTSContent() {
		'''
		import { JwtHelperService } from '@auth0/angular-jwt';
		
		// Angular
		import { NgModule } from '@angular/core';
		import { CommonModule } from '@angular/common';
		
		// Kerubin
		import { MessageHandlerService } from './message-handler.service';
		import { HttpClientWithToken } from '../security/http-client-token';
		
		
		
		@NgModule({
		  imports: [
		    CommonModule
		  ],
		  declarations: [
		  ],
		  exports: [ // app.module precisa desses modulos
		  ],
		  providers: [
		    MessageHandlerService,
		    HttpClientWithToken,
		  	// Kerubin End
		    JwtHelperService
		  ]
		})
		export class CoreModule { }
		
		'''
	}
	
}