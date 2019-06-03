package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateModule]
	}
	
	def generateModule(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebModuleName + '.ts'
		generateFile(entityFile, entity.doGenerate)
	}
	
	def CharSequence doGenerate(Entity entity) {
		val tranlationServiceName = service.toTranslationServiceClassName
		val serviceName = entity.toEntityWebServiceClassName
		val entityName = entity.toDtoName
		val entityWebName = entity.toWebName
		
		'''
		import { CommonModule } from '@angular/common';
		import { FormsModule } from '@angular/forms';
		import { NgModule } from '@angular/core';
		import { InputTextModule } from 'primeng/inputtext';
		import { ButtonModule } from 'primeng/button';
		import { InputTextareaModule } from 'primeng/inputtextarea';
		import { TableModule } from 'primeng/table';
		import { TooltipModule } from 'primeng/tooltip';
		import { ToastModule } from 'primeng/toast';
		import { ConfirmDialogModule } from 'primeng/confirmdialog';
		import { AutoCompleteModule } from 'primeng/autocomplete';
		import { PanelModule } from 'primeng/panel';
		import { InputSwitchModule } from 'primeng/inputswitch';
		import { AccordionModule } from 'primeng/accordion';
		import { SpinnerModule } from 'primeng/spinner';
		import { DialogModule } from 'primeng/dialog';
		import { DropdownModule } from 'primeng/dropdown';
		
		// Kerubin - BEGIN
		import { «tranlationServiceName» } from './../i18n/«service.serviceWebTranslationComponentPathName»';
		import { «serviceName» } from './«entityWebName».service';
		import { «entityName»ListComponent } from './list-«entityWebName».component';
		import { «entityName»Component } from './crud-«entityWebName».component';
		import { «entityName»RoutingModule } from './«entityWebName»-routing.module';
		// Kerubin - END
		
		@NgModule({
		
		  imports: [
		    // PrimeNG
		    CommonModule,
		    FormsModule,
		    InputTextModule,
		    ButtonModule,
		    InputTextareaModule,
		    TableModule,
		    TooltipModule,
		    ToastModule,
		    ConfirmDialogModule,
		    AutoCompleteModule,
		    PanelModule,
		    InputSwitchModule,
		    AccordionModule,
		    SpinnerModule,
		    DialogModule,
		    DropdownModule,
		
		    // Kerubin
		    «entityName»RoutingModule
		
		  ],
		
		  declarations: [
		    «entityName»Component,
		    «entityName»ListComponent
		  ],
		
		  exports: [
		
		  ],
		
		  providers: [
		    «serviceName»,
		    «tranlationServiceName»
		  ]
		
		})
		
		export class «entity.toEntityWebModuleClassName» { }
		'''		
		
	}
	
	
	
	
	
	
	
}