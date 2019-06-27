package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import br.com.kerubin.dsl.mkl.model.Slot

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
		val relations = entity.slots.filter[isEntity && !asEntity.isSameEntity(entity)]
		val hasRelations = !relations.isEmpty
		
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
		import {CalendarModule} from 'primeng/calendar';
		import { CurrencyMaskModule } from 'ng2-currency-mask';
		import {CardModule} from 'primeng/card';
		
		// Kerubin - BEGIN
		import { «tranlationServiceName» } from './../i18n/«service.serviceWebTranslationComponentPathName»';
		import { «serviceName» } from './«entityWebName».service';
		import { «entityName»ListComponent } from './list-«entityWebName».component';
		import { «entityName»Component } from './crud-«entityWebName».component';
		import { «entityName»RoutingModule } from './«entityWebName»-routing.module';
		«IF hasRelations»
		«relations.generateImports_1_RelationModules»
		«ENDIF»
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
			CalendarModule,
			CurrencyMaskModule,
			CardModule,
		
		    // Kerubin
		    «entityName»RoutingModule«IF hasRelations»,«ENDIF»
		    «IF hasRelations»
    		«relations.generateImports_2_RelationModules»
    		«ENDIF»
		
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
	
	def CharSequence generateImports_2_RelationModules(Iterable<Slot> slots) {
		slots.map[generateImport_2_RelationModule].join(',\r\n')
	}
	
	def CharSequence generateImport_2_RelationModule(Slot slot) {
		val moduleName = slot.asEntity.toEntityWebModuleClassName
		'''	«moduleName»'''
	}	
	
	def CharSequence generateImports_1_RelationModules(Iterable<Slot> slots) {
		'''
		«slots.map[generateImport_1_RelationModule].join»
		'''
	}
	
	def CharSequence generateImport_1_RelationModule(Slot slot) {
		val webModuleName = slot.asEntity.toEntityWebModuleClassName
		val webName = slot.asEntity.toWebName
		'''
		import { «webModuleName» } from '../«webName»/«webName».module';
		'''
	}	
	
	
	
	
	
}