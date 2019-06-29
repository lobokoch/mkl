package br.com.kerubin.dsl.mkl.generator.web.account

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebAccountModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateAccountModule
	}
	
	def generateAccountModule() {
		val path = getWebAccountDir + '/'
		val fileName = path + 'kerubin-account.module.ts'
		generateFile(fileName, doGenerateAccountModule)
	}
	
	def CharSequence doGenerateAccountModule() {
		'''
		// Angular
		import { FormsModule } from '@angular/forms';
		import { CommonModule } from '@angular/common';
		import { NgModule } from '@angular/core';
		import { RouterModule } from '@angular/router';
		
		// PrimeMG
		import { DropdownModule } from 'primeng/dropdown';
		import { ButtonModule } from 'primeng/button';
		import { InputTextModule } from 'primeng/inputtext';		
		
		// Kerubin
		import { NewAccountComponent } from './newaccount/newaccount.component';
		import { ConfirmAccountComponent } from './confirmaccount/confirmaccount.component';
		import { ConfigNewAccountComponent } from './confignewaccount/confignewaccount.component';
		
		@NgModule({
		
		  imports: [
		    CommonModule,
		    FormsModule,
		    InputTextModule,
		    ButtonModule,
		    DropdownModule
		  ],
		
		  declarations: [
		    ConfigNewAccountComponent,
		    ConfirmAccountComponent,
		    NewAccountComponent
		  ],
		
		  exports: [
		    ConfigNewAccountComponent,
		    ConfirmAccountComponent,
		    NewAccountComponent,
		    RouterModule
		  ]
		
		})
		
		export class KerubinAccountModule {  }
		
		'''
	}
	
}