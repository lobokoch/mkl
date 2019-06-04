package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebAppModuleTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateComponent
	}
	
	def generateComponent() {
		val path = webAppDir
		val filePath = path + toWebAppModuleName + '.ts'
		generateFile(filePath, generateAppComponent)
	}
	
	def CharSequence generateAppComponent() {
		'''
		import { BrowserModule } from '@angular/platform-browser';
		import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
		import { NgModule } from '@angular/core';
		
		import { AppComponent } from './app.component';
		import { CoreModule } from './core/core.module';
		import { AppRoutingModule } from './app-routing.module';
		
		@NgModule({
		  declarations: [
		    AppComponent
		  ],
		
		  imports: [
		    BrowserModule,
		    BrowserAnimationsModule,
		
		    CoreModule,
		    AppRoutingModule
		  ],
		
		  providers: [
		
		  ],
		
		  bootstrap: [
		    AppComponent
		  ]
		})
		
		export class AppModule {
		
		}

		'''
	}
	
}