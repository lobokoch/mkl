package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityCRUDComponentTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	StringConcatenationExt imports
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateComponent]
	}
	
	def generateComponent(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityTSComponent)
	}
	
	def CharSequence doGenerateEntityTSComponent(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val fieldName = entity.fieldName
		val serviceName = entity.toEntityWebServiceClassName
		val serviceVar = serviceName.toFirstLower
		
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { «serviceName» } from './«webName».service';''')
		imports.add('''import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationComponentPathName»';''')
		entity.slots.filter[it.isEntity].forEach[
			val slotAsEntity = it.asEntity
			imports.newLine
			imports.add('''import { «slotAsEntity.toEntityWebServiceClassName» } from './«slotAsEntity.toEntityWebServiceNameWithPath»';''')
			imports.add('''import { «slotAsEntity.toDtoName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
			imports.add('''import { «slotAsEntity.toAutoCompleteName» } from './«slotAsEntity.toEntityWebModelNameWithPah»';''')
		]
		entity.slots.filter[it.isEnum].forEach[
			val slotAsEnum = it.asEnum
			imports.newLine
			imports.add('''import { «slotAsEnum.toDtoName» } from '«service.serviceWebEnumsPathName»';''')
		]
		
		val component = entity.toEntityWebCRUDComponentName
		
		val body = '''
		
		@Component({
		  selector: 'app-«component»',
		  templateUrl: './«component».html',
		  styleUrls: ['./«component».css']
		})
		
		export class «entity.toEntityWebComponentClassName» implements OnInit {
			
			«fieldName» = new «dtoName»();
			«entity.slots.filter[isEntity].map[mountAutoCompleteSuggestionsVar].join('\n\r')»
			«entity.slots.filter[isEnum].map[mountDropdownOptionsVar].join('\n\r')»
			«IF entity.isEnableReplication»«entity.entityReplicationQuantity» = 1;«ENDIF»
			
			constructor(
			    private «serviceVar»: «serviceName»,
			    private «service.toTranslationServiceVarName»: «service.toTranslationServiceClassName»,
			    «entity.slots.filter[isEntity].map[mountServiceConstructorInject].join('\n\r')»
			    private route: ActivatedRoute,
			    private messageService: MessageService
			) { 
				«entity.slots.filter[isEnum].map['''this.«it.webDropdownOptionsInitializationMethod»();'''].join('\n\r')»
			}
			
			ngOnInit() {
			    const id = this.route.snapshot.params['id'];
			    if (id) {
			      this.get«dtoName»ById(id);
			    }
			}
			
			begin(form: FormControl) {
			    form.reset();
			    setTimeout(function() {
			      this.«fieldName» = new «dtoName»();
			    }.bind(this), 1);
			}
			
			save(form: FormControl) {
			    if (this.isEditing) {
			      this.update(form);
			    } else {
			      this.create(form);
			    }
			}
			
			create(form: FormControl) {
			    this.«serviceVar».create(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.showSuccess('Registro criado com sucesso!');
			    }).
			    catch(error => {
			      this.showError('Erro ao criar registro: ' + error);
			    });
			}
			
			update(form: FormControl) {
			    this.«serviceVar».update(this.«fieldName»)
			    .then((«fieldName») => {
			      this.«fieldName» = «fieldName»;
			      this.showSuccess('Registro alterado!');
			    })
			    .catch(error => {
			      this.showError('Erro ao atualizar registro: ' + error);
			    });
			}
			
			get«dtoName»ById(id: string) {
			    this.«serviceVar».retrieve(id)
			    .then((«fieldName») => this.«fieldName» = «fieldName»)
			    .catch(error => {
			      this.showError('Erro ao buscar registro: ' + id);
			    });
			}
			
			get isEditing() {
			    return Boolean(this.«fieldName».id);
			}
			«IF entity.isEnableReplication»
			
			replicar«dtoName»() {
			    this.«serviceVar».replicar«dtoName»(this.«fieldName».id, this.«fieldName».agrupador, this.«entity.entityReplicationQuantity»)
			    .then((result) => {
			      if (result === true) {
			        this.showSuccess('Os registros foram criados com sucesso.');
			      } else {
			        this.showError('Não foi possível criar os registros.');
			      }
			    })
			    .catch(error => {
			      this.showError('Ocorreu um erro ao criar os registros: ' + error);
			    });
			  }
			«ENDIF»
			
			«entity.slots.filter[isEntity].map[mountAutoComplete].join('\n\r')»
			
			«entity.slots.filter[isEnum].map[it.generateEnumInitializationOptions].join»
			
			public showSuccess(msg: string) {
			    this.messageService.add({severity: 'success', summary: 'Successo', detail: msg});
			}
			
			public showError(msg: string) {
			    this.messageService.add({severity: 'error', summary: 'Erro', detail: msg});
			}
			
			«buildTranslationMethod(service)»
		}
		'''
		
		val source = imports.ln.toString + body
		source
	}
	
	def CharSequence generateEnumInitializationOptions(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		private «slot.webDropdownOptionsInitializationMethod»() {
		    this.«slot.webDropdownOptions» = [
		    	«enumerarion.items.map['''{ label: this.getTranslation('«slot.translationKey + '_' + it.name.toLowerCase»'), value: '«it.name»' }'''].join(', \r\n')»
		    ];
		}
		  
		'''
	}
	
	def CharSequence mountDropdownOptionsVar(Slot slot) {
		val enumerarion = slot.asEnum
		'''
		«slot.webDropdownOptions»: «enumerarion.toDtoName»[];
		'''
	}
	
	def CharSequence mountAutoCompleteSuggestionsVar(Slot slot) {
		val entity = slot.asEntity
		'''
		«slot.webAutoCompleteSuggestions»: «entity.toAutoCompleteName»[];
		'''
	}
	
	def CharSequence mountAutoComplete(Slot slot) {
		val entity = slot.asEntity
		val serviceName = entity.toEntityWebServiceClassName.toFirstLower
		
		var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id]
		if (resultSlots.isEmpty) {
			resultSlots = entity.slots.filter[it.autoCompleteResult]
		}
		
		'''
		«slot.toAutoCompleteClearMethodName»(event) {
			// The autoComplete value has been reseted
			this.«slot.ownerEntity.fieldName».«slot.fieldName» = null;
		}
		
		«slot.toAutoCompleteName»(event) {
		    const query = event.query;
		    this.«serviceName»
		      .autoComplete(query)
		      .then((result) => {
		        this.«slot.webAutoCompleteSuggestions» = result as «entity.toAutoCompleteName»[];
		      })
		      .catch(error => {
		        this.showError('Erro ao buscar registros com o termo: ' + query);
		      });
		}
		
		«IF !resultSlots.isEmpty»
		«slot.webAutoCompleteFieldConverter»(«slot.fieldName»: «entity.toAutoCompleteName») {
			if («slot.fieldName») {
				return «resultSlots.map['''«slot.fieldName».«it.fieldName»'''].join(" + ' - ' + ")»;
			} else {
				return null;
			}
		}
		«ENDIF»
		'''
	}
	
	def CharSequence mountServiceConstructorInject(Slot slot) {
		val serviceName = slot.asEntity.toEntityWebServiceClassName
		'''
		private «serviceName.toFirstLower»: «serviceName»,
		'''
	}
	
	def void initializeImports(Entity entity) {
		imports.add('''
		import { Component, OnInit } from '@angular/core';
		import { FormControl } from '@angular/forms';
		import { ActivatedRoute, Router } from '@angular/router';
		import {MessageService} from 'primeng/api';
		''')
	}
	
	
}